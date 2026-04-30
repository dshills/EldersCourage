package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"

	"github.com/dshills/EldersCourage/internal/loot"
	"github.com/dshills/EldersCourage/internal/report"
	"github.com/dshills/EldersCourage/internal/validate"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return usage()
	}

	switch args[0] {
	case "validate-data":
		if len(args) != 2 {
			return fmt.Errorf("validate-data requires exactly one path\n\n%s", usageText())
		}
		result, err := validate.Data(args[1])
		if err != nil {
			return err
		}
		fmt.Printf("validated %d JSON file(s) in %s\n", result.FilesChecked, args[1])
		return nil
	case "generate-loot":
		item, err := runGenerateLoot(args[1:])
		if err != nil {
			return err
		}
		encoded, err := json.MarshalIndent(item, "", "  ")
		if err != nil {
			return err
		}
		fmt.Println(string(encoded))
		return nil
	case "acceptance-report":
		if len(args) != 2 {
			return fmt.Errorf("acceptance-report requires exactly one data path\n\n%s", usageText())
		}
		acceptance, err := report.Generate(args[1])
		if err != nil {
			return err
		}
		fmt.Println(acceptance.Text())
		return nil
	case "help", "-h", "--help":
		return usage()
	default:
		return fmt.Errorf("unknown command %q\n\n%s", args[0], usageText())
	}
}

func runGenerateLoot(args []string) (loot.Item, error) {
	options := loot.GenerateOptions{DataRoot: "./game/data"}
	for index := 0; index < len(args); index++ {
		switch args[index] {
		case "--level":
			index++
			if index >= len(args) {
				return loot.Item{}, fmt.Errorf("--level requires a value")
			}
			level, err := strconv.Atoi(args[index])
			if err != nil {
				return loot.Item{}, fmt.Errorf("--level must be numeric: %w", err)
			}
			options.Level = level
		case "--rarity":
			index++
			if index >= len(args) {
				return loot.Item{}, fmt.Errorf("--rarity requires a value")
			}
			options.Rarity = args[index]
		case "--seed":
			index++
			if index >= len(args) {
				return loot.Item{}, fmt.Errorf("--seed requires a value")
			}
			seed, err := strconv.ParseInt(args[index], 10, 64)
			if err != nil {
				return loot.Item{}, fmt.Errorf("--seed must be numeric: %w", err)
			}
			options.Seed = seed
		case "--data":
			index++
			if index >= len(args) {
				return loot.Item{}, fmt.Errorf("--data requires a value")
			}
			options.DataRoot = args[index]
		default:
			return loot.Item{}, fmt.Errorf("unknown generate-loot flag %q", args[index])
		}
	}
	if options.Level <= 0 {
		return loot.Item{}, fmt.Errorf("generate-loot requires --level")
	}
	if options.Rarity == "" {
		return loot.Item{}, fmt.Errorf("generate-loot requires --rarity")
	}
	return loot.Generate(options)
}

func usage() error {
	fmt.Print(usageText())
	return nil
}

func usageText() string {
	return `elders is the EldersCourage prototype tooling CLI.

Usage:
  elders validate-data ./game/data
  elders generate-loot --level 5 --rarity relic [--seed 42] [--data ./game/data]
  elders acceptance-report ./game/data
`
}
