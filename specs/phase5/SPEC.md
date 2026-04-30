# EldersCourage — Phase 5 SPEC.md

## Phase Name

**Phase 5: Item Identity, Identification, Attunement, Curses, and Discovery**

## Purpose

Phase 4 added class identity through character classes, active skills, passive talents, cooldowns, and build choices.

Phase 5 gives items identity.

The core fantasy of EldersCourage is not just “find sword, number goes up.” That is fine, but it is also oatmeal wearing chainmail. Items in this game should feel old, dangerous, partially understood, and occasionally malicious. Some powers are obvious. Some are hidden. Some require identification. Some awaken through use. Some reveal themselves only when equipped by a sufficiently advanced character. Some are cursed.

This phase introduces the foundation for:

* Hidden item properties
* Item identification
* Attunement progress
* Level-gated item reveals
* Cursed effects
* Discovery messages
* A first pass at mysterious rings

This is not the full ring-soul system yet. It creates the machinery that later lets rings behave like trapped spellcaster souls.

---

# Primary Goal

Implement an item discovery system where equipment can have known, unknown, hidden, locked, and cursed properties. The player should be able to find mysterious items, inspect them, identify them with scrolls, equip them, reveal powers through attunement, and suffer or benefit from discovered properties.

The player should be able to:

1. Find unidentified equipment.
2. See that the item has unknown properties.
3. Use an Identify Scroll on an item.
4. Reveal one or more hidden properties.
5. Equip identified or partially identified items.
6. Build attunement through use.
7. Reveal additional properties when attunement thresholds are met.
8. Reveal properties when player level requirements are met.
9. Encounter at least one cursed item property.
10. See positive and negative item effects reflected in stats/combat.
11. Receive clear discovery messages when item powers are revealed.

---

# Recommended Target

Continue using the current browser implementation.

Expected stack:

* Vite
* React
* TypeScript
* Existing Phase 4 state/reducer/systems structure
* Existing item, equipment, inventory, combat, quest, and message systems

Do not rewrite inventory or equipment. Extend them.

---

# Non-Goals

Do **not** implement yet:

* Fully procedural item generation
* Full loot rarity economy
* Vendor appraisal
* Item crafting
* Item merging/synergy system
* Full ring souls with dialogue trees
* Permanent curse removal economy
* Save/load persistence
* Complex affix weighting
* Item trading
* Deep durability/repair
* Socket/gem systems

No sockets. No gems. They have been banished to the Design Goblin Pit.

---

# Deliverables

## 1. Item Discovery Model

### Requirement

Extend item data to support properties that may be visible, hidden, locked, identified, revealed through attunement, or cursed.

Create or update:

```text
src/game/types/items.ts
src/game/systems/itemDiscovery.ts
src/game/systems/attunement.ts
src/game/data/items.ts
```

## Required Types

```ts
export type ItemKnowledgeState =
  | "known"
  | "unidentified"
  | "partially_identified"
  | "identified";

export type ItemPropertyVisibility =
  | "visible"
  | "hidden"
  | "locked_by_level"
  | "locked_by_attunement";

export type ItemPropertyKind =
  | "stat_modifier"
  | "combat_modifier"
  | "skill_modifier"
  | "resource_modifier"
  | "curse"
  | "lore";

export interface ItemRevealRequirement {
  type: "identify" | "player_level" | "attunement" | "equip" | "combat_use";
  value?: number;
}

export interface ItemProperty {
  id: string;
  name: string;
  description: string;
  kind: ItemPropertyKind;
  visibility: ItemPropertyVisibility;
  revealed: boolean;
  cursed: boolean;
  requirements: ItemRevealRequirement[];
  effects: ItemEffect[];
}

export interface ItemEffect {
  type:
    | "stat_bonus"
    | "stat_penalty"
    | "damage_bonus"
    | "damage_penalty"
    | "mana_cost_modifier"
    | "health_cost"
    | "xp_modifier"
    | "gold_modifier";
  stat?: keyof PlayerStats;
  skillId?: string;
  amount: number;
}

export interface ItemAttunementState {
  itemInstanceId: string;
  points: number;
  level: number;
  revealedThresholds: number[];
}

export interface ItemInstance {
  instanceId: string;
  itemId: string;
  quantity: number;
  knowledgeState: ItemKnowledgeState;
  identifiedPropertyIds: string[];
  revealedPropertyIds: string[];
  attunement?: ItemAttunementState;
}
```

### Important Design Rule

Separate item definitions from item instances.

* `ItemDefinition` is the template: “Old Sword,” “Ashen Ring,” etc.
* `ItemInstance` is the specific copy the player owns.

This matters because two copies of the same item type may have different discovery state later.

If the existing system currently stores only `Item`, migrate carefully.

## Suggested Type Split

```ts
export interface ItemDefinition {
  id: string;
  name: string;
  type: ItemType;
  description: string;
  icon: string;
  stackable: boolean;
  equippable: boolean;
  equipmentSlot?: EquipmentSlot;
  baseStats?: ItemStats;
  properties: ItemProperty[];
  attunable: boolean;
  maxAttunementLevel?: number;
}
```

### Acceptance Criteria

* Item definitions and item instances are separate.
* Inventory can render item instances using item definitions.
* Existing known/simple items still work.
* Discovery state belongs to item instances.
* Tests cover item instance creation and lookup.

---

# 2. Knowledge States

## Requirement

Items should display differently depending on knowledge state.

## Knowledge State Behavior

### known

Normal simple item. All basic information visible.

Used for:

* Minor Health Potion
* Gold handling if modeled as item
* Basic starter gear if desired

### unidentified

The player knows the item category, but not its real name or properties.

Example display:

```text
Unidentified Ring
A strange ring humming with old power.
Properties: ???
```

### partially_identified

Some properties are known, others are still hidden/locked.

Example:

```text
Ashen Ring
+1 Spell Power
???
Requires deeper attunement
```

### identified

All properties that can be revealed by identification are known. Some may still be locked by level or attunement.

Example:

```text
Ashen Ring
+1 Spell Power
Ember skills cost 1 less mana
Locked: Attunement 2
```

## Display Rules

Inventory item card should show:

* Display name based on knowledge state
* Icon or mystery icon
* Known properties
* Unknown property placeholders
* Locked property hints when appropriate
* Curse visibility only after curse reveal unless item is fully cursed/obvious

### Acceptance Criteria

* Unidentified items do not reveal actual hidden property names/effects.
* Partially identified items show known properties and placeholders.
* Identified items show identify-revealed properties.
* Locked properties are displayed as locked/hinted, not fully revealed.
* Cursed properties remain hidden until revealed.

---

# 3. Identify Scrolls

## Requirement

Add Identify Scrolls as consumable items.

## Item Definition

```ts
{
  id: "identify-scroll",
  name: "Identify Scroll",
  type: "consumable",
  description: "Reveals hidden truths bound inside an item. Sometimes that is rude of it.",
  icon: "src/assets/items/identify-scroll.png",
  stackable: true,
  equippable: false,
  properties: [],
  attunable: false,
}
```

## Behavior

Using an Identify Scroll:

1. Player selects Identify Scroll.
2. UI enters identify-target mode.
3. Player selects an unidentified or partially identified item.
4. Scroll quantity decreases by 1.
5. One or more identify-revealable properties are revealed.
6. Item knowledge state updates.
7. Message log reports the discovery.

## Identify Target Rules

Can identify:

* `unidentified` items
* `partially_identified` items with unrevealed identify properties

Cannot identify:

* Fully known simple items
* Consumables with no hidden properties
* Items already fully identified
* Items not owned by the player

## Reveal Amount

For Phase 5:

* Identify Scroll reveals all properties whose requirement type is `identify`.
* It does not reveal properties locked by attunement or player level unless those properties also have identify requirements and the relevant lock is satisfied.

## Required Helpers

```ts
canIdentifyItem(instance: ItemInstance, definition: ItemDefinition): boolean
identifyItem(instance: ItemInstance, definition: ItemDefinition): ItemInstance
useIdentifyScroll(state: GameState, targetInstanceId: string): GameState
getUnrevealedIdentifyProperties(instance: ItemInstance, definition: ItemDefinition): ItemProperty[]
```

### Acceptance Criteria

* Identify Scroll appears in inventory.
* Using scroll requires target item selection.
* Scroll count decreases only on valid identify.
* Identifying reveals expected properties.
* Invalid targets show warning messages and do not consume scroll.
* Tests cover valid and invalid identification.

---

# 4. Attunement System

## Requirement

Add item attunement for selected equipment.

Attunement represents the player becoming spiritually/magically familiar with an item through use. It is not XP. It is item-specific discovery pressure.

## Attunement Rules

An item may be attunable if:

```ts
attunable: true
```

Attunement points are gained when:

* The item is equipped during combat victory.
* The player uses a skill affected by the item.
* The player takes damage while wearing defensive attunable gear.
* The player uses basic attack with an attunable weapon.

For Phase 5, keep it simple:

```text
Equipped attunable item gains 1 attunement point when the player wins combat.
Equipped attunable weapon gains 1 extra point when the player attacks with it.
Equipped attunable trinket gains 1 extra point when the player uses a skill.
```

## Attunement Levels

```text
Level 0: 0 points
Level 1: 2 points
Level 2: 5 points
Level 3: 9 points
```

Only levels 1 and 2 need to be reachable in Phase 5.

## Required Helpers

```ts
getAttunementLevel(points: number): number
addAttunementPoints(instance: ItemInstance, points: number): ItemInstance
processAttunementAfterCombat(state: GameState): GameState
processAttunementAfterAttack(state: GameState): GameState
processAttunementAfterSkillUse(state: GameState, skillId: string): GameState
getNewlyRevealedAttunementProperties(instance: ItemInstance, definition: ItemDefinition): ItemProperty[]
```

## Reveal Behavior

When an item reaches a required attunement level:

* Reveal matching properties.
* Add discovery message.
* If property is cursed, add a warning/cursed message.
* Apply newly revealed effect if applicable.

### Acceptance Criteria

* Equipped attunable items gain attunement points.
* Attunement level is displayed in item details.
* Reaching thresholds reveals locked properties.
* Revealed properties affect stats/combat.
* Attunement progress is per item instance.
* Tests cover thresholds and reveal behavior.

---

# 5. Level-Gated Item Properties

## Requirement

Some item properties should not reveal or activate until the player reaches a required level.

## Behavior

Properties with requirement:

```ts
{ type: "player_level", value: 3 }
```

Should:

* Display as locked if item is identified enough to hint at it.
* Reveal when player level reaches requirement.
* Activate once revealed.
* Add discovery message.

## Level-Up Integration

On player level-up:

1. Existing level-up behavior runs.
2. Check equipped and inventory items for level-gated reveals.
3. Reveal eligible properties.
4. Add messages.
5. Recalculate stats.

## Required Helper

```ts
processLevelGatedItemReveals(state: GameState): GameState
```

### Acceptance Criteria

* Level-gated properties do not apply before required level.
* Leveling up can reveal item properties.
* Messages report newly revealed properties.
* Tests cover level-gated reveal and activation.

---

# 6. Cursed Properties

## Requirement

Add support for cursed item properties.

Cursed properties are negative or risky effects that may be hidden until revealed. The player should be able to accidentally equip a cursed item.

## Curse Behavior

A cursed property:

```ts
cursed: true
kind: "curse"
```

May cause:

* Stat penalty
* Increased mana costs
* Health cost on attack/skill use
* Reduced gold gain
* Reduced XP gain

For Phase 5, implement only:

* Stat penalty
* Health cost on skill use or attack

## Curse Visibility

Before reveal:

```text
???
```

After reveal:

```text
Curse: Blood Price
You lose 2 health whenever you use a skill.
```

## Curse Activation Rule

Curses should only apply once revealed **or** if the item is equipped and the curse trigger occurs, causing the curse to reveal itself.

This gives the desired nasty surprise:

```text
The Ashen Ring burns cold. Curse revealed: Blood Price.
You lose 2 health.
```

## Required Helpers

```ts
getActiveCurses(state: GameState): ItemProperty[]
processCursesOnAttack(state: GameState): GameState
processCursesOnSkillUse(state: GameState, skillId: string): GameState
revealCurse(instance: ItemInstance, propertyId: string): ItemInstance
```

### Acceptance Criteria

* Cursed properties can exist hidden on items.
* Curses reveal when triggered if not already revealed.
* Revealed curses display clearly in item details.
* Curse effects apply correctly.
* Curse messages are clear and alarming.
* Tests cover hidden curse trigger and revealed curse behavior.

---

# 7. Required Phase 5 Items

## Requirement

Add at least four discovery-driven items.

## Item 1: Ashen Ring

A first mysterious ring. This is the early foundation for later ring souls.

```ts
id: "ashen-ring"
type: "trinket"
equipmentSlot: "trinket"
equippable: true
attunable: true
maxAttunementLevel: 3
knowledgeState on drop: "unidentified"
```

Base visible description while unidentified:

```text
A blackened ring warm to the touch. It feels like a coal that forgot how to die.
```

Properties:

### Ember Memory

```ts
id: "ashen-ring-ember-memory"
name: "Ember Memory"
kind: "stat_modifier"
visibility: "hidden"
revealed: false
cursed: false
requirements: [{ type: "identify" }]
effects: [{ type: "stat_bonus", stat: "spellPower", amount: 1 }]
```

### Hungry Spark

```ts
id: "ashen-ring-hungry-spark"
name: "Hungry Spark"
kind: "skill_modifier"
visibility: "locked_by_attunement"
revealed: false
cursed: false
requirements: [{ type: "attunement", value: 2 }]
effects: [{ type: "damage_bonus", skillId: "ember-bolt", amount: 3 }]
```

### Blood Price

```ts
id: "ashen-ring-blood-price"
name: "Blood Price"
kind: "curse"
visibility: "hidden"
revealed: false
cursed: true
requirements: [{ type: "combat_use" }]
effects: [{ type: "health_cost", amount: 2 }]
```

Curse behavior:

* Triggers when player uses a skill while Ashen Ring is equipped.
* Reveals itself on first trigger.
* Costs 2 health per skill use thereafter.

## Item 2: Roadwarden's Notched Blade

```ts
id: "roadwardens-notched-blade"
type: "weapon"
equipmentSlot: "weapon"
equippable: true
attunable: true
knowledgeState on drop: "partially_identified"
baseStats: { strength: 2 }
```

Properties:

### Steady Edge

```ts
requirements: [{ type: "identify" }]
effects: [{ type: "stat_bonus", stat: "defense", amount: 1 }]
```

### Oath Bite

```ts
requirements: [{ type: "attunement", value: 1 }]
effects: [{ type: "damage_bonus", skillId: "guarded-strike", amount: 2 }]
```

### Old Weight

```ts
cursed: true
requirements: [{ type: "equip" }]
effects: [{ type: "stat_penalty", stat: "spellPower", amount: -1 }]
```

## Item 3: Whisperthread Cloak

```ts
id: "whisperthread-cloak"
type: "armor"
equipmentSlot: "armor"
equippable: true
attunable: true
knowledgeState on drop: "unidentified"
baseStats: { defense: 1 }
```

Properties:

### Quiet Hem

```ts
requirements: [{ type: "identify" }]
effects: [{ type: "stat_bonus", stat: "defense", amount: 1 }]
```

### Grave's Favor

```ts
requirements: [{ type: "attunement", value: 2 }]
effects: [{ type: "damage_bonus", skillId: "grave-touch", amount: 2 }]
```

## Item 4: Elder Glass Charm

```ts
id: "elder-glass-charm"
type: "trinket"
equipmentSlot: "trinket"
equippable: true
attunable: false
knowledgeState on drop: "unidentified"
```

Properties:

### Clear Thought

```ts
requirements: [{ type: "identify" }]
effects: [{ type: "stat_bonus", stat: "maxManaBonus", amount: 10 }]
```

### Patient Light

```ts
requirements: [{ type: "player_level", value: 3 }]
effects: [{ type: "stat_bonus", stat: "spellPower", amount: 1 }]
```

### Acceptance Criteria

* All four items exist as definitions.
* At least two can drop or be found during gameplay.
* At least one cursed item can be encountered.
* At least one attunement reveal is reachable in normal play.
* Item details display discovery state correctly.

---

# 8. Loot Integration

## Requirement

Update zone loot so Phase 5 items can be found.

## Suggested Placement

### Roadside Cache

Add:

* Identify Scroll x2
* Elder Glass Charm x1

### Road Bandit

Chance/drop:

* Roadwarden's Notched Blade
* Identify Scroll x1

### Elder Stone Completion Reward

Add one class-aware item reward:

* Roadwarden: Roadwarden's Notched Blade
* Ember Sage: Ashen Ring
* Gravebound Scout: Whisperthread Cloak

If class-aware reward is too much for this phase, use Ashen Ring as universal reward.

## Loot Behavior

Loot messages should respect knowledge state:

```text
You found an Unidentified Ring.
You found an Identify Scroll.
You found Whisperthread Cloak.
```

Do not reveal true item names if item is unidentified unless the item definition says its name is visible.

### Acceptance Criteria

* Identify Scrolls are obtainable.
* Discovery items are obtainable.
* Loot messages do not spoil hidden identity.
* Existing loot still works.

---

# 9. Inventory and Item Details UI

## Requirement

Upgrade inventory item details to support discovery state.

## Item Detail Panel Must Show

* Display name
* Item type
* Equipment slot
* Knowledge state
* Base stats if known/visible
* Known properties
* Unknown property placeholders
* Locked property hints
* Attunement level and progress if attunable
* Cursed properties if revealed
* Available actions:

  * Equip
  * Unequip if currently equipped
  * Use if consumable
  * Identify if valid target mode is active

## Unknown Property Display

Examples:

```text
Unknown Property: ???
Locked Property: Requires Attunement 2
Locked Property: Requires Level 3
```

## Attunement Display

Example:

```text
Attunement: Level 1 — 3 / 5 points to Level 2
```

## Curse Display

Example:

```text
Curse: Blood Price
Lose 2 health whenever you use a skill.
```

## Visual Requirements

* Unknown properties should feel mysterious.
* Revealed cursed properties should be visually distinct.
* Do not use color alone to indicate curses.
* Use labels/text such as `Curse`, `Unknown`, `Locked`, `Revealed`.

### Acceptance Criteria

* Inventory clearly communicates item mystery.
* Player can identify valid items from inventory flow.
* Attunement progress is visible.
* Curses are clearly marked once revealed.
* UI remains usable with existing equipment and consumables.

---

# 10. Equipment Stat Integration

## Requirement

Update effective stat calculations to include revealed item properties.

## Rules

* Base item stats always apply when item is equipped if the item itself is equippable.
* Revealed positive properties apply when item is equipped.
* Revealed curses apply when item is equipped.
* Hidden curses may trigger and reveal themselves based on trigger rules.
* Unrevealed positive hidden properties do not apply.
* Locked properties do not apply until revealed.

## Required Helper Updates

Update existing helpers:

```ts
getEquipmentStats(equipment: EquipmentSlots, itemInstances: ItemInstance[], definitions: ItemDefinition[]): PlayerStats
getEffectiveStats(player: PlayerState, state: GameState): PlayerStats
getEffectiveMaxHealth(player: PlayerState, state: GameState): number
getEffectiveMaxMana(player: PlayerState, state: GameState): number
```

If function signatures become ugly, introduce selectors:

```ts
selectEffectivePlayerStats(state: GameState): PlayerStats
selectEffectiveMaxHealth(state: GameState): number
selectEffectiveMaxMana(state: GameState): number
selectEquippedItemInstances(state: GameState): ItemInstance[]
```

### Acceptance Criteria

* Revealed item properties affect stats.
* Unrevealed item properties do not affect stats.
* Cursed stat penalties affect stats after reveal/activation.
* Stat display updates after identification, attunement reveal, curse reveal, equip, and unequip.

---

# 11. Combat Integration

## Requirement

Item discovery should interact with combat.

## Combat Hooks

Add hooks to combat flow:

### On Basic Attack

* Apply revealed weapon damage bonuses.
* Process attack-triggered curses.
* Add weapon attunement point if applicable.

### On Skill Use

* Apply revealed skill damage bonuses.
* Apply revealed mana cost modifiers.
* Process skill-triggered curses.
* Add trinket attunement point if applicable.

### On Combat Victory

* Grant attunement point to all equipped attunable items.
* Reveal newly unlocked attunement properties.
* Grant normal XP/loot.

## Required Helpers

```ts
getRevealedDamageBonusForSkill(state: GameState, skillId: string): number
getRevealedDamageBonusForBasicAttack(state: GameState): number
getManaCostModifierForSkill(state: GameState, skillId: string): number
processItemHooksOnBasicAttack(state: GameState): GameState
processItemHooksOnSkillUse(state: GameState, skillId: string): GameState
processItemHooksOnCombatVictory(state: GameState): GameState
```

### Acceptance Criteria

* Item properties can modify combat.
* Hidden properties do not modify combat until revealed.
* Curses can trigger during attack or skill use.
* Attunement advances through combat.
* Combat messages report item-related events.

---

# 12. Discovery Messages

## Requirement

Add clear message types for discovery events.

## Message Type Expansion

Add to `GameMessage` type:

```ts
type: "discovery" | "curse" | existingTypes
```

## Required Message Examples

Identification:

```text
The scroll burns to ash. Ashen Ring reveals: Ember Memory.
```

Attunement:

```text
Ashen Ring grows warmer. Attunement reached Level 2.
```

Property reveal:

```text
New property revealed: Hungry Spark.
```

Curse reveal:

```text
Curse revealed: Blood Price. The ring drinks a sliver of your life.
```

Level-gated reveal:

```text
Elder Glass Charm catches the light. Patient Light has awakened.
```

Invalid identify:

```text
The scroll refuses. There is nothing hidden here it can reveal.
```

### Acceptance Criteria

* Discovery messages are distinct from normal loot/combat messages.
* Curse messages are visually distinct and alarming.
* Important reveal events are not silent.
* Messages do not duplicate on repeated state updates.

---

# 13. Identify Target Mode UI

## Requirement

Using an Identify Scroll should enter a clear target-selection mode.

## Behavior

When player clicks Use on Identify Scroll:

* Inventory remains open.
* UI displays message/banner:

```text
Choose an item to identify.
```

* Valid target items are highlighted.
* Invalid target items are dimmed or disabled.
* Player may cancel target mode.

## Required State

Add UI/game state:

```ts
export interface InventoryInteractionState {
  mode: "normal" | "identify_target";
  sourceItemInstanceId?: string;
}
```

Or equivalent.

## Actions

```ts
export type GameAction =
  | { type: "ENTER_IDENTIFY_MODE"; scrollInstanceId: string }
  | { type: "CANCEL_ITEM_TARGET_MODE" }
  | { type: "IDENTIFY_TARGET_ITEM"; targetInstanceId: string }
  // existing actions
```

### Acceptance Criteria

* Identify mode is obvious.
* Valid targets are visually indicated.
* Cancel works.
* Identifying exits identify mode.
* Invalid action does not consume scroll.

---

# 14. Class Interaction

## Requirement

Item discovery should work for all three classes, but some items should feel better for certain builds.

## Expected Interactions

### Roadwarden

* Benefits from Roadwarden's Notched Blade.
* May dislike Ashen Ring curse because skill use costs health.
* Uses Identify Scroll to reveal defensive/martial bonuses.

### Ember Sage

* Benefits strongly from Ashen Ring.
* Blood Price curse is dangerous because Ember Sage uses skills often.
* Elder Glass Charm is useful because of mana/spell power.

### Gravebound Scout

* Benefits from Whisperthread Cloak.
* Can use Grave Touch to offset some curse health costs.
* May use Elder Glass Charm as hybrid support.

### Acceptance Criteria

* No class is blocked from using discovery items.
* At least one item has obvious class synergy.
* At least one item has a meaningful drawback.
* Item effects interact with Phase 4 skills.

---

# 15. Testing Requirements

## Required Test Areas

Add tests for:

### Item Instance Model

* Create item instance from definition.
* Instance has unique ID.
* Instance stores knowledge state separately from definition.
* Stackable and non-stackable behavior still works.

### Identification

* Can identify valid unidentified item.
* Can identify partially identified item with hidden identify properties.
* Cannot identify fully known item.
* Cannot identify item with no identify-revealable properties.
* Scroll is consumed only on success.

### Property Reveal

* Identify reveals identify properties.
* Attunement reveals attunement properties.
* Player level reveals level-gated properties.
* Hidden properties do not apply before reveal.
* Revealed properties apply after reveal.

### Attunement

* Attunement points increase on combat victory.
* Weapon attunement increases on attack.
* Trinket attunement increases on skill use.
* Thresholds calculate correctly.
* Newly reached thresholds reveal properties once.

### Curses

* Hidden curse can reveal on trigger.
* Revealed curse applies effect.
* Curse message appears once on reveal.
* Curse effect can repeat after reveal if trigger repeats.

### Effective Stats

* Base item stats apply when equipped.
* Revealed stat bonuses apply.
* Unrevealed stat bonuses do not apply.
* Revealed stat penalties apply.
* Unequipping removes item effects.

### Combat Hooks

* Revealed skill damage bonus modifies skill damage.
* Revealed basic attack bonus modifies basic damage.
* Mana cost modifier changes skill cost.
* Health-cost curse reduces health on trigger.

### UI State / Reducer

* Enter identify mode.
* Cancel identify mode.
* Identify target exits mode.
* Invalid target preserves mode or exits based on chosen UX, but does not consume scroll.

## Acceptance Criteria

* Existing Phase 2–4 tests still pass.
* New systems have meaningful unit coverage.
* Combat/item integration tests cover at least Ashen Ring.
* Test names clearly describe discovery rules.

---

# 16. State Architecture Requirements

## Requirement

Keep item discovery rules out of React components.

Recommended structure:

```text
src/game/systems/
  itemDiscovery.ts
  attunement.ts
  itemEffects.ts
  curses.ts
  selectors.ts
```

## Reducer Action Additions

Add or extend:

```ts
export type GameAction =
  | { type: "ENTER_IDENTIFY_MODE"; scrollInstanceId: string }
  | { type: "CANCEL_ITEM_TARGET_MODE" }
  | { type: "IDENTIFY_TARGET_ITEM"; targetInstanceId: string }
  | { type: "PROCESS_ITEM_REVEALS_FOR_LEVEL_UP" }
  // existing actions remain
```

Most item reveal processing should happen automatically inside existing actions:

* `USE_SKILL`
* `ATTACK_ENEMY`
* `RESOLVE_COMBAT_VICTORY`
* `EQUIP_ITEM`
* `LEVEL_UP`

Do not make the UI manually call item reveal helpers. That is how bugs breed in the walls.

### Acceptance Criteria

* React components dispatch actions only.
* Systems/selectors handle item discovery rules.
* Item effects are centralized and testable.

---

# 17. Visual Asset Requirements

## Requirement

Add or placeholder new item icons.

## Required Assets

```text
src/assets/items/identify-scroll.png
src/assets/items/ashen-ring.png
src/assets/items/roadwardens-notched-blade.png
src/assets/items/whisperthread-cloak.png
src/assets/items/elder-glass-charm.png
src/assets/items/unidentified-ring.png
src/assets/items/unidentified-weapon.png
src/assets/items/unidentified-armor.png
src/assets/items/unidentified-trinket.png
```

## Fallback Approach

If custom art is not available:

* Use existing ring/gem/scroll/charm icons from current assets.
* Use CSS-framed placeholders.
* Keep filenames stable so art can be replaced later.

## Visual Style

* Unidentified items should have shadowed or question-mark presentation.
* Identified items should use their real icon.
* Cursed items should have an ominous visual marker once curse is revealed.
* Attunable items should have a subtle glow/progress indicator.

### Acceptance Criteria

* New items have icons or stable placeholders.
* Unidentified items are visually distinct.
* Revealed curses are visually distinct.
* Attunement progress is visible without cluttering inventory.

---

# 18. Balance Requirements

## Requirement

Keep item discovery exciting but not overpowering.

## Rules of Thumb

* Phase 5 item bonuses should be small but noticeable.
* Curses should be survivable but meaningful.
* Identify Scrolls should be limited enough to create choice.
* Attunement should reveal something within one short play session.

## Suggested Balance

* Player should find 2 Identify Scrolls early.
* Player should encounter 2–3 items worth identifying.
* Ashen Ring should be strong for Ember Sage but risky.
* Blood Price health cost should be 2 per skill use; if too harsh, reduce to 1.
* Attunement Level 1 should be reachable after one or two encounters.
* Attunement Level 2 should be reachable before zone completion if item is equipped early.

### Acceptance Criteria

* Discovery mechanics are visible during normal play.
* Player is not flooded with mystery items.
* At least one identify decision matters.
* At least one attunement reveal happens without grinding.

---

# 19. UI Acceptance Checklist

Phase 5 UI is complete when:

1. Inventory supports unidentified item display.
2. Item details show knowledge state.
3. Unknown properties appear as placeholders.
4. Locked properties show requirement hints.
5. Identify Scroll can enter target mode.
6. Valid identify targets are highlighted.
7. Identified properties become visible.
8. Attunement level/progress is visible.
9. Curses appear distinctly once revealed.
10. Discovery messages are shown.
11. Stat changes after reveal/equip are visible.
12. Existing inventory/equipment/consumable behavior still works.

---

# 20. Implementation Plan

## Step 1 — Split Item Definitions and Instances

* Introduce `ItemDefinition` and `ItemInstance`.
* Migrate inventory to store instances.
* Update selectors to resolve instance + definition.
* Preserve existing items and equipment behavior.

## Step 2 — Add Discovery Types

* Add knowledge states.
* Add item properties.
* Add reveal requirements.
* Add item effects.

## Step 3 — Update Inventory UI

* Show display names based on knowledge state.
* Show known/unknown/locked properties.
* Add mystery icons/placeholders.

## Step 4 — Add Identify Scroll

* Add scroll item definition.
* Add identify target mode.
* Implement identification helpers.
* Wire inventory actions.

## Step 5 — Add Required Discovery Items

* Add Ashen Ring.
* Add Roadwarden's Notched Blade.
* Add Whisperthread Cloak.
* Add Elder Glass Charm.

## Step 6 — Integrate Loot

* Add scrolls and discovery items to containers/enemies/rewards.
* Ensure loot messages respect unknown identity.

## Step 7 — Implement Revealed Item Effects

* Add selectors for equipped item effects.
* Apply revealed stat modifiers.
* Apply revealed combat/skill modifiers.

## Step 8 — Implement Attunement

* Add attunement state to item instances.
* Add attunement points from victory, attacks, and skills.
* Reveal attunement-locked properties.
* Add messages.

## Step 9 — Implement Level-Gated Reveals

* Process item reveals on level-up.
* Show messages.
* Update stats.

## Step 10 — Implement Curses

* Add hidden curse trigger processing.
* Reveal curses on trigger.
* Apply curse effects.
* Add curse messages.

## Step 11 — Combat Hook Integration

* Add item hooks to attack/skill/victory flow.
* Verify item effects interact with class skills.

## Step 12 — Visual Polish

* Add icons/placeholders.
* Add unknown/locked/curse visual states.
* Add attunement progress display.

## Step 13 — Tests and Cleanup

* Add tests for discovery, identify, attunement, curses, item effects, and combat hooks.
* Run full suite.
* Remove obsolete item assumptions.

---

# 21. Suggested Commit Plan

```text
1. refactor: split item definitions from item instances
2. feat: add item discovery types and property model
3. feat: update inventory UI for unknown and locked item properties
4. feat: add identify scroll and identify target mode
5. feat: add discovery-driven equipment items
6. feat: integrate discovery items into loot tables
7. feat: apply revealed item effects to player stats
8. feat: add attunement progression and property reveals
9. feat: add level-gated item property reveals
10. feat: add cursed item property triggers and effects
11. feat: integrate item hooks into combat flow
12. test: cover identification, attunement, curses, and item effects
13. style: polish item mystery, curse, and attunement visuals
```

---

# 22. Acceptance Criteria for Entire Phase

Phase 5 is complete when:

1. Inventory uses item instances separate from item definitions.
2. Items can be known, unidentified, partially identified, or identified.
3. Items can contain visible, hidden, attunement-locked, and level-locked properties.
4. Identify Scrolls can reveal identify-based properties.
5. Identify target mode works and is understandable.
6. Attunable equipped items gain attunement points.
7. Attunement thresholds reveal properties.
8. Level-gated properties reveal on level-up.
9. Cursed properties can exist hidden on items.
10. Hidden curses can reveal when triggered.
11. Revealed curses apply negative effects.
12. Revealed positive properties apply beneficial effects.
13. Unrevealed properties do not apply.
14. Combat uses revealed item hooks for attacks, skills, and victory.
15. At least four discovery-driven items exist.
16. At least one cursed item is obtainable.
17. At least one attunement reveal is reachable in normal play.
18. At least one Identify Scroll decision matters.
19. UI clearly communicates unknown, locked, revealed, cursed, and attuned states.
20. Existing Phase 2–4 functionality still works.
21. Tests cover discovery, identification, attunement, curses, and item effect integration.

---

# 23. Future Phase Hooks

After Phase 5, the project is ready for one of these directions:

## Phase 6 Candidate A — Ring Souls

* Rings contain trapped spellcaster souls.
* Rings whisper, warn, lie, or bargain.
* Ring powers and curses reflect the soul inside.
* Attunement unlocks memories/personality fragments.

## Phase 6 Candidate B — Item Synergies and Merging

* Certain item combinations unlock new properties.
* Some synergies are explicit.
* Some require scrolls.
* Some are discoverable through use.
* Some create curses.

## Phase 6 Candidate C — Multi-Zone Dungeon Expansion

* Add more zones.
* Add room transitions.
* Add elite encounters.
* Add stronger item discovery pressure.

## Phase 6 Candidate D — Expanded Skill Trees

* Larger class talent trees.
* Skill upgrades.
* Item-skill build paths.

Do not implement these in Phase 5. Just leave the system open enough that they can slot in without surgery performed by candlelight.

---

# 24. Definition of Done

Phase 5 is done when items in EldersCourage stop feeling like static stat cards and start feeling like suspicious little artifacts with secrets.

The player should find something mysterious, wonder what it does, spend a scroll, reveal a useful power, equip it, awaken another power through use, and maybe discover that the item has teeth.

That is the heart of this phase:

**loot as discovery, not just arithmetic.**
