# EldersCourage Prototype Implementation Plan

## Purpose

This plan converts `SPEC.md` into an implementation sequence for the Ashen Catacombs playable prototype. The goal is to deliver one complete, playable ARPG loop while avoiding premature expansion into deferred systems.

## Guiding Principles

- Implement one milestone at a time.
- Keep placeholder visuals simple and readable.
- Prefer playable behavior over architectural completeness.
- Keep content data-driven where it directly supports validation, loot, enemies, items, echoes, or synergies.
- Document architectural choices in `DECISIONS.md`.
- Track milestone pass/fail status in `ACCEPTANCE.md`.
- Do not implement out-of-scope systems unless all prototype goals are complete.

## Assumed Technical Direction

- Game engine: Godot 4.x.
- External tooling: Go 1.22+ using the standard library by default.
- Game content format: JSON.
- Save format: JSON.
- Initial movement: WASD, with mouse or directional attack targeting.
- Initial dungeon layout: fixed room order before randomization.

## Target Repository Layout

```text
game/
  project.godot
  scenes/
  scripts/
  assets/
  ui/
  data/
    classes/
    skills/
    items/
    enemies/
    echoes/
    synergies/
    dungeons/
    loot/
tools/
  cmd/elders/
  internal/validate/
  internal/loot/
  internal/sim/
  internal/balance/
  schema/
specs/prototype/
  SPEC.md
  PLAN.md
  ACCEPTANCE.md
  DECISIONS.md
```

## Phase 0: Project Foundation

### Goals

Create the minimum repository scaffolding needed to support milestone implementation.

### Tasks

1. Create `game/` Godot project structure.
2. Create placeholder `ACCEPTANCE.md` and `DECISIONS.md`.
3. Add initial JSON data folders under `game/data/`.
4. Add `tools/` Go module or decide whether to reuse the root `go.mod`.
5. Add a minimal `elders validate-data` command stub.

### Exit Criteria

- Godot project opens.
- Go tooling builds.
- Content directories exist.
- Initial decisions are documented.

## Phase 1: Combat Arena

### Goals

Deliver Milestone 1: a single playable room where the player and one enemy can fight and die.

### Tasks

1. Implement a top-down combat test scene.
2. Add player movement, camera, health, and input mapping.
3. Implement Grave Strike with hit detection, damage, crit roll, and Will gain if practical.
4. Implement one skill, preferably Blood Cleave, with placeholder arc feedback.
5. Add Bone Thrall with pursuit, melee attack, health, and death.
6. Add damage feedback through numbers, flashes, or simple hit effects.
7. Add player death state and restart behavior.

### Exit Criteria

- Player can kill a Bone Thrall.
- Bone Thrall can damage and kill the player.
- Basic attack and one skill are visible and usable.
- Combat loop runs without crashes.

## Phase 2: Skills, Resources, and Enemy Variety

### Goals

Make combat meaningfully varied and establish reusable combat primitives.

### Tasks

1. Implement Will as a resource with HUD display.
2. Add Blood Cleave, Grave Step, and Bell of the Dead.
3. Add cooldown tracking and skill UI indicators.
4. Implement Bleed, Burn, Chill, and Vulnerable status effects.
5. Add Ash Witch ranged behavior.
6. Add Hollowed Brute slam behavior and knockback.
7. Add shared damage flow for skill multipliers, crits, armor/resistance, status effects, and death checks.

### Exit Criteria

- All three skills work with visible effects.
- All three enemy types behave differently.
- Status effects affect combat outcomes.
- Player success depends on movement, timing, and skill use.

## Phase 3: Loot, Inventory, and Equipment

### Goals

Make loot drops change player power and create the base item model.

### Tasks

1. Define JSON schemas or validation rules for item data.
2. Add item definitions for at least 10 starter items.
3. Implement dropped loot pickups.
4. Implement inventory UI.
5. Implement equipment slots: weapon, armor, ring 1, ring 2.
6. Implement item tooltips with rarity, slot, visible stats, and unknown fields.
7. Apply equipped item stats to combat calculations.
8. Add Grave Marks as collectable/displayed currency.

### Exit Criteria

- Player can pick up, inspect, equip, and unequip items.
- Equipment changes stats or behavior.
- Enemies and placeholder boss/chest can drop loot.
- Item data is loaded from JSON rather than fully hardcoded.

## Phase 4: Rings, Identification, and Attunement

### Goals

Implement the signature item discovery loop.

### Tasks

1. Add required ring data with soul metadata and whispers.
2. Implement per-item-instance attunement state unless documented otherwise.
3. Award attunement XP for kills, elite kills, boss kills, and tagged actions.
4. Implement attunement thresholds through level 5.
5. Reveal hidden stats, curses, echoes, whispers, or synergy hints at thresholds.
6. Add Identify Scroll drops and inventory use flow.
7. Ensure Identify Scrolls reveal valid hidden information and are not wasted on fully known items.
8. Update item tooltip to show progress, revealed properties, curses, and `????` slots.

### Exit Criteria

- Equipped items gain attunement XP.
- Hidden properties unlock at thresholds.
- Ring curses and soul metadata can be revealed.
- Identify Scrolls reveal useful hidden item information.

## Phase 5: Echoes and Death Consequences

### Goals

Make item power and player failure leave persistent gameplay traces.

### Tasks

1. Implement Item Echo definitions and triggers.
2. Add at least one working Item Echo in combat.
3. Create Death Echo on player death at the death location.
4. Mark rooms with unreclaimed Death Echoes as haunted.
5. Apply haunted modifiers to enemies in that room.
6. Implement reclaim interaction or clear-room reclaim behavior.
7. Grant attunement XP reward after reclaiming a Death Echo.

### Exit Criteria

- Death creates a persistent Death Echo.
- Haunted rooms are mechanically different.
- Player can reclaim a Death Echo.
- Item Echo triggers during normal combat.

## Phase 6: Dungeon Flow, Elite, Boss, and Save/Load

### Goals

Deliver the full Ashen Catacombs vertical slice.

### Tasks

1. Implement fixed room sequence: entrance, 3 combat rooms, elite room, treasure/shrine room, boss room.
2. Add room spawn points, exits, encounter definitions, and loot table references.
3. Implement elite modifiers: Burning, Vampiric, Echoing.
4. Add The Bell-Ringer Below with Bell Slam, Call the Buried, and Echo Toll.
5. Add boss rewards, reward chest, and exit portal.
6. Implement JSON save/load for player level, XP, skills, inventory, equipment, attunement, revealed properties, Death Echoes, and Grave Marks.
7. Save on equipment changes, level up, death, dungeon exit, and dungeon completion.

### Exit Criteria

- Player can start and complete a dungeon run.
- Elite enemies and boss are functional.
- Rewards are granted after boss defeat.
- Save/load preserves meaningful state.

## Phase 7: Data Validation and Content Completion

### Goals

Ensure prototype content is complete, valid, and maintainable.

### Tasks

1. Complete required content counts: 10 weapons, 8 armor pieces, 10 rings, 5 curses, 5 item echoes, 5 synergies.
2. Implement `elders validate-data ./game/data`.
3. Validate required fields, unique IDs, references, stat names, rarity values, echo triggers, synergy tags, and JSON syntax.
4. Add unit tests for validation logic.
5. Add deterministic loot generation support if needed for validation or testing.
6. Add optional commands only after the validator is stable.

### Exit Criteria

- Required content exists in JSON.
- Validator catches malformed data and broken references.
- `go test ./...` passes.
- `elders validate-data ./game/data` passes.

## Phase 8: Prototype Polish and Acceptance Pass

### Goals

Stabilize the vertical slice and verify the full acceptance list.

### Tasks

1. Walk through all acceptance criteria in `SPEC.md`.
2. Update `ACCEPTANCE.md` with pass/fail notes.
3. Fix blocking crashes, broken loops, unreadable UI, and missing feedback.
4. Tune rough combat numbers for a short but complete run.
5. Confirm performance with roughly 20 enemies, 30 dropped items, and multiple effects.
6. Document remaining gaps and deferred systems.

### Exit Criteria

- All prototype acceptance criteria pass or have explicit documented exceptions.
- The dungeon loop is playable from launch to completion.
- Known limitations are documented.

## Implementation Order Summary

1. Project scaffolding.
2. Single-room combat.
3. Skills and enemy variety.
4. Loot and equipment.
5. Rings, Identify Scrolls, and attunement.
6. Item Echoes and Death Echoes.
7. Dungeon flow, elite enemies, boss, and save/load.
8. Data validation and content completion.
9. Polish, balance, and final acceptance pass.

## Key Risks and Mitigations

- Scope creep: enforce milestone boundaries and defer nonessential systems.
- Data model churn: start with simple JSON and evolve only when a feature needs it.
- Unfun combat: validate feel in Phase 1 before building item complexity.
- UI overload: reveal only the information required for the current milestone.
- Save compatibility: accept breaking save changes during prototype unless milestone acceptance requires migration.

## First Recommended Task

Implement Phase 0 and Phase 1 only. The first playable target is one room, one player, one enemy, one attack, one skill, health, damage, and death.
