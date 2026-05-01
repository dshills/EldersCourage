package phase6

import "testing"

func TestOpenPanelReplacesActivePanel(t *testing.T) {
	state := OpenPanel(UIState{}, "inventory")
	state = OpenPanel(state, "talents")

	if state.ActivePanel != "talents" {
		t.Fatalf("ActivePanel = %q, want talents", state.ActivePanel)
	}
}

func TestTogglePanelClosesMatchingPanel(t *testing.T) {
	state := TogglePanel(UIState{}, "inventory")
	if state.ActivePanel != "inventory" {
		t.Fatalf("ActivePanel = %q, want inventory", state.ActivePanel)
	}
	state = TogglePanel(state, "inventory")
	if state.ActivePanel != "" {
		t.Fatalf("ActivePanel = %q, want empty", state.ActivePanel)
	}
}

func TestClosePanelClearsActivePanel(t *testing.T) {
	state := ClosePanel(UIState{ActivePanel: "talents"})
	if state.ActivePanel != "" {
		t.Fatalf("ActivePanel = %q, want empty", state.ActivePanel)
	}
}

func TestToggleDebugMode(t *testing.T) {
	state := ToggleDebugMode(UIState{})
	if !state.DebugMode {
		t.Fatal("DebugMode = false, want true")
	}
	state = ToggleDebugMode(state)
	if state.DebugMode {
		t.Fatal("DebugMode = true, want false")
	}
}
