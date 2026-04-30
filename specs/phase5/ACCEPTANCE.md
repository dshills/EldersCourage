# EldersCourage Phase 5 Acceptance

Date: 2026-04-30

## Implemented Scope

- Added item instances separate from item definitions for the Elder Road runtime.
- Added Phase 5 discovery item data for Identify Scroll, Ashen Ring, Roadwarden's Notched Blade, Whisperthread Cloak, and Elder Glass Charm.
- Added validator support for Phase 5 item properties, reveal requirements, item effects, attunement constraints, curses, and skill references.
- Added Go helper coverage for item instance creation, identification, attunement thresholds, level-gated reveals, curse triggers, revealed stats, and skill damage bonuses.
- Added Identify Scroll target mode in the Godot inventory.
- Added inventory display support for unknown, locked, revealed, cursed, and attuned item states.
- Added revealed item stat effects, skill damage modifiers, mana cost modifiers, curse health costs, attack/skill/victory attunement hooks, and level-gated reveal hooks.
- Added Phase 5 items to Elder Road loot and class-aware completion rewards.

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

- Select each class and begin Elder Road.
- Open the Roadside Cache and confirm Identify Scrolls, Elder Glass Charm, and Ashen Ring appear with discovery-aware names.
- Use an Identify Scroll and select a valid hidden item.
- Attempt to identify an invalid item and confirm the scroll is not consumed.
- Equip Ashen Ring and use a skill to reveal Blood Price.
- Confirm Blood Price applies health cost on later skill use.
- Gain attunement while Ashen Ring is equipped and confirm attunement progress appears in item details.
- Defeat Road Bandit and confirm Roadwarden's Notched Blade can drop.
- Equip Roadwarden's Notched Blade and confirm its equip-triggered curse reveal.
- Complete Elder Road with each class and confirm class-aware completion rewards.

## Deferred Scope

- Full procedural item generation.
- Vendor appraisal and curse removal economy.
- Save/load persistence for item discovery state.
- Ring soul dialogue and personality systems.
- Crafting, sockets, gems, item merging, and broad affix weighting.

## Notes

Godot headless checks verify script compilation and scene loading. Full item-discovery feel, target-mode clarity, attunement pacing, and curse readability still require manual play in the Godot app window.
