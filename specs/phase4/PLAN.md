# EldersCourage Phase 4 Implementation Plan

## Purpose

This plan converts `specs/phase4/SPEC.md` into an implementation sequence for the current repository.

The Phase 4 spec still references a browser React/Vite target. This repository is Godot-first: Phase 1, Phase 2, and Phase 3 are implemented in Godot, the launch scene is currently `game/scenes/phase3/ElderRoadOutskirts.tscn`, and Go tooling validates data and pure gameplay helpers. Phase 4 should extend the existing Godot Phase 3 loop rather than introducing a second frontend stack.

The target is build identity: class selection, class-specific starting state, active skills, mana costs, cooldowns, temporary modifiers, passive talents, talent points from leveling, and enough UI to make those choices clear during Elder Road Outskirts.

## Guiding Principles

- Extend Phase 3 systems rather than replacing the adventure loop.
- Keep class, skill, and talent definitions data-driven.
- Route gameplay changes through named actions in state scripts.
- Keep combat math deterministic and covered by Go helper tests.
- Implement a compact talent system, not a large branching tree.
- Preserve Phase 1, Phase 2, and Phase 3 direct scene loads.
- Avoid deferred systems such as save/load, class multiclassing, complex status engines, ring souls, curses, and hidden item powers.

## Target Structure

Extend the existing layout:

```text
game/
  data/
    phase4/
      classes.json
      skills.json
      talents.json
      starter_items.json
  scenes/
    phase4/
      ClassSelection.tscn
  scripts/
    phase4/
      phase4_state.gd
      class_selection.gd
      skill_bar.gd
      talent_panel.gd
```

Phase 4 may either:

1. Fold class/skill/talent behavior into an upgraded Phase 3 `ElderRoadOutskirts.tscn`, or
2. Add a Phase 4 wrapper launch scene that shows class selection and then instantiates/reuses the Elder Road scene.

Prefer option 1 if it keeps the implementation smaller and clearer. Prefer option 2 if class selection makes the Phase 3 scene too coupled.

Add Go helper packages/tests under:

```text
internal/phase4/
```

## Baseline Check

### Tasks

Run:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

### Exit Criteria

- Existing validation and tests pass.
- Phase 1, Phase 2, and Phase 3 scenes load.
- Any current Phase 3 issues are recorded before Phase 4 changes begin.

## Milestone 1: Phase 4 Data Contracts and Validation

### Goal

Add class, skill, talent, and starter-item data with validator support before runtime integration.

### Implementation Tasks

1. Add `game/data/phase4/classes.json` with:
   - Roadwarden
   - Ember Sage
   - Gravebound Scout
2. Add `game/data/phase4/skills.json` with:
   - Guarded Strike
   - Shield Bash
   - Ember Bolt
   - Kindle
   - Piercing Shot
   - Grave Touch
3. Add `game/data/phase4/talents.json` with the three four-node class trees:
   - Road Oaths
   - Ember Memory
   - Grave Tracks
4. Add or extend item data with required starter gear:
   - Ember Staff
   - Scout Knife
   - Traveler's Cloak
5. Extend Go validation for:
   - class IDs and required fields
   - class starting item references
   - class starting skill references
   - skill class references, costs, cooldowns, targets, resources, effects
   - talent tree class references
   - talent node ranks, required levels, prerequisites, and effects
   - starter equipment item fields and stats
6. Add validation tests for malformed Phase 4 data and bad references.

### Exit Criteria

- Phase 4 data validates through `validate-data`.
- Invalid class/skill/talent references are rejected.
- Existing Phase 3 data still validates.

## Milestone 2: Pure Helper Systems and Tests

### Goal

Implement deterministic helper logic for classes, skills, cooldowns, temporary modifiers, talents, and talent point progression.

### Implementation Tasks

1. Add `internal/phase4` helper types for:
   - character classes
   - active skills
   - skill effects
   - temporary modifiers
   - talents and talent trees
   - player skill/talent state
2. Add class initialization helpers:
   - initialize player from class definition
   - grant starting items
   - auto-equip starting weapon and armor
   - add known skills
3. Add skill helpers:
   - `CanUseSkill`
   - resource failure reason
   - skill effect amount
   - apply resource cost
   - apply skill effects
   - reduce cooldowns
4. Add modifier helpers:
   - active modifiers by target
   - modified player stats
   - modified enemy attack
   - advance/expire modifiers
5. Add talent helpers:
   - can spend point
   - spend point
   - get rank
   - collect effects
   - stat bonuses
   - skill damage/cost/cooldown modifiers
6. Add tests for:
   - all three class initializations
   - skill validation failures
   - damage, healing, and mana restoration
   - cooldown set/decrement
   - Guarded Strike and Shield Bash modifiers
   - talent requirements, prerequisites, max rank, and effects
   - level-up talent point gain
   - each class defeating Goblin Scout in a deterministic helper test

### Exit Criteria

- `go test ./...` covers the new rules.
- Helper tests do not require Godot UI.
- Phase 3 helper tests still pass.

## Milestone 3: Player State Expansion

### Goal

Expand Godot runtime state to support class, skill, talent, cooldown, selected skill, and temporary modifier state.

### Implementation Tasks

1. Add or extend a Godot state script for Phase 4:
   - `classId`
   - known skill IDs
   - cooldown map
   - selected skill ID
   - available talent points
   - spent talent points
   - talent ranks
   - temporary modifiers
2. Update level-up behavior:
   - level 2 grants 1 talent point
   - later levels grant 1 talent point each
   - class-specific level-up messages are supported
3. Add `select_class(class_id)` or equivalent initialization action.
4. Add `choose_new_class()` and `restart_same_class()` flows.
5. Ensure Phase 3 movement, inventory, combat, equipment, loot, quest, and completion state still work after expansion.

### Exit Criteria

- Runtime state resets deterministically from selected class.
- Talent points are displayed and updated.
- Phase 3 loop still works with class state present.

## Milestone 4: Class Selection Screen

### Goal

Require class choice before entering Elder Road Outskirts.

### Implementation Tasks

1. Add a class selection view/scene.
2. Render three class cards:
   - name
   - subtitle
   - description
   - portrait/icon
   - stat preview
   - starting items
   - starting skills
3. Add `Begin Journey`.
4. Initialize player state from selected class.
5. Add class-specific start messages.
6. Add restart choices:
   - restart same class
   - choose new class

### Exit Criteria

- Class selection appears before gameplay.
- Each class preview is readable.
- Choosing a class starts the Elder Road loop with correct state.
- Restart can return to class selection.

## Milestone 5: Starter Items and Auto-Equip

### Goal

Make class starting state materially different through gear and stats.

### Implementation Tasks

1. Add Ember Staff, Scout Knife, and Traveler's Cloak to runtime item definitions.
2. Ensure Roadwarden starts with:
   - Old Sword equipped
   - Roadwarden Vest equipped
   - Minor Health Potion in inventory
3. Ensure Ember Sage starts with:
   - Ember Staff equipped
   - Cracked Ember Charm equipped or in trinket slot
   - Minor Health Potion in inventory
4. Ensure Gravebound Scout starts with:
   - Scout Knife equipped
   - Traveler's Cloak equipped
   - Minor Health Potion in inventory
5. Display class, equipped items, effective stats, health, mana, and gold correctly.

### Exit Criteria

- Starter item references resolve.
- Starting weapon/armor are auto-equipped.
- Consumables are in inventory.
- Effective stats include class and equipment bonuses.

## Milestone 6: Active Skill Runtime

### Goal

Let each class use two active skills in combat with costs, cooldowns, messages, and deterministic effects.

### Implementation Tasks

1. Load skill definitions into runtime state.
2. Add `use_skill(skill_id)` action.
3. Validate:
   - skill is known
   - enemy target exists for enemy skills
   - enough mana/resource exists
   - cooldown is ready
4. Apply resource costs.
5. Apply effects:
   - damage
   - heal
   - restore mana
   - temporary buff
   - temporary debuff
6. Add class-appropriate combat messages.
7. Set cooldowns after use.
8. Decrement cooldowns after each turn.
9. Preserve basic attack fallback.

### Exit Criteria

- Each class has exactly two starting active skills.
- Skills affect enemy/player state.
- Mana costs and cooldowns are enforced.
- Skill messages appear in the log.
- Basic attack still works.

## Milestone 7: Temporary Modifiers

### Goal

Support the minimum modifier behavior needed by class skills.

### Implementation Tasks

1. Add temporary modifier records to runtime state.
2. Implement Guarded Strike:
   - damage enemy
   - add temporary +2 player defense for next retaliation
3. Implement Shield Bash:
   - damage enemy
   - reduce enemy attack by 2 for next retaliation
4. Apply modifiers during retaliation calculations.
5. Expire modifiers at predictable end-of-turn timing.
6. Ensure expired modifiers no longer affect stats.

### Exit Criteria

- Guarded Strike reduces incoming retaliation.
- Shield Bash reduces enemy attack for one retaliation.
- Modifiers expire correctly.
- Tests cover application and expiration.

## Milestone 8: Skill Bar and Mana UI

### Goal

Expose active skills clearly during combat.

### Implementation Tasks

1. Add a skill bar near the action controls.
2. For each known skill, show:
   - name or icon
   - mana/resource cost
   - cooldown remaining
   - disabled state when unavailable
3. Add selected/hover detail text:
   - description
   - effects
   - cost
   - cooldown
4. Update mana display after skill use and mana restore.
5. Add warning messages for invalid skill use.

### Exit Criteria

- Skill buttons are visible and usable.
- Disabled states match resource/cooldown/target rules.
- Mana UI updates immediately.

## Milestone 9: Passive Talent Runtime

### Goal

Let the player spend level-up talent points on class-specific passive talents.

### Implementation Tasks

1. Load talent tree for selected class.
2. Add `spend_talent_point(talent_id)` action.
3. Enforce:
   - available points
   - max rank
   - required level
   - prerequisites
4. Apply talent effects immediately:
   - stat bonuses
   - skill damage bonuses
   - resource cost reductions
   - cooldown reductions
5. Integrate talent stat bonuses into effective stats.
6. Integrate talent skill effects into skill calculations.

### Exit Criteria

- Level-up grants talent points.
- Spend validation works.
- Talent effects change stats or skill behavior.
- Talent state persists during the current session.

## Milestone 10: Talent Panel UI

### Goal

Make talent choices understandable and spendable.

### Implementation Tasks

1. Add a talent panel toggle.
2. Show:
   - class tree name
   - available points
   - talent nodes/cards
   - rank/max rank
   - required level
   - prerequisites
   - spend button
3. Display node state:
   - locked
   - available
   - ranked
   - maxed
4. Update stats/skill details immediately after spending.

### Exit Criteria

- Talent panel opens/closes.
- Player can spend a valid point.
- Invalid spends are blocked with feedback.
- UI reflects updated ranks and points.

## Milestone 11: Combat Integration and Balance Pass

### Goal

Ensure all three classes can complete Elder Road Outskirts and feel meaningfully different.

### Implementation Tasks

1. Play through or simulate the zone as:
   - Roadwarden
   - Ember Sage
   - Gravebound Scout
2. Confirm balance goals:
   - Roadwarden survives well and kills slower.
   - Ember Sage kills quickly but cares about mana/health.
   - Gravebound Scout is flexible without dominating.
3. Tune small values if needed:
   - starting mana
   - skill costs
   - Road Bandit health
   - enemy attack
   - shrine/potion restoration
4. Document any tuning in acceptance notes.

### Exit Criteria

- Each class can complete the zone with reasonable play.
- No class is soft-locked by mana or damage.
- Combat still carries risk.

## Milestone 12: Final Verification and Documentation

### Goal

Close Phase 4 with full verification, README updates, and an acceptance record.

### Implementation Tasks

1. Run full verification commands.
2. Add `specs/phase4/ACCEPTANCE.md`.
3. Update `README.md` with:
   - Phase 4 launch scene/flow
   - class selection controls
   - skill/talent controls
   - verification commands
4. Confirm Phase 1, Phase 2, and Phase 3 scenes still load directly.
5. Commit final documentation.

### Exit Criteria

- Working tree is clean.
- Phase 4 acceptance record exists.
- Automated checks pass.
- Manual class checklist is documented.

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

- Select each class.
- Confirm starting stats, skills, equipment, gold, and messages.
- Use both skills for each class.
- Confirm mana costs and cooldowns.
- Confirm Guarded Strike and Shield Bash modifiers affect retaliation.
- Reach level 2 and gain a talent point.
- Spend a level 2 talent.
- Confirm talent effects update stats or skill behavior.
- Complete Elder Road Outskirts with each class.
- Restart same class and choose a different class.

## Suggested Commit Plan

Use small commits:

1. `Add phase 4 implementation plan`
2. `Add phase 4 class skill and talent data`
3. `Add phase 4 validation`
4. `Add phase 4 helper tests`
5. `Expand runtime state for classes and skills`
6. `Add class selection flow`
7. `Add starter equipment initialization`
8. `Implement active skill runtime`
9. `Add temporary combat modifiers`
10. `Add skill bar and mana UI`
11. `Implement passive talent runtime`
12. `Add talent panel UI`
13. `Tune phase 4 class balance`
14. `Document phase 4 acceptance status`

## Deferred Scope

Do not implement these in Phase 4:

- React/Vite browser application.
- Full branching skill trees.
- Multi-classing.
- Respec economy.
- Procedural skills.
- Animation-heavy spell effects.
- Full status-effect engine.
- Deep item-skill synergy.
- Hidden/identified item powers.
- Ring souls and curses.
- Multiple zones.
- Save/load persistence.
- Networked play.

## Definition of Done

Phase 4 is complete when the player must choose Roadwarden, Ember Sage, or Gravebound Scout before play; starts with class-specific stats, gear, and two skills; can use mana-costed and cooldown-gated skills in Elder Road combat; gains talent points on level-up; spends points in a compact class-specific talent tree; and can complete Elder Road Outskirts with each class.

The result should make class choice change how combat feels without adding fake complexity or destabilizing the existing Phase 1 through Phase 3 slices.
