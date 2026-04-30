package phase5

import "fmt"

type KnowledgeState string

const (
	Known               KnowledgeState = "known"
	Unidentified        KnowledgeState = "unidentified"
	PartiallyIdentified KnowledgeState = "partially_identified"
	Identified          KnowledgeState = "identified"
)

type Stats struct {
	Strength       int
	Defense        int
	SpellPower     int
	MaxHealthBonus int
	MaxManaBonus   int
}

type ItemDefinition struct {
	ID            string
	Name          string
	Type          string
	Stackable     bool
	Equippable    bool
	EquipmentSlot string
	Stats         Stats
	DefaultState  KnowledgeState
	Properties    []ItemProperty
	Attunable     bool
}

type ItemInstance struct {
	InstanceID            string
	ItemID                string
	Quantity              int
	KnowledgeState        KnowledgeState
	IdentifiedPropertyIDs []string
	RevealedPropertyIDs   []string
	Attunement            AttunementState
}

type Requirement struct {
	Type  string
	Value int
}

type ItemEffect struct {
	Type    string
	Stat    string
	SkillID string
	Amount  int
}

type ItemProperty struct {
	ID           string
	Name         string
	Kind         string
	Visibility   string
	Cursed       bool
	Requirements []Requirement
	Effects      []ItemEffect
}

type AttunementState struct {
	Points             int
	Level              int
	RevealedThresholds []int
}

type Inventory struct {
	NextInstanceNumber int
	Items              []ItemInstance
	Equipment          map[string]string
}

func NewInventory() Inventory {
	return Inventory{NextInstanceNumber: 1, Equipment: map[string]string{"weapon": "", "armor": "", "trinket": ""}}
}

func CreateItemInstance(def ItemDefinition, quantity int, nextNumber int) ItemInstance {
	state := def.DefaultState
	if state == "" {
		state = Known
	}
	if quantity < 1 {
		quantity = 1
	}
	instance := ItemInstance{
		InstanceID:     fmt.Sprintf("%s_%04d", def.ID, nextNumber),
		ItemID:         def.ID,
		Quantity:       quantity,
		KnowledgeState: state,
	}
	if def.Attunable {
		instance.Attunement = AttunementState{}
	}
	for _, property := range def.Properties {
		if property.Visibility == "visible" {
			instance.RevealedPropertyIDs = append(instance.RevealedPropertyIDs, property.ID)
		}
	}
	return instance
}

func AddItem(inventory Inventory, def ItemDefinition, quantity int) Inventory {
	if inventory.NextInstanceNumber == 0 {
		inventory.NextInstanceNumber = 1
	}
	if inventory.Equipment == nil {
		inventory.Equipment = map[string]string{"weapon": "", "armor": "", "trinket": ""}
	}
	if quantity <= 0 {
		return inventory
	}
	if def.Stackable {
		for index := range inventory.Items {
			if inventory.Items[index].ItemID == def.ID {
				inventory.Items[index].Quantity += quantity
				return inventory
			}
		}
		inventory.Items = append(inventory.Items, CreateItemInstance(def, quantity, inventory.NextInstanceNumber))
		inventory.NextInstanceNumber++
		return inventory
	}
	for range quantity {
		inventory.Items = append(inventory.Items, CreateItemInstance(def, 1, inventory.NextInstanceNumber))
		inventory.NextInstanceNumber++
	}
	return inventory
}

func LookupInstance(inventory Inventory, instanceID string) (ItemInstance, bool) {
	for _, item := range inventory.Items {
		if item.InstanceID == instanceID {
			return item, true
		}
	}
	return ItemInstance{}, false
}

func Equip(inventory Inventory, definitions map[string]ItemDefinition, instanceID string) (Inventory, bool) {
	instance, ok := LookupInstance(inventory, instanceID)
	if !ok {
		return inventory, false
	}
	definition, ok := definitions[instance.ItemID]
	if !ok || !definition.Equippable || definition.EquipmentSlot == "" {
		return inventory, false
	}
	if inventory.Equipment == nil {
		inventory.Equipment = map[string]string{}
	}
	inventory.Equipment[definition.EquipmentSlot] = instanceID
	return inventory, true
}

func EquipmentStats(inventory Inventory, definitions map[string]ItemDefinition) Stats {
	var stats Stats
	for _, instanceID := range inventory.Equipment {
		instance, ok := LookupInstance(inventory, instanceID)
		if !ok {
			continue
		}
		definition, ok := definitions[instance.ItemID]
		if !ok {
			continue
		}
		stats = AddStats(stats, definition.Stats)
	}
	return stats
}

func AddStats(a Stats, b Stats) Stats {
	return Stats{
		Strength:       a.Strength + b.Strength,
		Defense:        a.Defense + b.Defense,
		SpellPower:     a.SpellPower + b.SpellPower,
		MaxHealthBonus: a.MaxHealthBonus + b.MaxHealthBonus,
		MaxManaBonus:   a.MaxManaBonus + b.MaxManaBonus,
	}
}

func CanIdentifyItem(instance ItemInstance, definition ItemDefinition) bool {
	return len(UnrevealedIdentifyProperties(instance, definition)) > 0
}

func UnrevealedIdentifyProperties(instance ItemInstance, definition ItemDefinition) []ItemProperty {
	properties := []ItemProperty{}
	for _, property := range definition.Properties {
		if hasString(instance.RevealedPropertyIDs, property.ID) {
			continue
		}
		if hasRequirement(property, "identify", 0) {
			properties = append(properties, property)
		}
	}
	return properties
}

func IdentifyItem(instance ItemInstance, definition ItemDefinition) (ItemInstance, []ItemProperty, bool) {
	revealed := UnrevealedIdentifyProperties(instance, definition)
	if len(revealed) == 0 {
		return instance, nil, false
	}
	for _, property := range revealed {
		instance.IdentifiedPropertyIDs = appendUnique(instance.IdentifiedPropertyIDs, property.ID)
		instance.RevealedPropertyIDs = appendUnique(instance.RevealedPropertyIDs, property.ID)
	}
	if allIdentifyPropertiesRevealed(instance, definition) {
		instance.KnowledgeState = Identified
	} else {
		instance.KnowledgeState = PartiallyIdentified
	}
	return instance, revealed, true
}

func AddAttunementPoints(instance ItemInstance, definition ItemDefinition, points int) (ItemInstance, []ItemProperty) {
	if !definition.Attunable || points <= 0 {
		return instance, nil
	}
	instance.Attunement.Points += points
	newLevel := AttunementLevel(instance.Attunement.Points)
	revealed := []ItemProperty{}
	if newLevel > instance.Attunement.Level {
		for level := instance.Attunement.Level + 1; level <= newLevel; level++ {
			instance.Attunement.RevealedThresholds = appendUniqueInt(instance.Attunement.RevealedThresholds, level)
		}
		instance.Attunement.Level = newLevel
	}
	for _, property := range definition.Properties {
		if hasString(instance.RevealedPropertyIDs, property.ID) {
			continue
		}
		for _, requirement := range property.Requirements {
			if requirement.Type == "attunement" && instance.Attunement.Level >= requirement.Value {
				instance.RevealedPropertyIDs = appendUnique(instance.RevealedPropertyIDs, property.ID)
				revealed = append(revealed, property)
				break
			}
		}
	}
	return instance, revealed
}

func AttunementLevel(points int) int {
	switch {
	case points >= 9:
		return 3
	case points >= 5:
		return 2
	case points >= 2:
		return 1
	default:
		return 0
	}
}

func RevealLevelGatedProperties(instance ItemInstance, definition ItemDefinition, playerLevel int) (ItemInstance, []ItemProperty) {
	revealed := []ItemProperty{}
	for _, property := range definition.Properties {
		if hasString(instance.RevealedPropertyIDs, property.ID) {
			continue
		}
		for _, requirement := range property.Requirements {
			if requirement.Type == "player_level" && playerLevel >= requirement.Value {
				instance.RevealedPropertyIDs = appendUnique(instance.RevealedPropertyIDs, property.ID)
				revealed = append(revealed, property)
				break
			}
		}
	}
	return instance, revealed
}

func RevealTriggeredCurses(instance ItemInstance, definition ItemDefinition, trigger string) (ItemInstance, []ItemProperty) {
	revealed := []ItemProperty{}
	for _, property := range definition.Properties {
		if !property.Cursed || !hasRequirement(property, trigger, 0) {
			continue
		}
		if !hasString(instance.RevealedPropertyIDs, property.ID) {
			instance.RevealedPropertyIDs = appendUnique(instance.RevealedPropertyIDs, property.ID)
			revealed = append(revealed, property)
		}
	}
	return instance, revealed
}

func RevealedStats(instance ItemInstance, definition ItemDefinition) Stats {
	var stats Stats
	for _, property := range definition.Properties {
		if !hasString(instance.RevealedPropertyIDs, property.ID) {
			continue
		}
		for _, effect := range property.Effects {
			switch effect.Type {
			case "stat_bonus", "stat_penalty":
				stats = addStatByName(stats, effect.Stat, effect.Amount)
			}
		}
	}
	return stats
}

func RevealedSkillDamageBonus(instance ItemInstance, definition ItemDefinition, skillID string) int {
	total := 0
	for _, property := range definition.Properties {
		if !hasString(instance.RevealedPropertyIDs, property.ID) {
			continue
		}
		for _, effect := range property.Effects {
			if effect.Type == "damage_bonus" && effect.SkillID == skillID {
				total += effect.Amount
			}
		}
	}
	return total
}

func RevealedHealthCost(instance ItemInstance, definition ItemDefinition, trigger string) int {
	total := 0
	for _, property := range definition.Properties {
		if !property.Cursed || !hasString(instance.RevealedPropertyIDs, property.ID) || !hasRequirement(property, trigger, 0) {
			continue
		}
		for _, effect := range property.Effects {
			if effect.Type == "health_cost" {
				total += effect.Amount
			}
		}
	}
	return total
}

func allIdentifyPropertiesRevealed(instance ItemInstance, definition ItemDefinition) bool {
	for _, property := range definition.Properties {
		if hasRequirement(property, "identify", 0) && !hasString(instance.RevealedPropertyIDs, property.ID) {
			return false
		}
	}
	return true
}

func hasRequirement(property ItemProperty, requirementType string, value int) bool {
	for _, requirement := range property.Requirements {
		if requirement.Type != requirementType {
			continue
		}
		if value == 0 || requirement.Value == value {
			return true
		}
	}
	return false
}

func addStatByName(stats Stats, stat string, amount int) Stats {
	switch stat {
	case "strength":
		stats.Strength += amount
	case "defense":
		stats.Defense += amount
	case "spellPower":
		stats.SpellPower += amount
	case "maxHealthBonus":
		stats.MaxHealthBonus += amount
	case "maxManaBonus":
		stats.MaxManaBonus += amount
	}
	return stats
}

func appendUnique(values []string, value string) []string {
	if hasString(values, value) {
		return values
	}
	return append(values, value)
}

func appendUniqueInt(values []int, value int) []int {
	for _, existing := range values {
		if existing == value {
			return values
		}
	}
	return append(values, value)
}

func hasString(values []string, value string) bool {
	for _, existing := range values {
		if existing == value {
			return true
		}
	}
	return false
}
