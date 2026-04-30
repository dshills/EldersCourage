# Phase 4 Acceptance Record

Date: 2026-04-30

## Automated Verification

These checks passed for the Phase 4 implementation:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

## Implemented Scope

- Phase 4 continues the Godot-first implementation.
- The existing Elder Road Outskirts launch scene now starts with class selection.
- Roadwarden, Ember Sage, and Gravebound Scout definitions are data-driven under `game/data/phase4/`.
- Each class has starting stats, starting gear, two active skills, flavor messages, and a compact four-node talent tree.
- Active skills support mana costs, cooldowns, damage, healing, mana restoration, temporary player defense buffs, and temporary enemy attack debuffs.
- Level-up grants talent points.
- Talent spending enforces available points, level requirements, prerequisites, and max rank.
- Talent effects can modify stats, skill damage, skill cost, and cooldown.
- Go validation covers Phase 4 class, skill, talent, and starter-item data.
- Go tests cover class initialization, skill validation, effects, cooldowns, modifiers, talents, talent points, and deterministic class combat.

## Interactive Godot Checklist

- Launch the game and confirm class selection appears before map play.
- Select each class and confirm starting stats, gear, skills, gold, and class message.
- Use each class skill in combat and confirm mana/cooldown behavior.
- Confirm Basic Attack still works.
- Confirm Guarded Strike reduces retaliation through temporary defense.
- Confirm Shield Bash weakens the next enemy hit.
- Reach level 2 and confirm a talent point is granted.
- Open the talent panel with `Y` or Talents.
- Spend a valid level 2 talent and confirm points/rank/stat updates.
- Restart and choose a different class.
- Complete Elder Road Outskirts with each class.

## Deferred Scope

Full branching skill trees, multiclassing, respec economy, procedural skills, animation-heavy spell effects, full status-effect engine, item-skill synergies, hidden item powers, ring souls, curses, multiple zones, save/load, and networked play remain out of scope.
