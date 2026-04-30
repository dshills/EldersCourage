package main

import (
	"fmt"
	"os"

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
	case "help", "-h", "--help":
		return usage()
	default:
		return fmt.Errorf("unknown command %q\n\n%s", args[0], usageText())
	}
}

func usage() error {
	fmt.Print(usageText())
	return nil
}

func usageText() string {
	return `elders is the EldersCourage prototype tooling CLI.

Usage:
  elders validate-data ./game/data
`
}
