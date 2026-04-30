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

func TestDataAcceptsPhase2Documents(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase2/items.json", `[
		{"id":"old_sword","name":"Old Sword","type":"weapon","description":"A blade.","icon":"res://assets/items/sword.png","quantity":1,"stackable":false}
	]`)
	writeFile(t, root, "phase2/enemies.json", `[
		{"id":"ash_road_scout","name":"Ash Road Scout","health":30,"maxHealth":30,"defeated":false}
	]`)
	writeFile(t, root, "phase2/quests.json", `[
		{"id":"first_courage","title":"First Courage","description":"Recover the sword.","objectives":[{"id":"open_chest","label":"Open the chest","completed":false}],"completed":false}
	]`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsInvalidPhase2ItemType(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase2/items.json", `[
		{"id":"bad_item","name":"Bad Item","type":"armor","description":"No.","icon":"res://bad.png","quantity":1,"stackable":false}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for invalid phase2 item type")
	}
	if !strings.Contains(err.Error(), "invalid type") {
		t.Fatalf("error = %q, want invalid type", err.Error())
	}
}

func TestDataRejectsDuplicatePhase2QuestObjective(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase2/quests.json", `[
		{"id":"first_courage","title":"First Courage","description":"Recover the sword.","objectives":[
			{"id":"open_chest","label":"Open the chest","completed":false},
			{"id":"open_chest","label":"Open again","completed":false}
		],"completed":false}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for duplicate phase2 objective")
	}
	if !strings.Contains(err.Error(), "duplicate objective") {
		t.Fatalf("error = %q, want duplicate objective", err.Error())
	}
}

func TestDataAcceptsPhase3Documents(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase3/items.json", `[
		{"id":"phase3_old_sword","name":"Old Sword","type":"weapon","description":"A blade.","icon":"res://assets/items/sword.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"weapon","stats":{"strength":2}}
	]`)
	writeFile(t, root, "phase3/loot_tables.json", `[
		{"id":"phase3_loot_test","entries":[{"itemId":"phase3_old_sword","quantity":1,"chance":1}],"gold":{"min":1,"max":2}}
	]`)
	writeFile(t, root, "phase3/enemies.json", `[
		{"id":"phase3_goblin_scout","name":"Goblin Scout","health":30,"maxHealth":30,"attack":4,"defense":0,"xpReward":20,"lootTable":"phase3_loot_test"}
	]`)
	writeFile(t, root, "phase3/containers.json", `[
		{"id":"phase3_chest","name":"Chest","opened":false,"lootTableId":"phase3_loot_test"}
	]`)
	writeFile(t, root, "phase3/shrines.json", `[
		{"id":"phase3_shrine","name":"Shrine","activated":false,"restoreHealth":20,"restoreMana":10}
	]`)
	writeFile(t, root, "phase3/quest_chain.json", `{
		"id":"phase3_quest","title":"Quest","description":"Do work.","completed":false,
		"stages":[{"id":"stage","title":"Stage","description":"Do it.","completed":false,"objectives":[{"id":"objective","label":"Done","completed":false}]}]
	}`)
	writeFile(t, root, "phase3/zone_test.json", `{
		"id":"phase3_zone","name":"Zone","description":"A zone.","width":2,"height":1,"startPosition":[0,0],"completed":false,
		"tiles":[
			{"id":"tile_a","kind":"camp","name":"Camp","description":"Start","position":[0,0],"state":"visited"},
			{"id":"tile_b","kind":"road","name":"Road","description":"Fight","position":[1,0],"state":"visible","encounterId":"phase3_goblin_scout","containerId":"phase3_chest","shrineId":"phase3_shrine"}
		]
	}`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsPhase3ZoneOutOfBounds(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase3/zone_bad.json", `{
		"id":"phase3_zone","name":"Zone","description":"A zone.","width":1,"height":1,"startPosition":[0,0],"completed":false,
		"tiles":[{"id":"tile_bad","kind":"road","name":"Road","description":"Bad","position":[2,0],"state":"visible"}]
	}`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for phase3 out-of-bounds tile")
	}
	if !strings.Contains(err.Error(), "out of bounds") {
		t.Fatalf("error = %q, want out of bounds", err.Error())
	}
}

func TestDataRejectsPhase3UnknownLootItemReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase3/loot_tables.json", `[
		{"id":"phase3_loot_test","entries":[{"itemId":"missing_item","quantity":1,"chance":1}]}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for phase3 unknown loot item")
	}
	if !strings.Contains(err.Error(), "unknown item") {
		t.Fatalf("error = %q, want unknown item", err.Error())
	}
}

func TestDataAcceptsPhase4Documents(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase4/starter_items.json", `[
		{"id":"phase4_staff","name":"Staff","type":"weapon","description":"A staff.","icon":"res://staff.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"weapon","stats":{"spellPower":2}}
	]`)
	writeFile(t, root, "phase4/skills.json", `[
		{"id":"ember_bolt","classId":"ember_sage","name":"Ember Bolt","description":"Burn.","icon":"res://bolt.png","targetType":"enemy","resource":"mana","resourceCost":10,"cooldownTurns":0,"effects":[{"type":"damage","amount":10,"scalingStat":"spellPower","scalingMultiplier":1.5}],"messageTemplate":"Burn {damage}."}
	]`)
	writeFile(t, root, "phase4/talents.json", `[
		{"id":"ember_memory","classId":"ember_sage","name":"Ember Memory","nodes":[
			{"id":"living_flame","classId":"ember_sage","name":"Living Flame","description":"Power.","maxRank":2,"requiredLevel":2,"prerequisiteTalentIds":[],"effects":[{"type":"stat_bonus","stat":"spellPower","amount":1}]},
			{"id":"focused_ember","classId":"ember_sage","name":"Focused Ember","description":"Bolt.","maxRank":1,"requiredLevel":3,"prerequisiteTalentIds":["living_flame"],"effects":[{"type":"skill_damage_bonus","skillId":"ember_bolt","amount":4}]}
		]}
	]`)
	writeFile(t, root, "phase4/classes.json", `[
		{"id":"ember_sage","name":"Ember Sage","subtitle":"Keeper","description":"Fire.","portrait":"res://portrait.png","baseStats":{"strength":1,"defense":1,"spellPower":5,"maxHealthBonus":-5,"maxManaBonus":25},"startingHealth":85,"startingMana":75,"startingGold":8,"startingItemIds":["phase4_staff"],"startingSkillIds":["ember_bolt"],"talentTreeId":"ember_memory","startMessage":"Start.","levelUpMessage":"Level {level}."}
	]`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsPhase4ClassUnknownSkill(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase4/starter_items.json", `[
		{"id":"phase4_staff","name":"Staff","type":"weapon","description":"A staff.","icon":"res://staff.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"weapon","stats":{"spellPower":2}}
	]`)
	writeFile(t, root, "phase4/talents.json", `[
		{"id":"ember_memory","classId":"ember_sage","name":"Ember Memory","nodes":[{"id":"living_flame","classId":"ember_sage","name":"Living Flame","description":"Power.","maxRank":2,"requiredLevel":2,"prerequisiteTalentIds":[],"effects":[{"type":"stat_bonus","stat":"spellPower","amount":1}]}]}
	]`)
	writeFile(t, root, "phase4/classes.json", `[
		{"id":"ember_sage","name":"Ember Sage","subtitle":"Keeper","description":"Fire.","portrait":"res://portrait.png","baseStats":{"strength":1,"defense":1,"spellPower":5,"maxHealthBonus":-5,"maxManaBonus":25},"startingHealth":85,"startingMana":75,"startingGold":8,"startingItemIds":["phase4_staff"],"startingSkillIds":["missing_skill"],"talentTreeId":"ember_memory","startMessage":"Start.","levelUpMessage":"Level {level}."}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown phase4 skill")
	}
	if !strings.Contains(err.Error(), "unknown skill") {
		t.Fatalf("error = %q, want unknown skill", err.Error())
	}
}

func TestDataRejectsPhase4TalentUnknownPrerequisite(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase4/talents.json", `[
		{"id":"road_oaths","classId":"roadwarden","name":"Road Oaths","nodes":[
			{"id":"stalwart_guard","classId":"roadwarden","name":"Stalwart Guard","description":"Guard.","maxRank":1,"requiredLevel":3,"prerequisiteTalentIds":["missing"],"effects":[{"type":"stat_bonus","stat":"defense","amount":1}]}
		]}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown phase4 prerequisite")
	}
	if !strings.Contains(err.Error(), "unknown prerequisite") {
		t.Fatalf("error = %q, want unknown prerequisite", err.Error())
	}
}

func TestDataAcceptsPhase5Items(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase4/skills.json", `[
		{"id":"ember_bolt","classId":"ember_sage","name":"Ember Bolt","description":"Burn.","icon":"res://bolt.png","targetType":"enemy","resource":"mana","resourceCost":10,"cooldownTurns":0,"effects":[{"type":"damage","amount":10}],"messageTemplate":"Burn {damage}."}
	]`)
	writeFile(t, root, "phase5/items.json", `[
		{"id":"phase5_identify_scroll","name":"Identify Scroll","type":"consumable","description":"Reveal.","icon":"res://scroll.png","quantity":1,"stackable":true,"equippable":false,"defaultKnowledgeState":"known","attunable":false,"properties":[]},
		{"id":"phase5_ashen_ring","name":"Ashen Ring","type":"trinket","description":"Ring.","icon":"res://ring.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"trinket","stats":{},"defaultKnowledgeState":"unidentified","attunable":true,"maxAttunementLevel":3,"properties":[
			{"id":"ember_memory","name":"Ember Memory","description":"Power.","kind":"stat_modifier","visibility":"hidden","revealed":false,"cursed":false,"requirements":[{"type":"identify"}],"effects":[{"type":"stat_bonus","stat":"spellPower","amount":1}]},
			{"id":"hungry_spark","name":"Hungry Spark","description":"Bolt.","kind":"skill_modifier","visibility":"locked_by_attunement","revealed":false,"cursed":false,"requirements":[{"type":"attunement","value":2}],"effects":[{"type":"damage_bonus","skillId":"ember_bolt","amount":3}]},
			{"id":"blood_price","name":"Blood Price","description":"Cost.","kind":"curse","visibility":"hidden","revealed":false,"cursed":true,"requirements":[{"type":"combat_use"}],"effects":[{"type":"health_cost","amount":2}]}
		]}
	]`)

	if _, err := Data(root); err != nil {
		t.Fatalf("Data returned error: %v", err)
	}
}

func TestDataRejectsPhase5UnknownSkillReference(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase5/items.json", `[
		{"id":"phase5_ashen_ring","name":"Ashen Ring","type":"trinket","description":"Ring.","icon":"res://ring.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"trinket","stats":{},"defaultKnowledgeState":"unidentified","attunable":true,"maxAttunementLevel":3,"properties":[
			{"id":"hungry_spark","name":"Hungry Spark","description":"Bolt.","kind":"skill_modifier","visibility":"locked_by_attunement","revealed":false,"cursed":false,"requirements":[{"type":"attunement","value":2}],"effects":[{"type":"damage_bonus","skillId":"missing_skill","amount":3}]}
		]}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for unknown phase5 skill")
	}
	if !strings.Contains(err.Error(), "unknown skill") {
		t.Fatalf("error = %q, want unknown skill", err.Error())
	}
}

func TestDataRejectsPhase5AttunementRequirementOnNonAttunableItem(t *testing.T) {
	root := t.TempDir()
	writeFile(t, root, "phase5/items.json", `[
		{"id":"phase5_charm","name":"Charm","type":"trinket","description":"Charm.","icon":"res://charm.png","quantity":1,"stackable":false,"equippable":true,"equipmentSlot":"trinket","stats":{},"defaultKnowledgeState":"unidentified","attunable":false,"properties":[
			{"id":"locked","name":"Locked","description":"No.","kind":"stat_modifier","visibility":"locked_by_attunement","revealed":false,"cursed":false,"requirements":[{"type":"attunement","value":1}],"effects":[{"type":"stat_bonus","stat":"defense","amount":1}]}
		]}
	]`)

	_, err := Data(root)
	if err == nil {
		t.Fatal("Data returned nil error for bad attunement requirement")
	}
	if !strings.Contains(err.Error(), "non-attunable") {
		t.Fatalf("error = %q, want non-attunable", err.Error())
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
