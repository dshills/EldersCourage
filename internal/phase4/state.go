package phase4

type Stats struct {
	Strength       int
	Defense        int
	SpellPower     int
	MaxHealthBonus int
	MaxManaBonus   int
}

type Item struct {
	ID            string
	EquipmentSlot string
	Equippable    bool
	Stats         Stats
}

type ClassDefinition struct {
	ID               string
	BaseStats        Stats
	StartingHealth   int
	StartingMana     int
	StartingGold     int
	StartingItemIDs  []string
	StartingSkillIDs []string
	TalentTreeID     string
}

type Player struct {
	ClassID       string
	Level         int
	Health        int
	MaxHealth     int
	Mana          int
	MaxMana       int
	Gold          int
	BaseStats     Stats
	Inventory     []Item
	Equipment     map[string]Item
	KnownSkillIDs []string
	Cooldowns     map[string]int
	TalentPoints  int
	SpentPoints   int
	TalentRanks   map[string]int
}

type Enemy struct {
	ID       string
	Health   int
	Attack   int
	Defense  int
	Defeated bool
}

type Effect struct {
	Type              string
	Amount            int
	Stat              string
	ScalingStat       string
	ScalingMultiplier float64
	DurationTurns     int
}

type Skill struct {
	ID            string
	ClassID       string
	TargetType    string
	Resource      string
	ResourceCost  int
	CooldownTurns int
	IgnoreDefense bool
	DefensePierce int
	Effects       []Effect
}

type Modifier struct {
	ID             string
	SourceSkillID  string
	Target         string
	Stat           string
	Amount         int
	RemainingTurns int
}

type TalentEffect struct {
	Type    string
	Stat    string
	SkillID string
	Amount  int
}

type Talent struct {
	ID            string
	ClassID       string
	MaxRank       int
	RequiredLevel int
	Prerequisites []string
	Effects       []TalentEffect
}

type TalentTree struct {
	ID      string
	ClassID string
	Nodes   []Talent
}

func InitializePlayer(class ClassDefinition, items map[string]Item) Player {
	player := Player{
		ClassID:       class.ID,
		Level:         1,
		Health:        class.StartingHealth,
		MaxHealth:     class.StartingHealth,
		Mana:          class.StartingMana,
		MaxMana:       class.StartingMana,
		Gold:          class.StartingGold,
		BaseStats:     class.BaseStats,
		Equipment:     map[string]Item{},
		KnownSkillIDs: append([]string{}, class.StartingSkillIDs...),
		Cooldowns:     map[string]int{},
		TalentRanks:   map[string]int{},
	}
	for _, itemID := range class.StartingItemIDs {
		item, ok := items[itemID]
		if !ok {
			continue
		}
		if item.Equippable && item.EquipmentSlot != "" {
			player.Equipment[item.EquipmentSlot] = item
		} else {
			player.Inventory = append(player.Inventory, item)
		}
	}
	return player
}

func HasSkill(player Player, skillID string) bool {
	for _, known := range player.KnownSkillIDs {
		if known == skillID {
			return true
		}
	}
	return false
}

func CanUseSkill(player Player, skill Skill, hasEnemy bool) bool {
	return SkillFailureReason(player, skill, hasEnemy) == ""
}

func SkillFailureReason(player Player, skill Skill, hasEnemy bool) string {
	if !HasSkill(player, skill.ID) {
		return "unknown skill"
	}
	if skill.TargetType == "enemy" && !hasEnemy {
		return "no target"
	}
	if player.Cooldowns[skill.ID] > 0 {
		return "cooldown"
	}
	if skill.Resource == "mana" && player.Mana < skill.ResourceCost {
		return "mana"
	}
	return ""
}

func ReduceCooldowns(player Player) Player {
	for skillID, remaining := range player.Cooldowns {
		if remaining <= 1 {
			player.Cooldowns[skillID] = 0
		} else {
			player.Cooldowns[skillID] = remaining - 1
		}
	}
	return player
}

func EquipmentStats(equipment map[string]Item) Stats {
	var stats Stats
	for _, item := range equipment {
		stats = AddStats(stats, item.Stats)
	}
	return stats
}

func EffectiveStats(player Player, tree TalentTree) Stats {
	return AddStats(AddStats(player.BaseStats, EquipmentStats(player.Equipment)), TalentStatBonuses(player, tree))
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

func EffectAmount(player Player, tree TalentTree, skill Skill, effect Effect) int {
	amount := effect.Amount
	stats := EffectiveStats(player, tree)
	switch effect.ScalingStat {
	case "strength":
		amount += int(float64(stats.Strength) * effect.ScalingMultiplier)
	case "defense":
		amount += int(float64(stats.Defense) * effect.ScalingMultiplier)
	case "spellPower":
		amount += int(float64(stats.SpellPower) * effect.ScalingMultiplier)
	}
	if effect.Type == "damage" {
		amount += SkillDamageBonus(player, tree, skill.ID)
	}
	if amount < 1 && effect.Type == "damage" {
		return 1
	}
	return amount
}

func ApplySkill(player Player, enemy Enemy, tree TalentTree, skill Skill) (Player, Enemy, []Modifier) {
	if skill.Resource == "mana" {
		player.Mana -= EffectiveSkillCost(player, tree, skill)
		if player.Mana < 0 {
			player.Mana = 0
		}
	}
	modifiers := []Modifier{}
	for _, effect := range skill.Effects {
		amount := EffectAmount(player, tree, skill, effect)
		switch effect.Type {
		case "damage":
			damage := amount
			if !skill.IgnoreDefense {
				defense := enemy.Defense - skill.DefensePierce
				if defense < 0 {
					defense = 0
				}
				damage -= defense
			}
			if damage < 1 {
				damage = 1
			}
			enemy.Health -= damage
			if enemy.Health <= 0 {
				enemy.Health = 0
				enemy.Defeated = true
			}
		case "heal":
			player.Health += amount
			if player.Health > player.MaxHealth {
				player.Health = player.MaxHealth
			}
		case "restore_mana":
			player.Mana += amount
			if player.Mana > player.MaxMana {
				player.Mana = player.MaxMana
			}
		case "buff":
			modifiers = append(modifiers, Modifier{SourceSkillID: skill.ID, Target: "player", Stat: effect.Stat, Amount: effect.Amount, RemainingTurns: effect.DurationTurns})
		case "debuff":
			modifiers = append(modifiers, Modifier{SourceSkillID: skill.ID, Target: "enemy", Stat: effect.Stat, Amount: effect.Amount, RemainingTurns: effect.DurationTurns})
		}
	}
	player.Cooldowns[skill.ID] = EffectiveCooldown(player, tree, skill)
	return player, enemy, modifiers
}

func ModifiedDefense(player Player, tree TalentTree, modifiers []Modifier) int {
	defense := EffectiveStats(player, tree).Defense
	for _, modifier := range modifiers {
		if modifier.Target == "player" && modifier.Stat == "defense" && modifier.RemainingTurns > 0 {
			defense += modifier.Amount
		}
	}
	return defense
}

func ModifiedEnemyAttack(enemy Enemy, modifiers []Modifier) int {
	attack := enemy.Attack
	for _, modifier := range modifiers {
		if modifier.Target == "enemy" && modifier.Stat == "attack" && modifier.RemainingTurns > 0 {
			attack += modifier.Amount
		}
	}
	if attack < 1 {
		return 1
	}
	return attack
}

func AdvanceModifiers(modifiers []Modifier) []Modifier {
	result := []Modifier{}
	for _, modifier := range modifiers {
		modifier.RemainingTurns--
		if modifier.RemainingTurns > 0 {
			result = append(result, modifier)
		}
	}
	return result
}

func GrantTalentPointOnLevel(player Player, newLevel int) Player {
	if newLevel > player.Level {
		player.TalentPoints += newLevel - player.Level
		player.Level = newLevel
	}
	return player
}

func TalentRank(player Player, talentID string) int {
	if player.TalentRanks == nil {
		return 0
	}
	return player.TalentRanks[talentID]
}

func CanSpendTalent(player Player, talent Talent) bool {
	if player.TalentPoints <= 0 || player.Level < talent.RequiredLevel || TalentRank(player, talent.ID) >= talent.MaxRank {
		return false
	}
	for _, prereq := range talent.Prerequisites {
		if TalentRank(player, prereq) == 0 {
			return false
		}
	}
	return true
}

func SpendTalent(player Player, talent Talent) Player {
	if !CanSpendTalent(player, talent) {
		return player
	}
	if player.TalentRanks == nil {
		player.TalentRanks = map[string]int{}
	}
	player.TalentRanks[talent.ID]++
	player.TalentPoints--
	player.SpentPoints++
	return player
}

func TalentStatBonuses(player Player, tree TalentTree) Stats {
	var stats Stats
	for _, talent := range tree.Nodes {
		rank := TalentRank(player, talent.ID)
		for _, effect := range talent.Effects {
			if effect.Type != "stat_bonus" {
				continue
			}
			amount := effect.Amount * rank
			switch effect.Stat {
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
		}
	}
	return stats
}

func SkillDamageBonus(player Player, tree TalentTree, skillID string) int {
	return talentSkillAmount(player, tree, skillID, "skill_damage_bonus")
}

func EffectiveSkillCost(player Player, tree TalentTree, skill Skill) int {
	cost := skill.ResourceCost - talentSkillAmount(player, tree, skill.ID, "resource_cost_reduction")
	if cost < 0 {
		return 0
	}
	return cost
}

func EffectiveCooldown(player Player, tree TalentTree, skill Skill) int {
	cooldown := skill.CooldownTurns - talentSkillAmount(player, tree, skill.ID, "cooldown_reduction")
	if cooldown < 0 {
		return 0
	}
	return cooldown
}

func talentSkillAmount(player Player, tree TalentTree, skillID string, effectType string) int {
	total := 0
	for _, talent := range tree.Nodes {
		rank := TalentRank(player, talent.ID)
		for _, effect := range talent.Effects {
			if effect.Type == effectType && effect.SkillID == skillID {
				total += effect.Amount * rank
			}
		}
	}
	return total
}
