# Phase 1 Acceptance Record

Date: 2026-04-30

## Automated Verification

These checks passed for the Phase 1 implementation:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

Latest acceptance report:

```text
Acceptance Report
=================
Data files checked: 12
Weapons: 15 / 10 PASS
Armor: 10 / 8 PASS
Rings: 14 / 10 PASS
Curses: 6 / 5 PASS
Item echoes: 7 / 5 PASS
Synergies: 5 / 5 PASS
Dungeons: 1 / 1 PASS

Runtime gameplay criteria require Godot manual verification.
```

## Implemented Scope

- Data-driven item, loot, cursed ring, curse, echo, enemy, elite modifier, and dungeon definitions.
- Inventory, equipment, stat modifiers, consumable use, and unequip controls.
- Ring attunement XP, threshold reveals, hidden stats, curses, whispers, and echo unlocks.
- Spectral Ember, Last Duel, and Bone Memory echo data, with runtime support for implemented combat triggers.
- Death Echo spawn, enemy empowerment, reclaim interaction, reclaim XP, and haunted modifier cleanup.
- Original placeholder player, enemy, loot, item icon, tile, UI theme, and VFX assets.
- Ashen Catacombs dungeon run with start, combat, elite, boss, completion reward, and replayable scene load.
- Go validation coverage for the Phase 1 data contracts.

## Interactive Godot Checklist

Use this checklist for editor playtesting:

- Start `game/scenes/dungeons/AshenCatacombsRun.tscn`.
- Clear several rooms and confirm visible loot drops.
- Pick up loot, open inventory with `I`, equip weapon, armor, and two rings.
- Confirm equipment changes damage, survivability, speed, critical chance, or echo power.
- Use consumables with `C` and unequip slots with `5` through `8`.
- Gain ring attunement from kills, elite kills, and Death Echo reclaim.
- Confirm hidden ring properties display as `???` before reveal and become visible at thresholds.
- Trigger Spectral Ember or Last Duel after the associated ring echo is unlocked.
- Die, confirm the Death Echo marker appears, reclaim it, and confirm nearby haunted enemy modifiers clear.
- Defeat The Bell-Ringer Below, collect the completion reward, and restart the scene from Play to confirm replay.

## Deferred Scope

No Phase 1 non-goals were intentionally added. Multiplayer, trading, town hubs, multiple classes, campaign content, final art, and complex crafting remain out of scope.
