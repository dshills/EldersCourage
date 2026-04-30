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
}

type ItemInstance struct {
	InstanceID            string
	ItemID                string
	Quantity              int
	KnowledgeState        KnowledgeState
	IdentifiedPropertyIDs []string
	RevealedPropertyIDs   []string
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
	return ItemInstance{
		InstanceID:     fmt.Sprintf("%s_%04d", def.ID, nextNumber),
		ItemID:         def.ID,
		Quantity:       quantity,
		KnowledgeState: state,
	}
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
