package phase6

type UIState struct {
	ActivePanel    string
	DebugMode      bool
	SelectedTileID string
	LastAnimation  AnimationEvent
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
