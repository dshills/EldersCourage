package phase4

import "testing"

func TestInitializePlayerEquipsStarterGear(t *testing.T) {
	class := ClassDefinition{
		ID:               "roadwarden",
		BaseStats:        Stats{Strength: 4, Defense: 3},
		StartingHealth:   120,
		StartingMana:     25,
		StartingGold:     5,
		StartingItemIDs:  []string{"sword", "potion"},
		StartingSkillIDs: []string{"guarded_strike", "shield_bash"},
	}
	items := map[string]Item{
		"sword":  {ID: "sword", Equippable: true, EquipmentSlot: "weapon"},
		"potion": {ID: "potion"},
	}
	player := InitializePlayer(class, items)
	if player.ClassID != "roadwarden" || player.Health != 120 || player.Gold != 5 {
		t.Fatalf("unexpected player initialization: %+v", player)
	}
	if player.Equipment["weapon"].ID != "sword" {
		t.Fatalf("weapon = %q, want sword", player.Equipment["weapon"].ID)
	}
	if len(player.Inventory) != 1 || player.Inventory[0].ID != "potion" {
		t.Fatalf("inventory = %+v, want potion", player.Inventory)
	}
	if !HasSkill(player, "shield_bash") {
		t.Fatal("missing starting skill shield_bash")
	}
}

func TestSkillValidationFailures(t *testing.T) {
	player := Player{KnownSkillIDs: []string{"ember_bolt"}, Mana: 5, Cooldowns: map[string]int{"ember_bolt": 0}}
	skill := Skill{ID: "ember_bolt", TargetType: "enemy", Resource: "mana", ResourceCost: 10}
	if got := SkillFailureReason(player, skill, true); got != "mana" {
		t.Fatalf("failure = %q, want mana", got)
	}
	player.Mana = 20
	player.Cooldowns["ember_bolt"] = 1
	if got := SkillFailureReason(player, skill, true); got != "cooldown" {
		t.Fatalf("failure = %q, want cooldown", got)
	}
	player.Cooldowns["ember_bolt"] = 0
	if got := SkillFailureReason(player, skill, false); got != "no target" {
		t.Fatalf("failure = %q, want no target", got)
	}
}

func TestApplySkillDamageHealManaAndCooldown(t *testing.T) {
	player := Player{
		Mana: 20, MaxMana: 40, Health: 20, MaxHealth: 40,
		BaseStats:     Stats{SpellPower: 4},
		KnownSkillIDs: []string{"grave_touch"},
		Cooldowns:     map[string]int{},
	}
	enemy := Enemy{Health: 30, Defense: 1}
	skill := Skill{
		ID: "grave_touch", TargetType: "enemy", Resource: "mana", ResourceCost: 12, CooldownTurns: 2,
		Effects: []Effect{
			{Type: "damage", Amount: 6, ScalingStat: "spellPower", ScalingMultiplier: 1},
			{Type: "heal", Amount: 5, ScalingStat: "spellPower", ScalingMultiplier: 0.5},
		},
	}
	player, enemy, _ = ApplySkill(player, enemy, TalentTree{}, skill)
	if player.Mana != 8 || player.Cooldowns["grave_touch"] != 2 {
		t.Fatalf("mana/cooldown = %d/%d, want 8/2", player.Mana, player.Cooldowns["grave_touch"])
	}
	if enemy.Health != 21 {
		t.Fatalf("enemy health = %d, want 21", enemy.Health)
	}
	if player.Health != 27 {
		t.Fatalf("player health = %d, want 27", player.Health)
	}
}

func TestCooldownsAndModifiers(t *testing.T) {
	player := Player{Cooldowns: map[string]int{"shield_bash": 2}}
	player = ReduceCooldowns(player)
	if player.Cooldowns["shield_bash"] != 1 {
		t.Fatalf("cooldown = %d, want 1", player.Cooldowns["shield_bash"])
	}
	mods := []Modifier{{Target: "enemy", Stat: "attack", Amount: -2, RemainingTurns: 1}}
	if got := ModifiedEnemyAttack(Enemy{Attack: 7}, mods); got != 5 {
		t.Fatalf("ModifiedEnemyAttack = %d, want 5", got)
	}
	if remaining := AdvanceModifiers(mods); len(remaining) != 0 {
		t.Fatalf("remaining modifiers = %d, want 0", len(remaining))
	}
}

func TestTalentSpendAndBonuses(t *testing.T) {
	talent := Talent{ID: "living_flame", MaxRank: 2, RequiredLevel: 2, Effects: []TalentEffect{{Type: "stat_bonus", Stat: "spellPower", Amount: 1}}}
	tree := TalentTree{Nodes: []Talent{talent}}
	player := Player{Level: 2, TalentPoints: 1, TalentRanks: map[string]int{}}
	if !CanSpendTalent(player, talent) {
		t.Fatal("CanSpendTalent = false, want true")
	}
	player = SpendTalent(player, talent)
	if player.TalentPoints != 0 || TalentRank(player, "living_flame") != 1 {
		t.Fatalf("talent state = points %d rank %d, want 0/1", player.TalentPoints, TalentRank(player, "living_flame"))
	}
	if got := TalentStatBonuses(player, tree).SpellPower; got != 1 {
		t.Fatalf("SpellPower bonus = %d, want 1", got)
	}
}

func TestTalentPrerequisiteAndLevelRequirements(t *testing.T) {
	talent := Talent{ID: "focused_ember", MaxRank: 1, RequiredLevel: 3, Prerequisites: []string{"living_flame"}}
	player := Player{Level: 3, TalentPoints: 1, TalentRanks: map[string]int{}}
	if CanSpendTalent(player, talent) {
		t.Fatal("CanSpendTalent without prerequisite = true, want false")
	}
	player.TalentRanks["living_flame"] = 1
	if !CanSpendTalent(player, talent) {
		t.Fatal("CanSpendTalent with prerequisite = false, want true")
	}
}

func TestGrantTalentPointOnLevel(t *testing.T) {
	player := GrantTalentPointOnLevel(Player{Level: 1}, 2)
	if player.Level != 2 || player.TalentPoints != 1 {
		t.Fatalf("level/talent points = %d/%d, want 2/1", player.Level, player.TalentPoints)
	}
}

func TestEachClassCanDefeatGoblinWithStartingSkill(t *testing.T) {
	cases := []struct {
		name   string
		player Player
		skill  Skill
		tree   TalentTree
	}{
		{"roadwarden", Player{Mana: 20, BaseStats: Stats{Strength: 4}, KnownSkillIDs: []string{"guarded_strike"}, Cooldowns: map[string]int{}}, Skill{ID: "guarded_strike", TargetType: "enemy", Resource: "mana", ResourceCost: 5, Effects: []Effect{{Type: "damage", Amount: 8, ScalingStat: "strength", ScalingMultiplier: 1.2}}}, TalentTree{}},
		{"ember", Player{Mana: 50, BaseStats: Stats{SpellPower: 5}, KnownSkillIDs: []string{"ember_bolt"}, Cooldowns: map[string]int{}}, Skill{ID: "ember_bolt", TargetType: "enemy", Resource: "mana", ResourceCost: 10, IgnoreDefense: true, Effects: []Effect{{Type: "damage", Amount: 10, ScalingStat: "spellPower", ScalingMultiplier: 1.5}}}, TalentTree{}},
		{"scout", Player{Mana: 50, BaseStats: Stats{Strength: 3}, KnownSkillIDs: []string{"piercing_shot"}, Cooldowns: map[string]int{}}, Skill{ID: "piercing_shot", TargetType: "enemy", Resource: "mana", ResourceCost: 7, DefensePierce: 1, Effects: []Effect{{Type: "damage", Amount: 7, ScalingStat: "strength", ScalingMultiplier: 1}}}, TalentTree{}},
	}
	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			enemy := Enemy{Health: 30}
			for turn := 0; turn < 4 && !enemy.Defeated; turn++ {
				tt.player, enemy, _ = ApplySkill(tt.player, enemy, tt.tree, tt.skill)
				tt.player = ReduceCooldowns(tt.player)
			}
			if !enemy.Defeated {
				t.Fatalf("%s did not defeat goblin, enemy health %d", tt.name, enemy.Health)
			}
		})
	}
}
