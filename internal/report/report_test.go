package report

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestAcceptanceTextIncludesCounts(t *testing.T) {
	acceptance := Acceptance{
		FilesChecked: 9,
		Weapons:      10,
		Armor:        8,
		Rings:        10,
		Curses:       5,
		ItemEchoes:   5,
		Synergies:    5,
		Dungeons:     1,
	}

	text := acceptance.Text()
	for _, expected := range []string{"Weapons: 10 / 10 PASS", "Dungeons: 1 / 1 PASS", "Runtime gameplay criteria require Godot manual verification."} {
		if !strings.Contains(text, expected) {
			t.Fatalf("report missing %q:\n%s", expected, text)
		}
	}
}

func TestGenerateUsesValidation(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/bad.json", `{"id":"bad","name":"Bad","type":"weapon","rarity":"invalid"}`)

	_, err := Generate(root)
	if err == nil {
		t.Fatal("Generate returned nil error for invalid data")
	}
}

func writeFile(t *testing.T, root string, name string, body string) {
	t.Helper()
	path := filepath.Join(root, name)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("MkdirAll: %v", err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("WriteFile: %v", err)
	}
}
