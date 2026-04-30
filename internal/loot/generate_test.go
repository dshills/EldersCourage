package loot

import (
	"os"
	"path/filepath"
	"testing"
)

func TestGenerateIsDeterministic(t *testing.T) {
	root := t.TempDir()
	writeLootItems(t, root, `[
		{"id":"weapon_a","name":"Weapon A","type":"weapon","rarity":"relic"},
		{"id":"weapon_b","name":"Weapon B","type":"weapon","rarity":"relic"},
		{"id":"weapon_c","name":"Weapon C","type":"weapon","rarity":"worn"}
	]`)

	options := GenerateOptions{DataRoot: root, Level: 5, Rarity: "relic", Seed: 42}
	first, err := Generate(options)
	if err != nil {
		t.Fatalf("Generate returned error: %v", err)
	}
	second, err := Generate(options)
	if err != nil {
		t.Fatalf("Generate returned error: %v", err)
	}
	if first.ID != second.ID {
		t.Fatalf("Generate not deterministic: %q != %q", first.ID, second.ID)
	}
	if first.Rarity != "relic" {
		t.Fatalf("rarity = %q, want relic", first.Rarity)
	}
}

func TestGenerateRejectsMissingRarity(t *testing.T) {
	root := t.TempDir()
	writeLootItems(t, root, `[{"id":"weapon_a","name":"Weapon A","type":"weapon","rarity":"worn"}]`)

	_, err := Generate(GenerateOptions{DataRoot: root, Level: 5, Rarity: "relic", Seed: 1})
	if err == nil {
		t.Fatal("Generate returned nil error")
	}
}

func writeLootItems(t *testing.T, root string, body string) {
	t.Helper()
	path := filepath.Join(root, "items", "items.json")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("MkdirAll: %v", err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("WriteFile: %v", err)
	}
}
