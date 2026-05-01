package phase10

import "testing"

func TestCanTransitionRequiresCompletedStage(t *testing.T) {
	transition := Transition{
		TargetZoneID: "ashwood_glen",
		Requires: []TransitionRequirement{
			{Type: "quest_stage_complete", QuestID: "phase3_the_elder_road", StageID: "phase3_break_the_ambush"},
		},
	}
	quests := map[string]QuestState{
		"phase3_the_elder_road": {CompletedStages: map[string]bool{}},
	}
	if CanTransition(transition, quests) {
		t.Fatal("transition available before required quest stage")
	}
	quests["phase3_the_elder_road"].CompletedStages["phase3_break_the_ambush"] = true
	if !CanTransition(transition, quests) {
		t.Fatal("transition unavailable after required quest stage")
	}
}

func TestApplyTransitionPreservesPerZonePosition(t *testing.T) {
	states := map[string]ZoneState{
		"phase3_elder_road_outskirts": NewZoneState(Point{X: 0, Y: 0}),
		"ashwood_glen":                NewZoneState(Point{X: 0, Y: 0}),
	}
	current, states := ApplyTransition(states, "phase3_elder_road_outskirts", Point{X: 4, Y: 3}, Transition{TargetZoneID: "ashwood_glen", Target: Point{X: 0, Y: 0}})
	if current != "ashwood_glen" {
		t.Fatalf("current zone = %q, want ashwood_glen", current)
	}
	if got := states["phase3_elder_road_outskirts"].Position; got != (Point{X: 4, Y: 3}) {
		t.Fatalf("elder road position = %+v, want 4,3", got)
	}
	if got := states["ashwood_glen"].Position; got != (Point{X: 0, Y: 0}) {
		t.Fatalf("ashwood position = %+v, want 0,0", got)
	}
}

func TestApplyNonlethalDamage(t *testing.T) {
	if got := ApplyNonlethalDamage(5, 2); got != 3 {
		t.Fatalf("health = %d, want 3", got)
	}
	if got := ApplyNonlethalDamage(3, 8); got != 1 {
		t.Fatalf("nonlethal health = %d, want 1", got)
	}
}

func TestBurningThornDamageMitigation(t *testing.T) {
	if got := BurningThornDamage(6, 1, false, false); got != 6 {
		t.Fatalf("unmitigated = %d, want 6", got)
	}
	if got := BurningThornDamage(6, 4, false, false); got != 3 {
		t.Fatalf("defense mitigated = %d, want 3", got)
	}
	if got := BurningThornDamage(6, 4, true, true); got != 1 {
		t.Fatalf("stacked mitigation = %d, want 1", got)
	}
}
