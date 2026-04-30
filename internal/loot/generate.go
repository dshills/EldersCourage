package loot

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"math/rand"
	"os"
	"path/filepath"
)

// Item is the subset of item data needed by loot generation.
type Item struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Type   string `json:"type"`
	Rarity string `json:"rarity"`
}

// GenerateOptions controls a deterministic loot roll.
type GenerateOptions struct {
	DataRoot string
	Level    int
	Rarity   string
	Seed     int64
}

// Generate picks a deterministic item matching the requested rarity when possible.
func Generate(options GenerateOptions) (Item, error) {
	items, err := loadItems(filepath.Join(options.DataRoot, "items"))
	if err != nil {
		return Item{}, err
	}
	candidates := make([]Item, 0, len(items))
	for _, item := range items {
		if options.Rarity == "" || item.Rarity == options.Rarity {
			candidates = append(candidates, item)
		}
	}
	if len(candidates) == 0 {
		return Item{}, fmt.Errorf("no loot candidates for rarity %q", options.Rarity)
	}
	seed := options.Seed
	if seed == 0 {
		seed = stableSeed(options.Level, options.Rarity)
	}
	source := rand.New(rand.NewSource(seed))
	return candidates[source.Intn(len(candidates))], nil
}

func loadItems(itemsDir string) ([]Item, error) {
	matches, err := filepath.Glob(filepath.Join(itemsDir, "*.json"))
	if err != nil {
		return nil, err
	}
	items := []Item{}
	for _, match := range matches {
		payload, err := os.ReadFile(match)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", match, err)
		}
		var batch []Item
		if err := json.Unmarshal(payload, &batch); err != nil {
			return nil, fmt.Errorf("%s: %w", match, err)
		}
		items = append(items, batch...)
	}
	return items, nil
}

func stableSeed(level int, rarity string) int64 {
	hash := fnv.New64a()
	_, _ = hash.Write([]byte(fmt.Sprintf("%d:%s", level, rarity)))
	return int64(hash.Sum64())
}
