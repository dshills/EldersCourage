# EldersCourage Phase 6 Acceptance

Date: 2026-05-01

## Implemented Scope

- Added centralized UI state for active panel, debug mode, selected tile, and UI animation events.
- Added Go helper coverage for UI panel state, header debug visibility, message capping/order, and tile markers.
- Reworked the Elder Road header from a pipe-separated debug line into zone, class, level, XP, gold, and optional debug details.
- Added a current-location details card with description, exits, and available actions.
- Increased map tile size and added clearer tile markers/states for current position, enemies, caches, shrines, objectives, opened, and spent states.
- Split the right panel into character summary, equipment, quest tracker, enemy card, and typed message log sections.
- Added health, mana, and XP progress bars.
- Reworked the bottom action dock into Move, Location, Combat, Skills, and Panels groups.
- Improved skill buttons with cost, cooldown, disabled reason, tooltip details, and class-flavored styling.
- Added a Quest and Log overlay panel.
- Added panel close controls, Escape handling, `Q` quest/log toggle, `T` talent toggle, `F3` debug toggle, and `1`/`2` skill shortcuts.

## Automated Verification

These commands passed:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
git diff --check
```

## Manual Checklist

- Launch Elder Road and choose each class.
- Confirm the header shows zone, class, level, XP, and gold without coordinates.
- Toggle `F3` and confirm debug location details appear only when enabled.
- Move with WASD/arrow keys and click adjacent map tiles.
- Confirm current tile, enemy, cache, shrine, and objective markers are visually distinct.
- Confirm location details update after moving, opening a container, activating a shrine, and clearing an encounter.
- Use basic attack and class skills from buttons and `1`/`2`.
- Confirm skill buttons show cost, cooldown, and unavailable reasons.
- Open and close inventory, talents, quest/log, and identify target mode.
- Confirm `Escape` closes panels or cancels identify mode.
- Confirm combat, loot, quest, discovery, and curse messages are visually distinct.
- Inspect layout at 1366px desktop width for overlap or clipping.

## Deferred Scope

- Full mobile layout.
- Large new art pass.
- Deep accessibility audit.
- Complex animation system.
- New gameplay systems, zones, classes, enemies, skills, or item mechanics.

## Notes

Godot headless checks verify import, scene load, and script compilation. Because the Phase 3 UI intentionally loads PNG source files at runtime to tolerate fresh clones without `.godot/imported` cache, Godot may print non-fatal image-load export warnings during headless checks.
