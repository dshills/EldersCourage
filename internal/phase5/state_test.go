package phase5

import "testing"

func TestCreateItemInstanceSeparatesDefinitionState(t *testing.T) {
	definition := ItemDefinition{ID: "ashen-ring", Name: "Ashen Ring", DefaultState: Unidentified}

	instance := CreateItemInstance(definition, 1, 7)

	if instance.InstanceID != "ashen-ring_0007" {
		t.Fatalf("InstanceID = %q, want ashen-ring_0007", instance.InstanceID)
	}
	if instance.ItemID != definition.ID {
		t.Fatalf("ItemID = %q, want %q", instance.ItemID, definition.ID)
	}
	if instance.KnowledgeState != Unidentified {
		t.Fatalf("KnowledgeState = %q, want unidentified", instance.KnowledgeState)
	}
	definition.DefaultState = Known
	if instance.KnowledgeState != Unidentified {
		t.Fatalf("instance knowledge changed with definition, got %q", instance.KnowledgeState)
	}
}

func TestAddItemStacksConsumablesAndSplitsEquipment(t *testing.T) {
	potion := ItemDefinition{ID: "potion", Stackable: true}
	blade := ItemDefinition{ID: "blade", Stackable: false}
	inventory := NewInventory()

	inventory = AddItem(inventory, potion, 1)
	inventory = AddItem(inventory, potion, 2)
	inventory = AddItem(inventory, blade, 2)

	if len(inventory.Items) != 3 {
		t.Fatalf("len(Items) = %d, want 3", len(inventory.Items))
	}
	if inventory.Items[0].ItemID != "potion" || inventory.Items[0].Quantity != 3 {
		t.Fatalf("stacked potion = %+v, want quantity 3", inventory.Items[0])
	}
	if inventory.Items[1].InstanceID == inventory.Items[2].InstanceID {
		t.Fatalf("equipment instances should have unique IDs: %+v", inventory.Items[1:])
	}
}

func TestEquipReferencesInstanceIDAndResolvesStats(t *testing.T) {
	definitions := map[string]ItemDefinition{
		"blade": {ID: "blade", Stackable: false, Equippable: true, EquipmentSlot: "weapon", Stats: Stats{Strength: 2}},
		"vest":  {ID: "vest", Stackable: false, Equippable: true, EquipmentSlot: "armor", Stats: Stats{Defense: 3}},
	}
	inventory := NewInventory()
	inventory = AddItem(inventory, definitions["blade"], 1)
	inventory = AddItem(inventory, definitions["vest"], 1)

	var ok bool
	inventory, ok = Equip(inventory, definitions, inventory.Items[0].InstanceID)
	if !ok {
		t.Fatal("Equip blade returned false")
	}
	inventory, ok = Equip(inventory, definitions, inventory.Items[1].InstanceID)
	if !ok {
		t.Fatal("Equip vest returned false")
	}

	if inventory.Equipment["weapon"] != inventory.Items[0].InstanceID {
		t.Fatalf("weapon slot = %q, want %q", inventory.Equipment["weapon"], inventory.Items[0].InstanceID)
	}
	stats := EquipmentStats(inventory, definitions)
	if stats.Strength != 2 || stats.Defense != 3 {
		t.Fatalf("EquipmentStats = %+v, want strength 2 defense 3", stats)
	}
}

func TestIdentifyRevealsIdentifyPropertiesOnly(t *testing.T) {
	definition := ashenRingDefinition()
	instance := CreateItemInstance(definition, 1, 1)

	instance, revealed, ok := IdentifyItem(instance, definition)
	if !ok {
		t.Fatal("IdentifyItem returned false")
	}
	if len(revealed) != 1 || revealed[0].ID != "ember_memory" {
		t.Fatalf("revealed = %+v, want ember_memory only", revealed)
	}
	if instance.KnowledgeState != Identified {
		t.Fatalf("KnowledgeState = %q, want identified", instance.KnowledgeState)
	}
	if hasString(instance.RevealedPropertyIDs, "hungry_spark") || hasString(instance.RevealedPropertyIDs, "blood_price") {
		t.Fatalf("Identify revealed locked or cursed properties: %+v", instance.RevealedPropertyIDs)
	}
}

func TestAttunementThresholdsRevealOnce(t *testing.T) {
	definition := ashenRingDefinition()
	instance := CreateItemInstance(definition, 1, 1)

	instance, revealed := AddAttunementPoints(instance, definition, 4)
	if instance.Attunement.Level != 1 {
		t.Fatalf("Level = %d, want 1", instance.Attunement.Level)
	}
	if len(revealed) != 0 {
		t.Fatalf("revealed at level 1 = %+v, want none", revealed)
	}
	instance, revealed = AddAttunementPoints(instance, definition, 1)
	if instance.Attunement.Level != 2 {
		t.Fatalf("Level = %d, want 2", instance.Attunement.Level)
	}
	if len(revealed) != 1 || revealed[0].ID != "hungry_spark" {
		t.Fatalf("revealed = %+v, want hungry_spark", revealed)
	}
	instance, revealed = AddAttunementPoints(instance, definition, 1)
	if len(revealed) != 0 {
		t.Fatalf("duplicate reveal = %+v, want none", revealed)
	}
}

func TestLevelGatedPropertiesRevealAndApply(t *testing.T) {
	definition := ItemDefinition{ID: "charm", Properties: []ItemProperty{{
		ID:           "patient_light",
		Requirements: []Requirement{{Type: "player_level", Value: 3}},
		Effects:      []ItemEffect{{Type: "stat_bonus", Stat: "spellPower", Amount: 1}},
	}}}
	instance := CreateItemInstance(definition, 1, 1)

	instance, revealed := RevealLevelGatedProperties(instance, definition, 2)
	if len(revealed) != 0 {
		t.Fatalf("level 2 revealed = %+v, want none", revealed)
	}
	if stats := RevealedStats(instance, definition); stats.SpellPower != 0 {
		t.Fatalf("SpellPower before reveal = %d, want 0", stats.SpellPower)
	}
	instance, revealed = RevealLevelGatedProperties(instance, definition, 3)
	if len(revealed) != 1 {
		t.Fatalf("level 3 revealed %d properties, want 1", len(revealed))
	}
	if stats := RevealedStats(instance, definition); stats.SpellPower != 1 {
		t.Fatalf("SpellPower after reveal = %d, want 1", stats.SpellPower)
	}
}

func TestHiddenCurseTriggersOnceAndHealthCostRepeats(t *testing.T) {
	definition := ashenRingDefinition()
	instance := CreateItemInstance(definition, 1, 1)

	instance, revealed := RevealTriggeredCurses(instance, definition, "combat_use")
	if len(revealed) != 1 || revealed[0].ID != "blood_price" {
		t.Fatalf("revealed = %+v, want blood_price", revealed)
	}
	if cost := RevealedHealthCost(instance, definition, "combat_use"); cost != 2 {
		t.Fatalf("health cost = %d, want 2", cost)
	}
	instance, revealed = RevealTriggeredCurses(instance, definition, "combat_use")
	if len(revealed) != 0 {
		t.Fatalf("duplicate curse reveal = %+v, want none", revealed)
	}
	if cost := RevealedHealthCost(instance, definition, "combat_use"); cost != 2 {
		t.Fatalf("repeated health cost = %d, want 2", cost)
	}
}

func TestUnrevealedDamageBonusDoesNotApplyBeforeReveal(t *testing.T) {
	definition := ashenRingDefinition()
	instance := CreateItemInstance(definition, 1, 1)
	if bonus := RevealedSkillDamageBonus(instance, definition, "ember_bolt"); bonus != 0 {
		t.Fatalf("bonus before reveal = %d, want 0", bonus)
	}
	instance, _ = AddAttunementPoints(instance, definition, 5)
	if bonus := RevealedSkillDamageBonus(instance, definition, "ember_bolt"); bonus != 3 {
		t.Fatalf("bonus after reveal = %d, want 3", bonus)
	}
}

func ashenRingDefinition() ItemDefinition {
	return ItemDefinition{
		ID:           "ashen-ring",
		DefaultState: Unidentified,
		Attunable:    true,
		Properties: []ItemProperty{
			{
				ID:           "ember_memory",
				Requirements: []Requirement{{Type: "identify"}},
				Effects:      []ItemEffect{{Type: "stat_bonus", Stat: "spellPower", Amount: 1}},
			},
			{
				ID:           "hungry_spark",
				Requirements: []Requirement{{Type: "attunement", Value: 2}},
				Effects:      []ItemEffect{{Type: "damage_bonus", SkillID: "ember_bolt", Amount: 3}},
			},
			{
				ID:           "blood_price",
				Cursed:       true,
				Requirements: []Requirement{{Type: "combat_use"}},
				Effects:      []ItemEffect{{Type: "health_cost", Amount: 2}},
			},
		},
	}
}
