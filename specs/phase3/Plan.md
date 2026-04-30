# EldersCourage Phase 3 Implementation Plan

## Purpose

This plan converts `specs/phase3/SPEC.md` into a concrete implementation sequence for the current repository.

The Phase 3 spec still references a browser React/Vite target. This repository is now Godot-first: Phase 1 and Phase 2 are implemented in Godot, the launch scene is `game/scenes/phase2/FirstAdventureLoop.tscn`, and the tooling/validation pipeline is built around Godot assets plus Go validators. Phase 3 should continue in Godot rather than introducing a second frontend stack.

The target is a repeatable mini-adventure loop in **Elder Road Outskirts**: movement across a small map, multiple encounters, containers, shrine interaction, equipment, XP, leveling, loot, consumables, a multi-stage quest chain, and a clear zone completion state.

## Guiding Principles

- Build on the existing Phase 2 scene and state model.
- Keep Phase 3 isolated enough that Phase 1 and Phase 2 scenes still load.
- Prefer data-driven content for zones, enemies, loot, items, containers, shrines, and quest stages.
- Route mutations through named actions or reducer-like handlers.
- Keep combat and progression deterministic and testable.
- Add visual polish only where it supports readability and playability.
- Avoid deferred systems such as save/load, procedural maps, skill trees, cursed rings, and full loot affixes.

## Target Structure

Use the existing Godot layout and extend it predictably:

```text
game/
  data/
    phase3/
      zone_elder_road_outskirts.json
      items.json
      enemies.json
      loot_tables.json
      containers.json
      shrines.json
      quest_chain.json
  scenes/
    phase3/
      ElderRoadOutskirts.tscn
  scripts/
    phase3/
      phase3_state.gd
      elder_road_outskirts.gd
      phase3_inventory.gd
      phase3_map.gd
      phase3_quest_tracker.gd
```

Add Go helper packages/tests under:

```text
internal/phase3/
```

## Baseline Check

### Tasks

1. Run:

   ```bash
   go test ./...
   go run ./cmd/elders validate-data ./game/data
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
   ```

2. Confirm Phase 2 behavior remains available:
   - chest
   - inventory
   - enemy targeting
   - attack
   - quest completion
3. Record any baseline failures before starting Phase 3.

### Exit Criteria

- Phase 1 and Phase 2 scenes still load.
- Existing Go tests and validation pass.
- Phase 3 work starts from a clean, committed baseline.

## Milestone 1: Phase 3 Data Contracts and Validation

### Goal

Add the structured data model for Elder Road Outskirts and extend validation before wiring runtime behavior.

### Implementation Tasks

1. Add `game/data/phase3/zone_elder_road_outskirts.json` with:
   - 5 columns by 4 rows
   - start position
   - at least 8 to 12 traversable positions
   - at least 3 interactable locations
   - at least 3 enemy encounter points
   - visited/default tile state
2. Add `game/data/phase3/items.json` with:
   - Old Sword
   - Roadwarden Vest
   - Cracked Ember Charm
   - Minor Health Potion
   - gold entry if needed for loot metadata
3. Add `game/data/phase3/enemies.json` with:
   - Goblin Scout
   - Starved Wolf
   - Road Bandit
4. Add `game/data/phase3/loot_tables.json`.
5. Add `game/data/phase3/containers.json`.
6. Add `game/data/phase3/shrines.json`.
7. Add `game/data/phase3/quest_chain.json` for `The Elder Road`.
8. Extend Go validation for Phase 3 documents:
   - unique IDs
   - zone dimensions and tile positions
   - encounter/container/shrine references
   - enemy fields and loot table references
   - item fields, equipment slots, stats, and consumable effects
   - quest stage/objective shape
9. Add validator tests for malformed Phase 3 data.

### Exit Criteria

- `go run ./cmd/elders validate-data ./game/data` validates Phase 3 files.
- Validator tests reject bad references and invalid shapes.
- Runtime implementation can load data without hard-coded JSX-style structures.

## Milestone 2: State Organization and Pure Helpers

### Goal

Create a Phase 3 state/action layer that can support movement, combat, equipment, loot, progression, and quests without scattering mutation logic through UI code.

### Implementation Tasks

1. Add `game/scripts/phase3/phase3_state.gd`.
2. Define state for:
   - player
   - zone
   - visited tiles
   - active encounter
   - containers
   - shrines
   - inventory
   - equipment
   - quest chain
   - messages
   - defeat/completion state
3. Add named action methods:
   - `move_player(direction)`
   - `open_container(container_id)`
   - `activate_shrine(shrine_id)`
   - `start_encounter(encounter_id)`
   - `attack_enemy()`
   - `equip_item(item_id)`
   - `use_item(item_id)`
   - `select_item(item_id)`
   - `toggle_inventory()`
   - `restart_game()`
4. Add pure Go helpers in `internal/phase3` for:
   - tile lookup
   - valid movement
   - visited tile updates
   - equipment stat aggregation
   - damage formulas
   - XP/leveling thresholds
   - quest chain completion
   - loot generation
   - consumable use

### Exit Criteria

- State resets deterministically.
- Major changes flow through named methods.
- Pure helper tests can cover core rules without Godot UI.

## Milestone 3: Elder Road Map Rendering

### Goal

Render Elder Road Outskirts as a small traversable map with a visible player position and visited tile states.

### Implementation Tasks

1. Add `game/scenes/phase3/ElderRoadOutskirts.tscn`.
2. Add `game/scripts/phase3/elder_road_outskirts.gd`.
3. Render the zone grid from data.
4. Use existing or new assets for:
   - camp
   - road
   - woods
   - chest/cache
   - shrine
   - ruins
   - gate
   - elder stone
5. Add a visible player marker/token.
6. Track and display tile state:
   - visible
   - visited
7. Add player position text.
8. Keep all Phase 3 map rendering data-driven from the zone file.

### Exit Criteria

- Player position is obvious.
- Map tiles are visually distinct.
- Visited tiles are visually distinct.
- Scene loads headlessly.

## Milestone 4: Movement

### Goal

Allow the player to move through valid adjacent nodes/tiles and receive clear feedback.

### Implementation Tasks

1. Add keyboard movement:
   - WASD
   - arrow keys
2. Add on-screen directional buttons.
3. Validate movement against:
   - map bounds
   - tile existence
   - blocked movement flag
4. Mark destination tiles visited.
5. Add movement messages:
   - successful travel
   - invalid movement
6. Allow click-to-move only for adjacent tiles if it stays simple.

### Exit Criteria

- Valid movement changes position.
- Invalid movement is blocked gracefully.
- Visited state updates immediately.
- Movement helpers are covered by tests.

## Milestone 5: Interactables, Containers, and Shrine

### Goal

Add map interactions beyond combat.

### Implementation Tasks

1. Add interact action for the current tile or adjacent valid interactable.
2. Implement containers:
   - Abandoned Chest
   - Roadside Cache
3. Containers open once, grant loot, update state, and add messages.
4. Implement Weathered Shrine:
   - activates once
   - restores 20 health
   - restores 10 mana
   - clamps to max values
   - optionally grants Cracked Ember Charm
5. Reflect opened/activated state in the map and message log.

### Exit Criteria

- Containers cannot be looted repeatedly.
- Shrine cannot be activated repeatedly.
- Restore effects respect max health/mana.
- Interactable state persists during the current session.

## Milestone 6: Equipment and Derived Stats

### Goal

Let the player equip gear and see stat changes immediately.

### Implementation Tasks

1. Extend Phase 3 item data with:
   - `equippable`
   - `equipmentSlot`
   - `stats`
2. Implement equipment slots:
   - weapon
   - armor
   - trinket
3. Add equip behavior:
   - equippable items show Equip action
   - occupied slots are replaced
   - replaced item returns to inventory
   - equipped item is visually marked or removed from regular display
4. Add derived stat helpers:
   - `get_equipment_stats`
   - `get_effective_stats`
   - `get_effective_max_health`
   - `get_effective_max_mana`
5. Update UI with equipment panel and stat display.
6. Ensure equipped weapon changes attack damage.

### Exit Criteria

- Player can equip weapon, armor, and trinket.
- Stats update immediately.
- Replacing gear works.
- Equipment helper tests cover slot fill, replacement, and derived stats.

## Milestone 7: Expanded Combat, XP, and Player Defeat

### Goal

Replace the single-target Phase 2 combat slice with multiple encounters and deterministic progression.

### Implementation Tasks

1. Attach encounter IDs to zone tiles.
2. Start encounters when entering or interacting with encounter tiles.
3. Render active enemy panel.
4. Implement player damage:

   ```text
   max(1, 8 + effective_strength - enemy_defense)
   ```

5. Implement enemy retaliation:

   ```text
   max(1, enemy_attack - effective_defense)
   ```

6. Mark enemies defeated and prevent repeated farming.
7. Grant XP once per defeated encounter.
8. Grant loot once per defeated encounter.
9. Implement player defeat:
   - health reaches 0
   - movement/attack disabled
   - restart button visible
   - restart resets state

### Exit Criteria

- Goblin Scout, Starved Wolf, and Road Bandit encounters work.
- Enemy stats differ.
- Equipment changes combat results.
- XP and loot are awarded once.
- Player defeat is handled cleanly.

## Milestone 8: Loot Tables and Consumables

### Goal

Make combat and containers feed inventory progression, and let consumables work from inventory.

### Implementation Tasks

1. Implement deterministic loot tables first.
2. Support gold loot separately from inventory items.
3. Emit loot messages for each award.
4. Add `generate_loot` helper with injectable random function only if random drops are added.
5. Add Minor Health Potion use behavior:
   - restores 25 health
   - clamps at effective max health
   - decrements quantity
   - removes item at zero quantity
   - blocks use at full health with a warning
6. Add Use button/action in inventory details.

### Exit Criteria

- Enemies and containers grant loot.
- Loot is not duplicated.
- Potion heals correctly.
- Potion quantity updates correctly.
- Consumable helper tests pass.

## Milestone 9: XP and Leveling

### Goal

Allow the player to reach level 2 through normal Phase 3 play.

### Implementation Tasks

1. Add player fields:
   - level
   - XP
   - XP to next level
   - base stats
2. Implement thresholds:
   - level 1 to 2 at 50 XP
   - level 2 to 3 at 100 XP
3. On level-up:
   - increase level by 1
   - increase max health by 10
   - increase max mana by 5
   - restore health and mana to max
   - add success message
4. Add XP/level display and XP bar/text.
5. Ensure level-up message appears once per level gained.

### Exit Criteria

- Defeated enemies grant XP.
- Player can reach level 2.
- Max health/mana increase on level-up.
- Health/mana restore on level-up.
- Leveling tests pass.

## Milestone 10: Elder Road Quest Chain and Zone Completion

### Goal

Replace the one-step Phase 2 quest with a multi-stage quest chain.

### Implementation Tasks

1. Implement `The Elder Road` quest chain.
2. Add stages:
   - Recover Supplies
   - Clear the Road
   - Break the Ambush
3. Wire objective completion to actions:
   - chest opened
   - Old Sword found
   - Goblin Scout defeated
   - Starved Wolf defeated
   - Road Bandit defeated
   - Elder Stone reached
4. Highlight active stage.
5. Keep completed stages visible but visually muted or collapsed.
6. On chain completion:
   - mark zone completed
   - show completion panel/message
   - award 25 bonus XP
   - award 20 gold
7. Prevent completion rewards from being granted more than once.

### Exit Criteria

- Quest stages complete from objective state.
- Quest chain completion is computed, not hard-coded in UI.
- Final rewards are granted once.
- Zone completion state is clear.

## Milestone 11: UI Integration and Visual Polish

### Goal

Make the larger loop understandable without overcrowding the screen.

### Implementation Tasks

1. Update the layout to show:
   - map panel
   - player position
   - movement controls
   - equipment panel
   - XP/level display
   - active enemy panel
   - inventory panel
   - quest chain tracker
   - zone completion message
   - capped message log
2. Add item details:
   - Equip button
   - Use button for consumables
   - equipped badge
   - stat display
3. Add stable visual assets/placeholders for:
   - player token
   - camp/road/woods/shrine/ruins/elder stone
   - closed/open chest
   - Goblin Scout
   - Starved Wolf
   - Road Bandit
   - Roadwarden Vest
   - Cracked Ember Charm
   - Minor Health Potion
4. Keep buttons keyboard focusable.
5. Ensure text remains readable.
6. Check common desktop and smaller window sizes for overlap.

### Exit Criteria

- UI clearly shows the new systems.
- Inventory and equipment actions are understandable.
- Important state changes produce messages.
- Message log remains capped.

## Milestone 12: Final Verification and Acceptance Record

### Goal

Close Phase 3 with automated checks, manual checklist, and documentation.

### Implementation Tasks

1. Run all verification commands.
2. Add `specs/phase3/ACCEPTANCE.md`.
3. Update `README.md` with:
   - Phase 3 launch scene if it becomes main
   - controls
   - verification commands
   - phase status
4. Decide whether `ElderRoadOutskirts.tscn` replaces Phase 2 as the launch scene.
5. Confirm Phase 1 and Phase 2 scenes still load directly.

### Exit Criteria

- Working tree is clean after final commit.
- Phase 3 acceptance record exists.
- Automated checks pass.
- Manual checklist is documented.

## Verification Commands

Run these after each milestone:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

Manual verification should cover:

- Move through Elder Road Outskirts.
- Attempt invalid movement.
- Open both containers once.
- Activate Weathered Shrine once.
- Fight all three encounters.
- Confirm enemy retaliation and player defeat/restart if applicable.
- Equip weapon, armor, and trinket.
- Use Minor Health Potion.
- Reach level 2.
- Complete all quest stages.
- Receive final XP/gold reward once.
- Confirm Phase 2 first loop and Phase 1 dungeon still load.

## Suggested Commit Plan

Use small commits:

1. `Add phase 3 implementation plan`
2. `Add phase 3 data and validation`
3. `Add phase 3 state helpers`
4. `Render Elder Road Outskirts map`
5. `Implement phase 3 movement`
6. `Add phase 3 containers and shrine`
7. `Add phase 3 equipment and stats`
8. `Expand phase 3 combat and XP`
9. `Add phase 3 loot and consumables`
10. `Implement Elder Road quest chain`
11. `Polish phase 3 UI and visuals`
12. `Document phase 3 acceptance status`

## Deferred Scope

Do not implement these in Phase 3:

- React/Vite browser application.
- Save/load persistence.
- Procedural maps.
- Full Diablo-style affix loot.
- Skill trees.
- Character classes.
- Real pathfinding.
- Multiplayer.
- Boss mechanics.
- Complex enemy AI.
- Item identification/attunement.
- Ring souls and curses.
- Vendor economy.

## Definition of Done

Phase 3 is complete when the player can explore Elder Road Outskirts, move across a small map, open caches, activate a shrine, fight Goblin Scout, Starved Wolf, and Road Bandit encounters, equip gear, use a health potion, gain XP, reach level 2, complete `The Elder Road` quest chain, receive final rewards once, and see clear feedback for every major action.

The result should be a small, repeatable RPG loop that is structurally ready for deeper ARPG systems without requiring a broad rewrite.
