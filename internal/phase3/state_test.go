package phase3

import "testing"

func TestMoveValidAndInvalid(t *testing.T) {
	tiles := []Tile{
		{ID: "a", Position: Position{X: 0, Y: 0}},
		{ID: "b", Position: Position{X: 1, Y: 0}},
	}
	position, ok := Move(Position{X: 0, Y: 0}, "east", tiles)
	if !ok || position != (Position{X: 1, Y: 0}) {
		t.Fatalf("Move east = (%+v, %v), want (1,0,true)", position, ok)
	}
	position, ok = Move(position, "east", tiles)
	if ok || position != (Position{X: 1, Y: 0}) {
		t.Fatalf("Move invalid = (%+v, %v), want unchanged false", position, ok)
	}
}

func TestMarkVisited(t *testing.T) {
	tiles := []Tile{{ID: "a", Position: Position{X: 0, Y: 0}, State: "visible"}}
	tiles = MarkVisited(tiles, Position{X: 0, Y: 0})
	if tiles[0].State != "visited" {
		t.Fatalf("State = %q, want visited", tiles[0].State)
	}
}

func TestEquipmentStatsAndDamage(t *testing.T) {
	player := Player{
		BaseStats: Stats{Strength: 1, Defense: 1},
		Equipment: map[string]Item{
			"weapon": {Stats: Stats{Strength: 2}},
			"armor":  {Stats: Stats{Defense: 2}},
		},
	}
	enemy := Enemy{Attack: 7, Defense: 1}
	if got := PlayerDamage(player, enemy); got != 10 {
		t.Fatalf("PlayerDamage = %d, want 10", got)
	}
	if got := EnemyDamage(enemy, player); got != 4 {
		t.Fatalf("EnemyDamage = %d, want 4", got)
	}
}

func TestApplyXPLevelsAndRestores(t *testing.T) {
	player := Player{Level: 1, XPToNextLevel: 50, Health: 10, MaxHealth: 100, Mana: 2, MaxMana: 40}
	player = ApplyXP(player, 50)
	if player.Level != 2 {
		t.Fatalf("Level = %d, want 2", player.Level)
	}
	if player.MaxHealth != 110 || player.Health != 110 {
		t.Fatalf("health = %d/%d, want 110/110", player.Health, player.MaxHealth)
	}
	if player.MaxMana != 45 || player.Mana != 45 {
		t.Fatalf("mana = %d/%d, want 45/45", player.Mana, player.MaxMana)
	}
}

func TestCompleteObjectiveCompletesChain(t *testing.T) {
	chain := QuestChain{Stages: []Stage{
		{ID: "stage", Objectives: []Objective{{ID: "a"}, {ID: "b"}}},
	}}
	chain = CompleteObjective(chain, "a")
	if chain.Stages[0].Completed || chain.Completed {
		t.Fatal("chain completed too early")
	}
	chain = CompleteObjective(chain, "b")
	if !chain.Stages[0].Completed || !chain.Completed {
		t.Fatal("chain did not complete")
	}
}

func TestUseHealthPotionHealsAndConsumes(t *testing.T) {
	player := Player{
		Health: 50, MaxHealth: 100,
		Inventory: []Item{{ID: "potion", Quantity: 1, Stackable: true}},
	}
	player, used := UseHealthPotion(player, "potion", 25)
	if !used {
		t.Fatal("used = false, want true")
	}
	if player.Health != 75 {
		t.Fatalf("Health = %d, want 75", player.Health)
	}
	if len(player.Inventory) != 0 {
		t.Fatalf("len(Inventory) = %d, want 0", len(player.Inventory))
	}
}
