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
