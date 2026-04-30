# EldersCourage Phase 5 Implementation Plan

## Purpose

This plan converts `specs/phase5/SPEC.md` into an implementation sequence for the current repository.

The Phase 5 spec references a browser React/Vite target, but this repository is Godot-first. Phase 1 through Phase 4 are implemented in Godot, the launch scene is currently `game/scenes/phase3/ElderRoadOutskirts.tscn`, and Go tooling validates authored JSON plus deterministic helper rules. Phase 5 should extend the existing Elder Road runtime, item data, inventory UI, equipment calculations, and combat flow rather than introducing a second frontend stack.

The target is item identity: item instances, unknown and revealed item properties, identification scrolls, attunement, level-gated reveals, curses, discovery messages, and a small set of mysterious equipment that interacts with Phase 4 classes and skills.

## Guiding Principles

- Extend the Phase 3/Phase 4 adventure loop rather than replacing inventory or combat.
- Separate item definitions from owned item instances before adding discovery state.
- Keep discovery, attunement, curse, and item-effect rules centralized in state/helper systems.
- Preserve existing known/simple items and current equipment behavior.
- Keep discovery data authored in JSON and covered by Go validation.
- Keep combat math deterministic and covered by Go helper tests.
- Make unknown, locked, revealed, cursed, and attuned states clear in the existing inventory UI.
- Avoid deferred systems such as procedural item generation, vendors, crafting, socketing, ring souls, save/load, and permanent curse removal.

## Target Structure

Extend the existing layout:

```text
game/
  data/
    phase5/
      items.json
      loot_overrides.json
  scripts/
    phase3/
      phase3_state.gd
      elder_road_outskirts.gd
```

If the Phase 3 state script becomes too large, split support code into focused Phase 5 scripts while keeping the launch scene stable:

```text
game/
  scripts/
    phase5/
      item_discovery.gd
      attunement.gd
      item_effects.gd
      curses.gd
```

Add Go helper packages/tests under:

```text
internal/phase5/
```

Extend validation in:

```text
internal/validate/
```

The default launch scene should remain `game/scenes/phase3/ElderRoadOutskirts.tscn` unless a wrapper scene becomes necessary. Phase 1, Phase 2, and direct Phase 3 scene loads must continue to work.

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
- Current item, inventory, equipment, class, skill, and talent behavior is understood before migration.
- Any baseline failures are recorded before Phase 5 changes begin.

## Milestone 1: Item Instance Model and Migration

### Goal

Separate item definitions from owned item instances without changing visible gameplay.

### Implementation Tasks

1. Add an item instance model to Godot runtime state:
   - `instance_id`
   - `item_id`
   - `quantity`
   - `knowledge_state`
   - `identified_property_ids`
   - `revealed_property_ids`
   - optional `attunement`
2. Keep item definitions as authored item templates.
3. Migrate inventory to store instances rather than raw item IDs or item definition dictionaries.
4. Update equipment slots to reference item instance IDs.
5. Add selectors/helpers to resolve an instance with its definition.
6. Preserve stack behavior for consumables.
7. Preserve non-stack behavior for equipment.
8. Preserve current Phase 3 and Phase 4 starter item grants, loot pickup, equip, use, and display behavior.
9. Add `internal/phase5` helper types for item definitions, item instances, inventory stacks, and equipment references.
10. Add tests for:
    - creating item instances from definitions
    - unique instance IDs
    - knowledge state living on instances
    - stackable consumable quantity behavior
    - non-stackable equipment instances
    - equipment resolving through instance IDs

### Exit Criteria

- Existing known/simple items still work.
- Inventory renders item instances using definitions.
- Equipment stats still match pre-migration behavior.
- `go test ./...` passes.
- `validate-data` still passes.

## Milestone 2: Discovery Data Contracts and Validation

### Goal

Add data support for item knowledge states, properties, reveal requirements, effects, attunement, and curses.

### Implementation Tasks

1. Add `game/data/phase5/items.json` with definitions for:
   - Identify Scroll
   - Ashen Ring
   - Roadwarden's Notched Blade
   - Whisperthread Cloak
   - Elder Glass Charm
2. Add discovery fields to item definitions:
   - `properties`
   - `attunable`
   - `maxAttunementLevel`
   - default drop knowledge state
   - unidentified display name/description/icon where needed
3. Define supported knowledge states:
   - `known`
   - `unidentified`
   - `partially_identified`
   - `identified`
4. Define supported property visibility states:
   - `visible`
   - `hidden`
   - `locked_by_level`
   - `locked_by_attunement`
5. Define supported property kinds and effects:
   - stat modifiers
   - skill damage modifiers
   - mana cost modifiers
   - health-cost curses
   - lore text if simple to display
6. Extend Go validation for Phase 5 documents:
   - unique item and property IDs
   - equipment slot and type consistency
   - valid knowledge states
   - valid property visibility, kind, requirement, and effect types
   - valid stats and skill references
   - attunement requirements only on attunable items
   - curse properties must be marked consistently
7. Add validator tests for invalid references and malformed discovery properties.

### Exit Criteria

- Phase 5 item data validates through `validate-data`.
- Invalid property/effect/requirement data is rejected.
- Existing Phase 1 through Phase 4 data still validates.

## Milestone 3: Pure Discovery, Attunement, Curse, and Effect Helpers

### Goal

Implement deterministic Go helper logic before wiring Godot runtime behavior.

### Implementation Tasks

1. Add `internal/phase5` helpers for:
   - display name and description by knowledge state
   - visible, hidden, locked, and revealed property selection
   - identify eligibility
   - identification reveal behavior
   - attunement level calculation
   - attunement point gains
   - newly revealed attunement properties
   - level-gated property reveals
   - curse reveal and trigger behavior
   - revealed item effect aggregation
2. Add effect selectors for:
   - equipped base stats
   - revealed stat bonuses
   - revealed stat penalties
   - revealed skill damage bonuses
   - revealed mana cost modifiers
   - health-cost curse triggers
3. Add tests for:
   - valid and invalid identification
   - identify-revealed properties
   - attunement thresholds at 0, 2, 5, and 9 points
   - threshold reveals happening once
   - level-gated reveal and activation
   - hidden curse trigger and repeated revealed curse effect
   - unrevealed positive properties not applying
   - unequip removing item effects
   - Ashen Ring modifying Ember Bolt only after reveal

### Exit Criteria

- New rules are covered by unit tests.
- Helpers do not require Godot UI.
- Existing Phase 2, Phase 3, and Phase 4 helper tests still pass.

## Milestone 4: Runtime Discovery State

### Goal

Bring the Phase 5 item model into the Godot state layer.

### Implementation Tasks

1. Update `game/scripts/phase3/phase3_state.gd` or add Phase 5 support scripts for:
   - item instance creation
   - item instance lookup
   - knowledge state updates
   - property reveal tracking
   - attunement state tracking
   - equipped instance lookup
2. Add runtime helpers matching the tested Go behavior:
   - `can_identify_item`
   - `identify_item`
   - `get_attunement_level`
   - `add_attunement_points`
   - `process_level_gated_item_reveals`
   - `get_active_curses`
   - item effect aggregation
3. Update startup/class initialization to grant item instances.
4. Update loot pickup to create item instances with correct default knowledge state.
5. Update equip/use/select inventory actions to operate on item instance IDs.
6. Ensure current consumables and starter gear still work.

### Exit Criteria

- Runtime state can hold multiple copies of the same item definition with separate discovery state.
- Loot, inventory selection, equip, and consumable use still work.
- Scene loads headlessly.

## Milestone 5: Identify Scroll and Target Mode

### Goal

Let the player use Identify Scrolls to reveal item properties through a clear inventory flow.

### Implementation Tasks

1. Add Identify Scroll as a consumable item definition.
2. Add Identify Scroll to obtainable loot.
3. Add inventory interaction state:
   - `normal`
   - `identify_target`
   - source scroll instance ID
4. Make Use on Identify Scroll enter target mode.
5. Highlight or mark valid identify targets in the inventory list.
6. Dim or disable invalid targets during target mode.
7. Add Cancel behavior for target mode.
8. On valid target:
   - reveal identify-based properties
   - decrease scroll quantity by 1
   - update item knowledge state
   - exit target mode
   - add discovery messages
9. On invalid target:
   - do not consume the scroll
   - add warning message
   - keep or exit target mode according to the least confusing implemented UI behavior

### Exit Criteria

- Identify Scroll appears in inventory.
- Using the scroll requires choosing a target item.
- Valid identification reveals expected properties.
- Invalid targets do not consume scrolls.
- Discovery messages identify what was revealed without spoiling unrevealed properties.

## Milestone 6: Discovery Items and Loot Integration

### Goal

Make Phase 5 discovery items obtainable during normal Elder Road play.

### Implementation Tasks

1. Add or integrate loot definitions for:
   - Identify Scroll x2 in Roadside Cache or equivalent early container
   - Elder Glass Charm in an early container
   - Roadwarden's Notched Blade from Road Bandit or class-aware reward
   - Ashen Ring as Ember Sage reward or universal Elder Stone reward
   - Whisperthread Cloak as Gravebound Scout reward or obtainable zone loot
2. If class-aware completion reward is small and clear, implement it.
3. If class-aware completion reward risks destabilizing the current quest flow, use Ashen Ring as universal completion reward and place the other items in loot tables.
4. Ensure at least two discovery items are obtainable before completion.
5. Ensure at least one cursed item is obtainable.
6. Ensure at least one attunement reveal is reachable in normal play.
7. Update loot messages to use display names based on knowledge state:
   - unidentified ring/weapon/armor/trinket names
   - known names for known items
   - no hidden property spoilers

### Exit Criteria

- Identify Scrolls are obtainable.
- All four Phase 5 item definitions exist.
- At least two discovery items are obtainable during gameplay.
- Loot messages respect item knowledge state.
- Existing loot still works.

## Milestone 7: Inventory and Item Detail UI

### Goal

Upgrade inventory details to clearly communicate mystery, locked properties, reveals, attunement, and curses.

### Implementation Tasks

1. Update item list rows/cards to show:
   - display name based on knowledge state
   - mystery label or icon for unidentified items
   - quantity for stackables
   - equipped marker
2. Update selected item details to show:
   - display name
   - item type
   - equipment slot
   - knowledge state
   - base stats when visible
   - known properties
   - unknown property placeholders
   - locked property hints
   - attunement level and progress
   - revealed curse labels
   - available actions
3. Add stable placeholder visuals or reuse existing approved assets for:
   - identify scroll
   - ring
   - weapon
   - armor/cloak
   - charm/trinket
   - unidentified item state
4. Ensure curses are marked with text labels, not color alone.
5. Ensure the inventory remains usable on the current screen dimensions.

### Exit Criteria

- Unknown properties are displayed as placeholders.
- Locked properties show level or attunement requirements without revealing effects.
- Revealed curses are clearly labeled.
- Attunement progress is visible for attunable items.
- Equip, use, and inventory selection remain usable.

## Milestone 8: Revealed Item Effects and Effective Stats

### Goal

Apply revealed item properties to player stats and skill calculations.

### Implementation Tasks

1. Update effective stat calculation to include:
   - class stats
   - equipment base stats
   - talent stat bonuses
   - revealed item stat bonuses
   - revealed item stat penalties
2. Add revealed property support for:
   - defense bonus
   - strength bonus if used by an item
   - spell power bonus
   - max mana bonus
   - max health bonus if needed
3. Ensure hidden and locked positive properties do not apply before reveal.
4. Ensure revealed curses with stat penalties apply while equipped.
5. Clamp current health/mana if max values change downward.
6. Update UI stat display after:
   - equip
   - unequip
   - identify
   - attunement reveal
   - level-gated reveal
   - curse reveal

### Exit Criteria

- Revealed item properties affect stats.
- Unrevealed item properties do not affect stats.
- Revealed stat penalties affect stats.
- Stat display updates immediately after discovery/equipment changes.

## Milestone 9: Attunement Runtime

### Goal

Let equipped attunable items gain progress and reveal powers through play.

### Implementation Tasks

1. Add attunement point and level state per item instance.
2. Implement thresholds:
   - level 0 at 0 points
   - level 1 at 2 points
   - level 2 at 5 points
   - level 3 at 9 points
3. Add combat hooks:
   - all equipped attunable items gain 1 point on combat victory
   - equipped attunable weapon gains 1 extra point on basic attack
   - equipped attunable trinket gains 1 extra point on skill use
4. Reveal matching attunement-locked properties on threshold.
5. Add discovery messages for:
   - attunement level reached
   - property revealed
   - cursed property revealed, if applicable
6. Prevent duplicate reveal messages for the same threshold/property.

### Exit Criteria

- Equipped attunable items gain points.
- Attunement level/progress displays in inventory details.
- Thresholds reveal matching properties.
- Revealed attunement properties affect stats or combat.
- Progress is per item instance.

## Milestone 10: Level-Gated Reveals

### Goal

Reveal eligible item properties when player level requirements are met.

### Implementation Tasks

1. Add a level-up hook after existing Phase 4 talent point behavior.
2. Check inventory and equipped items for `player_level` requirements.
3. Reveal eligible properties when the player reaches the required level.
4. Add discovery messages for each reveal.
5. Make locked level-gated properties show requirement hints when appropriate.
6. Recalculate effective stats after level-gated reveals.

### Exit Criteria

- Level-gated properties do not apply before the required level.
- Leveling up can reveal item properties.
- Revealed level-gated properties activate immediately.
- Messages report newly awakened properties.

## Milestone 11: Cursed Properties

### Goal

Support hidden cursed item properties that reveal and apply through combat/equipment triggers.

### Implementation Tasks

1. Add cursed property runtime helpers:
   - active revealed curses
   - hidden triggerable curses
   - reveal curse by property ID
   - process curse effects on attack
   - process curse effects on skill use
   - process curse effects on equip
2. Implement Phase 5 curse effects:
   - stat penalty
   - health cost on attack or skill use
3. Add trigger behavior for:
   - Ashen Ring Blood Price on skill use
   - Roadwarden's Notched Blade Old Weight on equip
4. Make first trigger reveal the curse and apply the effect.
5. Make later triggers apply the revealed curse effect without duplicate reveal messages.
6. Ensure curse effects cannot reduce health below the existing defeat rules without clear messaging.

### Exit Criteria

- Hidden curses can exist on items.
- Hidden curses reveal when triggered.
- Revealed curses display clearly.
- Curse effects apply correctly and repeat when appropriate.
- Curse messages are distinct from normal combat and loot messages.

## Milestone 12: Combat Item Hooks

### Goal

Make revealed item properties interact with Phase 4 skills and combat.

### Implementation Tasks

1. Add item hooks to basic attack:
   - revealed weapon damage bonuses
   - attack-triggered curses
   - weapon attunement point gain
2. Add item hooks to skill use:
   - revealed skill damage bonuses
   - revealed mana cost modifiers
   - skill-triggered curses
   - trinket attunement point gain
3. Add item hooks to combat victory:
   - equipped attunable item progress
   - attunement reveals
   - normal XP and loot continuation
4. Ensure interactions work for:
   - Roadwarden with Roadwarden's Notched Blade and Guarded Strike
   - Ember Sage with Ashen Ring and Ember Bolt
   - Gravebound Scout with Whisperthread Cloak and Grave Touch
   - Elder Glass Charm with mana/spell power
5. Tune small values if needed so curses are survivable and bonuses are noticeable.

### Exit Criteria

- Item properties can modify basic attacks and skills.
- Hidden properties do not modify combat before reveal.
- Curses can trigger during attack or skill use.
- Attunement advances through normal combat.
- Combat messages include item-related events.

## Milestone 13: Balance and Playability Pass

### Goal

Ensure discovery appears naturally in a short Elder Road session and does not overpower classes.

### Implementation Tasks

1. Play through or simulate as:
   - Roadwarden
   - Ember Sage
   - Gravebound Scout
2. Confirm:
   - the player finds Identify Scrolls early enough to use them
   - the player encounters 2 to 3 discovery items
   - at least one identify decision matters
   - at least one attunement reveal is reachable without grinding
   - Blood Price is dangerous but survivable
   - item bonuses are small but noticeable
3. Tune:
   - scroll count
   - item drop placement
   - attunement thresholds only if the spec thresholds make the zone too short
   - curse health cost only if it creates unavoidable failure
   - item bonuses if one class dominates
4. Document tuning decisions in acceptance notes.

### Exit Criteria

- All three classes can complete Elder Road Outskirts.
- Discovery mechanics appear during normal play.
- No class is blocked by cursed item interactions.
- Item rewards support class identity without replacing class skills/talents.

## Milestone 14: Final Verification and Documentation

### Goal

Close Phase 5 with verification, documentation, and an acceptance record.

### Implementation Tasks

1. Run full verification commands.
2. Add `specs/phase5/ACCEPTANCE.md`.
3. Update `README.md` with:
   - Phase 5 item discovery summary
   - Identify Scroll inventory flow
   - attunement and curse behavior
   - any new controls
   - verification commands
4. Confirm Phase 1, Phase 2, and Phase 3 scenes still load directly.
5. Confirm Phase 4 class selection, skills, and talents still work with item discovery.
6. Commit final documentation.

### Exit Criteria

- Working tree is clean.
- Phase 5 acceptance record exists.
- Automated checks pass.
- Manual item discovery checklist is documented.

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

- Select each class and begin Elder Road.
- Find Identify Scrolls and at least two discovery items.
- Inspect unidentified, partially identified, identified, locked, attuned, and cursed item states.
- Use Identify Scroll on a valid item.
- Attempt Identify Scroll on an invalid item and confirm no scroll is consumed.
- Equip Ashen Ring and trigger Blood Price through skill use.
- Equip Roadwarden's Notched Blade and reveal its equip curse.
- Gain attunement through victory, basic attack, and skill use.
- Reveal an attunement-locked property.
- Reach a level-gated reveal if reachable in the current zone.
- Confirm revealed stat and combat effects update the UI and combat math.
- Complete Elder Road Outskirts with Roadwarden, Ember Sage, and Gravebound Scout.
- Confirm direct Phase 1, Phase 2, and Phase 3 scene loads still work.

## Suggested Commit Plan

Use small commits:

1. `Add phase 5 implementation plan`
2. `Split inventory into item definitions and instances`
3. `Add phase 5 discovery item data`
4. `Add phase 5 discovery validation`
5. `Add phase 5 item discovery helpers`
6. `Migrate runtime item state to instances`
7. `Add identify scroll target flow`
8. `Add discovery items to Elder Road loot`
9. `Update inventory discovery details`
10. `Apply revealed item stat effects`
11. `Add item attunement reveals`
12. `Add level-gated item reveals`
13. `Add cursed item triggers`
14. `Integrate item effects with combat hooks`
15. `Tune phase 5 item discovery balance`
16. `Document phase 5 acceptance status`

## Deferred Scope

Do not implement these in Phase 5:

- fully procedural item generation
- broad rarity economy
- vendor appraisal
- crafting
- item merging or synergy systems
- full ring souls and dialogue
- permanent curse removal economy
- save/load persistence
- complex affix weighting
- trading
- durability and repair
- sockets or gems
- large art production pass
- additional zones beyond what is needed for item discovery in Elder Road

## Risks and Mitigations

- Inventory migration can break existing equipment and consumables. Mitigate by committing the instance migration separately before adding discovery behavior.
- GDScript state can become too large. Mitigate by extracting Phase 5 helper scripts if discovery helpers crowd `phase3_state.gd`.
- Hidden item properties can silently affect combat if selectors are inconsistent. Mitigate by centralizing revealed-effect selectors and testing unrevealed properties explicitly.
- Attunement can duplicate reveal messages if processed in multiple hooks. Mitigate by storing revealed property IDs and revealed thresholds on item instances.
- Loot messages can spoil hidden item identity. Mitigate by routing every loot display through the same display-name helper.
- Curses can create surprising defeats. Mitigate with clear messages, survivable values, and manual class playthroughs.
