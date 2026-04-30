# EldersCourage

EldersCourage is a playable dark fantasy RPG prototype. The project currently has two implemented slices:

- Phase 2 first-adventure loop: branded fantasy UI, chest interaction, loot pickup, inventory, enemy targeting, basic attack, quest tracker, and message log.
- Phase 1 Ashen Catacombs dungeon: real-time combat, loot, equipment, cursed soul-rings, attunement, item echoes, death echoes, elite enemies, boss encounter, and completion reward.

The Godot launch scene is currently `game/scenes/phase2/FirstAdventureLoop.tscn`.

## Requirements

- Go 1.22 or newer for tooling.
- Godot 4.x for running the prototype.

## Run

```bash
godot --path game
```

On macOS, if `godot` is not on `PATH`, use:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

To load the Phase 1 dungeon directly:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/dungeons/AshenCatacombsRun.tscn
```

## Phase 2 Controls

- Click the abandoned chest to open it once.
- Click the Ash Road Scout to target it.
- Click the Attack button to damage the selected scout.
- Click the Inventory button to open or close inventory.
- Select inventory items to view details.
- Click the Quest button to focus the quest tracker.

## Phase 1 Dungeon Controls

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

Use the Makefile for common checks:

```bash
make test
make validate
make acceptance
make godot-check
make check
```

Equivalent direct commands:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders generate-loot --level 5 --rarity relic --seed 42
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

## Project Layout

- `game/`: Godot project, scenes, scripts, UI placeholders, and JSON content.
- `game/assets/`: approved atlas-derived UI, item, portrait, terrain, sprite, icon, tile, and VFX assets.
- `game/data/`: data-driven Phase 1 and Phase 2 content.
- `game/data/phase2/`: first-adventure loop items, quest, and enemy definitions.
- `game/scenes/phase2/`: Phase 2 launch scene.
- `game/scripts/phase2/`: Phase 2 state/actions and UI shell script.
- `cmd/elders/`: Go CLI entry point.
- `internal/`: Go validation, loot generation, reporting, and Phase 2 state-helper tests.
- `specs/prototype/`: prototype specification, implementation plan, decisions, and acceptance status.
- `specs/phase1/`: Phase 1 spec, plan, and acceptance record.
- `specs/phase2/`: Phase 2 spec, plan, and acceptance record.

## Specs and Status

- Phase 1 plan: `specs/phase1/PLAN.md`
- Phase 1 acceptance: `specs/phase1/ACCEPTANCE.md`
- Phase 2 plan: `specs/phase2/PLAN.md`
- Phase 2 acceptance: `specs/phase2/ACCEPTANCE.md`

## Current Limitations

Godot headless loading verifies import, scene load, and script compilation. Gameplay feel, layout polish, and full interactive completion still require manual play in the editor or app window.
