package phase2

import "testing"

func TestAddItemToInventoryStacksExistingItem(t *testing.T) {
	inventory := []Item{{ID: "blue_potion", Name: "Blue Potion", Type: "consumable", Quantity: 1, Stackable: true}}

	inventory = AddItemToInventory(inventory, Item{ID: "blue_potion", Name: "Blue Potion", Type: "consumable", Stackable: true}, 2)

	if len(inventory) != 1 {
		t.Fatalf("len(inventory) = %d, want 1", len(inventory))
	}
	if inventory[0].Quantity != 3 {
		t.Fatalf("Quantity = %d, want 3", inventory[0].Quantity)
	}
}

func TestAddItemToInventoryKeepsNonStackableSeparate(t *testing.T) {
	inventory := []Item{{ID: "old_sword", Name: "Old Sword", Type: "weapon", Quantity: 1, Stackable: false}}

	inventory = AddItemToInventory(inventory, Item{ID: "old_sword", Name: "Old Sword", Type: "weapon", Stackable: false}, 1)

	if len(inventory) != 2 {
		t.Fatalf("len(inventory) = %d, want 2", len(inventory))
	}
}

func TestHasItemRequiresPositiveQuantity(t *testing.T) {
	inventory := []Item{{ID: "old_sword", Quantity: 1}, {ID: "blue_potion", Quantity: 0}}

	if !HasItem(inventory, "old_sword") {
		t.Fatal("HasItem old_sword = false, want true")
	}
	if HasItem(inventory, "blue_potion") {
		t.Fatal("HasItem blue_potion = true, want false")
	}
}

func TestCompleteQuestObjectiveUpdatesOnlyMatch(t *testing.T) {
	objectives := []Objective{
		{ID: "open_chest", Label: "Open chest"},
		{ID: "defeat_scout", Label: "Defeat scout"},
	}

	objectives = CompleteQuestObjective(objectives, "open_chest")

	if !objectives[0].Completed {
		t.Fatal("open_chest Completed = false, want true")
	}
	if objectives[1].Completed {
		t.Fatal("defeat_scout Completed = true, want false")
	}
}

func TestIsQuestCompleteRequiresAllObjectives(t *testing.T) {
	if IsQuestComplete(nil) {
		t.Fatal("IsQuestComplete(nil) = true, want false")
	}
	if IsQuestComplete([]Objective{{ID: "a", Completed: true}, {ID: "b"}}) {
		t.Fatal("IsQuestComplete(partial) = true, want false")
	}
	if !IsQuestComplete([]Objective{{ID: "a", Completed: true}, {ID: "b", Completed: true}}) {
		t.Fatal("IsQuestComplete(all complete) = false, want true")
	}
}

func TestDamageEnemyClampsHealthAndDefeatsAtZero(t *testing.T) {
	enemy := Enemy{ID: "ash_road_scout", Health: 8, MaxHealth: 30}

	enemy = DamageEnemy(enemy, 15)

	if enemy.Health != 0 {
		t.Fatalf("Health = %d, want 0", enemy.Health)
	}
	if !enemy.Defeated {
		t.Fatal("Defeated = false, want true")
	}
}
