package phase6

type UIState struct {
	ActivePanel    string
	DebugMode      bool
	SelectedTileID string
	LastAnimation  AnimationEvent
}

type HeaderView struct {
	Zone      string
	ClassName string
	Level     int
	XP        int
	XPToNext  int
	Gold      int
	DebugLine string
	ShowDebug bool
}

type Message struct {
	Type string
	Text string
}

type TileView struct {
	Current   bool
	Visited   bool
	Marker    string
	Available bool
}

type AnimationEvent struct {
	ID       string
	Type     string
	TargetID string
}

func OpenPanel(state UIState, panel string) UIState {
	state.ActivePanel = panel
	return state
}

func TogglePanel(state UIState, panel string) UIState {
	if state.ActivePanel == panel {
		state.ActivePanel = ""
		return state
	}
	state.ActivePanel = panel
	return state
}

func ClosePanel(state UIState) UIState {
	state.ActivePanel = ""
	return state
}

func ToggleDebugMode(state UIState) UIState {
	state.DebugMode = !state.DebugMode
	return state
}

func SelectTile(state UIState, tileID string) UIState {
	state.SelectedTileID = tileID
	return state
}

func PushAnimation(state UIState, event AnimationEvent) UIState {
	state.LastAnimation = event
	return state
}

func Header(zone string, className string, level int, xp int, xpToNext int, gold int, debug bool, position string, tileID string, encounterID string) HeaderView {
	view := HeaderView{Zone: zone, ClassName: className, Level: level, XP: xp, XPToNext: xpToNext, Gold: gold, ShowDebug: debug}
	if debug {
		if encounterID == "" {
			encounterID = "none"
		}
		view.DebugLine = "Position " + position + " | Tile " + tileID + " | Encounter " + encounterID
	}
	return view
}

func VisibleMessages(messages []Message, limit int) []Message {
	if limit <= 0 || len(messages) == 0 {
		return nil
	}
	result := []Message{}
	for index := len(messages) - 1; index >= 0 && len(result) < limit; index-- {
		result = append(result, messages[index])
	}
	return result
}

func Tile(current bool, visited bool, hasEnemy bool, hasContainer bool, containerOpened bool, hasShrine bool, shrineActivated bool, objective bool) TileView {
	view := TileView{Current: current, Visited: visited}
	switch {
	case hasEnemy:
		view.Marker = "Enemy"
		view.Available = true
	case hasContainer:
		if containerOpened {
			view.Marker = "Opened Cache"
		} else {
			view.Marker = "Cache"
			view.Available = true
		}
	case hasShrine:
		if shrineActivated {
			view.Marker = "Spent Shrine"
		} else {
			view.Marker = "Shrine"
			view.Available = true
		}
	case objective:
		view.Marker = "Objective"
		view.Available = true
	default:
		view.Marker = "Road"
	}
	return view
}
