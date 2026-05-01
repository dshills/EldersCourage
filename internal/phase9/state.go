package phase9

type Effect struct {
	Type                      string
	SkillID                   string
	Stat                      string
	Amount                    int
	Nonlethal                 bool
	RequiresAcceptedBargainID string
}

type Resonance struct {
	ID              string
	RequiredItemIDs []string
	Effects         []Effect
}

type ResonanceState struct {
	Discovered       map[string]bool
	AcceptedBargains map[string]bool
}

type MergeCondition struct {
	Type        string
	ResonanceID string
	ItemID      string
	SoulID      string
	Value       int
}

type MergeRecipe struct {
	ID              string
	RequiredItemIDs []string
	Conditions      []MergeCondition
}

type MergeState struct {
	Items                map[string]bool
	AttunementLevels     map[string]int
	DiscoveredResonances map[string]bool
	RevealedSoulNames    map[string]bool
}

func NewResonanceState() ResonanceState {
	return ResonanceState{
		Discovered:       map[string]bool{},
		AcceptedBargains: map[string]bool{},
	}
}

func Active(resonance Resonance, equipped map[string]bool) bool {
	if len(resonance.RequiredItemIDs) == 0 {
		return false
	}
	for _, itemID := range resonance.RequiredItemIDs {
		if !equipped[itemID] {
			return false
		}
	}
	return true
}

func Discover(state ResonanceState, resonanceID string) (ResonanceState, bool) {
	if state.Discovered == nil {
		state.Discovered = map[string]bool{}
	}
	if resonanceID == "" || state.Discovered[resonanceID] {
		return state, false
	}
	state.Discovered[resonanceID] = true
	return state, true
}

func SkillDamageBonus(state ResonanceState, resonance Resonance, equipped map[string]bool, skillID string) int {
	if !state.Discovered[resonance.ID] || !Active(resonance, equipped) {
		return 0
	}
	total := 0
	for _, effect := range resonance.Effects {
		if effect.Type != "skill_damage_bonus" || effect.SkillID != skillID {
			continue
		}
		if effect.RequiresAcceptedBargainID != "" && !state.AcceptedBargains[effect.RequiresAcceptedBargainID] {
			continue
		}
		total += effect.Amount
	}
	return total
}

func ApplyHealthCost(current int, effects []Effect) int {
	for _, effect := range effects {
		if effect.Type != "curse_health_cost" {
			continue
		}
		current -= effect.Amount
		if effect.Nonlethal && current < 1 {
			current = 1
		}
	}
	return current
}

func CanMerge(recipe MergeRecipe, state MergeState) bool {
	for _, itemID := range recipe.RequiredItemIDs {
		if !state.Items[itemID] {
			return false
		}
	}
	for _, condition := range recipe.Conditions {
		switch condition.Type {
		case "resonance_discovered":
			if !state.DiscoveredResonances[condition.ResonanceID] {
				return false
			}
		case "attunement_level":
			if state.AttunementLevels[condition.ItemID] < condition.Value {
				return false
			}
		case "soul_name_revealed":
			if !state.RevealedSoulNames[condition.SoulID] {
				return false
			}
		default:
			return false
		}
	}
	return true
}
