package phase10

type ZoneState struct {
	Position          Point
	Visited           map[string]bool
	ClearedEncounters map[string]bool
	OpenedContainers  map[string]bool
	ActivatedShrines  map[string]bool
	CompletedHazards  map[string]bool
}

type Point struct {
	X int
	Y int
}

type TransitionRequirement struct {
	Type    string
	QuestID string
	StageID string
}

type Transition struct {
	TargetZoneID string
	Target       Point
	Requires     []TransitionRequirement
}

type QuestState struct {
	CompletedStages map[string]bool
}

func NewZoneState(start Point) ZoneState {
	return ZoneState{
		Position:          start,
		Visited:           map[string]bool{},
		ClearedEncounters: map[string]bool{},
		OpenedContainers:  map[string]bool{},
		ActivatedShrines:  map[string]bool{},
		CompletedHazards:  map[string]bool{},
	}
}

func CanTransition(transition Transition, quests map[string]QuestState) bool {
	if transition.TargetZoneID == "" {
		return false
	}
	for _, requirement := range transition.Requires {
		switch requirement.Type {
		case "quest_stage_complete":
			if !quests[requirement.QuestID].CompletedStages[requirement.StageID] {
				return false
			}
		default:
			return false
		}
	}
	return true
}

func ApplyTransition(states map[string]ZoneState, currentZoneID string, currentPosition Point, transition Transition) (string, map[string]ZoneState) {
	current := states[currentZoneID]
	current.Position = currentPosition
	states[currentZoneID] = current
	target := states[transition.TargetZoneID]
	target.Position = transition.Target
	states[transition.TargetZoneID] = target
	return transition.TargetZoneID, states
}

func ApplyNonlethalDamage(health int, damage int) int {
	if damage <= 0 {
		return health
	}
	result := health - damage
	if result < 1 {
		return 1
	}
	return result
}

func BurningThornDamage(base int, defense int, resonanceActive bool, charmActive bool) int {
	damage := base
	if defense >= 4 && damage > 3 {
		damage = 3
	}
	if resonanceActive {
		damage -= 2
	}
	if charmActive {
		damage -= 2
	}
	if damage < 1 {
		return 1
	}
	return damage
}
