# Prototype Acceptance Status

## Phase 0: Project Foundation

- Status: Implemented.
- Godot project scaffold exists at `game/project.godot`.
- Initial data directories exist under `game/data/`.
- Go validator command exists at `cmd/elders`.
- Decisions are documented in `specs/prototype/DECISIONS.md`.

## Phase 1: Combat Arena

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Player movement, camera, health, death, basic attack, and Blood Cleave are present.
- Bone Thrall pursuit, melee damage, health, and death are present.
- Damage feedback is present through floating numbers.

## Phase 2: Skills and Enemy Variety

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Will, skill cooldowns, Grave Step, and Bell of the Dead are present.
- Bleed, Burn, Chill, and Vulnerable status effects are implemented in combat scripts.
- Bone Thrall, Ash Witch, and Hollowed Brute have distinct movement and attack behavior.
- HUD shows health, Will, enemy count, and major skill cooldowns.

## Phase 3: Loot and Equipment

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Starter item JSON includes 10 items across weapons, armor, and rings.
- Enemies drop loot and Grave Marks; clearing the arena spawns a reward chest.
- Player inventory, equipment slots, item tooltip text, and equip-by-number controls are present.
- Equipped visible stats affect base damage, max health, max Will, and armor.
- Go validation checks item shape, rarity/type values, stat names, duplicate IDs, malformed JSON, and loot references.

## Phase 4: Rings and Attunement

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Required accursed rings exist with soul metadata, hidden stats, curses, echoes, attunement, and synergy tags.
- Equipped attunable items gain XP when enemies die and when the arena is cleared.
- Attunement levels reveal soul, hidden stat, curse, and echo information at thresholds.
- Identify Scrolls can drop from enemies, are awarded on arena clear, and reveal the first unknown equipped or inventory item property.
- Tooltips show attunement progress, revealed properties, and unrevealed `????` slots.

## Phase 5: Echoes and Death Consequences

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Item Echo definitions exist under `game/data/echoes/` and revealed ring echoes can trigger when enemies die.
- Echo effects include damage pulses, Will restoration, Chill, Vulnerable, and short-lived visible areas.
- Player death creates a Death Echo at the death location and marks the room haunted.
- Haunted enemies gain increased damage and movement speed until the Death Echo is reclaimed.
- Pressing `T` after death respawns the player; touching the Death Echo reclaims it and grants attunement XP.

## Phase 6: Ashen Catacombs Vertical Slice

- Status: Implemented; Godot headless load passes, manual gameplay verification is pending.
- Fixed room sequence includes entrance, three combat rooms, one elite room, one treasure room, and one boss room.
- Elite room uses Burning, Vampiric, and Echoing modifiers.
- The Bell-Ringer Below boss has Bell Slam, Call the Buried, and Echo Toll behavior.
- Boss defeat drops `ring_bellringers_oath`, spawns a reward chest, grants completion rewards, and opens an exit portal.
- JSON save/load persists room index, completion state, player inventory, equipment, attunement/reveal state, Grave Marks, scrolls, and Death Echo state.

## Phase 7: Data Validation and Content Completion

- Status: Implemented.
- Required content counts are met: 10+ weapons, 8+ armor pieces, 10+ rings, 5+ curses, 5 item echoes, and 5 synergies.
- Synergy and curse data exist under `game/data/synergies/` and `game/data/curses/`.
- Go validation checks item, loot, echo, curse, synergy, dungeon, reference, tag, and prototype count rules.
- `elders generate-loot --level 5 --rarity relic` returns deterministic JSON loot from content data.

## Phase 8: Prototype Polish and Acceptance Pass

- Status: Implemented for static verification; Godot headless load passes, manual gameplay verification is still required.
- `README.md` documents setup, controls, run commands, validation commands, and limitations.
- `elders acceptance-report ./game/data` provides a repeatable static acceptance report for content completeness.
- Go tests, data validation, loot generation, and acceptance reporting are the automated verification gate.

## Prototype Acceptance Criteria

| # | Criterion | Status |
|---:|---|---|
| 1 | Player can launch the game and start a dungeon. | Implemented; requires Godot manual verification. |
| 2 | Player can move, attack, use skills, and dodge. | Implemented; requires Godot manual verification. |
| 3 | Enemies can pursue, attack, and kill the player. | Implemented; requires Godot manual verification. |
| 4 | Player can kill enemies and receive loot. | Implemented; requires Godot manual verification. |
| 5 | Player can equip weapons, armor, and rings. | Implemented; requires Godot manual verification. |
| 6 | Equipped items change player stats or behavior. | Implemented; requires Godot manual verification. |
| 7 | Rings contain soul metadata and can have curses. | Verified by data validation. |
| 8 | Items can gain attunement XP. | Implemented; requires Godot manual verification. |
| 9 | Attunement can reveal hidden properties. | Implemented; requires Godot manual verification. |
| 10 | Identify Scrolls can reveal hidden item information. | Implemented; requires Godot manual verification. |
| 11 | At least one Item Echo works during combat. | Implemented; requires Godot manual verification. |
| 12 | Player death creates a Death Echo. | Implemented; requires Godot manual verification. |
| 13 | Death Echoes affect the room until reclaimed. | Implemented; requires Godot manual verification. |
| 14 | Player can fight and defeat the boss. | Implemented; requires Godot manual verification. |
| 15 | Dungeon can be completed. | Implemented; requires Godot manual verification. |
| 16 | Save/load preserves meaningful state. | Implemented; requires Godot manual verification. |
| 17 | Content is loaded from data files rather than fully hardcoded. | Verified by data validation and runtime loader paths. |
| 18 | Go validator can check content data. | Verified by `go run ./cmd/elders validate-data ./game/data`. |

## Current Verification Notes

- Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit` to verify the project loads.
- Run `godot --path game` or open `game/project.godot` in the Godot app to manually verify gameplay.
- Run `go test ./...` to verify Go tooling.
- Run `go run ./cmd/elders validate-data ./game/data` to validate JSON content directories.
- Run `go run ./cmd/elders generate-loot --level 5 --rarity relic --seed 42` to test deterministic loot generation.
- Run `go run ./cmd/elders acceptance-report ./game/data` to produce the static acceptance report.
