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

func TestDataRejectsInvalidCurseEffectStat(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "curses/curses.json", `[
		{"id":"curse_bad","name":"Bad Curse","effects":[{"stat":"not_a_stat","value":1}]}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid curse effect stat")
	}
	if !strings.Contains(err.Error(), "invalid effect stat") {
		t.Fatalf("error = %q, want invalid effect stat", err.Error())
	}
}

func TestDataAcceptsValidCurseEffects(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "curses/curses.json", `[
		{"id":"curse_slow","name":"Slow Curse","effects":[{"stat":"move_speed","value":-8}]}
	]`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
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

func TestDataAcceptsWeightedLootReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "items/weapon.json", `{
		"id":"weapon_weighted",
		"name":"Weighted Blade",
		"type":"weapon",
		"rarity":"worn",
		"visibleStats":[{"stat":"base_damage","value":3}],
		"hiddenStats":[],
		"attunement":{},
		"synergyTags":[]
	}`)
	writeFile(t, root, "loot/arena.json", `{"id":"loot_test","drops":[{"itemId":"weapon_weighted","weight":5}]}`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsInvalidEchoTrigger(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/bad.json", `{"id":"echo_bad","name":"Bad Echo","trigger":"unknown","effect":{"type":"restore_will","amount":1}}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid echo trigger")
	}
	if !strings.Contains(err.Error(), "invalid trigger") {
		t.Fatalf("error = %q, want invalid trigger", err.Error())
	}
}

func TestDataRejectsInvalidEchoEffect(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/bad.json", `{"id":"echo_bad","name":"Bad Echo","trigger":"enemy_killed","effect":{"type":"unknown"}}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid echo effect")
	}
	if !strings.Contains(err.Error(), "invalid effect type") {
		t.Fatalf("error = %q, want invalid effect type", err.Error())
	}
}

func TestDataRejectsMissingEchoEffectField(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/bad.json", `{"id":"echo_bad","name":"Bad Echo","trigger":"enemy_killed","effect":{"type":"bell_pulse"}}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for missing echo effect field")
	}
	if !strings.Contains(err.Error(), "effect field") {
		t.Fatalf("error = %q, want effect field", err.Error())
	}
}

func TestDataRejectsInvalidDeathEchoReward(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/death.json", `{
		"id":"death_echo_bad",
		"name":"Bad Death Echo",
		"effectsUntilReclaimed":[{"target":"enemies_in_room","stat":"damage_percent","value":10}],
		"reclaimReward":{}
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid death echo reward")
	}
	if !strings.Contains(err.Error(), "attunementXp") {
		t.Fatalf("error = %q, want attunementXp", err.Error())
	}
}

func TestDataAcceptsValidDeathEcho(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "echoes/death.json", `{
		"id":"death_echo_last_breath",
		"name":"Echo of Your Last Breath",
		"effectsUntilReclaimed":[{"target":"enemies_in_room","stat":"damage_percent","value":10}],
		"reclaimReward":{"attunementXp":25}
	}`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsUnknownDungeonEnemyReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"combat","encounter":["missing_enemy"]}]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown dungeon enemy")
	}
	if !strings.Contains(err.Error(), "unknown enemy") {
		t.Fatalf("error = %q, want unknown enemy", err.Error())
	}
}

func TestDataAcceptsKnownDungeonEnemyReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "enemies/enemies.json", `[
		{"id":"bone_thrall","name":"Bone Thrall","role":"melee","maxHealth":60,"attackDamage":10}
	]`)
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"combat","encounter":["bone_thrall"]}]
	}`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsUnknownDungeonLootTableReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"treasure","lootTable":"missing_loot"}]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown dungeon loot table")
	}
	if !strings.Contains(err.Error(), "unknown loot table") {
		t.Fatalf("error = %q, want unknown loot table", err.Error())
	}
}

func TestDataRejectsUnknownDungeonRewardReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"treasure","rewardDrops":["missing_item"]}]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown dungeon reward")
	}
	if !strings.Contains(err.Error(), "unknown reward item") {
		t.Fatalf("error = %q, want unknown reward item", err.Error())
	}
}

func TestDataRejectsUnknownDungeonModifierReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"elite","modifiers":["missing_modifier"]}]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown dungeon modifier")
	}
	if !strings.Contains(err.Error(), "unknown modifier") {
		t.Fatalf("error = %q, want unknown modifier", err.Error())
	}
}

func TestDataAcceptsKnownDungeonModifierReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "modifiers/elite.json", `[
		{"id":"burning","name":"Burning","healthMultiplier":1.5,"damageMultiplier":1.25,"speedMultiplier":1.08}
	]`)
	writeFile(t, root, "dungeons/ashen.json", `{
		"id":"dungeon_test",
		"name":"Test Dungeon",
		"rooms":[{"id":"room_1","type":"elite","modifiers":["burning"]}]
	}`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
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
