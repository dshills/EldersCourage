package phase8

const (
	MinTrust = -3
	MaxTrust = 3
)

type SoulState struct {
	SoulRevealed       bool
	NameRevealed       bool
	MotivationRevealed bool
	Trust              int
	Memories           map[string]bool
	SeenWhispers       map[string]bool
	AcceptedBargains   map[string]bool
	RejectedBargains   map[string]bool
}

func NewSoulState() SoulState {
	return SoulState{
		Memories:         map[string]bool{},
		SeenWhispers:     map[string]bool{},
		AcceptedBargains: map[string]bool{},
		RejectedBargains: map[string]bool{},
	}
}

func ClampTrust(value int) int {
	if value < MinTrust {
		return MinTrust
	}
	if value > MaxTrust {
		return MaxTrust
	}
	return value
}

func AdjustTrust(state SoulState, amount int) SoulState {
	state.Trust = ClampTrust(state.Trust + amount)
	return state
}

func RevealStage(state SoulState) int {
	switch {
	case state.MotivationRevealed:
		return 3
	case state.NameRevealed:
		return 2
	case state.SoulRevealed:
		return 1
	default:
		return 0
	}
}

func RevealMemory(state SoulState, id string) (SoulState, bool) {
	if state.Memories == nil {
		state.Memories = map[string]bool{}
	}
	if id == "" || state.Memories[id] {
		return state, false
	}
	state.Memories[id] = true
	return state, true
}

func MarkWhisperSeen(state SoulState, id string) (SoulState, bool) {
	if state.SeenWhispers == nil {
		state.SeenWhispers = map[string]bool{}
	}
	if id == "" || state.SeenWhispers[id] {
		return state, false
	}
	state.SeenWhispers[id] = true
	return state, true
}

func ApplyNonlethalCost(current, amount int) int {
	if amount <= 0 {
		return current
	}
	result := current - amount
	if result < 1 {
		return 1
	}
	return result
}

func BargainResolved(state SoulState, id string) bool {
	return state.AcceptedBargains[id] || state.RejectedBargains[id]
}

func BargainDamageBonus(state SoulState, bargainID, skillID string, amount int) int {
	if skillID == "" || amount == 0 || !state.AcceptedBargains[bargainID] {
		return 0
	}
	return amount
}
