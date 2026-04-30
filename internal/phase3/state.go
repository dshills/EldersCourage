package phase3

// Position is a grid coordinate in Elder Road Outskirts.
type Position struct {
	X int
	Y int
}

// Tile is the minimal map tile model used by tests and validators.
type Tile struct {
	ID             string
	Position       Position
	State          string
	BlocksMovement bool
}

// Stats are player and equipment stats for Phase 3.
type Stats struct {
	Strength       int
	Defense        int
	SpellPower     int
	MaxHealthBonus int
	MaxManaBonus   int
}

// Item is a Phase 3 item definition or inventory instance.
type Item struct {
	ID            string
	Quantity      int
	Stackable     bool
	EquipmentSlot string
	Stats         Stats
}

// Player contains the fields needed by pure helper tests.
type Player struct {
	Level         int
	XP            int
	XPToNextLevel int
	Health        int
	MaxHealth     int
	Mana          int
	MaxMana       int
	BaseStats     Stats
	Inventory     []Item
	Equipment     map[string]Item
}

// Enemy is the deterministic Phase 3 combat target.
type Enemy struct {
	Health   int
	Attack   int
	Defense  int
	Defeated bool
}

// Objective, Stage, and QuestChain model The Elder Road.
type Objective struct {
	ID        string
	Completed bool
}

type Stage struct {
	ID         string
	Objectives []Objective
	Completed  bool
}

type QuestChain struct {
	Stages    []Stage
	Completed bool
}

// Move returns a new position if the target tile exists and is not blocked.
func Move(position Position, direction string, tiles []Tile) (Position, bool) {
	target := position
	switch direction {
	case "north":
		target.Y--
	case "south":
		target.Y++
	case "east":
		target.X++
	case "west":
		target.X--
	default:
		return position, false
	}
	tile, ok := TileAt(tiles, target)
	if !ok || tile.BlocksMovement {
		return position, false
	}
	return target, true
}

// TileAt returns the tile at position.
func TileAt(tiles []Tile, position Position) (Tile, bool) {
	for _, tile := range tiles {
		if tile.Position == position {
			return tile, true
		}
	}
	return Tile{}, false
}

// MarkVisited marks the tile at position visited.
func MarkVisited(tiles []Tile, position Position) []Tile {
	for index := range tiles {
		if tiles[index].Position == position {
			tiles[index].State = "visited"
			return tiles
		}
	}
	return tiles
}

// EquipmentStats sums equipment bonuses.
func EquipmentStats(equipment map[string]Item) Stats {
	var stats Stats
	for _, item := range equipment {
		stats.Strength += item.Stats.Strength
		stats.Defense += item.Stats.Defense
		stats.SpellPower += item.Stats.SpellPower
		stats.MaxHealthBonus += item.Stats.MaxHealthBonus
		stats.MaxManaBonus += item.Stats.MaxManaBonus
	}
	return stats
}

// EffectiveStats combines base and equipment stats.
func EffectiveStats(player Player) Stats {
	equipment := EquipmentStats(player.Equipment)
	return Stats{
		Strength:       player.BaseStats.Strength + equipment.Strength,
		Defense:        player.BaseStats.Defense + equipment.Defense,
		SpellPower:     player.BaseStats.SpellPower + equipment.SpellPower,
		MaxHealthBonus: player.BaseStats.MaxHealthBonus + equipment.MaxHealthBonus,
		MaxManaBonus:   player.BaseStats.MaxManaBonus + equipment.MaxManaBonus,
	}
}

func EffectiveMaxHealth(player Player) int {
	return player.MaxHealth + EquipmentStats(player.Equipment).MaxHealthBonus
}

func EffectiveMaxMana(player Player) int {
	return player.MaxMana + EquipmentStats(player.Equipment).MaxManaBonus
}

func PlayerDamage(player Player, enemy Enemy) int {
	damage := 8 + EffectiveStats(player).Strength - enemy.Defense
	if damage < 1 {
		return 1
	}
	return damage
}

func EnemyDamage(enemy Enemy, player Player) int {
	damage := enemy.Attack - EffectiveStats(player).Defense
	if damage < 1 {
		return 1
	}
	return damage
}

// ApplyXP applies XP and level-up rewards.
func ApplyXP(player Player, amount int) Player {
	player.XP += amount
	for player.XP >= player.XPToNextLevel && player.XPToNextLevel > 0 {
		player.XP -= player.XPToNextLevel
		player.Level++
		player.MaxHealth += 10
		player.MaxMana += 5
		player.Health = EffectiveMaxHealth(player)
		player.Mana = EffectiveMaxMana(player)
		if player.Level == 2 {
			player.XPToNextLevel = 100
		} else {
			player.XPToNextLevel += 50
		}
	}
	return player
}

// CompleteObjective updates matching objective, stage, and chain completion.
func CompleteObjective(chain QuestChain, objectiveID string) QuestChain {
	for stageIndex := range chain.Stages {
		for objectiveIndex := range chain.Stages[stageIndex].Objectives {
			if chain.Stages[stageIndex].Objectives[objectiveIndex].ID == objectiveID {
				chain.Stages[stageIndex].Objectives[objectiveIndex].Completed = true
			}
		}
		chain.Stages[stageIndex].Completed = allObjectivesComplete(chain.Stages[stageIndex].Objectives)
	}
	chain.Completed = true
	for _, stage := range chain.Stages {
		if !stage.Completed {
			chain.Completed = false
			break
		}
	}
	return chain
}

func allObjectivesComplete(objectives []Objective) bool {
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

// UseHealthPotion consumes a potion if healing is possible.
func UseHealthPotion(player Player, itemID string, healAmount int) (Player, bool) {
	if player.Health >= EffectiveMaxHealth(player) {
		return player, false
	}
	for index := range player.Inventory {
		if player.Inventory[index].ID != itemID || player.Inventory[index].Quantity <= 0 {
			continue
		}
		player.Health += healAmount
		if player.Health > EffectiveMaxHealth(player) {
			player.Health = EffectiveMaxHealth(player)
		}
		player.Inventory[index].Quantity--
		if player.Inventory[index].Quantity == 0 {
			player.Inventory = append(player.Inventory[:index], player.Inventory[index+1:]...)
		}
		return player, true
	}
	return player, false
}
