# EldersCourage Phase 2 Implementation Plan

## Purpose

This plan converts `specs/phase2/SPEC.md` into a practical implementation sequence for the current repository.

The spec recommends a browser-based React/Vite implementation unless the project has already chosen another target. This repository already contains a runnable Godot 4.x project with Phase 1 gameplay, assets, data, and Go validation tooling. Phase 2 should therefore be implemented in Godot rather than adding a second application stack.

The target is a small playable first-minute loop: the player sees a branded fantasy UI, interacts with a chest, receives loot, opens inventory, attacks a simple enemy, completes a short quest, and receives clear feedback.

## Guiding Principles

- Build on the existing Godot runtime instead of rewriting in React/Vite.
- Reuse the approved `game/assets/elderscourage.png` atlas and existing derived assets.
- Keep the loop deterministic and small.
- Keep gameplay state changes centralized and named.
- Prefer data files for items, enemies, quests, and scene setup when practical.
- Do not expand into Phase 1 advanced systems unless they already exist and can be reused cleanly.
- Keep each milestone runnable before moving to the next.

## Target Structure

Use the current Godot structure:

```text
game/
  assets/
    elderscourage.png
    icons/
    sprites/
    tiles/
    ui/
  data/
    phase2/
      items.json
      quests.json
      enemies.json
  scenes/
    phase2/
      FirstAdventureLoop.tscn
  scripts/
    phase2/
      first_adventure_loop.gd
      phase2_state.gd
      phase2_inventory.gd
      phase2_quest_tracker.gd
      phase2_message_log.gd
```

Keep Phase 2 isolated enough that it does not break the existing Phase 1 dungeon run.

## Baseline Check

### Tasks

1. Run existing automated checks:

   ```bash
   go test ./...
   go run ./cmd/elders validate-data ./game/data
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
   ```

2. Confirm the approved atlas-derived assets exist:
   - `game/assets/elderscourage.png`
   - `game/assets/ui/title_plaque.png`
   - `game/assets/sprites/loot/reward_chest.png`
   - existing item and loot icon crops

3. Record any existing failures before changing Phase 2 code.

### Exit Criteria

- Phase 1 checks still pass before Phase 2 work begins.
- Any new Phase 2 scene can be added without changing Phase 1 behavior.

## Milestone 1: Phase 2 Asset Integration

### Goal

Prepare the approved asset sheet crops needed by the first adventure loop.

### Implementation Tasks

1. Treat `game/assets/elderscourage.png` as the raw source atlas.
2. Reuse existing derived assets where possible:
   - title plaque
   - reward chest
   - item icons
   - loot sprites
3. Add any missing Phase 2-specific crops under existing folders:
   - `game/assets/ui/button_attack.png`
   - `game/assets/ui/button_inventory.png`
   - `game/assets/ui/button_quests.png`
   - `game/assets/ui/parchment_panel.png`
   - `game/assets/ui/inventory_panel.png`
   - `game/assets/ui/health_bar_frame.png`
   - `game/assets/ui/mana_bar_frame.png`
   - `game/assets/portraits/elder_hooded.png`
   - `game/assets/portraits/elder_warrior.png`
   - `game/assets/portraits/elf_scout.png`
4. Import new assets through Godot so `.import` metadata is committed.
5. Avoid replacing readable Phase 1 top-down sprites with portrait art.

### Exit Criteria

- Phase 2 UI and scene assets live in predictable folders.
- Missing visual assets have clear fallback drawing code.
- Godot imports all new textures without errors.

## Milestone 2: Core State, Data, and Named Actions

### Goal

Create deterministic Phase 2 state and named game actions that mirror the spec's TypeScript contracts in Godot data and GDScript.

### Implementation Tasks

1. Add Phase 2 data files:
   - `game/data/phase2/items.json`
   - `game/data/phase2/quests.json`
   - `game/data/phase2/enemies.json`
2. Define initial player state in `phase2_state.gd`:
   - name
   - health and max health
   - mana and max mana
   - gold
   - inventory
   - selected item
3. Define initial enemy state:
   - ID
   - name
   - health and max health
   - selected/targeted flag
   - defeated flag
4. Define the `First Courage` quest:
   - open the abandoned chest
   - recover the old sword
   - defeat the scout
5. Implement named action methods:
   - `open_chest()`
   - `select_enemy(enemy_id: String)`
   - `attack_selected_enemy()`
   - `toggle_inventory()`
   - `select_inventory_item(item_id: String)`
   - `add_message(text: String, type: String)`
   - `complete_quest_objective(objective_id: String)`
6. Ensure quest completion is computed from objective state.

### Exit Criteria

- Refreshing or replaying the scene resets to deterministic initial state.
- User interactions call named action methods.
- Invalid actions create warning messages instead of crashing.

## Milestone 3: Playable UI Shell

### Goal

Build a Godot scene that presents a branded fantasy game screen with a play area, status panels, action buttons, resource bars, inventory access, and quest display.

### Implementation Tasks

1. Add `game/scenes/phase2/FirstAdventureLoop.tscn`.
2. Add `game/scripts/phase2/first_adventure_loop.gd`.
3. Build the UI with Godot controls:
   - header/logo area
   - main play area
   - side status panel
   - bottom action bar
   - health and mana bars
   - quest button
   - attack button
   - inventory button
   - message log
4. Use approved atlas-derived UI assets where they improve the visual result.
5. Add hover, pressed, disabled, and keyboard focus states for controls.
6. Keep text readable over textured or painted backgrounds.
7. Make the scene responsive enough for common desktop and smaller window sizes.

### Exit Criteria

- The scene loads as a recognizable fantasy RPG screen.
- Buttons are keyboard focusable and visibly interactive.
- Inventory and quest controls produce visible UI changes.
- Attack button produces visible feedback even before combat is complete.

## Milestone 4: Inventory Panel

### Goal

Implement a basic 5x4 inventory grid with item selection and details.

### Implementation Tasks

1. Add an inventory panel component/script.
2. Render 20 inventory slots.
3. Show item icon, name, and quantity for occupied slots.
4. Let the player select an item.
5. Show selected item details:
   - name
   - type
   - description
   - quantity
6. Show gold as either a currency display or inventory item.
7. Ensure inventory can open and close from the button and keyboard shortcut.

### Exit Criteria

- Inventory opens and closes.
- Looted items appear in slots.
- Selecting an item updates the details panel.
- Empty slots remain visually stable.

## Milestone 5: Chest Interaction and Loot Pickup

### Goal

Add a one-shot chest interaction that gives the player loot and updates quest progress.

### Implementation Tasks

1. Render an abandoned chest in the play area.
2. Support chest states:
   - closed
   - opened
3. Clicking the chest calls `open_chest()`.
4. Opening the chest gives:
   - Old Sword
   - 10 gold
   - optional blue potion
5. Prevent repeated loot from the same chest.
6. Complete the `open-chest` objective.
7. Complete the `recover-sword` objective when the sword is added.
8. Add loot messages to the message log.

### Exit Criteria

- Chest visibly changes state after opening.
- Loot is granted once.
- Inventory reflects the new items.
- Quest objectives update immediately.

## Milestone 6: Enemy Targeting and Basic Attack

### Goal

Implement a deterministic attack action against a simple enemy or target dummy.

### Implementation Tasks

1. Render a simple enemy object in the play area.
2. Use a name compatible with the setting, such as `Ash Road Scout`, unless the spec's `Goblin Scout` is intentionally desired.
3. Support enemy states:
   - idle
   - targeted
   - damaged
   - defeated
4. Clicking the enemy calls `select_enemy(enemy_id)`.
5. Attack button calls `attack_selected_enemy()`.
6. Combat rules:
   - 10 damage without Old Sword
   - 15 damage with Old Sword
   - enemy health never drops below 0
   - defeated enemy cannot be attacked again
7. Add combat messages:
   - attack damage
   - target defeated
   - invalid attack warnings
8. Complete `defeat-scout` when enemy reaches 0 health.

### Exit Criteria

- Enemy can be selected.
- Attack changes enemy health.
- Old Sword changes attack damage.
- Defeat completes the quest objective.
- Invalid attacks are handled gracefully.

## Milestone 7: Quest Tracker and Message Log

### Goal

Make the player always understand current goals and feedback.

### Implementation Tasks

1. Render quest title and description.
2. Render objectives with distinct complete/incomplete states.
3. Do not rely on color alone for completion status.
4. Compute quest completion from objective state.
5. Emit a success message once when all objectives are complete.
6. Implement message types:
   - `info`
   - `success`
   - `warning`
   - `combat`
   - `loot`
7. Keep the latest 5 to 10 messages visible.

### Exit Criteria

- Quest objectives update immediately after actions.
- Quest completion is shown once.
- Chest, combat, completion, and invalid actions all create clear messages.

## Milestone 8: Validation and Tests

### Goal

Add focused coverage for Phase 2 data and pure state helpers.

### Implementation Tasks

1. Extend Go validation to include `game/data/phase2`.
2. Validate:
   - unique item IDs
   - required item fields
   - supported item types
   - quest objective IDs
   - enemy required fields
   - referenced items and objectives where applicable
3. Add GDScript-free pure helper tests in Go where practical if state rules are mirrored in data.
4. Add or update Go tests for:
   - adding item quantities
   - completing quest objectives
   - quest complete computation
   - damage clamping
5. Keep UI tests optional for this phase.

### Exit Criteria

- `go test ./...` passes.
- `go run ./cmd/elders validate-data ./game/data` passes.
- Validation catches malformed Phase 2 data.

## Milestone 9: Final Polish and Acceptance

### Goal

Make the Phase 2 loop feel like a complete first playable minute.

### Implementation Tasks

1. Tune layout spacing, readable text sizes, and control focus states.
2. Add simple visual feedback:
   - chest opened state
   - enemy targeted state
   - enemy damaged pulse
   - defeated state
   - quest completion feedback
3. Ensure no Phase 2 UI overlaps at common window sizes.
4. Add `specs/phase2/ACCEPTANCE.md` with verification results.
5. Decide whether `FirstAdventureLoop.tscn` should become the main scene or remain an alternate scene.

### Exit Criteria

- The player can complete the full loop:
  - launch scene
  - open chest
  - receive sword and gold
  - open inventory
  - select item
  - select enemy
  - attack and defeat enemy
  - complete quest
  - understand the result from UI feedback
- Phase 1 dungeon scene still loads.
- No non-goal systems were added.

## Verification Commands

Run these after each meaningful milestone:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

Manual verification should cover:

- Button hover, press, and focus states.
- Chest opens once and grants correct loot.
- Inventory toggle and item selection.
- Attack with and without Old Sword.
- Quest completion message appears once.
- Smaller window layout remains usable.

## Suggested Commit Plan

Use small commits:

1. `Add phase 2 plan`
2. `Add phase 2 asset crops`
3. `Add phase 2 data and validation`
4. `Build phase 2 Godot UI shell`
5. `Implement phase 2 inventory panel`
6. `Implement phase 2 chest loot loop`
7. `Implement phase 2 enemy attack loop`
8. `Add phase 2 quest and message flow`
9. `Polish phase 2 first adventure loop`
10. `Document phase 2 acceptance status`

## Deferred Scope

Do not implement these in Phase 2:

- React/Vite application unless explicitly requested.
- Full loot generation.
- Save/load persistence.
- Character classes.
- Skill trees.
- Multiple zones.
- Procedural maps.
- Deep combat math.
- NPC dialogue trees.
- Audio pipeline.
- New cursed ring, attunement, or echo systems beyond existing Phase 1 reuse.

## Definition of Done

Phase 2 is complete when the Godot project includes a stable `FirstAdventureLoop` scene where the player can see the fantasy UI, open the chest, receive the sword, inspect inventory, attack the scout, complete the quest, and understand every result through visible scene and message feedback.
