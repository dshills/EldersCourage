# EldersCourage — Phase 10 SPEC.md

## Phase Name

**Phase 10: Multi-Zone Expansion, Zone Transitions, Environmental Hazards, and Stronger Encounters**

## Canonical Implementation Target

This is a **Godot project**.

All implementation should use Godot-native systems:

- Godot 4.x
- `.tscn` scenes
- Control nodes for UI
- Node2D / Control map presentation as already implemented
- Resource files, dictionaries, or lightweight GDScript data definitions
- Autoloads where appropriate
- Signals for game events and UI updates
- Tween / AnimationPlayer for feedback
- InputMap for controls
- GDScript unless the project already uses C#

Any prior React/Vite/TypeScript/browser wording from older specs is obsolete. Preserve the game design intent and implement with Godot scenes, nodes, resources, signals, themes, and scripts.

---

# Purpose

Previous phases built the starter loop and deepened item identity:

- Exploration
- Combat
- Classes
- Skills
- Talents
- Item discovery
- Attunement
- Curses
- Ring souls
- Item resonances
- Item merging
- UI cleanup

Phase 10 expands the game beyond the starter zone.

The player currently has a working map and several systems, but they need somewhere new to go where those systems matter. This phase adds a second zone, zone transitions, environmental hazards, stronger enemies, a new quest chain, and content that uses ring souls/resonance/item discovery naturally.

This should feel like the first step from prototype arena into actual adventure structure.

---

# Primary Goal

Add a second playable zone connected to Elder Road Outskirts, including transition mechanics, new encounters, environmental hazards, new loot placement, and a new quest chain that uses existing class, item, ring soul, and resonance systems.

The player should be able to:

1. Complete or partially complete Elder Road Outskirts.
2. Unlock access to a second zone.
3. Transition between zones.
4. Explore the new zone map.
5. Encounter environmental hazards.
6. Fight stronger enemies.
7. Use existing skills, gear, ring soul effects, and resonances meaningfully.
8. Discover at least one zone-specific item or resonance hint.
9. Complete a new zone quest chain.
10. Return to the previous zone without losing current run state.

---

# Non-Goals

Do **not** implement in this phase:

- Full world map
- More than one new zone
- Procedural generation
- Save/load persistence unless already present
- Shops/vendors
- Crafting economy
- New character classes
- Large talent tree expansion
- Multiple new ring souls
- Full NPC dialogue system
- Complex pathfinding
- Animated character movement across tiles
- Multiplayer

This phase should add one good new zone, not a continent wearing a fake mustache.

---

# Design Pillars

## 1. The World Expands, But Stays Understandable

The player should clearly understand how to move between zones and what changed.

## 2. Environmental Hazards Matter

The new zone should introduce danger that is not just another enemy health bar.

## 3. Existing Systems Should Pay Off

Ring souls, item resonance, class skills, equipment, and item discovery should have natural places to matter.

## 4. Content Should Be Data-Driven

Zones, transitions, hazards, enemies, and quests should be defined in data where practical.

## 5. Do Not Break the Starter Zone

Elder Road Outskirts remains playable and should serve as the first zone.

---

# Deliverables

## 1. Multi-Zone State Model

### Requirement

Extend the game state to support multiple zones and zone transitions.

Current implementation likely assumes a single active zone. Refactor carefully so existing Elder Road Outskirts still works.

## Required State Additions

Add or adapt state to support:

```gdscript
{
    "current_zone_id": "elder_road_outskirts",
    "zone_states": {
        "elder_road_outskirts": {
            "player_position": {"x": 0, "y": 0},
            "visited_tile_ids": [],
            "cleared_encounter_ids": [],
            "opened_container_ids": [],
            "activated_shrine_ids": [],
            "completed_hazard_ids": []
        },
        "ashwood_glen": {
            "player_position": {"x": 0, "y": 0},
            "visited_tile_ids": [],
            "cleared_encounter_ids": [],
            "opened_container_ids": [],
            "activated_shrine_ids": [],
            "completed_hazard_ids": []
        }
    },
    "unlocked_zone_ids": ["elder_road_outskirts"]
}
```

Use the project’s existing naming conventions. If position is already stored in `player`, decide whether to move it into zone state or keep `player.position` synchronized. Prefer clear ownership.

## Recommended Ownership

- `GameState.current_zone_id` owns which zone is active.
- Each zone state owns last known player position for that zone.
- Player state owns character progression, inventory, equipment, class, skills, talents, etc.

## Required Helpers

```gdscript
func get_current_zone(game_state) -> Dictionary
func get_current_zone_state(game_state) -> Dictionary
func get_player_zone_position(game_state) -> Dictionary
func set_player_zone_position(game_state, zone_id: String, position: Dictionary) -> Dictionary
func is_zone_unlocked(game_state, zone_id: String) -> bool
func unlock_zone(game_state, zone_id: String) -> Dictionary
```

### Acceptance Criteria

- Game state supports more than one zone.
- Elder Road Outskirts still loads correctly.
- Current zone ID is tracked.
- Each zone preserves visited/cleared/opened/activated state.
- Returning to a previous zone restores last known position and state.

---

# 2. Zone Transition System

## Requirement

Add explicit zone transition tiles and transition actions.

## Zone Transition Definition

Extend zone tile definitions with optional transition data:

```gdscript
{
    "id": "elder_stone",
    "name": "Elder Stone",
    "kind": "objective",
    "position": {"x": 4, "y": 3},
    "transition": {
        "target_zone_id": "ashwood_glen",
        "target_position": {"x": 0, "y": 0},
        "requires": [
            {"type": "quest_stage_complete", "quest_id": "the_elder_road", "stage_id": "break_the_ambush"}
        ],
        "label": "Enter Ashwood Glen"
    }
}
```

## Transition Behavior

When the player is on a transition tile:

- Location details show transition action.
- Action dock shows transition button.
- If requirements are met, button is enabled.
- If requirements are unmet, button is disabled with reason.
- On transition:
  - Save current zone position/state.
  - Set current zone to target zone.
  - Set player position in target zone.
  - Add transition message.
  - Optional brief fade or transition animation.

## Required Actions

Add action:

```gdscript
{ "type": "TRANSITION_ZONE", "target_zone_id": String }
```

Or equivalent method:

```gdscript
func transition_to_zone(target_zone_id: String, target_position: Dictionary) -> void
```

## Transition Message Examples

```text
You pass beyond the Elder Stone into Ashwood Glen.
```

Blocked:

```text
The Elder Stone remains cold. The road behind you is not yet secure.
```

### Acceptance Criteria

- Transition tile exists in Elder Road Outskirts.
- Transition is blocked until required condition is met.
- Transition action appears in location details/action dock.
- Player can enter Ashwood Glen after unlocking it.
- Player can return to Elder Road Outskirts from Ashwood Glen.
- Zone state persists when moving between zones.

---

# 3. New Zone: Ashwood Glen

## Requirement

Add one new zone: **Ashwood Glen**.

## Zone Theme

Ashwood Glen is a burned forest beyond the Elder Stone where old fire magic and dead roots have fused into something hostile.

It should feel like the starter road has crossed into cursed wilderness.

## Zone Description

```text
A blackened woodland where ash falls without wind. The roots remember fire, and the stones remember screams.
```

## Map Size

Use a small but meaningful map.

Recommended:

```text
5 columns x 5 rows
```

This provides slightly more depth than the starter 5x4 map without becoming a content swamp.

## Suggested Layout

```text
[Entry]      [Ash Path]    [Cinder Cache] [Charred Bend] [Smoke Shrine]
[Old Roots]  [Ember Wisp]  [Ash Path]     [Burning Thorn] [Ash Path]
[Hollow Log] [Ash Path]    [Cinder Pool]  [Ash Path]       [Glassroot]
[Wolf Den]   [Ash Path]    [Cinder Acolyte] [Broken Cairn] [Ash Path]
[Return]     [Ash Path]    [Blackened Grove] [Ash Gate]    [Cinderheart]
```

## Required Tile Types

Add/support tile kinds:

```text
entry
return
ash_path
burned_woods
cache
shrine
hazard
enemy
objective
cairn
```

## Required Locations

At minimum, implement:

1. Ashwood Entry
2. Cinder Cache
3. Smoke Shrine
4. Burning Thorn hazard
5. Cinder Pool hazard
6. Ember Wisp encounter
7. Ash Wolf Den encounter
8. Cinder Acolyte encounter
9. Broken Cairn lore/interaction
10. Cinderheart objective
11. Return Road transition

### Acceptance Criteria

- Ashwood Glen zone data exists.
- Zone renders using existing ZoneMap UI.
- Player can move around the zone.
- New tile types have readable visual states.
- Location details work for new zone tiles.
- Return transition to Elder Road Outskirts exists.

---

# 4. Environmental Hazards

## Requirement

Add environmental hazards as non-enemy dangers on map tiles.

Hazards should use existing action/location systems and message feedback.

## Hazard Definition

```gdscript
{
    "id": "burning_thorn_001",
    "name": "Burning Thorn",
    "description": "A knot of thorn-vines burns without consuming itself.",
    "trigger": "on_enter_tile",
    "repeatable": false,
    "effects": [
        {"type": "damage_player", "amount": 6},
        {"type": "message", "message_type": "warning", "text": "Burning thorn tears at you for 6 damage."}
    ],
    "mitigations": [
        {"type": "stat_check", "stat": "defense", "value": 4, "reduced_amount": 3},
        {"type": "resonance_active", "resonance_id": "coal_remembers_flame", "reduced_amount": 2}
    ]
}
```

Use simpler shape if needed, but keep it data-driven.

## Required Hazards

### Burning Thorn

- Trigger: first time entering tile.
- Effect: 6 damage.
- Mitigation: Defense 4+ reduces damage to 3.
- Message:

```text
Burning thorn lashes from the ash and tears at you for {damage} damage.
```

### Cinder Pool

- Trigger: interact action or entering tile, whichever is easier.
- Effect: player loses 5 health or 5 mana depending on class.
- Ember Sage may gain a hint from Varn/Ashen Ring if equipped.
- If Ashen Ring/Varn soul is equipped/revealed, add whisper:

```text
Varn whispers: Not water. Failed fire. Step lightly.
```

### Acceptance Criteria

- Hazards can be attached to tiles.
- Hazards trigger once unless marked repeatable.
- Hazard effects apply correctly.
- Hazard messages appear.
- Mitigation logic works for at least Burning Thorn.
- Hazards cannot reduce player below 1 health unless explicit death behavior is later added.

---

# 5. New Enemies

## Requirement

Add stronger enemies appropriate for Ashwood Glen.

These should be tougher than starter enemies but still beatable by a level 2–3 character.

## Enemy 1: Ember Wisp

```gdscript
{
    "id": "ember_wisp",
    "name": "Ember Wisp",
    "health": 36,
    "attack": 8,
    "defense": 0,
    "xp_reward": 30,
    "traits": ["fire", "spirit"],
    "loot_table_id": "ember_wisp_loot"
}
```

Behavior:

- Low defense, moderate attack.
- Optional: takes +2 damage from Grave Touch if simple.

## Enemy 2: Ash Wolf

```gdscript
{
    "id": "ash_wolf",
    "name": "Ash Wolf",
    "health": 42,
    "attack": 9,
    "defense": 1,
    "xp_reward": 35,
    "traits": ["beast", "ash"],
    "loot_table_id": "ash_wolf_loot"
}
```

Behavior:

- Straightforward physical threat.

## Enemy 3: Cinder Acolyte

```gdscript
{
    "id": "cinder_acolyte",
    "name": "Cinder Acolyte",
    "health": 55,
    "attack": 10,
    "defense": 2,
    "xp_reward": 50,
    "traits": ["cultist", "fire"],
    "loot_table_id": "cinder_acolyte_loot"
}
```

Behavior:

- Hardest normal enemy in the zone.
- Should be dangerous but not a boss.
- Optional: if player uses Ashen Ring, Varn may comment.

## Enemy 4: Cinderheart Guardian

Objective encounter.

```gdscript
{
    "id": "cinderheart_guardian",
    "name": "Cinderheart Guardian",
    "health": 70,
    "attack": 11,
    "defense": 2,
    "xp_reward": 75,
    "traits": ["construct", "fire", "guardian"],
    "loot_table_id": "cinderheart_guardian_loot"
}
```

Behavior:

- Acts as mini-zone boss.
- Should be beatable by a player who completed most of Ashwood Glen.

### Acceptance Criteria

- New enemies are defined in data.
- New encounters are placed in Ashwood Glen.
- Existing combat works against new enemies.
- New enemies grant XP and loot once.
- Cinderheart Guardian completes a quest objective when defeated.

---

# 6. Zone Quest Chain: Ashes Beyond the Stone

## Requirement

Add a new quest chain for Ashwood Glen.

## Quest Chain Name

**Ashes Beyond the Stone**

## Quest Description

```text
Beyond the Elder Stone, the ash woods stir with old fire. Find what burns at the heart of the glen and silence it before the road is lost.
```

## Stages

### Stage 1 — Enter the Glen

Objectives:

- Pass beyond the Elder Stone.
- Visit Ashwood Entry.

### Stage 2 — Read the Ash

Objectives:

- Investigate the Broken Cairn.
- Survive or clear the Burning Thorn.
- Discover the Cinder Pool.

### Stage 3 — Clear the Burned Path

Objectives:

- Defeat Ember Wisp.
- Defeat Ash Wolf.
- Defeat Cinder Acolyte.

### Stage 4 — Quiet the Cinderheart

Objectives:

- Reach Cinderheart.
- Defeat Cinderheart Guardian.
- Claim the Cinderheart Remnant.

## Completion Reward

- 75 XP
- 30 gold
- Cinderheart Remnant item
- Unlocks future zone hook: Ash Gate

## Quest Messages

Stage start:

```text
Quest started: Ashes Beyond the Stone.
```

Stage complete:

```text
Quest stage complete: Read the Ash.
```

Quest complete:

```text
The Cinderheart dims. Ashwood Glen grows still, but not peaceful.
```

### Acceptance Criteria

- New quest chain appears after entering Ashwood Glen.
- Quest objectives update from zone actions, hazards, and encounters.
- Quest stages complete in order.
- Completion reward is granted once.
- Quest tracker handles multiple quest chains or current-zone quest focus cleanly.

---

# 7. New Items and Loot

## Requirement

Add zone-specific loot that supports existing item discovery/resonance systems.

## Required Item: Cinderheart Remnant

```gdscript
{
    "id": "cinderheart_remnant",
    "name": "Cinderheart Remnant",
    "type": "quest",
    "description": "A coal-red shard from the heart of Ashwood Glen. It pulses like something deciding whether to wake up.",
    "stackable": false,
    "equippable": false,
    "attunable": false
}
```

This item is a quest reward and future crafting/resonance hook.

## Required Item: Ashwood Charm

```gdscript
{
    "id": "ashwood_charm",
    "name": "Ashwood Charm",
    "unidentified_name": "Smoke-Dimmed Charm",
    "type": "trinket",
    "equipment_slot": "trinket",
    "equippable": true,
    "attunable": true,
    "max_attunement_level": 2,
    "base_stats": {"defense": 1},
    "description": "A knotted charm of black root and old ash. It smells faintly of rain that never came."
}
```

Properties:

- Identified: +1 defense.
- Attunement Level 1: Burning Thorn damage reduced by 2.
- Attunement Level 2: +1 spell power or +1 strength depending on class, if easy; otherwise +1 max mana bonus.

## Required Consumable: Ash Salve

```gdscript
{
    "id": "ash_salve",
    "name": "Ash Salve",
    "type": "consumable",
    "description": "A bitter gray salve used by road scouts to treat burns and thorn cuts.",
    "stackable": true,
    "equippable": false
}
```

Effect:

- Restore 20 health.
- Remove or reduce next hazard damage by 3 if status tracking is easy.
- If status tracking is not yet available, just heal 20.

## Loot Table Suggestions

### Cinder Cache

- Identify Scroll x1
- Ash Salve x1
- Chance/guaranteed Ashwood Charm

### Ember Wisp

- Gold 6–10
- Ash Salve chance

### Ash Wolf

- Gold 8–12
- Ash Salve chance

### Cinder Acolyte

- Gold 12–18
- Identify Scroll x1
- Ashwood Charm chance if not already found

### Cinderheart Guardian

- Cinderheart Remnant
- Gold 20
- Optional Identify Scroll x1

### Acceptance Criteria

- New items exist with stable IDs.
- Cinderheart Remnant is awarded once.
- Ashwood Charm can be found and equipped.
- Ash Salve can be used.
- Loot messages work with new items.
- Existing inventory/equipment/item discovery systems still work.

---

# 8. Ring Soul and Resonance Hooks

## Requirement

Ashwood Glen should make prior advanced systems matter without requiring them.

## Varn / Ashen Ring Hooks

If Ashen Ring or Staff of the Ashen Orator is equipped and Varn is revealed, add contextual whispers.

### On Enter Ashwood Glen

```text
Varn whispers: Ashwood. Hm. Someone here misunderstood fire with great confidence.
```

### On Cinder Pool

```text
Varn whispers: Failed fire. It curdled instead of consuming. Amateur work.
```

### On Cinder Acolyte Encounter

```text
Varn whispers: That one learned from a coward or a book. Possibly both.
```

### On Cinderheart Guardian

```text
Varn whispers: Ah. A heart that forgot the body was dead. I sympathize, unfortunately.
```

## Resonance Hooks

### Coal Remembers Flame

If active:

- Burning Thorn damage reduced by 2.
- Cinder Pool grants a discovery/hint message.

Message:

```text
Coal Remembers Flame steadies the heat around you.
```

### Staff of the Ashen Orator

If equipped:

- Ember Wisp takes +2 damage from Ember Bolt.
- Varn whisper chance on fire enemies.

## No Required Dependency

The player should be able to complete Ashwood Glen without Ashen Ring, Varn, or resonance systems. These systems enhance the zone, not hard-lock it.

### Acceptance Criteria

- Ring soul whispers trigger in Ashwood Glen when conditions are met.
- Resonance can mitigate at least one hazard.
- Advanced-system hooks do not break if player lacks required items.
- Zone is completable without advanced items.

---

# 9. UI Updates for Multiple Zones

## Requirement

Update UI to support zone transitions and multiple quest chains cleanly.

## Header

Header should show current zone name:

```text
Ashwood Glen
Ember Sage · Level 3 · XP 20/100 · Gold 42
```

## Map Panel

Map panel should re-render current zone.

## Location Details

Should show:

- Current location
- Zone transition action if present
- Hazard warning/status if tile has hazard
- Encounter/objective/container status

## Action Dock

Add/extend location action button for:

```text
Travel / Enter / Return
```

Examples:

```text
Enter Ashwood Glen
Return to Elder Road
```

## Quest Tracker

Support one of these approaches:

### Option A — Current Zone Quest Focus

Show quest chain relevant to current zone first.

### Option B — Quest Tabs

Show multiple quest chains with current active one expanded.

Recommended for Phase 10: **Option A**.

## Message Log

Add messages for:

- Zone transition
- Hazard trigger
- New quest start
- Quest stage completion

### Acceptance Criteria

- UI updates zone name after transition.
- Map changes to new zone.
- Action dock shows transition action when relevant.
- Quest tracker focuses Ashwood Glen quest while in Ashwood Glen.
- Returning to Elder Road restores correct UI and map.

---

# 10. Zone Visuals and Markers

## Requirement

Ashwood Glen should visually differ from Elder Road Outskirts.

## Required Visual Differences

- Darker/burned tile backgrounds.
- Ash/ember accent colors.
- Hazard markers.
- Objective marker for Cinderheart.
- Return transition marker.

## Suggested Marker Types

```text
hazard_marker
transition_marker
cinderheart_marker
lore_marker
```

Recommended paths:

```text
res://assets/ui/markers/hazard_marker.png
res://assets/ui/markers/transition_marker.png
res://assets/ui/markers/lore_marker.png
res://assets/zone/ash_path.png
res://assets/zone/burned_woods.png
res://assets/zone/cinder_pool.png
res://assets/zone/cinderheart.png
```

If custom assets are unavailable, use styled placeholders with stable scene/file names.

### Acceptance Criteria

- Ashwood Glen is visually distinct from Elder Road Outskirts.
- Hazard tiles are obvious.
- Transition tiles are obvious.
- Objective tile is obvious.
- Placeholder assets do not break the scene.

---

# 11. Balance Requirements

## Requirement

Ashwood Glen should assume the player is around level 2–3 after starter zone content.

## Balance Targets

- Player entering at level 1 should feel danger but not hard-lock.
- Player entering at level 2 should be challenged.
- Player with Ashen Ring/Staff/resonance should feel rewarded but not immortal.
- Hazards should matter but not be worse than enemies.

## Suggested Values

- Normal hazard damage: 5–6.
- Mitigated hazard damage: 2–3.
- New enemy XP: 30–75.
- Quest completion XP: 75.
- Player should likely reach next level by completing Ashwood Glen.

## Rest/Recovery

Smoke Shrine should restore health/mana once.

```text
Restore 30 health and 20 mana, not above max.
```

If player is struggling, Ash Salve provides recovery.

### Acceptance Criteria

- Zone is challenging but completable.
- Hazards are meaningful but not obnoxious.
- Recovery exists through shrine and consumables.
- At least one level-up is likely during/after the zone.

---

# 12. Data File Updates

## Requirement

Extend data definitions cleanly.

Recommended files to update/add:

```text
res://scripts/data/zone_defs.gd
res://scripts/data/enemy_defs.gd
res://scripts/data/item_defs.gd
res://scripts/data/loot_table_defs.gd
res://scripts/data/quest_defs.gd
res://scripts/data/hazard_defs.gd
```

If hazards can live inside zone definitions for now, that is acceptable. Extract them later if needed.

## Stable IDs

Use stable snake_case IDs:

```text
ashwood_glen
ashwood_entry
burning_thorn_001
cinder_pool_001
ember_wisp_001
ash_wolf_001
cinder_acolyte_001
cinderheart_guardian_001
ashes_beyond_the_stone
cinderheart_remnant
ashwood_charm
ash_salve
```

### Acceptance Criteria

- New IDs are stable and consistent.
- Data references resolve correctly.
- No broken item/enemy/quest references.

---

# 13. Godot Scene / Script Targets

## Requirement

Add or update scenes/scripts as needed.

## Likely Script Updates

```text
res://scripts/systems/zone.gd
res://scripts/systems/hazards.gd
res://scripts/systems/quests.gd
res://scripts/systems/combat.gd
res://scripts/systems/loot.gd
res://scripts/systems/ring_souls.gd
res://scripts/systems/item_resonance.gd
res://scripts/systems/ui_view_models.gd
```

## Likely Scene Updates

```text
res://scenes/map/ZoneMap.tscn
res://scenes/map/ZoneTile.tscn
res://scenes/map/LocationDetails.tscn
res://scenes/ui/HeaderBar.tscn
res://scenes/ui/QuestFocus.tscn
res://scenes/ui/ActionDock.tscn
```

## Optional New Scene

```text
res://scenes/ui/ZoneTransitionBanner.tscn
```

This can show a brief zone transition message/fade.

### Acceptance Criteria

- Existing scenes handle both zones without duplication.
- New hazards do not require bespoke UI scenes per hazard.
- UI view models support current zone context.

---

# 14. Testing / Verification Requirements

## Required Automated Tests If Test Setup Exists

Test pure logic where practical.

### Zone State

- Multiple zone states initialize correctly.
- Current zone is tracked.
- Zone unlock works.
- Returning to previous zone restores previous position.

### Transitions

- Transition blocked when requirements unmet.
- Transition succeeds when requirements met.
- Target zone and target position are set correctly.
- Transition message is produced.

### Hazards

- Burning Thorn triggers once.
- Burning Thorn damages player.
- Defense mitigation reduces damage.
- Hazard cannot reduce player below 1.
- Completed/triggered hazard state persists.

### Quests

- Entering Ashwood Glen starts Ashes Beyond the Stone.
- Hazard/interaction objectives complete correctly.
- Enemy defeat objectives complete correctly.
- Quest completion reward is granted once.

### Combat / Enemies

- New enemy definitions load.
- New enemies grant correct XP.
- Cinderheart Guardian completion updates quest.

### Loot

- Cinderheart Remnant awarded once.
- Ashwood Charm can be equipped.
- Ash Salve heals correctly.

### Ring/Resonance Hooks

- Varn whisper only appears when conditions met.
- Coal Remembers Flame reduces Burning Thorn damage if active.
- No hook crashes when item/ring absent.

## Required Manual Verification

Create or update:

```text
MULTI_ZONE_VERIFICATION.md
```

Checklist:

- Complete Elder Road transition requirement.
- Enter Ashwood Glen.
- Confirm header/map/quest update.
- Trigger Burning Thorn.
- Activate Smoke Shrine.
- Fight Ember Wisp.
- Fight Ash Wolf.
- Investigate Broken Cairn.
- Trigger/inspect Cinder Pool.
- Fight Cinder Acolyte.
- Reach Cinderheart.
- Defeat Cinderheart Guardian.
- Receive Cinderheart Remnant.
- Return to Elder Road Outskirts.
- Re-enter Ashwood Glen and confirm state persists.

### Acceptance Criteria

- Existing gameplay tests still pass.
- Multi-zone logic tests pass where available.
- Manual verification checklist exists.
- No single-zone assumptions remain in core movement/UI logic.

---

# 15. Implementation Plan

## Step 1 — Refactor Zone State for Multiple Zones

- Add `current_zone_id`.
- Add per-zone state map.
- Preserve Elder Road Outskirts behavior.
- Update zone helpers/selectors.

## Step 2 — Add Transition Model

- Add transition data to tiles.
- Add transition availability checks.
- Add transition action and messages.

## Step 3 — Add Ashwood Glen Zone Data

- Define 5x5 zone.
- Add all required tiles.
- Add return transition.
- Render using existing map UI.

## Step 4 — Add Hazard System

- Add hazard definitions.
- Add hazard trigger processing.
- Add Burning Thorn and Cinder Pool.
- Add mitigation handling.

## Step 5 — Add New Enemy Definitions and Encounters

- Add Ember Wisp.
- Add Ash Wolf.
- Add Cinder Acolyte.
- Add Cinderheart Guardian.
- Place encounters in Ashwood Glen.

## Step 6 — Add Ashwood Quest Chain

- Add Ashes Beyond the Stone.
- Add stages/objectives.
- Wire objectives to zone transition, hazards, interactions, and enemy defeats.

## Step 7 — Add New Items and Loot

- Add Cinderheart Remnant.
- Add Ashwood Charm.
- Add Ash Salve.
- Add loot tables.

## Step 8 — Add Ring Soul / Resonance Hooks

- Add Varn Ashwood whispers.
- Add Coal Remembers Flame hazard mitigation.
- Ensure hooks are optional and safe.

## Step 9 — Update UI View Models

- Header current zone.
- Map current zone.
- Location transition action.
- Quest focus by current zone.
- Hazard and transition markers.

## Step 10 — Add Zone Transition Presentation

- Add brief transition banner/fade if simple.
- Add transition messages.

## Step 11 — Balance Pass

- Play through Ashwood Glen with at least Ember Sage.
- Smoke test Roadwarden and Gravebound Scout.
- Tune hazard/enemy values if needed.

## Step 12 — Testing and Verification

- Add logic tests where available.
- Add `MULTI_ZONE_VERIFICATION.md`.
- Run existing checks.

---

# 16. Suggested Commit Plan

```text
1. refactor: support current zone and per-zone state
2. feat: add zone transition model and actions
3. feat: add Ashwood Glen zone data and return transition
4. feat: add environmental hazard system
5. feat: add Ashwood Glen hazards
6. feat: add Ashwood Glen enemies and encounters
7. feat: add Ashes Beyond the Stone quest chain
8. feat: add Ashwood items and loot tables
9. feat: add ring soul and resonance hooks for Ashwood Glen
10. refactor: update UI view models for multiple zones
11. feat: add zone transition presentation and messages
12. test: cover transitions hazards quests and zone state
13. docs: add multi-zone verification checklist
14. balance: tune Ashwood Glen combat and hazard values
```

---

# 17. Acceptance Criteria for Entire Phase

Phase 10 is complete when:

1. Game state supports multiple zones.
2. Elder Road Outskirts still works.
3. Ashwood Glen exists as a second zone.
4. Player can unlock Ashwood Glen from Elder Road Outskirts.
5. Player can transition into Ashwood Glen.
6. Player can return to Elder Road Outskirts.
7. Zone state persists across transitions.
8. Ashwood Glen has a 5x5 explorable map or equivalent.
9. Ashwood Glen has distinct visual presentation.
10. Environmental hazards exist and work.
11. Burning Thorn damages player and supports mitigation.
12. Cinder Pool exists as a hazard/interaction.
13. New enemies exist and are placed in the zone.
14. Cinderheart Guardian acts as zone objective encounter.
15. Ashes Beyond the Stone quest chain exists.
16. Quest objectives update from transition, interactions, hazards, and combat.
17. Quest completion grants reward once.
18. Cinderheart Remnant exists and is awarded.
19. Ashwood Charm exists and can be equipped.
20. Ash Salve exists and can be used.
21. Ring soul whispers can trigger in Ashwood Glen when conditions are met.
22. Coal Remembers Flame can mitigate at least one hazard if active.
23. UI correctly updates header/map/location/quest/action dock by current zone.
24. Manual multi-zone verification checklist exists.
25. Existing combat, inventory, item discovery, resonance, ring soul, and UI systems still work.

---

# 18. Future Phase Hooks

After Phase 10, strong next phases include:

## Candidate A — Additional Ring Souls

- Add 2–3 more soul-bound rings.
- Let different ring personalities react to Ashwood Glen.
- Add soul conflict if multiple soul items exist later.

## Candidate B — Expanded Encounter Presentation

- Enemy cards.
- Combat log upgrades.
- Floating damage text.
- Stronger hit and spell feedback.
- Mini-boss presentation for Cinderheart Guardian.

## Candidate C — Ash Gate / Third Zone

- Use Cinderheart Remnant to open Ash Gate.
- Add a more dangerous third zone.
- Introduce elite enemy modifiers.

## Candidate D — Camp / Rest / Preparation System

- Add camp upgrades.
- Add rest preparation choices.
- Add limited consumable management between zones.

Do not implement these during Phase 10. Add one strong second zone first. The game needs legs before it gets tap shoes.

---

# 19. Definition of Done

Phase 10 is done when EldersCourage no longer feels like a single-map prototype.

The player should secure Elder Road Outskirts, pass beyond the Elder Stone, enter Ashwood Glen, survive hazards, fight stronger enemies, complete a new quest chain, claim the Cinderheart Remnant, and return to the road with the sense that the world is opening up.

The game should still be small.

But now it should have a horizon.
