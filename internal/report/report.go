package report

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/dshills/EldersCourage/internal/validate"
)

// Acceptance summarizes the static checks that can be verified outside Godot.
type Acceptance struct {
	FilesChecked int
	Weapons      int
	Armor        int
	Rings        int
	Curses       int
	ItemEchoes   int
	Synergies    int
	Dungeons     int
}

// Generate validates data and returns static acceptance counts.
func Generate(dataRoot string) (Acceptance, error) {
	result, err := validate.Data(dataRoot)
	if err != nil {
		return Acceptance{}, err
	}

	acceptance := Acceptance{FilesChecked: result.FilesChecked}
	err = filepath.WalkDir(dataRoot, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() || filepath.Ext(path) != ".json" {
			return nil
		}
		payload, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		var decoded any
		if err := json.Unmarshal(payload, &decoded); err != nil {
			return err
		}
		countDocument(filepath.ToSlash(path), decoded, &acceptance)
		return nil
	})
	if err != nil {
		return Acceptance{}, err
	}

	return acceptance, nil
}

// Text formats the report for CLI output.
func (acceptance Acceptance) Text() string {
	lines := []string{
		"Acceptance Report",
		"=================",
		fmt.Sprintf("Data files checked: %d", acceptance.FilesChecked),
		fmt.Sprintf("Weapons: %d / 10 %s", acceptance.Weapons, passFail(acceptance.Weapons >= 10)),
		fmt.Sprintf("Armor: %d / 8 %s", acceptance.Armor, passFail(acceptance.Armor >= 8)),
		fmt.Sprintf("Rings: %d / 10 %s", acceptance.Rings, passFail(acceptance.Rings >= 10)),
		fmt.Sprintf("Curses: %d / 5 %s", acceptance.Curses, passFail(acceptance.Curses >= 5)),
		fmt.Sprintf("Item echoes: %d / 5 %s", acceptance.ItemEchoes, passFail(acceptance.ItemEchoes >= 5)),
		fmt.Sprintf("Synergies: %d / 5 %s", acceptance.Synergies, passFail(acceptance.Synergies >= 5)),
		fmt.Sprintf("Dungeons: %d / 1 %s", acceptance.Dungeons, passFail(acceptance.Dungeons >= 1)),
		"",
		"Runtime gameplay criteria require Godot manual verification.",
	}
	return strings.Join(lines, "\n")
}

func countDocument(path string, value any, acceptance *Acceptance) {
	switch {
	case strings.Contains(path, "/items/"):
		for _, record := range records(value) {
			switch record["type"] {
			case "weapon":
				acceptance.Weapons++
			case "armor":
				acceptance.Armor++
			case "ring":
				acceptance.Rings++
			}
		}
	case strings.Contains(path, "/curses/"):
		acceptance.Curses += len(records(value))
	case strings.Contains(path, "/echoes/"):
		for _, record := range records(value) {
			if _, ok := record["trigger"]; ok {
				acceptance.ItemEchoes++
			}
		}
	case strings.Contains(path, "/synergies/"):
		acceptance.Synergies += len(records(value))
	case strings.Contains(path, "/dungeons/"):
		acceptance.Dungeons += len(records(value))
	}
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

func passFail(pass bool) string {
	if pass {
		return "PASS"
	}
	return "FAIL"
}
