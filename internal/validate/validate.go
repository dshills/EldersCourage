package validate

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// Result summarizes a validation run.
type Result struct {
	FilesChecked int
}

type document struct {
	path  string
	value any
}

type contentSummary struct {
	Weapons     int
	Armor       int
	Rings       int
	Curses      int
	Echoes      int
	Synergies   int
	ItemTags    map[string]bool
	EnemyIDs    map[string]bool
	ModifierIDs map[string]bool
}

// Data validates JSON content files under root.
func Data(root string) (Result, error) {
	info, err := os.Stat(root)
	if err != nil {
		return Result{}, fmt.Errorf("validate data: %w", err)
	}
	if !info.IsDir() {
		return Result{}, fmt.Errorf("validate data: %s is not a directory", root)
	}

	seenIDs := map[string]string{}
	documents := []document{}
	result := Result{}

	err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() || filepath.Ext(path) != ".json" {
			return nil
		}

		result.FilesChecked++
		payload, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("%s: read file: %w", path, err)
		}

		var decoded any
		if err := json.Unmarshal(payload, &decoded); err != nil {
			return fmt.Errorf("%s: malformed JSON: %w", path, err)
		}
		documents = append(documents, document{path: path, value: decoded})

		return collectIDs(path, decoded, seenIDs)
	})
	if err != nil {
		return Result{}, err
	}
	summary := contentSummary{ItemTags: map[string]bool{}, EnemyIDs: map[string]bool{}, ModifierIDs: map[string]bool{}}
	for _, doc := range documents {
		if err := validateDocument(doc.path, doc.value, seenIDs); err != nil {
			return Result{}, err
		}
		summarizeDocument(doc.path, doc.value, &summary)
	}
	for _, doc := range documents {
		if err := validateReferences(doc.path, doc.value, seenIDs, summary.ItemTags, summary.EnemyIDs, summary.ModifierIDs); err != nil {
			return Result{}, err
		}
	}
	if shouldEnforcePrototypeCounts(root) {
		if err := validatePrototypeCounts(summary); err != nil {
			return Result{}, err
		}
	}

	return result, nil
}

func collectIDs(path string, value any, seenIDs map[string]string) error {
	switch typed := value.(type) {
	case map[string]any:
		return collectRecordID(path, typed, seenIDs)
	case []any:
		for _, child := range typed {
			record, ok := child.(map[string]any)
			if !ok {
				continue
			}
			if err := collectRecordID(path, record, seenIDs); err != nil {
				return err
			}
		}
	}
	return nil
}

func records(value any) []map[string]any {
	switch typed := value.(type) {
	case map[string]any:
		return []map[string]any{typed}
	case []any:
		result := []map[string]any{}
		for _, child := range typed {
			if record, ok := child.(map[string]any); ok {
				result = append(result, record)
			}
		}
		return result
	default:
		return nil
	}
}

func collectRecordID(path string, record map[string]any, seenIDs map[string]string) error {
	rawID, ok := record["id"]
	if !ok {
		return nil
	}
	id, ok := rawID.(string)
	if !ok || strings.TrimSpace(id) == "" {
		return fmt.Errorf("%s: field id must be a non-empty string", path)
	}
	if previous, exists := seenIDs[id]; exists {
		return fmt.Errorf("%s: duplicate id %q already defined in %s", path, id, previous)
	}
	seenIDs[id] = path
	return nil
}

func validateDocument(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/items/") {
		return validateItemDocument(path, value)
	}
	if strings.Contains(cleanPath, "/loot/") {
		return validateLootDocument(path, value, seenIDs)
	}
	if strings.Contains(cleanPath, "/echoes/") {
		return validateEchoDocument(path, value)
	}
	if strings.Contains(cleanPath, "/curses/") {
		return validateCurseDocument(path, value)
	}
	if strings.Contains(cleanPath, "/enemies/") {
		return validateEnemyDocument(path, value)
	}
	if strings.Contains(cleanPath, "/modifiers/") {
		return validateModifierDocument(path, value)
	}
	if strings.Contains(cleanPath, "/synergies/") {
		return validateSynergyDocument(path, value)
	}
	if strings.Contains(cleanPath, "/dungeons/") {
		return validateDungeonDocument(path, value)
	}
	return nil
}

func validateItemDocument(path string, value any) error {
	switch typed := value.(type) {
	case []any:
		for index, item := range typed {
			record, ok := item.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: item at index %d must be an object", path, index)
			}
			if err := validateItem(path, record); err != nil {
				return err
			}
		}
	case map[string]any:
		return validateItem(path, typed)
	default:
		return fmt.Errorf("%s: item document must be an object or array", path)
	}
	return nil
}

func validateItem(path string, item map[string]any) error {
	for _, field := range []string{"id", "name", "type", "rarity", "visibleStats", "hiddenStats", "attunement", "synergyTags"} {
		if _, ok := item[field]; !ok {
			return fmt.Errorf("%s: item missing required field %q", path, field)
		}
	}
	itemType, ok := item["type"].(string)
	if !ok || !validString(itemType, []string{"weapon", "armor", "ring", "consumable"}) {
		return fmt.Errorf("%s: item %q has invalid type %q", path, item["id"], item["type"])
	}
	rarity, ok := item["rarity"].(string)
	if !ok || !validString(rarity, []string{"worn", "forged", "relic", "accursed", "mythic_echoed"}) {
		return fmt.Errorf("%s: item %q has invalid rarity %q", path, item["id"], item["rarity"])
	}
	if err := validateStats(path, item["id"], item["visibleStats"]); err != nil {
		return err
	}
	if err := validateStats(path, item["id"], item["hiddenStats"]); err != nil {
		return err
	}
	if tags, ok := item["synergyTags"].([]any); !ok {
		return fmt.Errorf("%s: item %q synergyTags must be an array", path, item["id"])
	} else {
		for _, tag := range tags {
			if raw, ok := tag.(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: item %q has invalid synergy tag", path, item["id"])
			}
		}
	}
	return nil
}

func validateStats(path string, itemID any, value any) error {
	stats, ok := value.([]any)
	if !ok {
		return fmt.Errorf("%s: item %q stats must be an array", path, itemID)
	}
	for _, statValue := range stats {
		stat, ok := statValue.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: item %q stat must be an object", path, itemID)
		}
		name, ok := stat["stat"].(string)
		if !ok || !validString(name, validStatNames()) {
			return fmt.Errorf("%s: item %q has invalid stat %q", path, itemID, stat["stat"])
		}
		if _, ok := stat["value"].(float64); !ok {
			return fmt.Errorf("%s: item %q stat %q value must be numeric", path, itemID, name)
		}
	}
	return nil
}

func validateLootDocument(path string, value any, seenIDs map[string]string) error {
	loot, ok := value.(map[string]any)
	if !ok {
		return fmt.Errorf("%s: loot document must be an object", path)
	}
	drops, ok := loot["drops"].([]any)
	if !ok {
		return fmt.Errorf("%s: loot document must contain drops array", path)
	}
	for _, rawDrop := range drops {
		dropID := ""
		if rawID, ok := rawDrop.(string); ok {
			dropID = rawID
		} else if drop, ok := rawDrop.(map[string]any); ok {
			rawItemID, ok := drop["itemId"].(string)
			if !ok || strings.TrimSpace(rawItemID) == "" {
				return fmt.Errorf("%s: loot drop objects require non-empty itemId", path)
			}
			dropID = rawItemID
			weight, ok := drop["weight"].(float64)
			if !ok || weight <= 0 {
				return fmt.Errorf("%s: loot drop %q requires positive numeric weight", path, dropID)
			}
		} else {
			return fmt.Errorf("%s: loot drops must be item ID strings or weighted objects", path)
		}
		if _, exists := seenIDs[dropID]; !exists {
			return fmt.Errorf("%s: loot drop references unknown item %q", path, dropID)
		}
	}
	return nil
}

func validateEchoDocument(path string, value any) error {
	switch typed := value.(type) {
	case []any:
		for index, echo := range typed {
			record, ok := echo.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: echo at index %d must be an object", path, index)
			}
			if err := validateEcho(path, record); err != nil {
				return err
			}
		}
	case map[string]any:
		return validateEcho(path, typed)
	default:
		return fmt.Errorf("%s: echo document must be an object or array", path)
	}
	return nil
}

func validateEcho(path string, echo map[string]any) error {
	for _, field := range []string{"id", "name"} {
		if raw, ok := echo[field].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: echo missing string field %q", path, field)
		}
	}
	if trigger, ok := echo["trigger"].(string); ok {
		if !validString(trigger, []string{"enemy_killed", "enemy_killed_by_fire", "basic_attack_hit"}) {
			return fmt.Errorf("%s: echo %q has invalid trigger %q", path, echo["id"], trigger)
		}
		effect, ok := echo["effect"].(map[string]any)
		if !ok {
			return fmt.Errorf("%s: echo %q missing effect object", path, echo["id"])
		}
		effectType, ok := effect["type"].(string)
		if !ok || !validString(effectType, []string{"damage_orb", "delayed_second_hit", "brief_armor_gain", "restore_will", "chill_nearby", "vulnerable_nearby", "bell_pulse"}) {
			return fmt.Errorf("%s: echo %q has invalid effect type %q", path, echo["id"], effect["type"])
		}
		for _, field := range requiredEchoEffectFields(effectType) {
			if value, ok := effect[field].(float64); !ok || value < 0 {
				return fmt.Errorf("%s: echo %q effect field %q must be non-negative numeric", path, echo["id"], field)
			}
		}
	} else if strings.HasPrefix(fmt.Sprint(echo["id"]), "death_echo_") {
		if err := validateDeathEcho(path, echo); err != nil {
			return err
		}
	}
	return nil
}

func validateDeathEcho(path string, echo map[string]any) error {
	effects, ok := echo["effectsUntilReclaimed"].([]any)
	if !ok || len(effects) == 0 {
		return fmt.Errorf("%s: death echo %q requires effectsUntilReclaimed", path, echo["id"])
	}
	for _, rawEffect := range effects {
		effect, ok := rawEffect.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: death echo %q effect must be an object", path, echo["id"])
		}
		target, ok := effect["target"].(string)
		if !ok || !validString(target, []string{"enemies_in_room", "nearby_enemies"}) {
			return fmt.Errorf("%s: death echo %q has invalid effect target %q", path, echo["id"], effect["target"])
		}
		stat, ok := effect["stat"].(string)
		if !ok || !validString(stat, []string{"damage_percent", "movement_speed_percent"}) {
			return fmt.Errorf("%s: death echo %q has invalid effect stat %q", path, echo["id"], effect["stat"])
		}
		if value, ok := effect["value"].(float64); !ok || value < 0 {
			return fmt.Errorf("%s: death echo %q effect value must be non-negative numeric", path, echo["id"])
		}
	}
	reward, ok := echo["reclaimReward"].(map[string]any)
	if !ok {
		return fmt.Errorf("%s: death echo %q requires reclaimReward", path, echo["id"])
	}
	if value, ok := reward["attunementXp"].(float64); !ok || value < 0 {
		return fmt.Errorf("%s: death echo %q reclaimReward attunementXp must be non-negative numeric", path, echo["id"])
	}
	return nil
}

func requiredEchoEffectFields(effectType string) []string {
	switch effectType {
	case "damage_orb":
		return []string{"durationSeconds", "damagePerSecond"}
	case "delayed_second_hit":
		return []string{"damageMultiplier", "delaySeconds"}
	case "brief_armor_gain":
		return []string{"armor", "durationSeconds"}
	case "restore_will":
		return []string{"amount"}
	case "chill_nearby":
		return []string{"durationSeconds", "slowPercent"}
	case "vulnerable_nearby":
		return []string{"durationSeconds", "damageTakenPercent"}
	case "bell_pulse":
		return []string{"damage"}
	default:
		return nil
	}
}

func validateCurseDocument(path string, value any) error {
	for _, curse := range records(value) {
		for _, field := range []string{"id", "name"} {
			if raw, ok := curse[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: curse missing string field %q", path, field)
			}
		}
		effects, ok := curse["effects"].([]any)
		if !ok || len(effects) == 0 {
			return fmt.Errorf("%s: curse %q missing effects array", path, curse["id"])
		}
		for _, rawEffect := range effects {
			effect, ok := rawEffect.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: curse %q effect must be an object", path, curse["id"])
			}
			stat, ok := effect["stat"].(string)
			if !ok || !validString(stat, validStatNames()) {
				return fmt.Errorf("%s: curse %q has invalid effect stat %q", path, curse["id"], effect["stat"])
			}
			if _, ok := effect["value"].(float64); !ok {
				return fmt.Errorf("%s: curse %q effect value must be numeric", path, curse["id"])
			}
		}
	}
	return nil
}

func validateEnemyDocument(path string, value any) error {
	for _, enemy := range records(value) {
		for _, field := range []string{"id", "name", "role"} {
			if raw, ok := enemy[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: enemy missing string field %q", path, field)
			}
		}
		role, _ := enemy["role"].(string)
		if !validString(role, []string{"melee", "ranged", "heavy", "boss"}) {
			return fmt.Errorf("%s: enemy %q has invalid role %q", path, enemy["id"], role)
		}
		for _, field := range []string{"maxHealth", "attackDamage"} {
			if value, ok := enemy[field].(float64); !ok || value <= 0 {
				return fmt.Errorf("%s: enemy %q field %q must be positive numeric", path, enemy["id"], field)
			}
		}
	}
	return nil
}

func validateSynergyDocument(path string, value any) error {
	for _, synergy := range records(value) {
		for _, field := range []string{"id", "name"} {
			if raw, ok := synergy[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: synergy missing string field %q", path, field)
			}
		}
		discoveryType, ok := synergy["discoveryType"].(string)
		if !ok || !validString(discoveryType, []string{"explicit", "hidden", "scroll_revealed"}) {
			return fmt.Errorf("%s: synergy %q has invalid discoveryType %q", path, synergy["id"], synergy["discoveryType"])
		}
		tags, ok := synergy["requiredTags"].([]any)
		if !ok || len(tags) == 0 {
			return fmt.Errorf("%s: synergy %q requires non-empty requiredTags", path, synergy["id"])
		}
		for _, tag := range tags {
			if raw, ok := tag.(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: synergy %q has invalid required tag", path, synergy["id"])
			}
		}
		if _, ok := synergy["effect"].(map[string]any); !ok {
			return fmt.Errorf("%s: synergy %q missing effect object", path, synergy["id"])
		}
	}
	return nil
}

func validateDungeonDocument(path string, value any) error {
	for _, dungeon := range records(value) {
		rooms, ok := dungeon["rooms"].([]any)
		if !ok || len(rooms) == 0 {
			return fmt.Errorf("%s: dungeon %q requires rooms array", path, dungeon["id"])
		}
		for _, rawRoom := range rooms {
			room, ok := rawRoom.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: dungeon room must be an object", path)
			}
			roomType, ok := room["type"].(string)
			if !ok || !validString(roomType, []string{"entrance", "combat", "elite", "treasure", "boss"}) {
				return fmt.Errorf("%s: dungeon room has invalid type %q", path, room["type"])
			}
			for _, field := range []string{"playerStart"} {
				if rawPoint, ok := room[field]; ok {
					if err := validatePoint(path, room["id"], field, rawPoint); err != nil {
						return err
					}
				}
			}
			for _, rawPoint := range asArray(room["spawnPoints"]) {
				if err := validatePoint(path, room["id"], "spawnPoints", rawPoint); err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func validatePoint(path string, roomID any, field string, value any) error {
	point, ok := value.([]any)
	if !ok || len(point) != 2 {
		return fmt.Errorf("%s: dungeon room %q field %q must be a two-number array", path, roomID, field)
	}
	for _, coordinate := range point {
		if _, ok := coordinate.(float64); !ok {
			return fmt.Errorf("%s: dungeon room %q field %q must contain numeric coordinates", path, roomID, field)
		}
	}
	return nil
}

func validateModifierDocument(path string, value any) error {
	for _, modifier := range records(value) {
		for _, field := range []string{"id", "name"} {
			if raw, ok := modifier[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: modifier missing string field %q", path, field)
			}
		}
		for _, field := range []string{"healthMultiplier", "damageMultiplier", "speedMultiplier"} {
			if value, ok := modifier[field].(float64); !ok || value <= 0 {
				return fmt.Errorf("%s: modifier %q field %q must be positive numeric", path, modifier["id"], field)
			}
		}
		if color, ok := modifier["color"].([]any); ok {
			if len(color) != 3 {
				return fmt.Errorf("%s: modifier %q color must contain three numbers", path, modifier["id"])
			}
			for _, channel := range color {
				if _, ok := channel.(float64); !ok {
					return fmt.Errorf("%s: modifier %q color must be numeric", path, modifier["id"])
				}
			}
		}
	}
	return nil
}

func validateReferences(path string, value any, seenIDs map[string]string, itemTags map[string]bool, enemyIDs map[string]bool, modifierIDs map[string]bool) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/items/") {
		for _, item := range records(value) {
			if curse, ok := item["curse"].(map[string]any); ok {
				if id, ok := curse["id"].(string); ok && id != "" {
					if _, exists := seenIDs[id]; !exists {
						return fmt.Errorf("%s: item %q references unknown curse %q", path, item["id"], id)
					}
				}
			}
			for _, rawEcho := range asArray(item["echoes"]) {
				echo, ok := rawEcho.(map[string]any)
				if !ok {
					return fmt.Errorf("%s: item %q echo reference must be an object", path, item["id"])
				}
				id, ok := echo["id"].(string)
				if !ok || strings.TrimSpace(id) == "" {
					return fmt.Errorf("%s: item %q echo reference requires id", path, item["id"])
				}
				if _, exists := seenIDs[id]; !exists {
					return fmt.Errorf("%s: item %q references unknown echo %q", path, item["id"], id)
				}
			}
		}
	}
	if strings.Contains(cleanPath, "/synergies/") {
		for _, synergy := range records(value) {
			for _, rawTag := range asArray(synergy["requiredTags"]) {
				tag, _ := rawTag.(string)
				if !itemTags[tag] {
					return fmt.Errorf("%s: synergy %q requires unknown tag %q", path, synergy["id"], tag)
				}
			}
		}
	}
	if strings.Contains(cleanPath, "/dungeons/") {
		for _, dungeon := range records(value) {
			for _, rawRoom := range asArray(dungeon["rooms"]) {
				room, ok := rawRoom.(map[string]any)
				if !ok {
					continue
				}
				if lootTableID, ok := room["lootTable"].(string); ok && lootTableID != "" {
					if _, exists := seenIDs[lootTableID]; !exists {
						return fmt.Errorf("%s: dungeon room %q references unknown loot table %q", path, room["id"], lootTableID)
					}
				}
				for _, rawItemID := range asArray(room["rewardDrops"]) {
					itemID, ok := rawItemID.(string)
					if !ok || strings.TrimSpace(itemID) == "" {
						return fmt.Errorf("%s: dungeon room %q has invalid reward drop reference", path, room["id"])
					}
					if _, exists := seenIDs[itemID]; !exists {
						return fmt.Errorf("%s: dungeon room %q references unknown reward item %q", path, room["id"], itemID)
					}
				}
				for _, rawEnemyID := range asArray(room["encounter"]) {
					enemyID, ok := rawEnemyID.(string)
					if !ok || strings.TrimSpace(enemyID) == "" {
						return fmt.Errorf("%s: dungeon room %q has invalid enemy reference", path, room["id"])
					}
					if !enemyIDs[enemyID] {
						return fmt.Errorf("%s: dungeon room %q references unknown enemy %q", path, room["id"], enemyID)
					}
				}
				for _, rawModifierID := range asArray(room["modifiers"]) {
					modifierID, ok := rawModifierID.(string)
					if !ok || strings.TrimSpace(modifierID) == "" {
						return fmt.Errorf("%s: dungeon room %q has invalid modifier reference", path, room["id"])
					}
					if !modifierIDs[modifierID] {
						return fmt.Errorf("%s: dungeon room %q references unknown modifier %q", path, room["id"], modifierID)
					}
				}
			}
		}
	}
	return nil
}

func summarizeDocument(path string, value any, summary *contentSummary) {
	cleanPath := filepath.ToSlash(path)
	switch {
	case strings.Contains(cleanPath, "/items/"):
		for _, item := range records(value) {
			switch item["type"] {
			case "weapon":
				summary.Weapons++
			case "armor":
				summary.Armor++
			case "ring":
				summary.Rings++
			}
			for _, rawTag := range asArray(item["synergyTags"]) {
				if tag, ok := rawTag.(string); ok {
					summary.ItemTags[tag] = true
				}
			}
		}
	case strings.Contains(cleanPath, "/curses/"):
		summary.Curses += len(records(value))
	case strings.Contains(cleanPath, "/enemies/"):
		for _, enemy := range records(value) {
			if id, ok := enemy["id"].(string); ok {
				summary.EnemyIDs[id] = true
			}
		}
	case strings.Contains(cleanPath, "/modifiers/"):
		for _, modifier := range records(value) {
			if id, ok := modifier["id"].(string); ok {
				summary.ModifierIDs[id] = true
			}
		}
	case strings.Contains(cleanPath, "/echoes/"):
		for _, echo := range records(value) {
			if _, ok := echo["trigger"]; ok {
				summary.Echoes++
			}
		}
	case strings.Contains(cleanPath, "/synergies/"):
		summary.Synergies += len(records(value))
	}
}

func validatePrototypeCounts(summary contentSummary) error {
	requirements := []struct {
		name string
		got  int
		want int
	}{
		{"weapons", summary.Weapons, 10},
		{"armor", summary.Armor, 8},
		{"rings", summary.Rings, 10},
		{"curses", summary.Curses, 5},
		{"item echoes", summary.Echoes, 5},
		{"synergies", summary.Synergies, 5},
	}
	for _, requirement := range requirements {
		if requirement.got < requirement.want {
			return fmt.Errorf("prototype content requires at least %d %s, found %d", requirement.want, requirement.name, requirement.got)
		}
	}
	return nil
}

func shouldEnforcePrototypeCounts(root string) bool {
	return filepath.Base(filepath.Clean(root)) == "data"
}

func asArray(value any) []any {
	if typed, ok := value.([]any); ok {
		return typed
	}
	return nil
}

func validString(value string, allowed []string) bool {
	for _, candidate := range allowed {
		if value == candidate {
			return true
		}
	}
	return false
}

func validStatNames() []string {
	return []string{
		"armor",
		"attack_damage",
		"attack_speed",
		"base_damage",
		"bell_damage_percent",
		"cold_resistance",
		"cooldown_recovery_percent",
		"critical_chance",
		"critical_chance_percent",
		"echo_power",
		"fire_damage_percent",
		"fire_resistance",
		"max_health",
		"max_will",
		"move_speed",
	}
}
