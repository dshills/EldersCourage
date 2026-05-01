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
	if strings.Contains(cleanPath, "/phase2/items.json") {
		return validatePhase2ItemDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase2/enemies.json") {
		return validatePhase2EnemyDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase2/quests.json") {
		return validatePhase2QuestDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/items.json") {
		return validatePhase3ItemDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/enemies.json") {
		return validatePhase3EnemyDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/loot_tables.json") {
		return validatePhase3LootTableDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/containers.json") {
		return validatePhase3ContainerDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/shrines.json") {
		return validatePhase3ShrineDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/quest_chain.json") {
		return validatePhase3QuestChainDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase3/zone_") {
		return validatePhase3ZoneDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase4/starter_items.json") {
		return validatePhase3ItemDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase4/classes.json") {
		return validatePhase4ClassDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase4/skills.json") {
		return validatePhase4SkillDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase4/talents.json") {
		return validatePhase4TalentDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase5/items.json") {
		return validatePhase5ItemDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase8/ring_souls.json") {
		return validatePhase8RingSoulDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase9/item_resonances.json") {
		return validatePhase9ResonanceDocument(path, value)
	}
	if strings.Contains(cleanPath, "/phase9/item_merges.json") {
		return validatePhase9MergeDocument(path, value)
	}
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

func validatePhase4ClassDocument(path string, value any) error {
	for _, class := range records(value) {
		for _, field := range []string{"id", "name", "subtitle", "description", "portrait", "talentTreeId", "startMessage", "levelUpMessage"} {
			if raw, ok := class[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase4 class missing string field %q", path, field)
			}
		}
		classID, _ := class["id"].(string)
		if !validString(classID, []string{"roadwarden", "ember_sage", "gravebound_scout"}) {
			return fmt.Errorf("%s: phase4 class has invalid id %q", path, classID)
		}
		stats, ok := class["baseStats"].(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase4 class %q requires baseStats", path, classID)
		}
		if err := validatePhase3Stats(path, classID, stats); err != nil {
			return err
		}
		for _, field := range []string{"startingHealth", "startingMana", "startingGold"} {
			if value, ok := class[field].(float64); !ok || value < 0 {
				return fmt.Errorf("%s: phase4 class %q field %q must be non-negative numeric", path, classID, field)
			}
		}
		for _, field := range []string{"startingItemIds", "startingSkillIds"} {
			values, ok := class[field].([]any)
			if !ok || len(values) == 0 {
				return fmt.Errorf("%s: phase4 class %q requires %s", path, classID, field)
			}
			for _, rawValue := range values {
				if value, ok := rawValue.(string); !ok || strings.TrimSpace(value) == "" {
					return fmt.Errorf("%s: phase4 class %q has invalid %s entry", path, classID, field)
				}
			}
		}
	}
	return nil
}

func validatePhase4SkillDocument(path string, value any) error {
	for _, skill := range records(value) {
		for _, field := range []string{"id", "classId", "name", "description", "icon", "targetType", "resource", "messageTemplate"} {
			if raw, ok := skill[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase4 skill missing string field %q", path, field)
			}
		}
		classID, _ := skill["classId"].(string)
		if !validString(classID, []string{"roadwarden", "ember_sage", "gravebound_scout"}) {
			return fmt.Errorf("%s: phase4 skill %q has invalid classId %q", path, skill["id"], classID)
		}
		targetType, _ := skill["targetType"].(string)
		if !validString(targetType, []string{"enemy", "self"}) {
			return fmt.Errorf("%s: phase4 skill %q has invalid targetType %q", path, skill["id"], targetType)
		}
		resource, _ := skill["resource"].(string)
		if !validString(resource, []string{"mana", "health", "none"}) {
			return fmt.Errorf("%s: phase4 skill %q has invalid resource %q", path, skill["id"], resource)
		}
		for _, field := range []string{"resourceCost", "cooldownTurns"} {
			if value, ok := skill[field].(float64); !ok || value < 0 {
				return fmt.Errorf("%s: phase4 skill %q field %q must be non-negative numeric", path, skill["id"], field)
			}
		}
		effects, ok := skill["effects"].([]any)
		if !ok || len(effects) == 0 {
			return fmt.Errorf("%s: phase4 skill %q requires effects", path, skill["id"])
		}
		for _, rawEffect := range effects {
			effect, ok := rawEffect.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase4 skill %q effect must be object", path, skill["id"])
			}
			effectType, _ := effect["type"].(string)
			if !validString(effectType, []string{"damage", "heal", "restore_mana", "buff", "debuff"}) {
				return fmt.Errorf("%s: phase4 skill %q has invalid effect type %q", path, skill["id"], effectType)
			}
			if amount, ok := effect["amount"].(float64); !ok || amount == 0 {
				return fmt.Errorf("%s: phase4 skill %q effect amount must be non-zero numeric", path, skill["id"])
			}
			if stat, ok := effect["scalingStat"].(string); ok && stat != "" {
				if !validString(stat, []string{"strength", "defense", "spellPower", "maxHealthBonus", "maxManaBonus"}) {
					return fmt.Errorf("%s: phase4 skill %q has invalid scalingStat %q", path, skill["id"], stat)
				}
			}
			if _, ok := effect["scalingMultiplier"]; ok {
				if _, ok := effect["scalingMultiplier"].(float64); !ok {
					return fmt.Errorf("%s: phase4 skill %q scalingMultiplier must be numeric", path, skill["id"])
				}
			}
			if effectType == "buff" || effectType == "debuff" {
				stat, ok := effect["stat"].(string)
				if !ok || !validString(stat, []string{"strength", "defense", "spellPower", "attack"}) {
					return fmt.Errorf("%s: phase4 skill %q modifier effect requires valid stat", path, skill["id"])
				}
				if turns, ok := effect["durationTurns"].(float64); !ok || turns <= 0 {
					return fmt.Errorf("%s: phase4 skill %q modifier effect requires positive durationTurns", path, skill["id"])
				}
			}
		}
	}
	return nil
}

func validatePhase4TalentDocument(path string, value any) error {
	for _, tree := range records(value) {
		for _, field := range []string{"id", "classId", "name"} {
			if raw, ok := tree[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase4 talent tree missing string field %q", path, field)
			}
		}
		nodes, ok := tree["nodes"].([]any)
		if !ok || len(nodes) == 0 {
			return fmt.Errorf("%s: phase4 talent tree %q requires nodes", path, tree["id"])
		}
		for _, rawNode := range nodes {
			node, ok := rawNode.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase4 talent node must be object", path)
			}
			for _, field := range []string{"id", "classId", "name", "description"} {
				if raw, ok := node[field].(string); !ok || strings.TrimSpace(raw) == "" {
					return fmt.Errorf("%s: phase4 talent node missing string field %q", path, field)
				}
			}
			for _, field := range []string{"maxRank", "requiredLevel"} {
				if value, ok := node[field].(float64); !ok || value <= 0 {
					return fmt.Errorf("%s: phase4 talent %q field %q must be positive numeric", path, node["id"], field)
				}
			}
			if _, ok := node["prerequisiteTalentIds"].([]any); !ok {
				return fmt.Errorf("%s: phase4 talent %q requires prerequisiteTalentIds array", path, node["id"])
			}
			effects, ok := node["effects"].([]any)
			if !ok || len(effects) == 0 {
				return fmt.Errorf("%s: phase4 talent %q requires effects", path, node["id"])
			}
			for _, rawEffect := range effects {
				effect, ok := rawEffect.(map[string]any)
				if !ok {
					return fmt.Errorf("%s: phase4 talent %q effect must be object", path, node["id"])
				}
				effectType, _ := effect["type"].(string)
				if !validString(effectType, []string{"stat_bonus", "skill_damage_bonus", "resource_cost_reduction", "cooldown_reduction"}) {
					return fmt.Errorf("%s: phase4 talent %q has invalid effect type %q", path, node["id"], effectType)
				}
				if _, ok := effect["amount"].(float64); !ok {
					return fmt.Errorf("%s: phase4 talent %q effect amount must be numeric", path, node["id"])
				}
				if effectType == "stat_bonus" {
					stat, ok := effect["stat"].(string)
					if !ok || !validString(stat, []string{"strength", "defense", "spellPower", "maxHealthBonus", "maxManaBonus"}) {
						return fmt.Errorf("%s: phase4 talent %q stat_bonus requires valid stat", path, node["id"])
					}
				} else if raw, ok := effect["skillId"].(string); !ok || strings.TrimSpace(raw) == "" {
					return fmt.Errorf("%s: phase4 talent %q effect requires skillId", path, node["id"])
				}
			}
		}
	}
	return nil
}

func validatePhase3ItemDocument(path string, value any) error {
	for _, item := range records(value) {
		for _, field := range []string{"id", "name", "type", "description", "icon"} {
			if raw, ok := item[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 item missing string field %q", path, field)
			}
		}
		itemType, _ := item["type"].(string)
		if !validString(itemType, []string{"currency", "weapon", "armor", "trinket", "consumable", "quest", "rune"}) {
			return fmt.Errorf("%s: phase3 item %q has invalid type %q", path, item["id"], itemType)
		}
		if quantity, ok := item["quantity"].(float64); !ok || quantity < 0 {
			return fmt.Errorf("%s: phase3 item %q quantity must be non-negative numeric", path, item["id"])
		}
		equippable, ok := item["equippable"].(bool)
		if !ok {
			return fmt.Errorf("%s: phase3 item %q equippable must be boolean", path, item["id"])
		}
		if _, ok := item["stackable"].(bool); !ok {
			return fmt.Errorf("%s: phase3 item %q stackable must be boolean", path, item["id"])
		}
		if equippable {
			slot, ok := item["equipmentSlot"].(string)
			if !ok || !validString(slot, []string{"weapon", "armor", "trinket"}) {
				return fmt.Errorf("%s: phase3 item %q has invalid equipmentSlot %q", path, item["id"], item["equipmentSlot"])
			}
			if stats, ok := item["stats"].(map[string]any); !ok || len(stats) == 0 {
				return fmt.Errorf("%s: phase3 item %q requires stats object", path, item["id"])
			} else if err := validatePhase3Stats(path, item["id"], stats); err != nil {
				return err
			}
		}
		if effect, ok := item["effect"].(map[string]any); ok {
			effectType, _ := effect["type"].(string)
			if effectType != "heal" {
				return fmt.Errorf("%s: phase3 item %q has invalid effect type %q", path, item["id"], effectType)
			}
			if amount, ok := effect["amount"].(float64); !ok || amount <= 0 {
				return fmt.Errorf("%s: phase3 item %q heal amount must be positive numeric", path, item["id"])
			}
		}
	}
	return nil
}

func validatePhase3Stats(path string, itemID any, stats map[string]any) error {
	for stat, value := range stats {
		if !validString(stat, []string{"strength", "defense", "spellPower", "maxHealthBonus", "maxManaBonus"}) {
			return fmt.Errorf("%s: phase3 item %q has invalid stat %q", path, itemID, stat)
		}
		if _, ok := value.(float64); !ok {
			return fmt.Errorf("%s: phase3 item %q stat %q must be numeric", path, itemID, stat)
		}
	}
	return nil
}

func validatePhase5ItemDocument(path string, value any) error {
	seenPropertyIDs := map[string]bool{}
	for _, item := range records(value) {
		for _, field := range []string{"id", "name", "type", "description", "icon", "defaultKnowledgeState"} {
			if raw, ok := item[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase5 item missing string field %q", path, field)
			}
		}
		itemType, _ := item["type"].(string)
		if !validString(itemType, []string{"currency", "weapon", "armor", "trinket", "consumable", "quest", "rune"}) {
			return fmt.Errorf("%s: phase5 item %q has invalid type %q", path, item["id"], itemType)
		}
		if quantity, ok := item["quantity"].(float64); !ok || quantity < 0 {
			return fmt.Errorf("%s: phase5 item %q quantity must be non-negative numeric", path, item["id"])
		}
		equippable, ok := item["equippable"].(bool)
		if !ok {
			return fmt.Errorf("%s: phase5 item %q equippable must be boolean", path, item["id"])
		}
		if _, ok := item["stackable"].(bool); !ok {
			return fmt.Errorf("%s: phase5 item %q stackable must be boolean", path, item["id"])
		}
		knowledgeState, _ := item["defaultKnowledgeState"].(string)
		if !validString(knowledgeState, []string{"known", "unidentified", "partially_identified", "identified"}) {
			return fmt.Errorf("%s: phase5 item %q has invalid defaultKnowledgeState %q", path, item["id"], knowledgeState)
		}
		if equippable {
			slot, ok := item["equipmentSlot"].(string)
			if !ok || !validString(slot, []string{"weapon", "armor", "trinket"}) {
				return fmt.Errorf("%s: phase5 item %q has invalid equipmentSlot %q", path, item["id"], item["equipmentSlot"])
			}
			if stats, ok := item["stats"].(map[string]any); ok {
				if err := validatePhase3Stats(path, item["id"], stats); err != nil {
					return err
				}
			} else {
				return fmt.Errorf("%s: phase5 item %q requires stats object", path, item["id"])
			}
		}
		attunable, ok := item["attunable"].(bool)
		if !ok {
			return fmt.Errorf("%s: phase5 item %q attunable must be boolean", path, item["id"])
		}
		if attunable {
			if value, ok := item["maxAttunementLevel"].(float64); !ok || value <= 0 {
				return fmt.Errorf("%s: phase5 item %q requires positive maxAttunementLevel", path, item["id"])
			}
		}
		properties, ok := item["properties"].([]any)
		if !ok {
			return fmt.Errorf("%s: phase5 item %q requires properties array", path, item["id"])
		}
		for _, rawProperty := range properties {
			property, ok := rawProperty.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase5 item %q property must be object", path, item["id"])
			}
			if err := validatePhase5Property(path, item, property, attunable, seenPropertyIDs); err != nil {
				return err
			}
		}
	}
	return nil
}

func validatePhase5Property(path string, item map[string]any, property map[string]any, attunable bool, seenPropertyIDs map[string]bool) error {
	for _, field := range []string{"id", "name", "description", "kind", "visibility"} {
		if raw, ok := property[field].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: phase5 item %q property missing string field %q", path, item["id"], field)
		}
	}
	propertyID := property["id"].(string)
	if seenPropertyIDs[propertyID] {
		return fmt.Errorf("%s: duplicate phase5 property id %q", path, propertyID)
	}
	seenPropertyIDs[propertyID] = true
	kind, _ := property["kind"].(string)
	if !validString(kind, []string{"stat_modifier", "combat_modifier", "skill_modifier", "resource_modifier", "curse", "lore"}) {
		return fmt.Errorf("%s: phase5 property %q has invalid kind %q", path, propertyID, kind)
	}
	visibility, _ := property["visibility"].(string)
	if !validString(visibility, []string{"visible", "hidden", "locked_by_level", "locked_by_attunement"}) {
		return fmt.Errorf("%s: phase5 property %q has invalid visibility %q", path, propertyID, visibility)
	}
	revealed, ok := property["revealed"].(bool)
	if !ok {
		return fmt.Errorf("%s: phase5 property %q revealed must be boolean", path, propertyID)
	}
	cursed, ok := property["cursed"].(bool)
	if !ok {
		return fmt.Errorf("%s: phase5 property %q cursed must be boolean", path, propertyID)
	}
	if cursed && kind != "curse" {
		return fmt.Errorf("%s: phase5 property %q cursed properties must use kind curse", path, propertyID)
	}
	requirements, ok := property["requirements"].([]any)
	if !ok {
		return fmt.Errorf("%s: phase5 property %q requires requirements array", path, propertyID)
	}
	for _, rawRequirement := range requirements {
		requirement, ok := rawRequirement.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase5 property %q requirement must be object", path, propertyID)
		}
		requirementType, ok := requirement["type"].(string)
		if !ok || !validString(requirementType, []string{"identify", "player_level", "attunement", "equip", "combat_use"}) {
			return fmt.Errorf("%s: phase5 property %q has invalid requirement type %q", path, propertyID, requirement["type"])
		}
		if requirementType == "player_level" || requirementType == "attunement" {
			value, ok := requirement["value"].(float64)
			if !ok || value <= 0 {
				return fmt.Errorf("%s: phase5 property %q requirement %q needs positive value", path, propertyID, requirementType)
			}
		}
		if requirementType == "attunement" && !attunable {
			return fmt.Errorf("%s: phase5 property %q has attunement requirement on non-attunable item", path, propertyID)
		}
	}
	effects, ok := property["effects"].([]any)
	if !ok {
		return fmt.Errorf("%s: phase5 property %q requires effects array", path, propertyID)
	}
	for _, rawEffect := range effects {
		effect, ok := rawEffect.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase5 property %q effect must be object", path, propertyID)
		}
		effectType, ok := effect["type"].(string)
		if !ok || !validString(effectType, []string{"stat_bonus", "stat_penalty", "damage_bonus", "damage_penalty", "mana_cost_modifier", "restore_mana_bonus", "health_cost", "xp_modifier", "gold_modifier"}) {
			return fmt.Errorf("%s: phase5 property %q has invalid effect type %q", path, propertyID, effect["type"])
		}
		if _, ok := effect["amount"].(float64); !ok {
			return fmt.Errorf("%s: phase5 property %q effect amount must be numeric", path, propertyID)
		}
		if effectType == "stat_bonus" || effectType == "stat_penalty" {
			stat, ok := effect["stat"].(string)
			if !ok || !validString(stat, []string{"strength", "defense", "spellPower", "maxHealthBonus", "maxManaBonus"}) {
				return fmt.Errorf("%s: phase5 property %q stat effect requires valid stat", path, propertyID)
			}
		}
		if effectType == "damage_bonus" || effectType == "damage_penalty" || effectType == "mana_cost_modifier" || effectType == "restore_mana_bonus" {
			if raw, ok := effect["skillId"].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase5 property %q effect requires skillId", path, propertyID)
			}
		}
		if revealed && visibility != "visible" {
			return fmt.Errorf("%s: phase5 property %q starts revealed but is not visible", path, propertyID)
		}
	}
	return nil
}

func validatePhase8RingSoulDocument(path string, value any) error {
	seenWhispers := map[string]bool{}
	seenMemories := map[string]bool{}
	seenBargains := map[string]bool{}
	for _, soul := range records(value) {
		for _, field := range []string{"id", "name", "epithet", "discipline", "motivation"} {
			if raw, ok := soul[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase8 ring soul missing string field %q", path, field)
			}
		}
		tags, ok := soul["personalityTags"].([]any)
		if !ok || len(tags) == 0 {
			return fmt.Errorf("%s: phase8 ring soul %q requires personalityTags", path, soul["id"])
		}
		for _, rawTag := range tags {
			if tag, ok := rawTag.(string); !ok || strings.TrimSpace(tag) == "" {
				return fmt.Errorf("%s: phase8 ring soul %q has invalid personality tag", path, soul["id"])
			}
		}
		trustRange, ok := soul["trustRange"].(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase8 ring soul %q requires trustRange", path, soul["id"])
		}
		minTrust, minOK := trustRange["min"].(float64)
		maxTrust, maxOK := trustRange["max"].(float64)
		if !minOK || !maxOK || minTrust > maxTrust || minTrust < -3 || maxTrust > 3 {
			return fmt.Errorf("%s: phase8 ring soul %q trustRange must stay within -3..3", path, soul["id"])
		}
		if err := validatePhase8Whispers(path, soul, seenWhispers); err != nil {
			return err
		}
		memoryIDs, err := validatePhase8Memories(path, soul, seenMemories)
		if err != nil {
			return err
		}
		if err := validatePhase8Bargains(path, soul, seenBargains, memoryIDs); err != nil {
			return err
		}
	}
	return nil
}

func validatePhase8Whispers(path string, soul map[string]any, seenWhispers map[string]bool) error {
	whispers, ok := soul["whispers"].([]any)
	if !ok || len(whispers) == 0 {
		return fmt.Errorf("%s: phase8 ring soul %q requires whispers", path, soul["id"])
	}
	for _, rawWhisper := range whispers {
		whisper, ok := rawWhisper.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase8 ring soul %q whisper must be object", path, soul["id"])
		}
		for _, field := range []string{"id", "trigger", "line"} {
			if raw, ok := whisper[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase8 whisper missing string field %q", path, field)
			}
		}
		whisperID := whisper["id"].(string)
		if seenWhispers[whisperID] {
			return fmt.Errorf("%s: duplicate phase8 whisper id %q", path, whisperID)
		}
		seenWhispers[whisperID] = true
		trigger := whisper["trigger"].(string)
		if !validString(trigger, []string{"on_equip", "on_skill_use", "on_enemy_defeated", "on_attunement_level_up", "on_curse_trigger", "on_bargain_offered", "on_bargain_accepted", "on_bargain_rejected"}) {
			return fmt.Errorf("%s: phase8 whisper %q has invalid trigger %q", path, whisperID, trigger)
		}
		if once, ok := whisper["once"]; ok {
			if _, ok := once.(bool); !ok {
				return fmt.Errorf("%s: phase8 whisper %q once must be boolean", path, whisperID)
			}
		}
		if cooldown, ok := whisper["cooldownTurns"]; ok {
			if value, ok := cooldown.(float64); !ok || value < 0 {
				return fmt.Errorf("%s: phase8 whisper %q cooldownTurns must be non-negative numeric", path, whisperID)
			}
		}
		for _, field := range []string{"minTrust", "maxTrust"} {
			if raw, ok := whisper[field]; ok {
				if value, ok := raw.(float64); !ok || value < -3 || value > 3 {
					return fmt.Errorf("%s: phase8 whisper %q %s must stay within -3..3", path, whisperID, field)
				}
			}
		}
		for _, rawSkillID := range asArray(whisper["skillIds"]) {
			if skillID, ok := rawSkillID.(string); !ok || strings.TrimSpace(skillID) == "" {
				return fmt.Errorf("%s: phase8 whisper %q has invalid skillIds entry", path, whisperID)
			}
		}
	}
	return nil
}

func validatePhase8Memories(path string, soul map[string]any, seenMemories map[string]bool) (map[string]bool, error) {
	memories, ok := soul["memories"].([]any)
	if !ok || len(memories) == 0 {
		return nil, fmt.Errorf("%s: phase8 ring soul %q requires memories", path, soul["id"])
	}
	memoryIDs := map[string]bool{}
	for _, rawMemory := range memories {
		memory, ok := rawMemory.(map[string]any)
		if !ok {
			return nil, fmt.Errorf("%s: phase8 ring soul %q memory must be object", path, soul["id"])
		}
		for _, field := range []string{"id", "title", "text"} {
			if raw, ok := memory[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return nil, fmt.Errorf("%s: phase8 memory missing string field %q", path, field)
			}
		}
		memoryID := memory["id"].(string)
		if seenMemories[memoryID] {
			return nil, fmt.Errorf("%s: duplicate phase8 memory id %q", path, memoryID)
		}
		seenMemories[memoryID] = true
		memoryIDs[memoryID] = true
		reveal, ok := memory["reveal"].(map[string]any)
		if !ok {
			return nil, fmt.Errorf("%s: phase8 memory %q requires reveal", path, memoryID)
		}
		revealType, ok := reveal["type"].(string)
		if !ok || !validString(revealType, []string{"attunement", "attunement_or_bargain"}) {
			return nil, fmt.Errorf("%s: phase8 memory %q has invalid reveal type %q", path, memoryID, reveal["type"])
		}
		if level, ok := reveal["level"].(float64); !ok || level <= 0 || level > 3 {
			return nil, fmt.Errorf("%s: phase8 memory %q reveal level must be 1..3", path, memoryID)
		}
		if revealType == "attunement_or_bargain" {
			if bargainID, ok := reveal["bargainId"].(string); !ok || strings.TrimSpace(bargainID) == "" {
				return nil, fmt.Errorf("%s: phase8 memory %q requires bargainId", path, memoryID)
			}
		}
	}
	return memoryIDs, nil
}

func validatePhase8Bargains(path string, soul map[string]any, seenBargains map[string]bool, memoryIDs map[string]bool) error {
	bargains, ok := soul["bargains"].([]any)
	if !ok || len(bargains) == 0 {
		return fmt.Errorf("%s: phase8 ring soul %q requires bargains", path, soul["id"])
	}
	for _, rawBargain := range bargains {
		bargain, ok := rawBargain.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase8 ring soul %q bargain must be object", path, soul["id"])
		}
		for _, field := range []string{"id", "name", "offerLine", "acceptMessage", "rejectMessage"} {
			if raw, ok := bargain[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase8 bargain missing string field %q", path, field)
			}
		}
		bargainID := bargain["id"].(string)
		if seenBargains[bargainID] {
			return fmt.Errorf("%s: duplicate phase8 bargain id %q", path, bargainID)
		}
		seenBargains[bargainID] = true
		trigger, ok := bargain["trigger"].(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase8 bargain %q requires trigger", path, bargainID)
		}
		triggerType, ok := trigger["type"].(string)
		if !ok || triggerType != "attunement" {
			return fmt.Errorf("%s: phase8 bargain %q trigger type must be attunement", path, bargainID)
		}
		if level, ok := trigger["level"].(float64); !ok || level <= 0 || level > 3 {
			return fmt.Errorf("%s: phase8 bargain %q trigger level must be 1..3", path, bargainID)
		}
		healthCost, ok := bargain["healthCost"].(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase8 bargain %q requires healthCost", path, bargainID)
		}
		if amount, ok := healthCost["amount"].(float64); !ok || amount <= 0 {
			return fmt.Errorf("%s: phase8 bargain %q healthCost amount must be positive numeric", path, bargainID)
		}
		if nonlethal, ok := healthCost["nonlethal"].(bool); !ok || !nonlethal {
			return fmt.Errorf("%s: phase8 bargain %q healthCost must be nonlethal", path, bargainID)
		}
		for _, field := range []string{"trustOnAccept", "trustOnReject"} {
			if value, ok := bargain[field].(float64); !ok || value < -3 || value > 3 {
				return fmt.Errorf("%s: phase8 bargain %q %s must stay within -3..3", path, bargainID, field)
			}
		}
		for _, rawMemoryID := range asArray(bargain["revealMemoryIds"]) {
			memoryID, ok := rawMemoryID.(string)
			if !ok || strings.TrimSpace(memoryID) == "" {
				return fmt.Errorf("%s: phase8 bargain %q has invalid revealMemoryIds entry", path, bargainID)
			}
			if !memoryIDs[memoryID] {
				return fmt.Errorf("%s: phase8 bargain %q references unknown memory %q", path, bargainID, memoryID)
			}
		}
		effects, ok := bargain["effects"].([]any)
		if !ok || len(effects) == 0 {
			return fmt.Errorf("%s: phase8 bargain %q requires effects", path, bargainID)
		}
		for _, rawEffect := range effects {
			effect, ok := rawEffect.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase8 bargain %q effect must be object", path, bargainID)
			}
			effectType, ok := effect["type"].(string)
			if !ok || effectType != "damage_bonus" {
				return fmt.Errorf("%s: phase8 bargain %q has invalid effect type %q", path, bargainID, effect["type"])
			}
			if raw, ok := effect["skillId"].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase8 bargain %q effect requires skillId", path, bargainID)
			}
			if _, ok := effect["amount"].(float64); !ok {
				return fmt.Errorf("%s: phase8 bargain %q effect amount must be numeric", path, bargainID)
			}
		}
	}
	return nil
}

func validatePhase9ResonanceDocument(path string, value any) error {
	seenEffects := map[string]bool{}
	for _, resonance := range records(value) {
		for _, field := range []string{"id", "name", "description", "visibility", "discoveryMessage"} {
			if raw, ok := resonance[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase9 resonance missing string field %q", path, field)
			}
		}
		resonanceID := resonance["id"].(string)
		visibility := resonance["visibility"].(string)
		if !validString(visibility, []string{"visible", "hinted", "hidden", "locked_by_identify", "locked_by_attunement", "locked_by_level"}) {
			return fmt.Errorf("%s: phase9 resonance %q has invalid visibility %q", path, resonanceID, visibility)
		}
		if items, ok := resonance["requiredItemIds"].([]any); !ok || len(items) < 2 {
			return fmt.Errorf("%s: phase9 resonance %q requires at least two requiredItemIds", path, resonanceID)
		} else {
			for _, rawItemID := range items {
				if itemID, ok := rawItemID.(string); !ok || strings.TrimSpace(itemID) == "" {
					return fmt.Errorf("%s: phase9 resonance %q has invalid required item", path, resonanceID)
				}
			}
		}
		if slots, ok := resonance["requiredEquippedSlots"].([]any); !ok || len(slots) == 0 {
			return fmt.Errorf("%s: phase9 resonance %q requires requiredEquippedSlots", path, resonanceID)
		} else {
			for _, rawSlot := range slots {
				slot, ok := rawSlot.(string)
				if !ok || !validString(slot, []string{"weapon", "armor", "trinket"}) {
					return fmt.Errorf("%s: phase9 resonance %q has invalid required slot %q", path, resonanceID, rawSlot)
				}
			}
		}
		requirements, ok := resonance["discoveryRequirements"].([]any)
		if !ok || len(requirements) == 0 {
			return fmt.Errorf("%s: phase9 resonance %q requires discoveryRequirements", path, resonanceID)
		}
		for _, rawRequirement := range requirements {
			requirement, ok := rawRequirement.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase9 resonance %q discovery requirement must be object", path, resonanceID)
			}
			requirementType, ok := requirement["type"].(string)
			if !ok || !validString(requirementType, []string{"equip_together", "items_identified", "identify_item", "attunement_level", "skill_use", "enemy_defeated", "curse_trigger", "blood_price_revealed", "player_level", "location_entered"}) {
				return fmt.Errorf("%s: phase9 resonance %q has invalid discovery requirement %q", path, resonanceID, requirement["type"])
			}
			if count, ok := requirement["count"]; ok {
				if value, ok := count.(float64); !ok || value <= 0 {
					return fmt.Errorf("%s: phase9 resonance %q requirement count must be positive numeric", path, resonanceID)
				}
			}
		}
		effects, ok := resonance["effects"].([]any)
		if !ok {
			return fmt.Errorf("%s: phase9 resonance %q requires effects", path, resonanceID)
		}
		for _, rawEffect := range effects {
			effect, ok := rawEffect.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase9 resonance %q effect must be object", path, resonanceID)
			}
			if err := validatePhase9ResonanceEffect(path, resonanceID, effect, seenEffects); err != nil {
				return err
			}
		}
		for _, field := range []string{"cursed", "unstable"} {
			if _, ok := resonance[field].(bool); !ok {
				return fmt.Errorf("%s: phase9 resonance %q field %q must be boolean", path, resonanceID, field)
			}
		}
	}
	return nil
}

func validatePhase9ResonanceEffect(path string, resonanceID string, effect map[string]any, seenEffects map[string]bool) error {
	effectType, ok := effect["type"].(string)
	if !ok || !validString(effectType, []string{"stat_bonus", "stat_penalty", "skill_damage_bonus", "skill_heal_bonus", "skill_cost_modifier", "basic_attack_damage_bonus", "curse_health_cost", "message_only", "unlock_merge_recipe"}) {
		return fmt.Errorf("%s: phase9 resonance %q has invalid effect type %q", path, resonanceID, effect["type"])
	}
	key := fmt.Sprintf("%s:%s:%s:%s:%s", resonanceID, effectType, effect["skillId"], effect["stat"], effect["requiresAcceptedBargainId"])
	if seenEffects[key] {
		return fmt.Errorf("%s: duplicate phase9 resonance effect %q", path, key)
	}
	seenEffects[key] = true
	if effectType != "message_only" && effectType != "unlock_merge_recipe" {
		if _, ok := effect["amount"].(float64); !ok {
			return fmt.Errorf("%s: phase9 resonance %q effect amount must be numeric", path, resonanceID)
		}
	}
	switch effectType {
	case "stat_bonus", "stat_penalty":
		stat, ok := effect["stat"].(string)
		if !ok || !validString(stat, []string{"strength", "defense", "spellPower", "maxHealthBonus", "maxManaBonus"}) {
			return fmt.Errorf("%s: phase9 resonance %q stat effect requires valid stat", path, resonanceID)
		}
	case "skill_damage_bonus", "skill_heal_bonus":
		if raw, ok := effect["skillId"].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: phase9 resonance %q skill effect requires skillId", path, resonanceID)
		}
	case "curse_health_cost":
		if nonlethal, ok := effect["nonlethal"].(bool); !ok || !nonlethal {
			return fmt.Errorf("%s: phase9 resonance %q health cost must be nonlethal", path, resonanceID)
		}
	}
	return nil
}

func validatePhase9MergeDocument(path string, value any) error {
	for _, recipe := range records(value) {
		for _, field := range []string{"id", "name", "resultItemId", "risk", "visibility", "startMessage", "completeMessage"} {
			if raw, ok := recipe[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase9 merge missing string field %q", path, field)
			}
		}
		recipeID := recipe["id"].(string)
		if !validString(recipe["visibility"].(string), []string{"visible", "hinted", "hidden", "discovered"}) {
			return fmt.Errorf("%s: phase9 merge %q has invalid visibility %q", path, recipeID, recipe["visibility"])
		}
		if _, ok := recipe["consumesItems"].(bool); !ok {
			return fmt.Errorf("%s: phase9 merge %q consumesItems must be boolean", path, recipeID)
		}
		requiredItems, ok := recipe["requiredItemIds"].([]any)
		if !ok || len(requiredItems) < 2 {
			return fmt.Errorf("%s: phase9 merge %q requires at least two requiredItemIds", path, recipeID)
		}
		for _, rawItemID := range requiredItems {
			if itemID, ok := rawItemID.(string); !ok || strings.TrimSpace(itemID) == "" {
				return fmt.Errorf("%s: phase9 merge %q has invalid required item", path, recipeID)
			}
		}
		conditions, ok := recipe["requiredConditions"].([]any)
		if !ok || len(conditions) == 0 {
			return fmt.Errorf("%s: phase9 merge %q requires requiredConditions", path, recipeID)
		}
		for _, rawCondition := range conditions {
			condition, ok := rawCondition.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase9 merge %q condition must be object", path, recipeID)
			}
			conditionType, ok := condition["type"].(string)
			if !ok || !validString(conditionType, []string{"resonance_discovered", "attunement_level", "soul_name_revealed"}) {
				return fmt.Errorf("%s: phase9 merge %q has invalid condition type %q", path, recipeID, condition["type"])
			}
			if conditionType == "attunement_level" {
				if value, ok := condition["value"].(float64); !ok || value <= 0 {
					return fmt.Errorf("%s: phase9 merge %q attunement condition requires positive value", path, recipeID)
				}
				if raw, ok := condition["itemId"].(string); !ok || strings.TrimSpace(raw) == "" {
					return fmt.Errorf("%s: phase9 merge %q attunement condition requires itemId", path, recipeID)
				}
			}
		}
	}
	return nil
}

func validatePhase3EnemyDocument(path string, value any) error {
	for _, enemy := range records(value) {
		for _, field := range []string{"id", "name", "lootTable"} {
			if raw, ok := enemy[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 enemy missing string field %q", path, field)
			}
		}
		for _, field := range []string{"health", "maxHealth", "attack", "defense", "xpReward"} {
			value, ok := enemy[field].(float64)
			if !ok || value < 0 || (field == "health" || field == "maxHealth") && value == 0 {
				return fmt.Errorf("%s: phase3 enemy %q field %q must be valid numeric", path, enemy["id"], field)
			}
		}
	}
	return nil
}

func validatePhase3LootTableDocument(path string, value any) error {
	for _, table := range records(value) {
		if raw, ok := table["id"].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: phase3 loot table missing id", path)
		}
		entries, ok := table["entries"].([]any)
		if !ok {
			return fmt.Errorf("%s: phase3 loot table %q requires entries array", path, table["id"])
		}
		for _, rawEntry := range entries {
			entry, ok := rawEntry.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase3 loot table %q entry must be object", path, table["id"])
			}
			if raw, ok := entry["itemId"].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 loot table %q entry missing itemId", path, table["id"])
			}
			if quantity, ok := entry["quantity"].(float64); !ok || quantity <= 0 {
				return fmt.Errorf("%s: phase3 loot table %q entry quantity must be positive numeric", path, table["id"])
			}
			if chance, ok := entry["chance"].(float64); !ok || chance < 0 || chance > 1 {
				return fmt.Errorf("%s: phase3 loot table %q entry chance must be 0..1", path, table["id"])
			}
		}
		if gold, ok := table["gold"].(map[string]any); ok {
			minimum, minOK := gold["min"].(float64)
			maximum, maxOK := gold["max"].(float64)
			if !minOK || !maxOK || minimum < 0 || maximum < minimum {
				return fmt.Errorf("%s: phase3 loot table %q has invalid gold range", path, table["id"])
			}
		}
	}
	return nil
}

func validatePhase3ContainerDocument(path string, value any) error {
	for _, container := range records(value) {
		for _, field := range []string{"id", "name", "lootTableId"} {
			if raw, ok := container[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 container missing string field %q", path, field)
			}
		}
		if _, ok := container["opened"].(bool); !ok {
			return fmt.Errorf("%s: phase3 container %q opened must be boolean", path, container["id"])
		}
	}
	return nil
}

func validatePhase3ShrineDocument(path string, value any) error {
	for _, shrine := range records(value) {
		for _, field := range []string{"id", "name"} {
			if raw, ok := shrine[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 shrine missing string field %q", path, field)
			}
		}
		if _, ok := shrine["activated"].(bool); !ok {
			return fmt.Errorf("%s: phase3 shrine %q activated must be boolean", path, shrine["id"])
		}
		for _, field := range []string{"restoreHealth", "restoreMana"} {
			if value, ok := shrine[field].(float64); !ok || value < 0 {
				return fmt.Errorf("%s: phase3 shrine %q field %q must be non-negative numeric", path, shrine["id"], field)
			}
		}
	}
	return nil
}

func validatePhase3QuestChainDocument(path string, value any) error {
	chains := records(value)
	if len(chains) != 1 {
		return fmt.Errorf("%s: phase3 quest chain document must contain one object", path)
	}
	chain := chains[0]
	for _, field := range []string{"id", "title", "description"} {
		if raw, ok := chain[field].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: phase3 quest chain missing string field %q", path, field)
		}
	}
	stages, ok := chain["stages"].([]any)
	if !ok || len(stages) == 0 {
		return fmt.Errorf("%s: phase3 quest chain requires stages", path)
	}
	for _, rawStage := range stages {
		stage, ok := rawStage.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase3 quest stage must be object", path)
		}
		for _, field := range []string{"id", "title", "description"} {
			if raw, ok := stage[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 quest stage missing string field %q", path, field)
			}
		}
		objectives, ok := stage["objectives"].([]any)
		if !ok || len(objectives) == 0 {
			return fmt.Errorf("%s: phase3 quest stage %q requires objectives", path, stage["id"])
		}
		for _, rawObjective := range objectives {
			objective, ok := rawObjective.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase3 quest objective must be object", path)
			}
			for _, field := range []string{"id", "label"} {
				if raw, ok := objective[field].(string); !ok || strings.TrimSpace(raw) == "" {
					return fmt.Errorf("%s: phase3 quest objective missing string field %q", path, field)
				}
			}
			if _, ok := objective["completed"].(bool); !ok {
				return fmt.Errorf("%s: phase3 quest objective %q completed must be boolean", path, objective["id"])
			}
		}
	}
	return nil
}

func validatePhase3ZoneDocument(path string, value any) error {
	zones := records(value)
	if len(zones) != 1 {
		return fmt.Errorf("%s: phase3 zone document must contain one object", path)
	}
	zone := zones[0]
	for _, field := range []string{"id", "name", "description"} {
		if raw, ok := zone[field].(string); !ok || strings.TrimSpace(raw) == "" {
			return fmt.Errorf("%s: phase3 zone missing string field %q", path, field)
		}
	}
	width, widthOK := zone["width"].(float64)
	height, heightOK := zone["height"].(float64)
	if !widthOK || !heightOK || width <= 0 || height <= 0 {
		return fmt.Errorf("%s: phase3 zone requires positive width and height", path)
	}
	if err := validatePoint(path, zone["id"], "startPosition", zone["startPosition"]); err != nil {
		return err
	}
	tiles, ok := zone["tiles"].([]any)
	if !ok || len(tiles) == 0 {
		return fmt.Errorf("%s: phase3 zone %q requires tiles", path, zone["id"])
	}
	seenPositions := map[string]bool{}
	for _, rawTile := range tiles {
		tile, ok := rawTile.(map[string]any)
		if !ok {
			return fmt.Errorf("%s: phase3 zone tile must be object", path)
		}
		for _, field := range []string{"id", "kind", "name", "description", "state"} {
			if raw, ok := tile[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase3 zone tile missing string field %q", path, field)
			}
		}
		kind, _ := tile["kind"].(string)
		if !validString(kind, []string{"camp", "road", "woods", "chest", "shrine", "ruins", "gate", "elder_stone"}) {
			return fmt.Errorf("%s: phase3 zone tile %q has invalid kind %q", path, tile["id"], kind)
		}
		state, _ := tile["state"].(string)
		if !validString(state, []string{"hidden", "visible", "visited"}) {
			return fmt.Errorf("%s: phase3 zone tile %q has invalid state %q", path, tile["id"], state)
		}
		if err := validatePoint(path, tile["id"], "position", tile["position"]); err != nil {
			return err
		}
		position := tile["position"].([]any)
		x := position[0].(float64)
		y := position[1].(float64)
		if x < 0 || y < 0 || x >= width || y >= height {
			return fmt.Errorf("%s: phase3 zone tile %q position out of bounds", path, tile["id"])
		}
		positionKey := fmt.Sprintf("%d,%d", int(x), int(y))
		if seenPositions[positionKey] {
			return fmt.Errorf("%s: phase3 zone has duplicate tile position %s", path, positionKey)
		}
		seenPositions[positionKey] = true
	}
	return nil
}

func validatePhase2ItemDocument(path string, value any) error {
	for _, item := range records(value) {
		for _, field := range []string{"id", "name", "type", "description", "icon"} {
			if raw, ok := item[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase2 item missing string field %q", path, field)
			}
		}
		itemType, _ := item["type"].(string)
		if !validString(itemType, []string{"currency", "weapon", "consumable", "quest", "rune"}) {
			return fmt.Errorf("%s: phase2 item %q has invalid type %q", path, item["id"], itemType)
		}
		if quantity, ok := item["quantity"].(float64); !ok || quantity < 0 {
			return fmt.Errorf("%s: phase2 item %q quantity must be non-negative numeric", path, item["id"])
		}
		if _, ok := item["stackable"].(bool); !ok {
			return fmt.Errorf("%s: phase2 item %q stackable must be boolean", path, item["id"])
		}
	}
	return nil
}

func validatePhase2EnemyDocument(path string, value any) error {
	for _, enemy := range records(value) {
		for _, field := range []string{"id", "name"} {
			if raw, ok := enemy[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase2 enemy missing string field %q", path, field)
			}
		}
		for _, field := range []string{"health", "maxHealth"} {
			if value, ok := enemy[field].(float64); !ok || value <= 0 {
				return fmt.Errorf("%s: phase2 enemy %q field %q must be positive numeric", path, enemy["id"], field)
			}
		}
		if enemy["defeated"] != nil {
			if _, ok := enemy["defeated"].(bool); !ok {
				return fmt.Errorf("%s: phase2 enemy %q defeated must be boolean", path, enemy["id"])
			}
		}
	}
	return nil
}

func validatePhase2QuestDocument(path string, value any) error {
	for _, quest := range records(value) {
		for _, field := range []string{"id", "title", "description"} {
			if raw, ok := quest[field].(string); !ok || strings.TrimSpace(raw) == "" {
				return fmt.Errorf("%s: phase2 quest missing string field %q", path, field)
			}
		}
		objectives, ok := quest["objectives"].([]any)
		if !ok || len(objectives) == 0 {
			return fmt.Errorf("%s: phase2 quest %q requires objectives array", path, quest["id"])
		}
		seenObjectives := map[string]bool{}
		for _, rawObjective := range objectives {
			objective, ok := rawObjective.(map[string]any)
			if !ok {
				return fmt.Errorf("%s: phase2 quest %q objective must be an object", path, quest["id"])
			}
			for _, field := range []string{"id", "label"} {
				if raw, ok := objective[field].(string); !ok || strings.TrimSpace(raw) == "" {
					return fmt.Errorf("%s: phase2 quest %q objective missing string field %q", path, quest["id"], field)
				}
			}
			id := objective["id"].(string)
			if seenObjectives[id] {
				return fmt.Errorf("%s: phase2 quest %q has duplicate objective %q", path, quest["id"], id)
			}
			seenObjectives[id] = true
			if _, ok := objective["completed"].(bool); !ok {
				return fmt.Errorf("%s: phase2 quest %q objective %q completed must be boolean", path, quest["id"], id)
			}
		}
		if _, ok := quest["completed"].(bool); !ok {
			return fmt.Errorf("%s: phase2 quest %q completed must be boolean", path, quest["id"])
		}
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
	if strings.Contains(cleanPath, "/phase3/") {
		if err := validatePhase3References(path, value, seenIDs); err != nil {
			return err
		}
	}
	if strings.Contains(cleanPath, "/phase4/") {
		if err := validatePhase4References(path, value, seenIDs); err != nil {
			return err
		}
	}
	if strings.Contains(cleanPath, "/phase5/") {
		if err := validatePhase5References(path, value, seenIDs); err != nil {
			return err
		}
	}
	if strings.Contains(cleanPath, "/phase8/") {
		if err := validatePhase8References(path, value, seenIDs); err != nil {
			return err
		}
	}
	if strings.Contains(cleanPath, "/phase9/") {
		if err := validatePhase9References(path, value, seenIDs); err != nil {
			return err
		}
	}
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

func validatePhase4References(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/phase4/classes.json") {
		for _, class := range records(value) {
			for _, rawItemID := range asArray(class["startingItemIds"]) {
				itemID, _ := rawItemID.(string)
				if _, exists := seenIDs[itemID]; !exists {
					return fmt.Errorf("%s: phase4 class %q references unknown item %q", path, class["id"], itemID)
				}
			}
			for _, rawSkillID := range asArray(class["startingSkillIds"]) {
				skillID, _ := rawSkillID.(string)
				if _, exists := seenIDs[skillID]; !exists {
					return fmt.Errorf("%s: phase4 class %q references unknown skill %q", path, class["id"], skillID)
				}
			}
			treeID, _ := class["talentTreeId"].(string)
			if _, exists := seenIDs[treeID]; !exists {
				return fmt.Errorf("%s: phase4 class %q references unknown talent tree %q", path, class["id"], treeID)
			}
		}
	}
	if strings.Contains(cleanPath, "/phase4/talents.json") {
		for _, tree := range records(value) {
			nodeIDs := map[string]bool{}
			for _, rawNode := range asArray(tree["nodes"]) {
				if node, ok := rawNode.(map[string]any); ok {
					if id, ok := node["id"].(string); ok {
						nodeIDs[id] = true
					}
				}
			}
			for _, rawNode := range asArray(tree["nodes"]) {
				node, ok := rawNode.(map[string]any)
				if !ok {
					continue
				}
				for _, rawPrereq := range asArray(node["prerequisiteTalentIds"]) {
					prereq, _ := rawPrereq.(string)
					if !nodeIDs[prereq] {
						return fmt.Errorf("%s: phase4 talent %q references unknown prerequisite %q", path, node["id"], prereq)
					}
				}
				for _, rawEffect := range asArray(node["effects"]) {
					effect, ok := rawEffect.(map[string]any)
					if !ok {
						continue
					}
					if skillID, ok := effect["skillId"].(string); ok && skillID != "" {
						if _, exists := seenIDs[skillID]; !exists {
							return fmt.Errorf("%s: phase4 talent %q references unknown skill %q", path, node["id"], skillID)
						}
					}
				}
			}
		}
	}
	return nil
}

func validatePhase5References(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/phase5/items.json") {
		for _, item := range records(value) {
			if soulID, ok := item["soulId"].(string); ok && soulID != "" {
				if _, exists := seenIDs[soulID]; !exists {
					return fmt.Errorf("%s: phase5 item %q references unknown ring soul %q", path, item["id"], soulID)
				}
			}
			for _, rawProperty := range asArray(item["properties"]) {
				property, ok := rawProperty.(map[string]any)
				if !ok {
					continue
				}
				for _, rawEffect := range asArray(property["effects"]) {
					effect, ok := rawEffect.(map[string]any)
					if !ok {
						continue
					}
					if skillID, ok := effect["skillId"].(string); ok && skillID != "" {
						if _, exists := seenIDs[skillID]; !exists {
							return fmt.Errorf("%s: phase5 property %q references unknown skill %q", path, property["id"], skillID)
						}
					}
				}
			}
		}
	}
	return nil
}

func validatePhase8References(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if !strings.Contains(cleanPath, "/phase8/ring_souls.json") {
		return nil
	}
	for _, soul := range records(value) {
		for _, rawWhisper := range asArray(soul["whispers"]) {
			whisper, ok := rawWhisper.(map[string]any)
			if !ok {
				continue
			}
			for _, rawSkillID := range asArray(whisper["skillIds"]) {
				skillID, _ := rawSkillID.(string)
				if _, exists := seenIDs[skillID]; !exists {
					return fmt.Errorf("%s: phase8 whisper %q references unknown skill %q", path, whisper["id"], skillID)
				}
			}
		}
		for _, rawBargain := range asArray(soul["bargains"]) {
			bargain, ok := rawBargain.(map[string]any)
			if !ok {
				continue
			}
			for _, rawEffect := range asArray(bargain["effects"]) {
				effect, ok := rawEffect.(map[string]any)
				if !ok {
					continue
				}
				if skillID, ok := effect["skillId"].(string); ok && skillID != "" {
					if _, exists := seenIDs[skillID]; !exists {
						return fmt.Errorf("%s: phase8 bargain %q references unknown skill %q", path, bargain["id"], skillID)
					}
				}
			}
		}
	}
	return nil
}

func validatePhase9References(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/phase9/item_resonances.json") {
		for _, resonance := range records(value) {
			for _, rawItemID := range asArray(resonance["requiredItemIds"]) {
				itemID, ok := rawItemID.(string)
				if !ok || strings.TrimSpace(itemID) == "" {
					return fmt.Errorf("%s: phase9 resonance %q has invalid item reference", path, resonance["id"])
				}
				if _, exists := seenIDs[itemID]; !exists {
					return fmt.Errorf("%s: phase9 resonance %q references unknown item %q", path, resonance["id"], itemID)
				}
			}
			for _, rawRequirement := range asArray(resonance["discoveryRequirements"]) {
				requirement, ok := rawRequirement.(map[string]any)
				if !ok {
					continue
				}
				if skillID, ok := requirement["skillId"].(string); ok && skillID != "" {
					if _, exists := seenIDs[skillID]; !exists {
						return fmt.Errorf("%s: phase9 resonance %q references unknown skill %q", path, resonance["id"], skillID)
					}
				}
			}
			for _, rawEffect := range asArray(resonance["effects"]) {
				effect, ok := rawEffect.(map[string]any)
				if !ok {
					continue
				}
				if skillID, ok := effect["skillId"].(string); ok && skillID != "" {
					if _, exists := seenIDs[skillID]; !exists {
						return fmt.Errorf("%s: phase9 resonance %q references unknown skill %q", path, resonance["id"], skillID)
					}
				}
			}
		}
	}
	if strings.Contains(cleanPath, "/phase9/item_merges.json") {
		for _, recipe := range records(value) {
			for _, rawItemID := range asArray(recipe["requiredItemIds"]) {
				itemID, ok := rawItemID.(string)
				if !ok || strings.TrimSpace(itemID) == "" {
					return fmt.Errorf("%s: phase9 merge %q has invalid item reference", path, recipe["id"])
				}
				if _, exists := seenIDs[itemID]; !exists {
					return fmt.Errorf("%s: phase9 merge %q references unknown item %q", path, recipe["id"], itemID)
				}
			}
			resultItemID, _ := recipe["resultItemId"].(string)
			if _, exists := seenIDs[resultItemID]; !exists {
				return fmt.Errorf("%s: phase9 merge %q references unknown result item %q", path, recipe["id"], resultItemID)
			}
			for _, rawCondition := range asArray(recipe["requiredConditions"]) {
				condition, ok := rawCondition.(map[string]any)
				if !ok {
					continue
				}
				if resonanceID, ok := condition["resonanceId"].(string); ok && resonanceID != "" {
					if _, exists := seenIDs[resonanceID]; !exists {
						return fmt.Errorf("%s: phase9 merge %q references unknown resonance %q", path, recipe["id"], resonanceID)
					}
				}
				if itemID, ok := condition["itemId"].(string); ok && itemID != "" {
					if _, exists := seenIDs[itemID]; !exists {
						return fmt.Errorf("%s: phase9 merge %q references unknown condition item %q", path, recipe["id"], itemID)
					}
				}
				if soulID, ok := condition["soulId"].(string); ok && soulID != "" {
					if _, exists := seenIDs[soulID]; !exists {
						return fmt.Errorf("%s: phase9 merge %q references unknown soul %q", path, recipe["id"], soulID)
					}
				}
			}
		}
	}
	return nil
}

func validatePhase3References(path string, value any, seenIDs map[string]string) error {
	cleanPath := filepath.ToSlash(path)
	if strings.Contains(cleanPath, "/phase3/enemies.json") {
		for _, enemy := range records(value) {
			lootTableID, _ := enemy["lootTable"].(string)
			if _, exists := seenIDs[lootTableID]; !exists {
				return fmt.Errorf("%s: phase3 enemy %q references unknown loot table %q", path, enemy["id"], lootTableID)
			}
		}
	}
	if strings.Contains(cleanPath, "/phase3/loot_tables.json") {
		for _, table := range records(value) {
			for _, rawEntry := range asArray(table["entries"]) {
				entry, ok := rawEntry.(map[string]any)
				if !ok {
					continue
				}
				itemID, _ := entry["itemId"].(string)
				if _, exists := seenIDs[itemID]; !exists {
					return fmt.Errorf("%s: phase3 loot table %q references unknown item %q", path, table["id"], itemID)
				}
			}
		}
	}
	if strings.Contains(cleanPath, "/phase3/containers.json") {
		for _, container := range records(value) {
			lootTableID, _ := container["lootTableId"].(string)
			if _, exists := seenIDs[lootTableID]; !exists {
				return fmt.Errorf("%s: phase3 container %q references unknown loot table %q", path, container["id"], lootTableID)
			}
		}
	}
	if strings.Contains(cleanPath, "/phase3/shrines.json") {
		for _, shrine := range records(value) {
			if itemID, ok := shrine["grantItemId"].(string); ok && itemID != "" {
				if _, exists := seenIDs[itemID]; !exists {
					return fmt.Errorf("%s: phase3 shrine %q references unknown grant item %q", path, shrine["id"], itemID)
				}
			}
		}
	}
	if strings.Contains(cleanPath, "/phase3/zone_") {
		for _, zone := range records(value) {
			for _, rawTile := range asArray(zone["tiles"]) {
				tile, ok := rawTile.(map[string]any)
				if !ok {
					continue
				}
				for field, label := range map[string]string{
					"encounterId": "encounter",
					"containerId": "container",
					"shrineId":    "shrine",
				} {
					id, ok := tile[field].(string)
					if !ok || id == "" {
						continue
					}
					if _, exists := seenIDs[id]; !exists {
						return fmt.Errorf("%s: phase3 tile %q references unknown %s %q", path, tile["id"], label, id)
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
