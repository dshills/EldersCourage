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
	for _, doc := range documents {
		if err := validateDocument(doc.path, doc.value, seenIDs); err != nil {
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
	if !ok || !validString(itemType, []string{"weapon", "armor", "ring"}) {
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
		dropID, ok := rawDrop.(string)
		if !ok || strings.TrimSpace(dropID) == "" {
			return fmt.Errorf("%s: loot drop IDs must be non-empty strings", path)
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
	if trigger, ok := echo["trigger"].(string); ok && !validString(trigger, []string{"enemy_killed", "enemy_killed_by_fire"}) {
		return fmt.Errorf("%s: echo %q has invalid trigger %q", path, echo["id"], trigger)
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
		"base_damage",
		"bell_damage_percent",
		"cold_resistance",
		"cooldown_recovery_percent",
		"critical_chance_percent",
		"fire_damage_percent",
		"fire_resistance",
		"max_health",
		"max_will",
	}
}
