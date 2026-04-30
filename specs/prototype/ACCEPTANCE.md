# Prototype Acceptance Status

## Phase 0: Project Foundation

- Status: Implemented.
- Godot project scaffold exists at `game/project.godot`.
- Initial data directories exist under `game/data/`.
- Go validator command exists at `cmd/elders`.
- Decisions are documented in `specs/prototype/DECISIONS.md`.

## Phase 1: Combat Arena

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Player movement, camera, health, death, basic attack, and Blood Cleave are present.
- Bone Thrall pursuit, melee damage, health, and death are present.
- Damage feedback is present through floating numbers.

## Phase 2: Skills and Enemy Variety

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Will, skill cooldowns, Grave Step, and Bell of the Dead are present.
- Bleed, Burn, Chill, and Vulnerable status effects are implemented in combat scripts.
- Bone Thrall, Ash Witch, and Hollowed Brute have distinct movement and attack behavior.
- HUD shows health, Will, enemy count, and major skill cooldowns.

## Phase 3: Loot and Equipment

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Starter item JSON includes 10 items across weapons, armor, and rings.
- Enemies drop loot and Grave Marks; clearing the arena spawns a reward chest.
- Player inventory, equipment slots, item tooltip text, and equip-by-number controls are present.
- Equipped visible stats affect base damage, max health, max Will, and armor.
- Go validation checks item shape, rarity/type values, stat names, duplicate IDs, malformed JSON, and loot references.

## Phase 4: Rings and Attunement

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Required accursed rings exist with soul metadata, hidden stats, curses, echoes, attunement, and synergy tags.
- Equipped attunable items gain XP when enemies die and when the arena is cleared.
- Attunement levels reveal soul, hidden stat, curse, and echo information at thresholds.
- Identify Scrolls can drop from enemies, are awarded on arena clear, and reveal the first unknown equipped or inventory item property.
- Tooltips show attunement progress, revealed properties, and unrevealed `????` slots.

## Phase 5: Echoes and Death Consequences

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Item Echo definitions exist under `game/data/echoes/` and revealed ring echoes can trigger when enemies die.
- Echo effects include damage pulses, Will restoration, Chill, Vulnerable, and short-lived visible areas.
- Player death creates a Death Echo at the death location and marks the room haunted.
- Haunted enemies gain increased damage and movement speed until the Death Echo is reclaimed.
- Pressing `T` after death respawns the player; touching the Death Echo reclaims it and grants attunement XP.

## Phase 6: Ashen Catacombs Vertical Slice

- Status: Implemented; manual Godot verification is pending because Godot is not installed in this environment.
- Fixed room sequence includes entrance, three combat rooms, one elite room, one treasure room, and one boss room.
- Elite room uses Burning, Vampiric, and Echoing modifiers.
- The Bell-Ringer Below boss has Bell Slam, Call the Buried, and Echo Toll behavior.
- Boss defeat drops `ring_bellringers_oath`, spawns a reward chest, grants completion rewards, and opens an exit portal.
- JSON save/load persists room index, completion state, player inventory, equipment, attunement/reveal state, Grave Marks, scrolls, and Death Echo state.

## Current Verification Notes

- Run `godot --path game` to manually verify the combat arena.
- Run `go test ./...` to verify Go tooling.
- Run `go run ./cmd/elders validate-data ./game/data` to validate JSON content directories.
