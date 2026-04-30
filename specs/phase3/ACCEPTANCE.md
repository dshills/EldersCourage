# Phase 3 Acceptance Record

Date: 2026-04-30

## Automated Verification

These checks passed for the Phase 3 implementation:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

## Implemented Scope

- Phase 3 continues the Godot-first implementation.
- `game/scenes/phase3/ElderRoadOutskirts.tscn` is the launch scene.
- Elder Road Outskirts is data-driven under `game/data/phase3/`.
- The loop includes movement, visited tiles, containers, shrine activation, multiple encounters, enemy retaliation, equipment, XP, level-up, consumable healing, quest chain stages, and zone completion rewards.
- Go validation covers Phase 3 data shapes and references.
- Go tests cover Phase 3 movement, visited tiles, equipment-derived stats, combat formulas, XP/leveling, quest completion, and consumable behavior.
- Phase 1 and Phase 2 scenes still load directly.

## Interactive Godot Checklist

- Move around Elder Road Outskirts with WASD or arrow keys.
- Try invalid movement and confirm a warning message.
- Open the Abandoned Chest and Roadside Cache once.
- Equip Old Sword, Roadwarden Vest, and Cracked Ember Charm.
- Activate Weathered Shrine once.
- Fight Goblin Scout, Starved Wolf, and Road Bandit.
- Confirm enemy retaliation damages the player.
- Use Minor Health Potion from inventory.
- Gain enough XP to reach level 2.
- Reach the Elder Stone.
- Confirm `The Elder Road` quest chain completes and final rewards are granted once.
- Confirm Restart resets the run after defeat or completion.

## Deferred Scope

Save/load, procedural maps, full loot affixes, skill trees, character classes, pathfinding, multiplayer, boss mechanics, complex AI, identification/attunement, ring souls, curses, and vendor economy remain out of scope.
