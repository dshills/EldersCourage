package phase9

import "testing"

func TestActiveRequiresAllItemsEquipped(t *testing.T) {
	resonance := Resonance{
		ID:              "coal_remembers_flame",
		RequiredItemIDs: []string{"phase5_ashen_ring", "phase4_ember_staff"},
	}
	if Active(resonance, map[string]bool{"phase5_ashen_ring": true}) {
		t.Fatal("resonance active with missing required item")
	}
	if !Active(resonance, map[string]bool{"phase5_ashen_ring": true, "phase4_ember_staff": true}) {
		t.Fatal("resonance inactive with all required items equipped")
	}
}

func TestDiscoverDedupesResonances(t *testing.T) {
	state := NewResonanceState()
	var changed bool
	state, changed = Discover(state, "coal_remembers_flame")
	if !changed {
		t.Fatal("first discovery did not report changed")
	}
	state, changed = Discover(state, "coal_remembers_flame")
	if changed {
		t.Fatal("duplicate discovery reported changed")
	}
}

func TestSkillDamageBonusRequiresDiscoveryActiveItemsAndBargain(t *testing.T) {
	resonance := Resonance{
		ID:              "coal_remembers_flame",
		RequiredItemIDs: []string{"phase5_ashen_ring", "phase4_ember_staff"},
		Effects: []Effect{
			{Type: "skill_damage_bonus", SkillID: "ember_bolt", Amount: 2},
			{Type: "skill_damage_bonus", SkillID: "ember_bolt", Amount: 3, RequiresAcceptedBargainID: "breath_for_flame"},
		},
	}
	equipped := map[string]bool{"phase5_ashen_ring": true, "phase4_ember_staff": true}
	state := NewResonanceState()
	if got := SkillDamageBonus(state, resonance, equipped, "ember_bolt"); got != 0 {
		t.Fatalf("undiscovered bonus = %d, want 0", got)
	}
	state.Discovered[resonance.ID] = true
	if got := SkillDamageBonus(state, resonance, map[string]bool{"phase5_ashen_ring": true}, "ember_bolt"); got != 0 {
		t.Fatalf("inactive bonus = %d, want 0", got)
	}
	if got := SkillDamageBonus(state, resonance, equipped, "ember_bolt"); got != 2 {
		t.Fatalf("discovered bonus = %d, want 2", got)
	}
	state.AcceptedBargains["breath_for_flame"] = true
	if got := SkillDamageBonus(state, resonance, equipped, "ember_bolt"); got != 5 {
		t.Fatalf("accepted bargain bonus = %d, want 5", got)
	}
}

func TestApplyHealthCostCanBeNonlethal(t *testing.T) {
	effects := []Effect{{Type: "curse_health_cost", Amount: 5, Nonlethal: true}}
	if got := ApplyHealthCost(3, effects); got != 1 {
		t.Fatalf("nonlethal health cost = %d, want 1", got)
	}
}

func TestCanMergeRequiresItemsAndConditions(t *testing.T) {
	recipe := MergeRecipe{
		ID:              "ashen_orator_staff",
		RequiredItemIDs: []string{"phase5_ashen_ring", "phase4_ember_staff"},
		Conditions: []MergeCondition{
			{Type: "resonance_discovered", ResonanceID: "coal_remembers_flame"},
			{Type: "attunement_level", ItemID: "phase5_ashen_ring", Value: 2},
			{Type: "soul_name_revealed", SoulID: "varn_ashen_orator"},
		},
	}
	state := MergeState{
		Items:                map[string]bool{"phase5_ashen_ring": true, "phase4_ember_staff": true},
		AttunementLevels:     map[string]int{"phase5_ashen_ring": 2},
		DiscoveredResonances: map[string]bool{"coal_remembers_flame": true},
		RevealedSoulNames:    map[string]bool{"varn_ashen_orator": true},
	}
	if !CanMerge(recipe, state) {
		t.Fatal("merge unavailable with all items and conditions satisfied")
	}
	state.DiscoveredResonances = map[string]bool{}
	if CanMerge(recipe, state) {
		t.Fatal("merge available without discovered resonance")
	}
}
