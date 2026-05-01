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

func TestHeaderHidesDebugByDefault(t *testing.T) {
	view := Header("Elder Road", "Ember Sage", 2, 10, 100, 8, false, "0,0", "camp", "")
	if view.ShowDebug || view.DebugLine != "" {
		t.Fatalf("debug shown by default: %+v", view)
	}

	view = Header("Elder Road", "Ember Sage", 2, 10, 100, 8, true, "0,0", "camp", "")
	if !view.ShowDebug || view.DebugLine == "" {
		t.Fatalf("debug not shown when enabled: %+v", view)
	}
}

func TestVisibleMessagesNewestFirstAndCapped(t *testing.T) {
	messages := []Message{{Text: "one"}, {Text: "two"}, {Text: "three"}}
	visible := VisibleMessages(messages, 2)

	if len(visible) != 2 {
		t.Fatalf("len(visible) = %d, want 2", len(visible))
	}
	if visible[0].Text != "three" || visible[1].Text != "two" {
		t.Fatalf("visible = %+v, want newest first", visible)
	}
}

func TestTileMarkers(t *testing.T) {
	if got := Tile(false, false, true, false, false, false, false, false); got.Marker != "Enemy" || !got.Available {
		t.Fatalf("enemy tile = %+v, want available Enemy", got)
	}
	if got := Tile(false, false, false, true, true, false, false, false); got.Marker != "Opened Cache" || got.Available {
		t.Fatalf("opened cache tile = %+v, want unavailable Opened Cache", got)
	}
	if got := Tile(false, false, false, false, false, true, false, false); got.Marker != "Shrine" || !got.Available {
		t.Fatalf("shrine tile = %+v, want available Shrine", got)
	}
}
