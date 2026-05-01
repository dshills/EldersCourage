# EldersCourage

EldersCourage is a playable dark fantasy RPG prototype. The project currently has eight implemented prototype slices:

- Phase 8 prototype polish and acceptance pass: README/setup coverage, static acceptance reporting, automated Go/data verification, and documented manual Godot verification gaps.
- Phase 7 data validation and content completion: required content counts, richer item/cursed/synergy data, reference/tag validation, and deterministic loot generation.
- Phase 6 presentation pass: structured header, larger readable map tiles, current-location details, sectioned character/equipment/quest/log panel, grouped action dock, improved skill buttons, quest/log overlay, keyboard shortcuts, and centralized UI state.
- Phase 5 item identity: item instances, unidentified and partially identified equipment, Identify Scroll target mode, hidden/locked/revealed properties, attunement progress, level-gated reveals, cursed properties, and discovery messages.
- Phase 4 build identity: class selection, class-specific starting gear/stats, active skills, mana costs, cooldowns, temporary combat modifiers, talent points, and compact passive talent trees.
- Phase 3 Elder Road Outskirts: small explorable map, movement, containers, shrine, equipment, multiple encounters, enemy retaliation, XP, level-up, consumables, quest chain, and zone completion.
- Phase 2 first-adventure loop: branded fantasy UI, chest interaction, loot pickup, inventory, enemy targeting, basic attack, quest tracker, and message log.
- Phase 1 Ashen Catacombs dungeon: real-time combat, loot, equipment, cursed soul-rings, attunement, item echoes, death echoes, elite enemies, boss encounter, and completion reward.

The Godot launch scene is currently `game/scenes/phase3/ElderRoadOutskirts.tscn`, now with class selection, Phase 5 item discovery, the Phase 6 UI presentation pass, and Phase 7 completed content data layered into the Elder Road loop.

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

To load earlier slices directly:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/phase2/FirstAdventureLoop.tscn
/Applications/Godot.app/Contents/MacOS/Godot --path game res://scenes/dungeons/AshenCatacombsRun.tscn
```

## Current Godot Loop Controls

- Choose Roadwarden, Ember Sage, or Gravebound Scout, then click Begin Journey.
- WASD or arrow keys: move one tile.
- Click an adjacent map tile to move there.
- `E`: interact with current tile.
- `Space`: attack active enemy.
- `I`: open or close inventory.
- `Y` or `T`: open or close talents.
- `Q`: open or close the quest/log panel.
- `F3`: toggle debug location details in the header.
- `Escape`: close the active panel or cancel identify target mode.
- `1` and `2`: use class skill slots.
- Open Container button: open a chest/cache on current tile.
- Activate Shrine button: activate a shrine on current tile.
- Skill buttons: use known class skills and show cost/cooldown/disabled reason.
- Talents button: open or close the class talent panel.
- Equip button: equip selected inventory item.
- Use button: use selected consumable, or enter identify target mode when an Identify Scroll is selected.
- During identify target mode, click a highlighted inventory item to identify it.
- Cancel Identify button: leave identify target mode.
- Restart button: reset after defeat or completion.

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
go run ./cmd/elders generate-loot --level 5 --rarity relic --seed 42 --data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

## Project Layout

- `game/`: Godot project, scenes, scripts, UI placeholders, and JSON content.
- `game/assets/`: approved atlas-derived UI, item, portrait, terrain, sprite, icon, tile, and VFX assets.
- `game/data/`: data-driven Phase 1 through Phase 7 content.
- `game/data/items/phase7_items.json`: additional weapons, armor, rings, hidden properties, curses, echoes, and synergy tags used to satisfy content completeness checks.
- `game/data/curses/`: reusable curse definitions hydrated into item data at runtime.
- `game/data/synergies/`: prototype synergy definitions validated by the Go tooling.
- `game/data/phase5/`: discovery item definitions, hidden properties, attunement requirements, level-gated properties, and curses.
- `game/data/phase4/`: class, skill, talent, and starter item definitions.
- `game/data/phase3/`: Elder Road zone, items, enemies, loot tables, containers, shrine, and quest chain.
- `game/data/phase2/`: first-adventure loop items, quest, and enemy definitions.
- `game/scenes/phase3/`: Phase 3 launch scene.
- `game/scenes/phase2/`: Phase 2 launch scene.
- `game/scripts/phase3/`: Phase 3 state/actions and Elder Road UI shell script, extended with Phase 4 class/skill/talent runtime, Phase 5 item discovery, and Phase 6 UI state/presentation.
- `game/scripts/phase2/`: Phase 2 state/actions and UI shell script.
- `cmd/elders/`: Go CLI entry point for validation, loot generation, and acceptance reporting.
- `internal/`: Go validation, loot generation, reporting, and deterministic phase state-helper tests.
- `specs/prototype/`: prototype specification, implementation plan, decisions, and acceptance status.
- `specs/phase1/`: Phase 1 spec, plan, and acceptance record.
- `specs/phase2/`: Phase 2 spec, plan, and acceptance record.
- `specs/phase3/`: Phase 3 spec, plan, and acceptance record.
- `specs/phase4/`: Phase 4 spec, plan, and acceptance record.
- `specs/phase5/`: Phase 5 spec, plan, and acceptance record.
- `specs/phase6/`: Phase 6 spec, plan, and acceptance record.

## Specs and Status

- Phase 1 plan: `specs/phase1/PLAN.md`
- Phase 1 acceptance: `specs/phase1/ACCEPTANCE.md`
- Phase 2 plan: `specs/phase2/PLAN.md`
- Phase 2 acceptance: `specs/phase2/ACCEPTANCE.md`
- Phase 3 plan: `specs/phase3/Plan.md`
- Phase 3 acceptance: `specs/phase3/ACCEPTANCE.md`
- Phase 4 plan: `specs/phase4/PLAN.md`
- Phase 4 acceptance: `specs/phase4/ACCEPTANCE.md`
- Phase 5 plan: `specs/phase5/PLAN.md`
- Phase 5 acceptance: `specs/phase5/ACCEPTANCE.md`
- Phase 6 plan: `specs/phase6/PLAN.md`
- Phase 6 acceptance: `specs/phase6/ACCEPTANCE.md`
- Prototype Phase 7 and Phase 8 status: `specs/prototype/ACCEPTANCE.md`

## Static Acceptance Coverage

The current static acceptance report checks JSON validity and content completeness outside Godot:

- 10+ weapons
- 8+ armor pieces
- 10+ rings
- 5+ curses
- 5+ item echoes
- 5+ synergies
- 1+ dungeon definition

Run it with:

```bash
go run ./cmd/elders acceptance-report ./game/data
```

## Current Limitations

Godot headless loading verifies import, scene load, and script compilation. Go validation verifies data shape, references, tags, prototype content counts, deterministic loot generation, and static acceptance reporting. Gameplay feel, layout polish, save/load behavior, and full interactive dungeon completion still require manual play in the editor or app window.
