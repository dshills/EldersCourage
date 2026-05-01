package phase8

import "testing"

func TestClampTrust(t *testing.T) {
	for _, test := range []struct {
		name string
		in   int
		want int
	}{
		{name: "low", in: -7, want: -3},
		{name: "inside", in: 2, want: 2},
		{name: "high", in: 9, want: 3},
	} {
		t.Run(test.name, func(t *testing.T) {
			if got := ClampTrust(test.in); got != test.want {
				t.Fatalf("ClampTrust(%d) = %d, want %d", test.in, got, test.want)
			}
		})
	}
}

func TestRevealStage(t *testing.T) {
	if got := RevealStage(NewSoulState()); got != 0 {
		t.Fatalf("unrevealed stage = %d, want 0", got)
	}
	state := NewSoulState()
	state.SoulRevealed = true
	if got := RevealStage(state); got != 1 {
		t.Fatalf("presence stage = %d, want 1", got)
	}
	state.NameRevealed = true
	if got := RevealStage(state); got != 2 {
		t.Fatalf("name stage = %d, want 2", got)
	}
	state.MotivationRevealed = true
	if got := RevealStage(state); got != 3 {
		t.Fatalf("motivation stage = %d, want 3", got)
	}
}

func TestRevealMemoryDedupes(t *testing.T) {
	state := NewSoulState()
	var changed bool
	state, changed = RevealMemory(state, "varn_hall")
	if !changed {
		t.Fatal("first memory reveal did not report changed")
	}
	state, changed = RevealMemory(state, "varn_hall")
	if changed {
		t.Fatal("duplicate memory reveal reported changed")
	}
}

func TestMarkWhisperSeenDedupes(t *testing.T) {
	state := NewSoulState()
	var changed bool
	state, changed = MarkWhisperSeen(state, "varn_equip")
	if !changed {
		t.Fatal("first whisper mark did not report changed")
	}
	state, changed = MarkWhisperSeen(state, "varn_equip")
	if changed {
		t.Fatal("duplicate whisper mark reported changed")
	}
}

func TestApplyNonlethalCost(t *testing.T) {
	if got := ApplyNonlethalCost(12, 5); got != 7 {
		t.Fatalf("ApplyNonlethalCost = %d, want 7", got)
	}
	if got := ApplyNonlethalCost(3, 5); got != 1 {
		t.Fatalf("ApplyNonlethalCost low health = %d, want 1", got)
	}
}

func TestBargainDamageBonusRequiresAcceptedBargain(t *testing.T) {
	state := NewSoulState()
	if got := BargainDamageBonus(state, "breath_for_flame", "ember_bolt", 2); got != 0 {
		t.Fatalf("unaccepted bargain bonus = %d, want 0", got)
	}
	state.AcceptedBargains["breath_for_flame"] = true
	if got := BargainDamageBonus(state, "breath_for_flame", "ember_bolt", 2); got != 2 {
		t.Fatalf("accepted bargain bonus = %d, want 2", got)
	}
}
