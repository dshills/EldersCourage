package validate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDataAcceptsValidJSON(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/weapon.json", `{
		"id":"weapon_rusty_oath",
		"name":"Rusty Oath",
		"type":"weapon",
		"rarity":"worn",
		"visibleStats":[{"stat":"base_damage","value":3}],
		"hiddenStats":[],
		"attunement":{},
		"synergyTags":[]
	}`)

	result, err := Data(root)
	if err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
	if result.FilesChecked != 1 {
		t.Fatalf("FilesChecked = %d, want 1", result.FilesChecked)
	}
}

func TestDataRejectsMalformedJSON(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/broken.json", `{"id":`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for malformed JSON")
	}
	if !strings.Contains(err.Error(), "malformed JSON") {
		t.Fatalf("error = %q, want malformed JSON", err.Error())
	}
}

func TestDataRejectsDuplicateIDs(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/a.json", `{"id":"duplicate_id"}`)
	writeFile(t, root, "items/b.json", `{"id":"duplicate_id"}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for duplicate IDs")
	}
	if !strings.Contains(err.Error(), "duplicate id") {
		t.Fatalf("error = %q, want duplicate id", err.Error())
	}
}

func TestDataRejectsInvalidItemRarity(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/item.json", `{
		"id":"weapon_bad",
		"name":"Bad Weapon",
		"type":"weapon",
		"rarity":"legendary",
		"visibleStats":[],
		"hiddenStats":[],
		"attunement":{},
		"synergyTags":[]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid rarity")
	}
	if !strings.Contains(err.Error(), "invalid rarity") {
		t.Fatalf("error = %q, want invalid rarity", err.Error())
	}
}

func TestDataRejectsUnknownLootReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "loot/arena.json", `{"id":"loot_test","drops":["missing_item"]}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown loot reference")
	}
	if !strings.Contains(err.Error(), "unknown item") {
		t.Fatalf("error = %q, want unknown item", err.Error())
	}
}

func TestDataRejectsInvalidEchoTrigger(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/bad.json", `{"id":"echo_bad","name":"Bad Echo","trigger":"unknown"}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid echo trigger")
	}
	if !strings.Contains(err.Error(), "invalid trigger") {
		t.Fatalf("error = %q, want invalid trigger", err.Error())
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
