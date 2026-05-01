# EldersCourage — Phase 9 SPEC.md

## Phase Name

**Phase 9: Item Resonance, Synergies, Merging, and Dangerous Combinations**

## Canonical Implementation Target

This is a **Godot project**.

All implementation should use Godot-native systems:

* Godot 4.x
* `.tscn` scenes
* Control nodes for UI
* Resource files, dictionaries, or lightweight GDScript data definitions
* Autoloads where appropriate
* Signals for game events and UI updates
* Tween / AnimationPlayer for feedback
* InputMap for controls
* GDScript unless the project already uses C#

Any older React/Vite/TypeScript/browser wording from prior specs is obsolete. Preserve design intent; implement with Godot scenes, nodes, resources, signals, themes, and scripts.

---

# Purpose

Previous phases established exploration, combat, classes, skills, talents, item discovery, attunement, curses, UI cleanup, and the first Ring Soul.

Phase 9 adds another defining EldersCourage idea:

**Items are not isolated stat cards. Some items react to each other. Some resonate. Some awaken hidden properties. Some can be merged. Some combinations are safe, some are powerful, and some are impressively bad decisions.**

This phase introduces item synergies and merging in a controlled, data-driven way.

The goal is not a giant crafting system yet. The goal is a first playable version where the player can discover that certain pieces of equipment behave differently together and that some artifacts can be fused or awakened into new forms.

No gems. No sockets. Those remain locked in the Design Goblin Pit, where they belong.

---

# Primary Goal

Implement a small, deterministic item resonance system that detects meaningful item combinations, reveals synergy effects, supports at least one item merge, and introduces the risk that some combinations produce curses or unstable effects.

The player should be able to:

1. Equip two or more items that resonate.
2. See a hinted or discovered synergy.
3. Reveal explicit synergies through identification, attunement, or use.
4. Trigger a hidden synergy through combat or skill use.
5. Gain a beneficial effect from a discovered synergy.
6. Encounter at least one cursed or unstable synergy.
7. Merge at least one valid item pair into a new item.
8. See clear UI feedback for available, discovered, locked, and dangerous combinations.
9. Understand that not every combination is safe.

---

# Non-Goals

Do **not** implement in this phase:

* Full crafting economy
* Crafting materials
* Gems or sockets
* Procedural affix generation
* Vendor crafting stations
* Large recipe database
* Random recipe discovery tables
* Full alchemy system
* Multiple merge tiers
* Destructive item enchanting beyond the required examples
* Save/load persistence unless already present
* Multiplayer trading

This phase should introduce the first resonance and merge loop, not turn the game into Spreadsheet Blacksmith Simulator 9000.

---

# Design Pillars

## 1. Synergy Is Discovery

Some combinations should be obvious, some hinted, and some discovered only through use.

## 2. Merging Is Rare and Meaningful

Merging should feel like a special event, not inventory housekeeping.

## 3. Risk Matters

Some combinations should carry curses, instability, or tradeoffs.

## 4. Data-Driven Rules

Synergies and merges should be defined in data, not scattered through UI button callbacks.

## 5. UI Must Be Clear

The player needs to understand whether they are seeing a known synergy, a possible resonance, or a dangerous unknown.

---

# Deliverables

## 1. Item Resonance Data Model

### Requirement

Add a system for defining item synergies between equipped or owned items.

Recommended files:

```text
res://scripts/types/item_resonance_types.gd
res://scripts/data/item_resonance_defs.gd
res://scripts/systems/item_resonance.gd
res://scripts/systems/item_merging.gd
res://scenes/ui/ResonancePanel.tscn
res://scenes/ui/MergePanel.tscn
```

Use existing project paths if different.

## Core Concepts

A resonance is a relationship between two or more items.

A resonance may be:

* Visible immediately
* Hinted only
* Hidden until triggered
* Locked behind attunement
* Locked behind identification
* Locked behind player level
* Beneficial
* Cursed
* Unstable

## Suggested Resonance Definition Shape

```gdscript
const ITEM_RESONANCES := {
    "ashen_ring_ember_staff": {
        "id": "ashen_ring_ember_staff",
        "name": "Coal Remembers Flame",
        "description": "The Ashen Ring feeds old fire through the Ember Staff.",
        "required_item_ids": ["ashen_ring", "ember_staff"],
        "required_equipped_slots": ["trinket", "weapon"],
        "visibility": "hinted",
        "discovery_requirements": [
            {"type": "equip_together"},
            {"type": "skill_use", "skill_id": "ember_bolt"}
        ],
        "effects": [],
        "cursed": false,
        "unstable": false
    }
}
```

## Required Enums / Constants

Use strings or constants consistently:

```gdscript
enum ResonanceVisibility {
    VISIBLE,
    HINTED,
    HIDDEN,
    LOCKED_BY_IDENTIFY,
    LOCKED_BY_ATTUNEMENT,
    LOCKED_BY_LEVEL
}
```

If using dictionaries, string values are acceptable:

```text
visible
hinted
hidden
locked_by_identify
locked_by_attunement
locked_by_level
```

## Resonance State

Track discovered/triggered resonance state globally or per player run:

```gdscript
{
    "discovered_resonance_ids": [],
    "triggered_resonance_ids": [],
    "rejected_resonance_ids": [],
    "merge_recipe_ids_discovered": []
}
```

### Acceptance Criteria

* Resonances are data-driven.
* Resonance state is tracked separately from item definitions.
* Existing items still work if they have no resonances.
* System can check equipped items for active resonances.
* System can check inventory for possible merge recipes.

---

# 2. Resonance Effect Model

## Requirement

Add effects that activate only when a resonance is active and discovered, unless explicitly designed as hidden/cursed.

## Effect Types

Support these effect types for Phase 9:

```text
stat_bonus
stat_penalty
skill_damage_bonus
skill_cost_modifier
basic_attack_damage_bonus
curse_health_cost
message_only
unlock_merge_recipe
```

## Suggested Effect Shape

```gdscript
{
    "type": "skill_damage_bonus",
    "skill_id": "ember_bolt",
    "amount": 2
}
```

## Activation Rules

* Revealed beneficial resonances apply while required items are equipped.
* Revealed cursed resonances apply while required items are equipped.
* Hidden cursed resonances may trigger and reveal on use.
* Resonance effects stop applying when required items are unequipped.
* Merged items may permanently inherit or transform resonance effects according to recipe rules.

## Required Helpers

```gdscript
func get_active_resonances(game_state) -> Array
func get_discovered_active_resonances(game_state) -> Array
func get_hidden_triggerable_resonances(game_state, trigger: String) -> Array
func get_resonance_effects(game_state) -> Array
func apply_resonance_effects_to_stats(game_state, base_stats: Dictionary) -> Dictionary
func get_resonance_skill_damage_bonus(game_state, skill_id: String) -> int
func get_resonance_skill_cost_modifier(game_state, skill_id: String) -> int
```

### Acceptance Criteria

* Active discovered resonances modify stats/skills correctly.
* Hidden resonances do not reveal/apply unless rules say so.
* Unequipping required items disables the resonance.
* Effects are integrated into existing stat and combat selectors.

---

# 3. Required Resonances

## Requirement

Implement at least four resonances.

Two should be beneficial. One should be hidden/discovered through use. One should be cursed or unstable.

---

## Resonance 1 — Coal Remembers Flame

### Required Items

* Ashen Ring
* Ember Staff

### Theme

Varn recognizes the Ember Staff as a crude but acceptable conduit.

### Visibility

Hinted when both items are equipped.

### Discovery

Discovered after player uses Ember Bolt while both items are equipped.

### Effect

* Ember Bolt deals +2 damage.
* If Breath for Flame bargain was accepted, add an additional +1 damage.

### Message on Discovery

```text
The Ashen Ring warms around the Ember Staff's rhythm. Resonance discovered: Coal Remembers Flame.
```

### Varn Whisper

```text
There. The staff is inelegant, but even a shovel may conduct lightning if history is desperate.
```

### Acceptance Criteria

* Equipping Ashen Ring + Ember Staff creates a hinted resonance.
* Using Ember Bolt reveals the resonance.
* Ember Bolt receives damage bonus while both items remain equipped.
* Removing either item disables the bonus.

---

## Resonance 2 — Road Oath Tempered

### Required Items

* Roadwarden's Notched Blade
* Roadwarden Vest

### Theme

Old road gear recognizes old road duty.

### Visibility

Visible if both items are identified.

### Discovery

Discovered immediately when both are equipped and identified.

### Effect

* +1 Defense
* Guarded Strike deals +1 damage

### Message on Discovery

```text
The blade and vest settle into the same old oath. Resonance discovered: Road Oath Tempered.
```

### Acceptance Criteria

* Resonance appears when both items are equipped.
* Requires both items to be identified.
* Defense bonus appears in character summary.
* Guarded Strike damage bonus applies.

---

## Resonance 3 — Grave Thread

### Required Items

* Whisperthread Cloak
* Scout Knife

### Theme

The cloak bends sound around the knife hand.

### Visibility

Hidden.

### Discovery

Discovered after the Gravebound Scout defeats an enemy while both items are equipped.

Other classes may discover it after two enemy defeats with both items equipped.

### Effect

* Piercing Shot deals +2 damage.
* Grave Touch heals +1 additional health.

### Message on Discovery

```text
The Whisperthread Cloak tightens as the blade falls silent. Resonance discovered: Grave Thread.
```

### Acceptance Criteria

* Hidden until triggered by enemy defeat.
* Gravebound Scout discovers it faster.
* Effects apply only while both items are equipped.
* Does not reveal from merely viewing inventory.

---

## Resonance 4 — Breath Debt

### Required Items

* Ashen Ring
* Elder Glass Charm

### Theme

The charm clarifies Varn's hunger too well.

### Visibility

Hidden cursed resonance.

### Discovery

Triggers when player uses any skill while both items are equipped and Ashen Ring's Blood Price curse has already been revealed.

### Effect

* Skill costs 1 less mana.
* Skill use costs +1 additional health from Blood Price.

### Message on Discovery

```text
The Elder Glass Charm sharpens the ring's hunger. Cursed resonance revealed: Breath Debt.
```

### Varn Whisper

```text
Efficiency always requires sacrifice. Preferably yours.
```

### Acceptance Criteria

* Hidden until triggered.
* Reveals as cursed resonance.
* Mana cost reduction applies.
* Additional health cost applies.
* Player cannot be reduced below 1 health by this health cost.

---

# 4. Resonance Discovery Rules

## Requirement

Resonance discovery should happen through gameplay events, not manual player guessing alone.

## Supported Discovery Triggers

```text
equip_together
identify_item
attunement_level
skill_use
enemy_defeated
curse_trigger
player_level
location_entered
```

For Phase 9, implement at least:

* equip_together
* skill_use
* enemy_defeated
* curse_trigger

## Discovery Processing Hooks

Call resonance processing after:

* Item equipped
* Item identified
* Skill used
* Enemy defeated
* Curse triggered
* Attunement level changed

## Required Helpers

```gdscript
func process_resonance_trigger(game_state, trigger: String, context: Dictionary = {}) -> Dictionary
func discover_resonance(game_state, resonance_id: String) -> Dictionary
func is_resonance_discovered(game_state, resonance_id: String) -> bool
func can_discover_resonance(game_state, resonance_def: Dictionary, trigger: String, context: Dictionary = {}) -> bool
```

### Acceptance Criteria

* Resonances are discovered automatically from gameplay triggers.
* Discovery messages appear once.
* Trigger conditions are testable.
* Discovery does not happen accidentally from unrelated actions.

---

# 5. Resonance UI

## Requirement

Add a UI panel or section showing known and hinted item resonances.

Recommended scene:

```text
res://scenes/ui/ResonancePanel.tscn
```

This may be accessed from:

* Inventory panel
* Character/equipment panel
* A new `Resonance` button in inventory/equipment details
* Item detail panel when selecting an item involved in a resonance

## Resonance UI Sections

### Active Resonances

Shows discovered active resonances from currently equipped items.

Example:

```text
Coal Remembers Flame
Ashen Ring + Ember Staff
Ember Bolt deals +2 damage.
```

### Hinted Resonances

Shows partial hints when requirements are partially known.

Example:

```text
Something stirs between Ashen Ring and Ember Staff.
Use flame through the staff to understand it.
```

### Cursed Resonances

Shows revealed cursed resonances clearly.

Example:

```text
Cursed Resonance: Breath Debt
Skills cost 1 less mana, but Blood Price costs 1 more health.
```

### Locked / Unknown

Do not show all hidden resonances. Only show hints when the resonance visibility says `hinted` or when enough discovery requirements have been met.

## Visual Requirements

* Beneficial resonance: gold/green accent
* Hinted resonance: muted blue/gold accent
* Cursed resonance: purple/red accent
* Inactive discovered resonance: muted/gray

### Acceptance Criteria

* Player can see active discovered resonances.
* Player can see hinted resonances without full spoilers.
* Cursed resonances are clearly marked.
* Hidden resonances remain hidden until discovered.
* UI uses Phase 7 styling patterns.

---

# 6. Item Detail Integration

## Requirement

Item details should show resonance-related information for selected items.

When selecting an item, show:

* Active resonances involving this item
* Discovered inactive resonances involving this item
* Hints involving this item if visible
* Merge recipes involving this item if discovered

## Example: Ashen Ring Detail

```text
Resonance
- Coal Remembers Flame: Active with Ember Staff
- Breath Debt: Cursed, active with Elder Glass Charm
```

Before discovery:

```text
Resonance
Something in this ring reacts to old fire.
```

## Acceptance Criteria

* Item details show relevant resonance information.
* Hidden resonances are not spoiled.
* Active/inactive status is clear.
* UI remains readable.

---

# 7. Item Merge Data Model

## Requirement

Add a small item merge system.

A merge consumes two or more items and produces a new item or upgraded item instance.

Recommended file:

```text
res://scripts/data/item_merge_defs.gd
```

## Merge Recipe Shape

```gdscript
const ITEM_MERGE_RECIPES := {
    "ashen_staff_merge": {
        "id": "ashen_staff_merge",
        "name": "Staff of the Ashen Orator",
        "required_item_ids": ["ashen_ring", "ember_staff"],
        "required_conditions": [
            {"type": "resonance_discovered", "resonance_id": "ashen_ring_ember_staff"},
            {"type": "attunement_level", "item_id": "ashen_ring", "value": 2}
        ],
        "consumes_items": true,
        "result_item_id": "staff_of_the_ashen_orator",
        "risk": "curse_carryover",
        "visibility": "hinted"
    }
}
```

## Merge Visibility

Recipes may be:

```text
visible
hinted
hidden
discovered
```

For Phase 9:

* Show recipe hints once required resonance is discovered.
* Do not reveal hidden merge recipes before discovery.

## Required Helpers

```gdscript
func get_available_merge_recipes(game_state) -> Array
func get_hinted_merge_recipes(game_state) -> Array
func can_merge_items(game_state, recipe_id: String) -> bool
func merge_items(game_state, recipe_id: String) -> Dictionary
func discover_merge_recipe(game_state, recipe_id: String) -> Dictionary
```

### Acceptance Criteria

* Merge recipes are data-driven.
* Player can see available discovered/hinted recipes.
* Merge validation checks required items and conditions.
* Merge consumes required items if recipe says so.
* Merge creates result item instance.
* Merge messages are shown.

---

# 8. Required Merge Recipe

## Merge Recipe 1 — Staff of the Ashen Orator

### Required Items

* Ashen Ring
* Ember Staff

### Required Conditions

* Coal Remembers Flame resonance discovered.
* Ashen Ring attunement level at least 2.
* Varn's soul name revealed.

### Result Item

```text
Staff of the Ashen Orator
```

### Item Type

Weapon

### Equipment Slot

Weapon

### Theme

The ring's ember-soul is partially bound into the staff, creating a stronger but riskier caster weapon.

### Merge Behavior

* Consumes Ember Staff.
* Consumes Ashen Ring as an equipped trinket/item.
* Creates Staff of the Ashen Orator.
* Staff inherits Varn soul binding.
* Trinket slot becomes empty.
* Weapon slot equips Staff of the Ashen Orator automatically.
* Blood Price curse carries over to the staff.
* The player receives a major message and Varn whisper.

## Result Item Definition

```gdscript
{
    "id": "staff_of_the_ashen_orator",
    "name": "Staff of the Ashen Orator",
    "type": "weapon",
    "equipment_slot": "weapon",
    "equippable": true,
    "attunable": true,
    "max_attunement_level": 4,
    "soul_id": "varn_ashen_orator",
    "base_stats": {
        "spell_power": 4,
        "max_mana_bonus": 10
    },
    "description": "A staff threaded with black-gold ash. Varn's voice moves through it more easily now. That is not necessarily comforting."
}
```

## Result Properties

### Orator's Flame

* Ember Bolt +4 damage.
* Revealed immediately on merge.

### Borrowed Breath

* Kindle restores +5 additional mana.
* Revealed at staff attunement level 1.

### Blood Price Carried

* Skill use costs 2 health.
* Revealed immediately if Ashen Ring curse was revealed.
* If not revealed before merge, triggers on first skill use.

### Acceptance Criteria

* Recipe appears only after required conditions are met.
* Merge consumes Ashen Ring and Ember Staff.
* Result item is created and equipped as weapon.
* Varn soul state transfers or is reattached to result item.
* Curse carryover works.
* Ember Bolt bonus applies from new staff.

---

# 9. Merge UI

## Requirement

Add a merge interface.

Recommended scene:

```text
res://scenes/ui/MergePanel.tscn
```

This panel may be accessed from:

* Inventory panel
* Resonance panel
* Item details when merge is available

## Merge Panel Must Show

* Recipe name
* Required items
* Required conditions
* Result item preview
* Known risks
* Merge button
* Cancel/close button

## Example

```text
Staff of the Ashen Orator

Requires:
✓ Ashen Ring
✓ Ember Staff
✓ Coal Remembers Flame discovered
✓ Ashen Ring Attunement 2

Result:
Staff of the Ashen Orator
+4 Spell Power
+10 Mana
Known Risk: Blood Price carries forward.

[Merge] [Cancel]
```

## Confirmation

Merging should require confirmation.

Before final merge:

```text
This will consume Ashen Ring and Ember Staff. Varn seems delighted. Continue?
```

### Acceptance Criteria

* Merge panel shows clear requirements.
* Missing requirements are visible.
* Merge button disabled until requirements are met.
* Confirmation is required.
* Result and risk are communicated.

---

# 10. Merge Event Presentation

## Requirement

Merging should feel significant.

Use a lightweight Godot presentation:

* Dim background or use existing panel overlay.
* Show merge result card.
* Play a short glow/tween effect.
* Add message log entries.
* Trigger Varn whisper if soul-related.

## Required Messages

On merge start:

```text
Ash circles the Ember Staff. The ring begins to speak in sparks.
```

On merge complete:

```text
Merge complete: Staff of the Ashen Orator has awakened.
```

Varn whisper:

```text
Ah. At last, a proper throat for fire.
```

### Acceptance Criteria

* Merge feels more important than normal equip/use.
* Presentation is brief and non-blocking after completion.
* Result item is easy to understand.

---

# 11. Dangerous Combination Handling

## Requirement

Support unstable or cursed combinations.

For Phase 9, implement one cursed resonance: Breath Debt.

## Unstable/Cursed Rules

* Cursed resonance can be hidden until triggered.
* Cursed resonance should reveal with an alarming message.
* Cursed resonance effects should be visible after reveal.
* Cursed resonance may still include upside.

## Required Helper

```gdscript
func process_cursed_resonance_trigger(game_state, trigger: String, context: Dictionary = {}) -> Dictionary
```

## Health Cost Safety

Any health-cost resonance or curse should not reduce the player below 1 health in Phase 9 unless explicit death-by-curse is later implemented.

### Acceptance Criteria

* Breath Debt reveals on correct trigger.
* Breath Debt has upside and downside.
* UI clearly marks it as cursed.
* Health cost cannot directly kill player.

---

# 12. Ring Soul Integration

## Requirement

Resonance and merging should interact with Ring Souls where appropriate.

## Varn-Specific Interactions

### Coal Remembers Flame

Varn whisper on discovery.

### Breath Debt

Varn whisper on cursed reveal.

### Staff Merge

* Varn soul transfers from Ashen Ring to Staff of the Ashen Orator.
* Varn trust +1 if player previously accepted Breath for Flame.
* Varn trust unchanged if not.
* Varn whisper on merge.

## Soul Transfer Rules

When merging Ashen Ring into Staff of the Ashen Orator:

* Existing Varn memory reveal state should carry over.
* Existing trust should carry over.
* Seen whispers should carry over.
* Bargain history should carry over.
* Attunement may either:

  * carry over partially, or
  * reset for the new item while soul memories remain.

Recommended:

```text
Soul state carries over.
Item attunement resets to level 0 for the new staff.
```

This lets the new weapon have its own attunement progression.

### Acceptance Criteria

* Varn does not duplicate as two soul states after merge.
* Soul history carries over.
* Ashen Ring item instance is removed.
* Staff has Varn soul binding.
* RingSoulPanel works for staff if selected.

---

# 13. Combat Integration

## Requirement

Resonance effects must affect existing combat calculations.

## Integration Points

### Skill Damage

Add resonance bonuses to skill damage calculation:

```text
base skill damage
+ player stats scaling
+ item property bonuses
+ talent bonuses
+ ring soul bargain bonuses
+ resonance bonuses
```

Do not double-apply bonuses.

### Skill Cost

Apply cost modifiers:

```text
final cost = max(0, base cost + item modifiers + resonance modifiers + talent modifiers)
```

### Health Costs

Process health-cost curses/resonances after skill validation but before or during skill resolution.

Health cost cannot reduce below 1 for Phase 9.

### Acceptance Criteria

* Coal Remembers Flame modifies Ember Bolt damage.
* Breath Debt modifies skill mana cost and health cost.
* Staff of the Ashen Orator modifies Ember Bolt damage.
* Bonuses are not duplicated.
* Existing skills still work without resonances.

---

# 14. Item Discovery Integration

## Requirement

Resonance should respect item identification/discovery rules.

## Rules

* Identified items may reveal visible resonances.
* Unidentified items should not reveal exact resonance names unless discovered through use.
* Hinted resonance may use vague language.
* Cursed resonance should remain hidden until triggered.
* Merge recipes should not fully reveal until preconditions are met.

## Examples

Before discovery:

```text
Something in the Ashen Ring reacts to old fire.
```

After discovery:

```text
Coal Remembers Flame
Ashen Ring + Ember Staff
Ember Bolt deals +2 damage.
```

Cursed after reveal:

```text
Cursed Resonance: Breath Debt
Skills cost 1 less mana, but Blood Price costs 1 more health.
```

### Acceptance Criteria

* Resonance UI does not spoil hidden combinations.
* Discovery state updates after correct gameplay events.
* Identifying items can enable visible resonance discovery.
* Cursed resonances remain hidden until triggered.

---

# 15. Data Additions

## Requirement

Add or update item definitions needed for Phase 9.

## Required Items

Existing:

* Ashen Ring
* Ember Staff
* Roadwarden's Notched Blade
* Roadwarden Vest
* Whisperthread Cloak
* Scout Knife
* Elder Glass Charm

New:

* Staff of the Ashen Orator

## Optional Future Stub Items

Do not implement unless useful for tests/placeholders:

* Graveglass Needle
* Oathbound Buckler
* Cinder-Script Wraps

### Acceptance Criteria

* Required items exist and have stable IDs.
* New staff item exists.
* Resonance definitions reference valid item IDs.
* Merge recipe references valid result item ID.

---

# 16. UI / UX Acceptance Checklist

Phase 9 UI is complete when:

1. Inventory or equipment UI shows active discovered resonances.
2. Hinted resonances are shown without full spoilers.
3. Cursed resonances are clearly marked after reveal.
4. Item details show resonances involving the selected item.
5. Merge panel shows required items and conditions.
6. Merge button is disabled until conditions are met.
7. Merge confirmation is required.
8. Merge result is clearly shown.
9. Resonance discovery messages are distinct.
10. Varn whispers appear for Varn-related resonances.
11. UI remains consistent with the Phase 7 style.

---

# 17. Testing / Verification Requirements

## Required Automated Tests If Test Setup Exists

Test pure logic where practical.

### Resonance Detection

* Active resonance detected when required items are equipped.
* Resonance inactive when one item is missing.
* Resonance inactive when one item is unequipped.
* Visible resonance requires identification if configured.

### Resonance Discovery

* Coal Remembers Flame discovered after Ember Bolt use.
* Road Oath Tempered discovered when both identified items equipped.
* Grave Thread discovered after correct enemy defeat trigger.
* Breath Debt discovered after curse trigger conditions.
* Discovery messages happen once.

### Resonance Effects

* Coal Remembers Flame adds Ember Bolt damage.
* Breath Debt reduces mana cost and increases health cost.
* Road Oath Tempered adds defense.
* Grave Thread modifies Piercing Shot and Grave Touch.
* Effects stop when required items are unequipped.

### Merge Recipes

* Staff merge unavailable before conditions.
* Staff merge available after conditions.
* Merge consumes Ashen Ring and Ember Staff.
* Merge creates Staff of the Ashen Orator.
* Result item auto-equips.
* Varn soul state transfers.

### Safety

* Health-cost resonance cannot reduce player below 1.
* No duplicate resonance effects.
* Non-resonant item combinations do nothing.

## Required Manual Verification

Create or update:

```text
ITEM_RESONANCE_VERIFICATION.md
```

Checklist:

* Equip Ashen Ring and Ember Staff.
* Use Ember Bolt.
* Confirm Coal Remembers Flame discovery.
* Confirm Ember Bolt damage increase.
* Equip Ashen Ring and Elder Glass Charm after Blood Price reveal.
* Use skill and confirm Breath Debt reveal.
* Confirm mana discount and added health cost.
* Reach Ashen Ring attunement level 2.
* Confirm Staff of the Ashen Orator merge becomes available.
* Merge items.
* Confirm Ashen Ring and Ember Staff are consumed.
* Confirm Staff is equipped.
* Confirm Varn soul state transferred.

### Acceptance Criteria

* Existing gameplay tests still pass.
* New resonance/merge logic tests pass where available.
* Manual verification checklist exists or is updated.
* No resonance feature breaks normal inventory/equipment behavior.

---

# 18. Godot Implementation Notes

## Signals

If the project uses signals, add resonance hooks to existing event flow:

```gdscript
signal item_equipped(item_instance_id)
signal item_identified(item_instance_id)
signal skill_used(skill_id)
signal enemy_defeated(enemy_id)
signal curse_triggered(item_instance_id, curse_id)
signal resonance_discovered(resonance_id)
signal merge_completed(recipe_id, result_item_instance_id)
```

Signals are optional if direct system calls are clearer.

## UI Scenes

Recommended scenes:

```text
res://scenes/ui/ResonancePanel.tscn
res://scenes/ui/ResonanceRow.tscn
res://scenes/ui/MergePanel.tscn
res://scenes/ui/MergeRequirementRow.tscn
res://scenes/ui/MergeResultCard.tscn
```

## Avoid

* Putting resonance logic inside UI buttons.
* Hard-coding item IDs in multiple places.
* Applying bonuses in more than one calculation path.
* Showing hidden recipe spoilers.

---

# 19. Implementation Plan

## Step 1 — Add Resonance Data Structures

* Create resonance definitions.
* Add resonance state to game state.
* Add helper functions for item/equipment matching.

## Step 2 — Implement Active Resonance Detection

* Detect required items in equipment.
* Detect discovered active resonances.
* Detect hinted resonances.

## Step 3 — Add Resonance Discovery Processing

* Add trigger processing for equip, skill use, enemy defeat, and curse trigger.
* Add discovery messages.
* Prevent duplicate discovery.

## Step 4 — Add Required Resonances

* Add Coal Remembers Flame.
* Add Road Oath Tempered.
* Add Grave Thread.
* Add Breath Debt.

## Step 5 — Integrate Resonance Effects

* Add stat bonuses/penalties.
* Add skill damage bonuses.
* Add skill cost modifiers.
* Add health-cost resonance handling.

## Step 6 — Add Resonance UI

* Add ResonancePanel.
* Add item detail resonance section.
* Show active/hinted/cursed states.

## Step 7 — Add Merge Recipe Model

* Add merge recipe definitions.
* Add availability checks.
* Add recipe discovery state.

## Step 8 — Add Staff of the Ashen Orator

* Add item definition.
* Add properties and soul binding.
* Add combat effects.

## Step 9 — Implement Staff Merge

* Add recipe availability.
* Add merge confirmation.
* Consume source items.
* Create/equip result item.
* Transfer Varn soul state.

## Step 10 — Add Merge UI

* Show requirements.
* Show result preview.
* Show risks.
* Confirm before merge.

## Step 11 — Add Presentation Feedback

* Add resonance discovery message styling.
* Add merge completion animation/tween.
* Add Varn whispers.

## Step 12 — Testing and Verification

* Add logic tests if available.
* Add manual verification checklist.
* Smoke test all classes.

---

# 20. Suggested Commit Plan

```text
1. feat: add item resonance definitions and state
2. feat: detect active and hinted resonances
3. feat: process resonance discovery triggers
4. feat: add first resonance definitions
5. feat: integrate resonance effects into stats and combat
6. feat: add resonance UI panel and item detail section
7. feat: add item merge recipe definitions and availability checks
8. feat: add Staff of the Ashen Orator item definition
9. feat: implement Ashen Ring and Ember Staff merge
10. feat: add merge panel confirmation and result presentation
11. feat: integrate Varn whispers and soul transfer with merge
12. test: cover resonance discovery effects and merge behavior
13. docs: add item resonance verification checklist
```

---

# 21. Acceptance Criteria for Entire Phase

Phase 9 is complete when:

1. Item resonances are data-driven.
2. Resonance state tracks discovered and triggered combinations.
3. Equipping Ashen Ring + Ember Staff can reveal Coal Remembers Flame.
4. Coal Remembers Flame improves Ember Bolt while active.
5. Road Oath Tempered works for Roadwarden gear.
6. Grave Thread works for Scout gear.
7. Breath Debt reveals as a cursed resonance.
8. Breath Debt has both upside and downside.
9. Resonance effects stop when required items are unequipped.
10. Resonance UI shows active discovered resonances.
11. Hinted resonances do not fully spoil hidden effects.
12. Item details show relevant resonance information.
13. Merge recipe model exists.
14. Staff of the Ashen Orator item exists.
15. Ashen Ring + Ember Staff can merge after required conditions.
16. Merge consumes required items.
17. Merge creates and equips Staff of the Ashen Orator.
18. Varn soul state transfers to the new staff.
19. Merge requires confirmation.
20. Merge and resonance messages are clear.
21. Existing combat, inventory, ring soul, item discovery, and UI systems still work.
22. Manual verification checklist exists or is updated.

---

# 22. Future Phase Hooks

After Phase 9, strong next phases include:

## Candidate A — Multi-Zone Expansion

* Add second zone.
* Add zone transition flow.
* Add stronger enemies and environmental hazards.
* Let resonances matter outside the first map.

## Candidate B — Additional Ring Souls

* Add more rings with different personalities.
* Add conflicting soul interactions.
* Add ring-specific synergies.

## Candidate C — Expanded Merge Network

* Add several more merge recipes.
* Add unstable merges.
* Add scroll-revealed merge hints.

## Candidate D — Encounter Presentation Upgrade

* Enemy cards.
* Better hit effects.
* Floating combat text.
* Turn/encounter summary panel.

Do not implement these during Phase 9. Keep this phase focused on proving resonance and one meaningful merge.

---

# 23. Definition of Done

Phase 9 is done when the player learns that gear is not just a pile of numbers.

They should equip two items and notice something stir. They should use a skill and discover a resonance. They should feel the upside. They should find one cursed interaction and think, correctly, that maybe ancient magic is not OSHA compliant.

Then they should merge Ashen Ring and Ember Staff into Staff of the Ashen Orator and realize they did not just craft an item.

They gave Varn a better microphone.
