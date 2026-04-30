# EldersCourage

EldersCourage is a playable prototype for a dark action RPG focused on real-time combat, loot, cursed soul-rings, attunement, item echoes, and death echoes.

The current implementation targets the Ashen Catacombs vertical slice described in `specs/prototype/SPEC.md`.

## Requirements

- Go 1.22 or newer for tooling.
- Godot 4.x for running the prototype.

## Run the Prototype

```bash
godot --path game
```

On macOS, if `godot` is not on `PATH`, use:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

Primary controls:

- WASD: move
- Left mouse: Grave Strike
- `Q`: Blood Cleave
- `E`: Grave Step
- `R`: Bell of the Dead
- `I`: inventory
- `1`-`4`: equip inventory entries
- `5`-`8`: unequip weapon, armor, ring 1, ring 2
- `C`: use first consumable in inventory
- `Z`: use Identify Scroll
- `N`: advance to next cleared room
- `F5`: save
- `F9`: load
- `T`: restart, or respawn after death if a Death Echo exists

## Tooling

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders generate-loot --level 5 --rarity relic --seed 42
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
```

## Project Layout

- `game/`: Godot project, scenes, scripts, UI placeholders, and JSON content.
- `game/data/`: data-driven items, loot, echoes, curses, synergies, and dungeon definitions.
- `cmd/elders/`: Go CLI entry point.
- `internal/`: Go validation, loot generation, and reporting packages.
- `specs/prototype/`: prototype specification, implementation plan, decisions, and acceptance status.

## Current Limitations

Godot headless loading verifies script compilation and project import. Gameplay feel and full run completion still require manual play in the editor or app window.
