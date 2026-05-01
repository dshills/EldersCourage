# EldersCourage Phase 8 Implementation Plan

## Purpose

This plan converts `specs/phase8/SPEC.md` into an implementation sequence for the current Godot project.

Phase 8 makes the Ashen Ring feel inhabited instead of merely enchanted. The target is a single polished vertical slice: the player can find the Ashen Ring, identify it, equip it, hear Varn, reveal memories through attunement, suffer Blood Price, and choose whether to accept the Breath for Flame bargain.

The current launch scene is still `game/scenes/phase3/ElderRoadOutskirts.tscn`. Runtime state is concentrated in `game/scripts/phase3/phase3_state.gd`, presentation in `game/scripts/phase3/elder_road_outskirts.gd`, UI helpers in `game/scripts/ui/`, and item data across `game/data/phase3/`, `game/data/phase4/`, and `game/data/phase5/`. Phase 8 should extend those systems rather than introducing a parallel game loop.

## Guiding Principles

- Keep the launch scene stable and continue using `ElderRoadOutskirts.tscn`.
- Extend the existing `phase5_ashen_ring`; do not replace it with a second Ashen Ring id.
- Preserve the current item discovery, attunement, curse, combat, class, inventory, shrine, and message flows.
- Keep the phase focused on one soul-bound ring and one named soul: Varn, The Ashen Orator.
- Keep ring soul data authored and reviewable. Do not generate procedural souls.
- Track soul state per item instance, not globally by item definition.
- Hide unrevealed soul identity, motivations, memories, curses, and bargain effects until the correct reveal stage.
- Avoid whisper spam: one ring whisper per gameplay event, with once-only and cooldown rules.
- Keep all health costs nonlethal where the spec requires it. Blood Price and Breath for Flame cannot reduce health below 1.
- Use Phase 7 UI styling and layout patterns. Add dedicated scenes only where they make the UI easier to maintain.
- Do not add full dialogue trees, multiple ring slots, ring fusion, save/load, campaign branching, morality systems, or new zones during Phase 8.

## Current Implementation Notes

The relevant current files are:

```text
game/scripts/phase3/phase3_state.gd
game/scripts/phase3/elder_road_outskirts.gd
game/scripts/ui/ui_theme.gd
game/scripts/ui/ui_view_models.gd
game/data/phase3/shrines.json
game/data/phase3/loot_tables.json
game/data/phase5/items.json
game/scenes/phase3/ElderRoadOutskirts.tscn
internal/validate/
```

Existing behavior to preserve:

- The Weathered Shrine restores health and mana through `activate_shrine`.
- Containers and some debug/test paths can already grant `phase5_ashen_ring`.
- `phase5_identify_scroll` supports targeted identification.
- `phase5_ashen_ring` already has identify, attunement, and curse properties.
- Trinkets can be equipped through the current equipment flow.
- Skill use processes equipped curses and grants trinket attunement.
- Attunement level-ups reveal item properties through existing requirement checks.
- The message log already supports typed messages and Phase 7 styling.

Current implementation risks:

- `phase3_state.gd` is already the integration point for inventory, combat, curses, shrine activation, attunement, and messages. Phase 8 should add helpers around it instead of scattering soul logic inline.
- `elder_road_outskirts.gd` is large. Ring soul UI should be added through focused helper methods or small scenes rather than further expanding monolithic refresh blocks.
- Item data uses local camelCase keys such as `itemId`, `equipmentSlot`, and `defaultKnowledgeState`; map spec examples like `soul_id` to local style as `soulId`.
- The spec recommends Weathered Shrine acquisition, while the current loot table already grants the ring in normal play. Implement the shrine reward as canonical Phase 8 placement, then decide whether the cache keeps a duplicate only if testing needs it.

## Target Structure

Prefer small additions that match the repo’s current data-driven shape:

```text
game/
  data/
    phase8/
      ring_souls.json
  scripts/
    phase8/
      ring_souls.gd
      ring_soul_view_models.gd
  scenes/
    ui/
      RingBargainPanel.tscn
      RingWhisperToast.tscn
```

`RingBargainPanel.tscn` and `RingWhisperToast.tscn` are useful if the UI becomes easier to maintain with separate scenes. If extraction slows delivery, build them with helper methods in `elder_road_outskirts.gd` first and extract after behavior is stable.

Add optional pure helper tests under:

```text
internal/phase8/
```

Use `internal/phase8` for deterministic logic that can be mirrored cleanly in Go: reveal stages, trust clamping, whisper filtering, bargain state, memory unlocks, and nonlethal health costs.

## Baseline Check

### Tasks

Run before implementation:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

### Manual Baseline

Record the current behavior for:

- Activating the Weathered Shrine.
- Opening the Roadside Cache.
- Identifying `phase5_ashen_ring`.
- Equipping `phase5_ashen_ring`.
- Triggering Blood Price through skill use.
- Reaching attunement levels 1, 2, and 3.
- Viewing the ring in inventory details.

### Exit Criteria

- Existing Go tests pass.
- Data validation passes.
- Phase 3 scene loads headlessly.
- Current Ashen Ring discovery, attunement, and curse behavior is understood before soul changes begin.

## Milestone 1: Ring Soul Data and Validation

### Goal

Add Varn’s authored soul data and link it to the existing Ashen Ring without changing current item identity.

### Implementation Tasks

1. Create:

   ```text
   game/data/phase8/ring_souls.json
   ```

2. Add a single soul record:
   - id: `varn_ashen_orator`
   - name: `Varn`
   - epithet: `The Ashen Orator`
   - discipline: ember rhetoric / binding flame
   - personality tags: eloquent, vain, hungry, persuasive, wounded
   - motivation: `To feel living breath again, even borrowed.`
3. Add Varn’s required whispers:
   - on equip
   - on skill use
   - on enemy defeated
   - on attunement level up
   - on curse trigger
   - low trust
   - bargain offered
   - bargain accepted
   - bargain rejected
4. Add Varn’s required memories:
   - `varn_hall_of_cinders`
   - `varn_failed_binding`
   - `varn_last_breath`
5. Add the required bargain:
   - id: `breath_for_flame`
   - trigger: attunement level 2
   - health cost: 5 current health, not below 1
   - accept: trust +1, reveal last memory, add Ember Bolt +2 damage bonus
   - reject: trust -1 and no bonus
6. Extend `phase5_ashen_ring` in `game/data/phase5/items.json` with:

   ```json
   "soulId": "varn_ashen_orator"
   ```

7. Add validator coverage for:
   - duplicate soul ids
   - missing required soul fields
   - missing memory, whisper, or bargain ids
   - item `soulId` references that do not exist
   - bargain trust changes outside the allowed range
   - nonlethal health cost configuration for required effects

### Exit Criteria

- `phase5_ashen_ring` links to Varn.
- Varn’s whispers, memories, and bargain are authored in data.
- Data validation catches broken soul references.
- Existing item properties on the Ashen Ring remain intact.

## Milestone 2: Ring Soul Runtime State

### Goal

Track soul reveal and relationship state per item instance.

### Implementation Tasks

1. Add `game/scripts/phase8/ring_souls.gd` with helpers for:
   - loading soul definitions
   - initializing soul state
   - clamping trust from -3 to +3
   - checking reveal stage
   - marking memories revealed
   - marking whispers seen
   - tracking bargain offered, accepted, and rejected ids
2. Update state loading in `phase3_state.gd` to load Phase 8 ring soul definitions on reset.
3. Extend item instance creation so items with `soulId` receive a `soul` state dictionary:

   ```text
   soulId
   soulRevealed
   trust
   memoryIdsRevealed
   whisperIdsSeen
   bargainIdsOffered
   bargainIdsAccepted
   bargainIdsRejected
   lastWhisperTurnsById
   ```

4. Ensure non-soul items do not receive soul state.
5. Preserve soul state when item instances are updated after reveal, attunement, equip, or inventory movement.

### Exit Criteria

- Soul state initializes for `phase5_ashen_ring`.
- Non-soul items remain unchanged.
- Trust cannot move outside -3 to +3.
- Existing inventory and equipment actions preserve per-instance soul data.

## Milestone 3: Soul Reveal Stages and Memories

### Goal

Reveal Varn gradually through identification, attunement, and bargain state.

### Implementation Tasks

1. Implement reveal helpers:
   - `reveal_soul_presence`
   - `reveal_soul_name`
   - `reveal_soul_motivation`
   - `get_soul_reveal_stage`
   - `reveal_memory`
2. Reveal soul presence when the ring is identified, equipped, or its curse first triggers, whichever happens first.
3. Reveal Varn’s name at attunement level 1.
4. Reveal Varn’s motivation at attunement level 2.
5. Reveal `varn_hall_of_cinders` at attunement level 1.
6. Reveal `varn_failed_binding` at attunement level 2.
7. Reveal `varn_last_breath` at attunement level 3 or when Breath for Flame is accepted.
8. Emit `memory` or `discovery` messages when a reveal happens, once per reveal.

### Exit Criteria

- Soul presence can reveal without revealing Varn’s name.
- Name, motivation, and memories unlock at the required stages.
- Reveals happen once and do not duplicate messages.
- Existing attunement property reveals still work.

## Milestone 4: Ring Whispers and Message Types

### Goal

Make Varn react contextually without overwhelming the message log.

### Implementation Tasks

1. Implement whisper helpers:
   - `get_available_whispers`
   - `select_whisper`
   - `process_ring_whisper_trigger`
   - `mark_whisper_seen`
2. Support required triggers:
   - `on_equip`
   - `on_skill_use`
   - `on_enemy_defeated`
   - `on_attunement_level_up`
   - `on_curse_trigger`
   - `on_bargain_offered`
   - `on_bargain_accepted`
   - `on_bargain_rejected`
3. Add once-only and cooldown behavior.
4. Enforce one ring whisper per gameplay event.
5. Add message types:
   - `ring_whisper`
   - `bargain`
   - `memory`
6. Update message labels and colors in `elder_road_outskirts.gd` to make whispers visually distinct.
7. If practical, add `RingWhisperToast.tscn`; otherwise, keep whisper presentation in the message log for the first pass.

### Exit Criteria

- Equipping the ring can trigger Varn’s equip whisper once.
- Skill use, enemy defeat, attunement, and curse triggers can produce contextual whispers.
- Once-only whispers do not repeat.
- Repeatable whispers respect cooldowns.
- No whisper fires when no soul-bound ring is equipped.

## Milestone 5: Blood Price Soul Integration

### Goal

Connect the existing Blood Price curse to Varn and make the curse nonlethal.

### Implementation Tasks

1. Keep the existing `phase5_ashen_ring_blood_price` property.
2. Update curse processing so Blood Price health loss cannot reduce the player below 1 health.
3. Reveal soul presence when Blood Price first triggers if the soul is still unknown.
4. Emit a soul-aware curse message when Blood Price triggers.
5. Trigger Varn’s `on_curse_trigger` whisper.
6. Ensure other curses still behave according to their own definitions.

### Exit Criteria

- Blood Price costs 2 health on skill use while the Ashen Ring is equipped.
- Blood Price cannot directly kill the player.
- The curse reveal remains visible in item details.
- Varn can react to Blood Price without breaking non-ring curses.

## Milestone 6: Breath for Flame Bargain

### Goal

Offer one clear, consequential bargain at attunement level 2.

### Implementation Tasks

1. Detect when the equipped or selected Ashen Ring reaches attunement level 2.
2. Offer `breath_for_flame` once if it has not been accepted or rejected.
3. Store pending bargain UI state separately from item data.
4. Add `RingBargainPanel.tscn` or an equivalent Phase 7 styled overlay with:
   - bargain title
   - Varn line
   - visible health cost
   - accept button
   - reject button
5. Implement accept:
   - reduce current health by 5, not below 1
   - trust +1
   - mark bargain accepted
   - reveal `varn_last_breath`
   - apply Ember Bolt +2 damage bonus
   - emit bargain and memory messages
6. Implement reject:
   - trust -1
   - mark bargain rejected
   - no damage bonus
   - emit bargain message and rejection whisper
7. Apply the bargain damage bonus only after acceptance.

### Exit Criteria

- Bargain appears once at attunement level 2.
- Accept and reject are both clear and functional.
- Accept applies health cost, trust gain, memory reveal, and damage bonus.
- Reject applies trust loss and no bonus.
- Bargain state does not reset during normal inventory/equipment refreshes.

## Milestone 7: Combat Bonus Integration

### Goal

Apply Ashen Ring bonuses at the right reveal states without overpowering the current combat loop.

### Implementation Tasks

1. Preserve current `Ember Memory` behavior as +1 Spell Power after identification.
2. Preserve or tune `Hungry Spark` as Ember Bolt +3 damage at attunement level 2.
3. Add Breath for Flame’s Ember Bolt +2 damage after bargain acceptance.
4. Ensure the total possible Ember Bolt bonus is +5 from Hungry Spark and Breath for Flame.
5. Confirm hidden or unrevealed bonuses do not apply before their required reveal state.
6. Confirm Roadwarden and Gravebound Scout can equip or ignore the ring safely.

### Exit Criteria

- Ember Sage benefits from the ring without trivializing combat.
- Non-Ember Sage classes do not break when equipping the ring.
- Combat damage reflects only revealed or accepted ring effects.
- Blood Price remains a meaningful drawback.

## Milestone 8: Weathered Shrine Acquisition

### Goal

Move Phase 8’s canonical Ashen Ring acquisition to the Weathered Shrine event.

### Implementation Tasks

1. Extend shrine activation for `phase3_weathered_shrine`.
2. Keep the existing health and mana restoration.
3. Grant `phase5_ashen_ring` the first time the shrine is activated.
4. Grant one `phase5_identify_scroll` if the player does not already have one.
5. Add the required message:

   ```text
   At the shrine's base, ash gathers around a blackened ring.
   ```

6. Decide whether to remove the guaranteed Roadside Cache Ashen Ring after shrine placement is stable. If keeping both temporarily, document why in acceptance notes.

### Exit Criteria

- Ashen Ring is obtainable in normal play from the Weathered Shrine.
- Player has a way to identify it.
- Existing shrine restoration behavior still works.
- Acquisition message is flavorful and distinct.

## Milestone 9: Ring Soul UI

### Goal

Show the player what they have learned about Varn without exposing hidden information.

### Implementation Tasks

1. Extend inventory item details or add a focused `RingSoulPanel`.
2. Show a soul section only for soul-bound rings.
3. Include:
   - identity or unknown presence
   - epithet when revealed
   - trust state
   - attunement progress
   - known powers
   - known curses
   - revealed memories
   - bargain history
4. Hide unrevealed identity, motivation, memories, curses, and bargain effects.
5. Add an `Inspect Soul` action only if it improves clarity over inline item details.
6. Keep layout consistent with Phase 7 spacing, colors, and panel hierarchy.
7. Ensure the message log handles `ring_whisper`, `memory`, `bargain`, and `curse` entries cleanly.

### Exit Criteria

- Varn’s name appears only after reveal.
- Attunement progress remains visible.
- Revealed memories are readable.
- Revealed curses are visible.
- Bargain history is visible after offer, accept, or reject.
- UI remains readable and consistent with Phase 7.

## Milestone 10: Automated Tests

### Goal

Cover the ring soul rules that are easy to regress.

### Implementation Tasks

1. Add Go helper coverage under `internal/phase8` for pure logic where practical:
   - soul state initialization
   - trust clamping
   - reveal stage calculation
   - once-only whisper filtering
   - memory reveal deduplication
   - bargain accept/reject effects
   - nonlethal health costs
2. Extend data validation tests for ring soul records and item references.
3. Add or update GDScript/headless smoke checks only where the current project structure supports them cleanly.
4. Ensure existing Phase 2 through Phase 7 tests still pass.

### Exit Criteria

- `go test ./...` passes.
- `go run ./cmd/elders validate-data ./game/data` passes.
- Tests cover reveal, whisper, memory, bargain, curse, and combat bonus edge cases where practical.

## Milestone 11: Manual Verification and Acceptance Docs

### Goal

Document the playthrough checks needed for a narrative/UI-heavy phase.

### Implementation Tasks

1. Create:

   ```text
   specs/phase8/RING_SOUL_VERIFICATION.md
   specs/phase8/ACCEPTANCE.md
   ```

2. Include manual verification for:
   - acquire Ashen Ring from Weathered Shrine
   - receive Identify Scroll if needed
   - identify Ashen Ring
   - equip Ashen Ring
   - trigger Varn equip whisper
   - use skill and trigger Blood Price
   - verify Blood Price cannot reduce health below 1
   - defeat an enemy and trigger contextual whisper
   - reach attunement level 1 and reveal Varn’s name and first memory
   - reach attunement level 2 and reveal motivation, second memory, and bargain
   - accept bargain and verify health cost, trust gain, final memory, and Ember Bolt bonus
   - reset or alternate path to reject bargain and verify trust loss and no bonus
   - smoke test Roadwarden and Gravebound Scout
3. Add screenshots if UI layout changes materially.

### Exit Criteria

- Manual verification file exists and reflects the implemented flow.
- Acceptance doc summarizes completed criteria and any deliberate deviations.
- Visible UI changes have screenshots or concise notes.

## Suggested Order and Commit Plan

Use small commits between milestones:

```text
1. feat: add Varn ring soul data
2. feat: link Ashen Ring to soul state
3. feat: implement ring soul reveal stages
4. feat: add ring whispers and message types
5. feat: integrate Blood Price with Varn
6. feat: add Breath for Flame bargain
7. feat: apply ring soul combat bonuses
8. feat: grant Ashen Ring from Weathered Shrine
9. feat: add ring soul UI
10. test: cover ring soul state and validation
11. docs: add phase 8 verification notes
```

Before each commit, run the smallest relevant validation. Before the final commit, run the full verification set:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

## Acceptance Criteria for Phase 8

Phase 8 is complete when:

1. Ashen Ring is obtainable during normal play from the Weathered Shrine.
2. Ashen Ring is linked to Varn, The Ashen Orator.
3. Ring soul state is tracked per item instance.
4. Soul presence can be revealed without revealing full identity.
5. Varn’s name reveals through attunement.
6. Varn’s motivation reveals through deeper attunement.
7. Varn can whisper through the message system.
8. Whispers are contextual and do not spam.
9. At least three Varn memory fragments exist.
10. Memories reveal through attunement or bargain.
11. Ring UI displays revealed soul information.
12. Blood Price is soul-aware and cannot directly kill the player.
13. Breath for Flame appears once.
14. Player can accept or reject the bargain.
15. Accept and reject consequences apply correctly.
16. Ring powers and curses affect combat only when revealed or triggered according to rules.
17. Existing item discovery, attunement, combat, class, shrine, and UI systems still work.
18. Manual verification checklist exists or is updated.

## Deferred Work

Do not implement these during Phase 8:

- Additional named ring souls.
- Procedural souls.
- Multiple ring slots.
- Ring fusion.
- Full dialogue trees.
- Voice acting.
- Complex soul reputation.
- Long-term campaign branching.
- Companion AI.
- Save/load support unless it already exists.
- New zones or multi-zone ring clue systems.

## Definition of Done

Phase 8 is done when the Ashen Ring is no longer just a stat object.

The player should find it, identify it, wear it, hear it, learn who is inside, benefit from its power, pay for that power, and make one clear bargain with consequences. The implementation should prove the first soul-bound ring cleanly without expanding beyond that focused slice.
