# EldersCourage Phase 9 Implementation Plan

## Purpose

This plan converts `specs/phase9/SPEC.md` into an implementation sequence for the current Godot project.

Phase 9 adds item resonance and one meaningful merge. The goal is a controlled, data-driven system where equipped item combinations can hint, reveal, apply benefits, apply cursed tradeoffs, and unlock a special merge into Staff of the Ashen Orator.

The current launch scene remains `game/scenes/phase3/ElderRoadOutskirts.tscn`. Runtime state is concentrated in `game/scripts/phase3/phase3_state.gd`, presentation in `game/scripts/phase3/elder_road_outskirts.gd`, shared UI helpers in `game/scripts/ui/`, Phase 8 ring soul logic in `game/scripts/phase8/ring_souls.gd`, and data across `game/data/phase3/`, `game/data/phase4/`, `game/data/phase5/`, and `game/data/phase8/`.

Phase 9 should extend those systems without turning resonance into a broad crafting economy.

## Guiding Principles

- Keep the launch scene stable and continue using `ElderRoadOutskirts.tscn`.
- Keep resonance and merge rules data-driven.
- Use actual local item ids, not shorthand ids from the spec examples.
- Preserve existing item discovery, attunement, curse, ring soul, combat, inventory, class, and UI behavior.
- Track resonance state at the run/player level, separate from item definitions.
- Apply resonance effects only through one calculation path to avoid duplicate bonuses.
- Do not reveal hidden or cursed combinations until their gameplay triggers occur.
- Do not add materials, sockets, gems, vendors, procedural recipes, or a broad crafting economy.
- Keep health-cost resonance and curse effects nonlethal for this phase.
- Reuse Phase 7 UI styling and Phase 8 ring soul messaging patterns.
- Add dedicated UI scenes only when they reduce complexity; helper-built overlays are acceptable for the first pass.

## Current Implementation Notes

Important existing ids:

```text
Ashen Ring:                  phase5_ashen_ring
Ember Staff:                 phase4_ember_staff
Roadwarden's Notched Blade:  phase5_roadwardens_notched_blade
Roadwarden Vest:             phase3_roadwarden_vest
Whisperthread Cloak:         phase5_whisperthread_cloak
Scout Knife:                 phase4_scout_knife
Elder Glass Charm:           phase5_elder_glass_charm
Varn soul id:                varn_ashen_orator
Ember Bolt skill:            ember_bolt
Kindle skill:                kindle
Guarded Strike skill:        guarded_strike
Piercing Shot skill:         piercing_shot
Grave Touch skill:           grave_touch
```

Relevant current files:

```text
game/scripts/phase3/phase3_state.gd
game/scripts/phase3/elder_road_outskirts.gd
game/scripts/phase8/ring_souls.gd
game/data/phase3/items.json
game/data/phase4/starter_items.json
game/data/phase4/skills.json
game/data/phase5/items.json
game/data/phase8/ring_souls.json
internal/validate/
internal/phase8/
```

Existing behavior to preserve:

- Phase 8 grants Ashen Ring from Weathered Shrine.
- `phase5_ashen_ring` already has Varn soul state, Blood Price, attunement, bargain state, and Ember Bolt bonuses.
- Skill damage already includes skill base damage, stat scaling, talent bonuses, revealed item damage bonuses, and accepted ring bargain bonuses.
- Skill cost already includes talent and item modifiers.
- Blood Price is nonlethal for Ashen Ring.
- Item details already show discovered properties and ring soul details.
- The message log supports `ring_whisper`, `memory`, and `bargain`.

Current implementation risks:

- `phase3_state.gd` is already the central gameplay integration point. Add resonance helpers around it and avoid scattering item-id checks through combat calculations.
- Phase 8 has direct Varn-specific logic for the ring. The merge must transfer that soul state instead of duplicating it.
- Merging consumes equipped items, so inventory removal and equipment references must be handled carefully.
- Several required resonances involve class starter gear, so tests and manual checks should cover all three classes.

## Target Structure

Prefer additions that match the repo’s current data-driven pattern:

```text
game/
  data/
    phase9/
      item_resonances.json
      item_merges.json
  scripts/
    phase9/
      item_resonance.gd
      item_merging.gd
      resonance_view_models.gd
```

Add UI scenes only if helpful:

```text
game/scenes/ui/ResonancePanel.tscn
game/scenes/ui/MergePanel.tscn
```

If scene extraction slows progress, build the panels in `elder_road_outskirts.gd` first, using the same overlay and helper-button patterns as inventory, quest, talents, and the Phase 8 bargain panel.

Add pure helper tests under:

```text
internal/phase9/
```

Use `internal/phase9` for deterministic resonance matching, discovery, effect aggregation, merge requirements, and nonlethal health-cost helpers.

## Baseline Check

### Tasks

Run before implementation:

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

### Manual Baseline

Record current behavior for:

- Equipping Ember Staff and Ashen Ring.
- Revealing Ashen Ring Blood Price.
- Accepting or rejecting Breath for Flame.
- Equipping Roadwarden gear.
- Equipping Gravebound Scout gear.
- Skill damage and skill cost before resonance effects.
- Item details for Ashen Ring and other required items.

### Exit Criteria

- Existing Go tests pass.
- Data validation passes.
- Phase 3 scene loads headlessly.
- Current Phase 8 ring soul and bargain behavior is understood before resonance changes begin.

## Milestone 1: Resonance Data and Validation

### Goal

Add data definitions for the four required resonances and validate their item, skill, and effect references.

### Implementation Tasks

1. Create:

   ```text
   game/data/phase9/item_resonances.json
   ```

2. Add required resonances:
   - `coal_remembers_flame`
   - `road_oath_tempered`
   - `grave_thread`
   - `breath_debt`
3. Use local camelCase field names, for example:
   - `requiredItemIds`
   - `requiredEquippedSlots`
   - `discoveryRequirements`
   - `skillId`
4. Add supported visibility values:
   - `visible`
   - `hinted`
   - `hidden`
   - `locked_by_identify`
   - `locked_by_attunement`
   - `locked_by_level`
5. Add supported effect types:
   - `stat_bonus`
   - `stat_penalty`
   - `skill_damage_bonus`
   - `skill_cost_modifier`
   - `basic_attack_damage_bonus`
   - `curse_health_cost`
   - `message_only`
   - `unlock_merge_recipe`
6. Extend Go data validation for:
   - duplicate resonance ids
   - missing required fields
   - invalid visibility and trigger values
   - unknown item references
   - unknown skill references
   - invalid effect shape
   - health-cost effects marked nonlethal where required

### Exit Criteria

- Four resonance definitions exist in data.
- Resonance definitions reference valid current item and skill ids.
- Validator catches broken resonance references.
- Existing data validation still passes.

## Milestone 2: Resonance Runtime State and Detection

### Goal

Track discovered and triggered resonance state, and detect active/hinted resonances from current equipment.

### Implementation Tasks

1. Add `game/scripts/phase9/item_resonance.gd`.
2. Add run-level state in `phase3_state.gd`:

   ```text
   resonance = {
     discoveredResonanceIds = [],
     triggeredResonanceIds = [],
     rejectedResonanceIds = [],
     mergeRecipeIdsDiscovered = []
   }
   ```

3. Load `game/data/phase9/item_resonances.json` during reset.
4. Implement helpers:
   - `get_active_resonances`
   - `get_discovered_active_resonances`
   - `get_hinted_resonances`
   - `is_resonance_discovered`
   - `discover_resonance`
   - `required_items_equipped`
   - `required_items_owned`
5. Treat non-resonant items as no-ops.
6. Keep item matching based on `itemId`, not display name.

### Exit Criteria

- Equipped item combinations can be detected.
- Discovered state is separate from item data.
- Hinted resonance can be detected without applying its full effect.
- Existing equipment and inventory behavior is unchanged for non-resonant items.

## Milestone 3: Resonance Discovery Triggers

### Goal

Discover resonances through gameplay events instead of manual guessing.

### Implementation Tasks

1. Implement:
   - `process_resonance_trigger`
   - `can_discover_resonance`
   - `discover_resonance`
2. Hook processing after:
   - item equipped
   - item identified
   - skill used
   - enemy defeated
   - curse triggered
   - attunement level changed
3. Discovery behavior:
   - Coal Remembers Flame: hinted on equip, discovered after `ember_bolt` while Ashen Ring and Ember Staff are equipped.
   - Road Oath Tempered: discovered when Notched Blade and Roadwarden Vest are equipped and identified.
   - Grave Thread: discovered after enemy defeat while Whisperthread Cloak and Scout Knife are equipped; Gravebound Scout needs one defeat, other classes need two.
   - Breath Debt: discovered on skill use or curse trigger while Ashen Ring and Elder Glass Charm are equipped and Blood Price has been revealed.
4. Add discovery messages once.
5. Trigger Varn whispers for Coal Remembers Flame and Breath Debt.

### Exit Criteria

- Required resonances discover at the correct time.
- Discovery messages are not duplicated.
- Hidden resonances remain hidden from unrelated actions.
- Varn-related resonances can trigger ring-whisper messaging.

## Milestone 4: Resonance Effects in Stats and Combat

### Goal

Apply discovered active resonance effects through existing stat, skill damage, skill cost, and health-cost paths.

### Implementation Tasks

1. Implement effect helpers:
   - `get_resonance_effects`
   - `apply_resonance_effects_to_stats`
   - `get_resonance_skill_damage_bonus`
   - `get_resonance_skill_cost_modifier`
   - `get_resonance_health_cost`
2. Integrate stat bonuses into `effective_stats` or `revealed_item_stats` adjacent logic.
3. Integrate skill damage bonuses into `skill_effect_amount`.
4. Integrate skill cost modifiers into `effective_skill_cost`.
5. Process resonance health cost during skill use after skill validation and before/during skill resolution.
6. Keep all resonance health costs nonlethal.
7. Avoid double-applying Staff of the Ashen Orator item property bonuses and resonance bonuses.

### Exit Criteria

- Coal Remembers Flame adds Ember Bolt damage only while active and discovered.
- Breath Debt reduces skill mana cost and adds health cost only while active and discovered.
- Road Oath Tempered adds defense and Guarded Strike damage.
- Grave Thread modifies Piercing Shot damage and Grave Touch healing where supported.
- Effects stop immediately when required items are unequipped.
- Non-resonant items and skills still work.

## Milestone 5: Resonance UI and Item Detail Integration

### Goal

Show active, hinted, cursed, and relevant item-level resonance information without spoiling hidden rules.

### Implementation Tasks

1. Add a Resonance section in inventory/equipment UI or a dedicated panel.
2. Add item detail resonance text for selected items.
3. Show:
   - discovered active resonances
   - discovered inactive resonances involving selected item
   - visible/hinted resonance hints
   - revealed cursed resonances
4. Hide:
   - hidden undiscovered resonances
   - exact hidden recipe details before requirements are met
5. Add message labels/colors if needed:
   - `resonance`
   - `merge`
6. Use Phase 7 panel, color, spacing, and button patterns.

### Exit Criteria

- Player can see active discovered resonances.
- Hinted resonances appear without full spoilers.
- Breath Debt is clearly marked as cursed after reveal.
- Selected item details show relevant resonance information.
- UI remains readable with Phase 8 ring soul details present.

## Milestone 6: Merge Data and Staff Item Definition

### Goal

Add the merge recipe model and the Staff of the Ashen Orator item definition.

### Implementation Tasks

1. Create:

   ```text
   game/data/phase9/item_merges.json
   ```

2. Add recipe:
   - id: `staff_of_the_ashen_orator_merge`
   - required items: `phase5_ashen_ring`, `phase4_ember_staff`
   - required discovered resonance: `coal_remembers_flame`
   - required Ashen Ring attunement level: 2
   - required Varn name revealed
   - consumes source items
   - result item id: `phase9_staff_of_the_ashen_orator`
   - risk: `curse_carryover`
   - visibility: `hinted`
3. Add `phase9_staff_of_the_ashen_orator` to a Phase 9 item data file or `phase5/items.json` if reuse is simpler.
4. Staff properties:
   - weapon, equippable, `equipmentSlot: weapon`
   - spellPower +4
   - maxManaBonus +10
   - attunable, max attunement level 4
   - `soulId: varn_ashen_orator`
   - Orator's Flame: Ember Bolt +4, visible immediately
   - Borrowed Breath: Kindle restores +5 additional mana at attunement level 1
   - Blood Price Carried: skill use costs 2 health, revealed immediately if carried over from ring or on first skill use
5. Extend validation for:
   - merge recipe references
   - result item references
   - required resonance references
   - required condition shape

### Exit Criteria

- Merge recipe is data-driven.
- Staff item exists and validates.
- Merge recipe references valid items, resonance, and result item.
- Existing item validation still passes.

## Milestone 7: Merge Availability and Execution

### Goal

Make Staff of the Ashen Orator merge available only after its required conditions, then consume source items and create the result.

### Implementation Tasks

1. Add `game/scripts/phase9/item_merging.gd`.
2. Implement helpers:
   - `get_available_merge_recipes`
   - `get_hinted_merge_recipes`
   - `can_merge_items`
   - `discover_merge_recipe`
   - `merge_items`
3. Check required conditions:
   - source items are owned or equipped
   - Coal Remembers Flame discovered
   - Ashen Ring attunement level at least 2
   - Varn name revealed
4. Merge execution:
   - show start message
   - remove Ashen Ring and Ember Staff instances
   - clear trinket slot
   - create Staff of the Ashen Orator
   - transfer Varn soul state to the staff
   - reset new staff attunement to level 0
   - preserve or carry Blood Price reveal state
   - equip staff in weapon slot
   - add completion message and Varn whisper
5. Ensure Varn is not duplicated across old ring and new staff.

### Exit Criteria

- Merge is unavailable before requirements.
- Merge becomes available after requirements.
- Merge consumes the source item instances.
- Staff is created and auto-equipped.
- Varn soul state transfers.
- Source equipment references are cleaned up.

## Milestone 8: Merge UI and Presentation

### Goal

Give merging a clear confirmation and result presentation.

### Implementation Tasks

1. Add a merge panel or inventory overlay.
2. Show:
   - recipe name
   - required items
   - required conditions
   - result item preview
   - known risks
   - enabled/disabled merge button
   - cancel/close button
3. Require confirmation before final merge.
4. Add required messages:
   - `Ash circles the Ember Staff. The ring begins to speak in sparks.`
   - `Merge complete: Staff of the Ashen Orator has awakened.`
5. Add Varn whisper:
   - `Ah. At last, a proper throat for fire.`
6. Add a brief visual pulse or reuse existing overlay/message animation.

### Exit Criteria

- Merge requirements are visible.
- Missing requirements are understandable.
- Merge button is disabled until requirements are met.
- Confirmation is required.
- Result and risk are communicated.
- Merge feels distinct from normal equip/use.

## Milestone 9: Automated Tests

### Goal

Cover deterministic resonance and merge rules.

### Implementation Tasks

1. Add `internal/phase9`.
2. Cover:
   - active resonance matching when required items are equipped
   - inactive when required item is missing or unequipped
   - visible/identified requirements
   - Coal Remembers Flame discovery trigger
   - Grave Thread class-specific discovery count
   - Breath Debt cursed trigger condition
   - effect aggregation and no duplicate bonuses
   - nonlethal health cost
   - merge requirement checks
   - merge result and soul transfer model
3. Extend validator tests for resonance and merge documents.

### Exit Criteria

- `go test ./...` passes.
- Resonance and merge helper tests cover the risky logic.
- Data validation tests reject broken references.

## Milestone 10: Manual Verification and Acceptance Docs

### Goal

Document the manual checks needed for resonance, merge UI, and class-specific flows.

### Implementation Tasks

1. Create:

   ```text
   specs/phase9/ITEM_RESONANCE_VERIFICATION.md
   specs/phase9/ACCEPTANCE.md
   ```

2. Include manual checks for:
   - Coal Remembers Flame discovery and damage bonus
   - Road Oath Tempered discovery and bonuses
   - Grave Thread discovery for Gravebound Scout and another class
   - Breath Debt reveal, mana discount, added health cost, and nonlethal safety
   - Staff of the Ashen Orator merge availability
   - merge confirmation
   - source item consumption
   - staff auto-equip
   - Varn soul transfer
   - item detail resonance display
   - merge panel requirements and risk display
3. Note any known headless Godot image import warnings if still present.

### Exit Criteria

- Manual verification checklist exists.
- Acceptance doc records implemented criteria and deliberate deviations.
- Final verification commands are recorded.

## Suggested Order and Commit Plan

Use small commits between milestones:

```text
1. feat: add item resonance definitions
2. feat: detect active item resonances
3. feat: process resonance discovery triggers
4. feat: apply resonance combat effects
5. feat: add resonance UI
6. feat: add merge definitions and ashen orator staff
7. feat: implement ashen staff merge
8. feat: add merge UI and presentation
9. test: cover resonance and merge rules
10. docs: add phase 9 verification notes
```

Before each commit, run the smallest relevant validation. Before final commit, run:

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

## Acceptance Criteria for Phase 9

Phase 9 is complete when:

1. Item resonances are data-driven.
2. Resonance state tracks discovered and triggered combinations.
3. Equipping Ashen Ring and Ember Staff can hint Coal Remembers Flame.
4. Using Ember Bolt can reveal Coal Remembers Flame.
5. Coal Remembers Flame improves Ember Bolt while active.
6. Road Oath Tempered works for Roadwarden gear.
7. Grave Thread works for Scout gear.
8. Breath Debt reveals as a cursed resonance.
9. Breath Debt has both upside and downside.
10. Resonance effects stop when required items are unequipped.
11. Resonance UI shows active discovered resonances.
12. Hinted resonances do not fully spoil hidden effects.
13. Item details show relevant resonance information.
14. Merge recipe model exists.
15. Staff of the Ashen Orator item exists.
16. Ashen Ring and Ember Staff can merge after required conditions.
17. Merge consumes required items.
18. Merge creates and equips Staff of the Ashen Orator.
19. Varn soul state transfers to the new staff.
20. Merge requires confirmation.
21. Merge and resonance messages are clear.
22. Existing combat, inventory, ring soul, item discovery, and UI systems still work.
23. Manual verification checklist exists.

## Deferred Work

Do not implement these during Phase 9:

- Crafting materials.
- Gems or sockets.
- Vendor crafting stations.
- Large recipe database.
- Procedural recipe discovery.
- Multiple merge tiers.
- Full alchemy.
- Random affix generation.
- Destructive enchanting beyond the required staff merge.
- New zones.
- Additional ring souls.
- Expanded merge network.
- Save/load support unless it already exists.

## Definition of Done

Phase 9 is done when gear combinations become legible gameplay instead of hidden arithmetic.

The player should equip resonant items, notice hints, discover at least one benefit through use, uncover one dangerous interaction, and complete one significant merge that transfers Varn into Staff of the Ashen Orator without breaking the existing Phase 3 through Phase 8 loop.
