# EldersCourage Phase 10 Implementation Plan

## Purpose

This plan converts `specs/phase10/SPEC.md` into an implementation sequence for the current Godot project.

Phase 10 expands the playable prototype from one starter zone into a two-zone adventure. It adds Ashwood Glen, zone transitions, environmental hazards, stronger encounters, a zone quest chain, and a small set of zone-specific loot while preserving all previous systems: classes, combat, skills, talents, item discovery, attunement, curses, ring souls, resonance, and item merging.

The current launch scene remains:

```text
game/scenes/phase3/ElderRoadOutskirts.tscn
```

The current core runtime remains:

```text
game/scripts/phase3/phase3_state.gd
game/scripts/phase3/elder_road_outskirts.gd
game/scripts/ui/ui_view_models.gd
```

Phase 10 should extend those files conservatively and extract helper scripts only where they reduce risk.

## Guiding Principles

- Keep Elder Road Outskirts playable and recognizable.
- Add exactly one new zone: `ashwood_glen`.
- Make zone state explicit before adding new content.
- Keep player progression, inventory, equipment, class, talents, ring souls, and resonance state global to the run.
- Keep per-zone state local to each zone: position, visited tiles, cleared encounters, opened containers, activated shrines, completed hazards.
- Keep transition and hazard rules data-driven.
- Do not add save/load, a world map, vendors, procedural maps, new classes, broad crafting, or additional ring souls.
- Prefer clear, testable helpers over a broad architecture rewrite.
- Keep all health-loss hazard effects nonlethal for this phase.
- Reuse the existing overlay/action/message style instead of inventing a new UI framework.

## Current Implementation Notes

Important current facts:

```text
Current zone data:       game/data/phase3/zone_elder_road_outskirts.json
Current quest data:      game/data/phase3/quest_chain.json
Current enemies:         game/data/phase3/enemies.json
Current loot tables:     game/data/phase3/loot_tables.json
Current containers:      game/data/phase3/containers.json
Current shrines:         game/data/phase3/shrines.json
Phase 5 item data:       game/data/phase5/items.json
Phase 8 soul data:       game/data/phase8/ring_souls.json
Phase 9 resonance data:  game/data/phase9/item_resonances.json
```

`phase3_state.gd` currently has single-zone assumptions:

- `zone` is one loaded dictionary.
- `quest_chain` is one loaded dictionary.
- `player.position` stores map position directly.
- `completed_encounters`, container `opened`, and shrine `activated` are effectively global for the one zone.
- `current_tile()` and `tile_at()` read from `zone`.
- UI view models assume `game_state.zone` is the active zone.

Phase 10 should introduce multi-zone support without renaming the launch scene or forcing a new top-level game state object.

## Target Structure

Add or extend data files:

```text
game/data/phase10/zone_ashwood_glen.json
game/data/phase10/hazards.json
game/data/phase10/quest_chain_ashes_beyond_the_stone.json
```

Extend existing data files:

```text
game/data/phase3/zone_elder_road_outskirts.json
game/data/phase3/enemies.json
game/data/phase3/loot_tables.json
game/data/phase3/containers.json
game/data/phase3/shrines.json
game/data/phase5/items.json
```

Add helper scripts if the state file becomes too large:

```text
game/scripts/phase10/zone_state.gd
game/scripts/phase10/hazards.gd
```

Add Go helper tests:

```text
internal/phase10/
```

Extend validation:

```text
internal/validate/validate.go
internal/validate/validate_test.go
```

## Baseline Check

Run before implementation:

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

Manual baseline:

- Start each class.
- Move around Elder Road Outskirts.
- Open the abandoned chest and roadside cache.
- Activate Weathered Shrine.
- Defeat the three existing encounters.
- Complete The Elder Road.
- Confirm inventory, ring soul, resonance, and merge UI still open cleanly.

Exit criteria:

- Existing automated checks pass.
- Current single-zone behavior is understood before state ownership changes begin.

## Milestone 1: Multi-Zone State Model

### Goal

Make `phase3_state.gd` support multiple zones while preserving current behavior.

### Implementation Tasks

1. Add state fields:

   ```gdscript
   var zones_by_id := {}
   var quest_chains_by_id := {}
   var current_zone_id := "phase3_elder_road_outskirts"
   var unlocked_zone_ids := []
   var zone_states := {}
   ```

2. Keep `zone` as an active-zone compatibility alias for UI and existing helpers.
3. Keep `player.position` synchronized with the current zone state's `playerPosition` for this phase.
4. Add helpers:

   ```gdscript
   func get_current_zone() -> Dictionary
   func get_current_zone_state() -> Dictionary
   func get_player_zone_position() -> Dictionary
   func set_player_zone_position(zone_id: String, position: Dictionary) -> void
   func is_zone_unlocked(zone_id: String) -> bool
   func unlock_zone(zone_id: String) -> void
   ```

5. Create default zone state from each zone's `startPosition`.
6. Move or mirror per-zone collections:
   - visited tile ids
   - cleared encounter ids
   - opened container ids
   - activated shrine ids
   - completed hazard ids
7. Update `_mark_current_tile_visited`, `move_player`, `current_tile`, `tile_at`, `open_container`, `activate_shrine`, and encounter completion paths to use current zone state.
8. Keep legacy `completed_encounters` in sync until the refactor is stable, or replace it only after all call sites are updated.

### Exit Criteria

- Elder Road Outskirts still loads and plays.
- Current zone ID is tracked.
- Per-zone state is initialized.
- Returning to current-zone helpers works exactly as before for the starter zone.
- Go tests and Godot headless scene load pass.

## Milestone 2: Zone Transition System

### Goal

Add transition tiles and transition actions between Elder Road Outskirts and Ashwood Glen.

### Implementation Tasks

1. Extend `game/data/phase3/zone_elder_road_outskirts.json` tile `tile_elder_stone` with transition data:

   ```json
   {
     "targetZoneId": "ashwood_glen",
     "targetPosition": [0, 0],
     "label": "Enter Ashwood Glen",
     "blockedMessage": "The Elder Stone remains cold. The road behind you is not yet secure.",
     "requires": [
       { "type": "quest_stage_complete", "questId": "phase3_the_elder_road", "stageId": "phase3_break_the_ambush" }
     ]
   }
   ```

2. Add an Ashwood return tile that transitions back to Elder Road Outskirts.
3. Implement:

   ```gdscript
   func can_transition_from_current_tile() -> Dictionary
   func transition_from_current_tile() -> void
   func transition_to_zone(target_zone_id: String, target_position: Dictionary) -> void
   ```

4. Save current zone position before changing zones.
5. Load target zone data and restore its last known position unless the transition explicitly supplies a target position.
6. Add transition messages and a brief UI animation through existing animation hooks.
7. Extend `UIViewModels.get_action_availability_view_model` and location details to expose transition action state.
8. Add or repurpose an action dock button for `Enter`, `Travel`, or `Return`.

### Exit Criteria

- Transition action appears at the Elder Stone.
- Transition is blocked before the required quest stage is complete.
- Transition enters Ashwood Glen after requirements are met.
- Return transition restores Elder Road Outskirts.
- Zone state persists across travel.

## Milestone 3: Ashwood Glen Zone Data

### Goal

Add the second playable zone and render it through the existing map UI.

### Implementation Tasks

1. Create `game/data/phase10/zone_ashwood_glen.json`.
2. Use `id: "ashwood_glen"`.
3. Set dimensions to `5 x 5`.
4. Add required locations:
   - `ashwood_entry`
   - `cinder_cache`
   - `smoke_shrine`
   - `burning_thorn_001`
   - `cinder_pool_001`
   - `ember_wisp_001`
   - `ash_wolf_001`
   - `cinder_acolyte_001`
   - `broken_cairn`
   - `cinderheart`
   - `return_road`
5. Add supported tile kinds:
   - `entry`
   - `return`
   - `ash_path`
   - `burned_woods`
   - `cache`
   - `shrine`
   - `hazard`
   - `enemy`
   - `objective`
   - `cairn`
6. Update tile marker and style logic in `elder_road_outskirts.gd` and `ui_view_models.gd` so Ashwood tiles read visually distinct.
7. Add placeholder colors/markers in code first. Add asset files only if they already fit the repo's asset workflow.

### Exit Criteria

- Ashwood Glen loads as active zone.
- Map renders 5x5.
- Player can move around Ashwood.
- Tile markers are readable.
- Elder Road map still renders 5x4 correctly.

## Milestone 4: Hazards

### Goal

Add data-driven environmental hazards and trigger them from zone tiles.

### Implementation Tasks

1. Create `game/data/phase10/hazards.json`.
2. Define:
   - `burning_thorn_001`
   - `cinder_pool_001`
3. Add hazard ids to Ashwood Glen hazard tiles.
4. Implement helper script or state methods:

   ```gdscript
   func hazard_definition(hazard_id: String) -> Dictionary
   func trigger_tile_hazard(tile: Dictionary, trigger: String) -> void
   func hazard_completed(hazard_id: String) -> bool
   func mark_hazard_completed(hazard_id: String) -> void
   func calculate_hazard_damage(hazard: Dictionary) -> int
   ```

5. Trigger Burning Thorn on first tile entry.
6. Trigger Cinder Pool by interaction unless entry-trigger is simpler.
7. Keep health damage nonlethal.
8. Implement Burning Thorn mitigations:
   - defense 4+ reduces damage to 3
   - active `coal_remembers_flame` reduces damage by 2
   - equipped Ashwood Charm attunement hook can be added after item data exists
9. Add Cinder Pool class/resource behavior:
   - Ember Sage loses mana first if available
   - other classes lose health
10. Add ring soul whisper hooks when Varn is revealed and Ashen Ring or Staff of the Ashen Orator is equipped.

### Exit Criteria

- Hazards trigger from tiles.
- Repeatable false hazards trigger once per zone state.
- Damage and messages are correct.
- Mitigation works for Burning Thorn.
- Hazards cannot reduce health below 1.
- Missing advanced items do not break hazard handling.

## Milestone 5: Ashwood Enemies and Loot

### Goal

Add stronger Ashwood encounters and zone-specific loot.

### Implementation Tasks

1. Extend `game/data/phase3/enemies.json` or add a Phase 10 enemy file loaded into `enemies_by_id`.
2. Add:
   - `ember_wisp`
   - `ash_wolf`
   - `cinder_acolyte`
   - `cinderheart_guardian`
3. Add Ashwood encounter ids on zone tiles:
   - `ember_wisp_001`
   - `ash_wolf_001`
   - `cinder_acolyte_001`
   - `cinderheart_guardian_001`
4. Add loot tables:
   - `ember_wisp_loot`
   - `ash_wolf_loot`
   - `cinder_acolyte_loot`
   - `cinderheart_guardian_loot`
   - `cinder_cache_loot`
5. Add containers and shrine data:
   - `cinder_cache`
   - `smoke_shrine`
6. Add Varn encounter whispers for Cinder Acolyte and Cinderheart Guardian when applicable.
7. Add Staff of the Ashen Orator hook: Ember Wisp takes +2 damage from Ember Bolt when the staff is equipped.

### Exit Criteria

- New encounters start and complete through existing combat.
- XP and loot grant once.
- Smoke Shrine restores once.
- New enemies are stronger than starter enemies but beatable by level 2-3 characters.
- Cinderheart Guardian can complete its quest objective.

## Milestone 6: Items and Consumables

### Goal

Add Ashwood-specific rewards that use existing inventory, equipment, item discovery, and consumable behavior.

### Implementation Tasks

1. Add to `game/data/phase5/items.json` or a loaded Phase 10 item file:
   - `cinderheart_remnant`
   - `ashwood_charm`
   - `ash_salve`
2. Use current item field names:
   - `equipmentSlot`, not `equipment_slot`
   - `maxAttunementLevel`, not `max_attunement_level`
   - `stats`, not `base_stats`
3. Give Ashwood Charm:
   - trinket slot
   - `defense: 1`
   - attunement level 1 hazard mitigation property
   - attunement level 2 stat or max mana property
4. Add Ash Salve as stackable consumable with heal effect amount 20.
5. If next-hazard-damage status is simple, add it; otherwise keep Ash Salve to heal-only for this phase.
6. Ensure Cinderheart Remnant is granted only once from quest completion or guardian loot, not both.

### Exit Criteria

- New item ids validate.
- Ash Salve can be used.
- Ashwood Charm can be equipped and attuned.
- Cinderheart Remnant is awarded once.
- Item details remain readable.

## Milestone 7: Ashes Beyond the Stone Quest Chain

### Goal

Support the Ashwood quest chain and focus the quest tracker on the current zone.

### Implementation Tasks

1. Create `game/data/phase10/quest_chain_ashes_beyond_the_stone.json`.
2. Add quest id `ashes_beyond_the_stone`.
3. Add four stages:
   - `enter_the_glen`
   - `read_the_ash`
   - `clear_the_burned_path`
   - `quiet_the_cinderheart`
4. Add objective ids for:
   - entering Ashwood
   - visiting Ashwood Entry
   - investigating Broken Cairn
   - clearing Burning Thorn
   - discovering Cinder Pool
   - defeating each Ashwood enemy
   - reaching Cinderheart
   - defeating Cinderheart Guardian
   - claiming Cinderheart Remnant
5. Replace single `quest_chain` with active quest chain compatibility:

   ```gdscript
   func current_quest_chain() -> Dictionary
   func quest_chain_for_zone(zone_id: String) -> Dictionary
   func complete_objective(objective_id: String, quest_id: String = "") -> void
   ```

6. Start Ashes Beyond the Stone when entering Ashwood Glen.
7. Complete stages in order.
8. Grant completion reward once:
   - 75 XP
   - 30 gold
   - Cinderheart Remnant
   - future hook: Ash Gate message/unlock flag

### Exit Criteria

- The Elder Road quest still works.
- Ashwood quest starts on entry.
- Quest tracker focuses Ashwood while in Ashwood Glen.
- Objectives update from transitions, hazards, cairn interaction, encounters, and reward claim.
- Completion reward is granted once.

## Milestone 8: UI and Visual Polish

### Goal

Make the multi-zone experience clear and readable.

### Implementation Tasks

1. Update header view model to show current zone name.
2. Update debug text to include current zone id.
3. Update location details to show:
   - transition labels
   - hazard status
   - objective/cairn interactions
4. Add action dock support for:
   - transition
   - hazard interaction
   - cairn investigation
5. Update tile marker logic:
   - hazard marker
   - transition marker
   - lore/cairn marker
   - Cinderheart objective marker
6. Add Ashwood color styling in `_tile_style` or equivalent map presentation code.
7. Keep text sizing conservative so the 5x5 map and current UI panels remain readable.
8. Ensure message labels/colors include hazard and transition messages if current labels are not enough.

### Exit Criteria

- Current zone is obvious in the header.
- Transition actions are obvious and disabled/enabled correctly.
- Ashwood Glen visually differs from Elder Road Outskirts.
- Hazard and objective tiles are obvious.
- Quest tracker remains readable with multiple quest chains.

## Milestone 9: Validation and Tests

### Goal

Add automated coverage for the new data contracts and deterministic rules.

### Implementation Tasks

1. Extend `internal/validate` for:
   - Phase 10 zone files
   - transition references
   - hazard references
   - Ashwood quest chain references
   - enemy references
   - container, shrine, and loot table references
   - item references
2. Add validation tests for:
   - valid Ashwood zone data
   - unknown transition target zone
   - unknown hazard id
   - unknown enemy id
   - unknown quest objective or malformed quest stage
3. Add `internal/phase10` tests for:
   - zone unlock and transition requirement logic
   - per-zone position preservation
   - nonlethal hazard damage
   - Burning Thorn mitigation
   - quest objective/stage completion
4. Keep tests deterministic and independent of Godot runtime.

### Exit Criteria

- `go test ./...` passes.
- `validate-data` catches broken Phase 10 references.
- Existing Phase 9 tests still pass.

## Milestone 10: Acceptance Documentation

### Goal

Document what was implemented and how to manually verify it.

### Implementation Tasks

1. Create:

   ```text
   specs/phase10/ACCEPTANCE.md
   specs/phase10/ASHWOOD_GLEN_VERIFICATION.md
   ```

2. Include verification commands:

   ```bash
   env GOCACHE=/private/tmp/elders-go-cache go test ./...
   go run ./cmd/elders validate-data ./game/data
   go run ./cmd/elders acceptance-report ./game/data
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
   ```

3. Add manual checks for:
   - transition lock/unlock
   - Ashwood movement
   - returning to Elder Road
   - hazards
   - Cinder Cache
   - Smoke Shrine
   - each new enemy
   - quest stage progression
   - Cinderheart reward
   - Varn/resonance optional hooks

### Exit Criteria

- Acceptance doc accurately reflects implemented behavior.
- Manual verification checklist is specific enough to reproduce.

## Final Verification

Run:

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

Manual smoke pass:

- Start a new Ember Sage run.
- Complete enough Elder Road objectives to unlock Ashwood Glen.
- Enter Ashwood Glen.
- Trigger Burning Thorn and Cinder Pool.
- Open Cinder Cache.
- Activate Smoke Shrine.
- Defeat at least Ember Wisp and Cinder Acolyte.
- Return to Elder Road and verify position/state.
- Re-enter Ashwood and verify position/state.
- Complete Cinderheart Guardian and quest reward.

## Commit Strategy

If implementation is requested, commit between milestones:

1. `Add phase10 multi-zone state`
2. `Add zone transition flow`
3. `Add Ashwood Glen zone data`
4. `Implement Ashwood hazards`
5. `Add Ashwood encounters and loot`
6. `Add Ashwood items`
7. `Add Ashwood quest chain`
8. `Update multi-zone UI`
9. `Test phase10 zone rules`
10. `Document phase10 acceptance`
