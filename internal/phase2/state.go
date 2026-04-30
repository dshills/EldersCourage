package phase2

// Item is the minimal inventory shape used by the Phase 2 first loop.
type Item struct {
	ID        string
	Name      string
	Type      string
	Quantity  int
	Stackable bool
}

// Objective is a single quest objective.
type Objective struct {
	ID        string
	Label     string
	Completed bool
}

// Enemy is the deterministic target used by the Phase 2 combat slice.
type Enemy struct {
	ID        string
	Name      string
	Health    int
	MaxHealth int
	Defeated  bool
}

// AddItemToInventory adds or stacks an item according to its Stackable flag.
func AddItemToInventory(inventory []Item, item Item, quantity int) []Item {
	if quantity <= 0 {
		return inventory
	}
	if item.Stackable {
		for index := range inventory {
			if inventory[index].ID == item.ID {
				inventory[index].Quantity += quantity
				return inventory
			}
		}
	}
	item.Quantity = quantity
	return append(inventory, item)
}

// HasItem reports whether an inventory contains a positive quantity of itemID.
func HasItem(inventory []Item, itemID string) bool {
	for _, item := range inventory {
		if item.ID == itemID && item.Quantity > 0 {
			return true
		}
	}
	return false
}

// CompleteQuestObjective marks a matching objective complete.
func CompleteQuestObjective(objectives []Objective, objectiveID string) []Objective {
	for index := range objectives {
		if objectives[index].ID == objectiveID {
			objectives[index].Completed = true
			return objectives
		}
	}
	return objectives
}

// IsQuestComplete reports whether every objective is complete.
func IsQuestComplete(objectives []Objective) bool {
	if len(objectives) == 0 {
		return false
	}
	for _, objective := range objectives {
		if !objective.Completed {
			return false
		}
	}
	return true
}

// DamageEnemy applies clamped deterministic damage and sets Defeated at zero health.
func DamageEnemy(enemy Enemy, damage int) Enemy {
	if damage <= 0 || enemy.Defeated {
		return enemy
	}
	enemy.Health -= damage
	if enemy.Health <= 0 {
		enemy.Health = 0
		enemy.Defeated = true
	}
	return enemy
}
