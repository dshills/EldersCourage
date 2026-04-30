
# EldersCourage — Phase 3 SPEC.md

## Phase Name

**Phase 3: Exploration, Equipment, Encounters, and Repeatable Adventure Loop**

## Purpose

Phase 2 established the first playable minute: UI shell, inventory, chest interaction, basic combat, quest tracking, and player feedback.

Phase 3 should turn that vertical slice into a repeatable mini-adventure loop. The player should be able to move through a small map, encounter enemies, collect gear, equip items, gain experience, level up, and complete a slightly larger quest chain.

This is still not the full game. This phase builds the core gameplay skeleton that later systems can hang meat on without collapsing like a tavern chair under an ogre.

---

# Primary Goal

Implement a small explorable zone with player movement, multiple interactable locations, multiple enemy encounters, basic equipment, XP/leveling, and a repeatable combat-loot-progression loop.

The player should be able to:

1. Move around a small map.
2. Enter or trigger multiple encounters.
3. Fight more than one enemy.
4. Loot items from enemies and containers.
5. Equip a weapon and armor item.
6. See stat changes from equipment.
7. Gain XP from combat.
8. Level up at least once.
9. Complete a multi-step quest chain.
10. End the phase with a clear mini-zone completion state.

---

# Recommended Target

Continue using the current browser implementation.

Expected stack:

* Vite
* React
* TypeScript
* Existing styling approach from Phase 2
* Existing asset folders and game state structure

Do not rewrite the app unless absolutely necessary. Refactor surgically.

---

# Non-Goals

Do **not** implement yet:

* Procedural generation
* Save/load
* Full Diablo-style loot affix system
* Full skill trees
* Multiple character classes
* Real pathfinding
* Multiplayer
* Full animation state machine
* Boss mechanics
* Complex enemy AI
* Full item identification/attunement
* Ring souls
* Cursed item systems
* Deep economy
* Vendor shops

This phase should create durable foundations, not a haunted cathedral of half-finished systems.

---

# Deliverables

## 1. Explorable Zone

### Requirement

Create one small zone called:

**Elder Road Outskirts**

The zone should include:

* A visible map/playfield.
* Player position.
* Tile or node-based movement.
* At least 8–12 traversable positions.
* At least 3 interactable locations.
* At least 3 enemy encounter points.
* A clear zone-complete objective.

### Movement Model

Use a simple grid or node graph.

Recommended simple grid size:

```text
5 columns x 4 rows
```

Example:

```text
[Camp] [Road] [Chest] [Woods] [Shrine]
[Road] [Road] [Goblin] [Road] [Ruins]
[Woods] [Bandit] [Road] [Chest] [Road]
[Gate] [Road] [Wolf] [Road] [Elder Stone]
```

The player can move one tile/node at a time using:

* Arrow keys or WASD.
* On-screen directional buttons.
* Optional click-to-move on adjacent tiles.

### Tile States

Each tile/node should support:

```ts
type TileState = "hidden" | "visible" | "visited";
```

For Phase 3, the full map may start visible if fog-of-war adds complexity. However, visited state should be tracked.

### Acceptance Criteria

* Player has a visible current position.
* Player can move between valid adjacent nodes/tiles.
* Invalid movement is blocked gracefully.
* Visited tiles are visually distinct.
* Interactable locations can only be triggered when the player is on that tile or adjacent, depending on the chosen interaction model.

---

# 2. Zone Data Model

## Requirement

Move zone/map data into structured files.

Recommended files:

```text
src/game/data/zones.ts
src/game/types/zone.ts
```

## Required Types

```ts
export type Direction = "north" | "south" | "east" | "west";

export type TileKind =
  | "camp"
  | "road"
  | "woods"
  | "chest"
  | "shrine"
  | "ruins"
  | "gate"
  | "elder_stone";

export type TileState = "hidden" | "visible" | "visited";

export interface ZonePosition {
  x: number;
  y: number;
}

export interface ZoneTile {
  id: string;
  kind: TileKind;
  name: string;
  description: string;
  position: ZonePosition;
  state: TileState;
  encounterId?: string;
  containerId?: string;
  shrineId?: string;
  blocksMovement?: boolean;
}

export interface Zone {
  id: string;
  name: string;
  description: string;
  width: number;
  height: number;
  startPosition: ZonePosition;
  tiles: ZoneTile[];
  completed: boolean;
}
```

### Acceptance Criteria

* Zone data is not hard-coded directly in JSX.
* Rendering reads from zone data.
* Movement logic uses positions and map bounds.
* Tile lookup helpers exist and are tested.

---

# 3. Player Progression

## Requirement

Expand player state with XP, level, and combat stats.

## Required Player Fields

Extend `PlayerState`:

```ts
export interface PlayerStats {
  strength: number;
  defense: number;
  spellPower: number;
  maxHealthBonus: number;
  maxManaBonus: number;
}

export interface PlayerState {
  name: string;
  level: number;
  xp: number;
  xpToNextLevel: number;
  health: number;
  maxHealth: number;
  mana: number;
  maxMana: number;
  gold: number;
  baseStats: PlayerStats;
  inventory: Item[];
  equipment: EquipmentSlots;
  selectedItemId?: string;
  position: ZonePosition;
}
```

## Leveling Rules

For Phase 3, keep leveling deterministic and simple.

```text
Level 1 -> 2: 50 XP
Level 2 -> 3: 100 XP
```

Only level 2 needs to be reachable in this phase.

When leveling up:

* Increase level by 1.
* Increase max health by 10.
* Increase max mana by 5.
* Restore health and mana to new max values.
* Add a success message.

### Acceptance Criteria

* Player gains XP from defeated enemies.
* XP bar or text is visible.
* Player can level up at least once.
* Level-up changes stats and restores health/mana.
* Level-up message appears once per level gained.

---

# 4. Equipment System

## Requirement

Implement basic equipment slots and stat modifiers.

## Equipment Slots

Required slots:

```ts
export type EquipmentSlot = "weapon" | "armor" | "trinket";

export interface EquipmentSlots {
  weapon?: Item;
  armor?: Item;
  trinket?: Item;
}
```

## Item Expansion

Extend `Item`:

```ts
export interface ItemStats {
  strength?: number;
  defense?: number;
  spellPower?: number;
  maxHealthBonus?: number;
  maxManaBonus?: number;
}

export interface Item {
  id: string;
  name: string;
  type: ItemType;
  description: string;
  icon: string;
  quantity: number;
  stackable: boolean;
  equippable: boolean;
  equipmentSlot?: EquipmentSlot;
  stats?: ItemStats;
}
```

## Required Items

Add these items:

### Old Sword

```ts
{
  id: "old-sword",
  name: "Old Sword",
  type: "weapon",
  equipmentSlot: "weapon",
  equippable: true,
  stackable: false,
  stats: { strength: 2 },
}
```

### Roadwarden Vest

```ts
{
  id: "roadwarden-vest",
  name: "Roadwarden Vest",
  type: "armor",
  equipmentSlot: "armor",
  equippable: true,
  stackable: false,
  stats: { defense: 2, maxHealthBonus: 5 },
}
```

### Cracked Ember Charm

```ts
{
  id: "cracked-ember-charm",
  name: "Cracked Ember Charm",
  type: "trinket",
  equipmentSlot: "trinket",
  equippable: true,
  stackable: false,
  stats: { spellPower: 1, maxManaBonus: 5 },
}
```

### Minor Health Potion

```ts
{
  id: "minor-health-potion",
  name: "Minor Health Potion",
  type: "consumable",
  equippable: false,
  stackable: true,
}
```

## Equipment Behavior

* Equippable items show an Equip button in item details.
* Equipped items are removed from regular inventory display or visually marked as equipped.
* Equipping an item in an occupied slot replaces the old item.
* Replaced item returns to inventory.
* Stat changes are reflected immediately.
* Equipped weapon affects attack damage.
* Equipped armor affects incoming damage if retaliation is enabled.

## Derived Stat Calculation

Create pure helpers:

```ts
getEquipmentStats(equipment: EquipmentSlots): PlayerStats
getEffectiveStats(player: PlayerState): PlayerStats
getEffectiveMaxHealth(player: PlayerState): number
getEffectiveMaxMana(player: PlayerState): number
```

### Acceptance Criteria

* Player can equip weapon, armor, and trinket.
* Equipment modifies displayed stats.
* Equipped weapon changes damage calculation.
* Equipment logic is handled by helpers, not scattered across components.
* Tests cover equipping, replacing, and derived stats.

---

# 5. Expanded Combat

## Requirement

Replace the single-enemy combat slice with multiple encounters.

## Enemy Types

Add at least 3 enemy definitions.

### Goblin Scout

```ts
health: 30
attack: 4
defense: 0
xpReward: 20
lootTable: [gold, minor potion]
```

### Starved Wolf

```ts
health: 24
attack: 6
defense: 0
xpReward: 20
lootTable: [gold]
```

### Road Bandit

```ts
health: 45
attack: 7
defense: 1
xpReward: 35
lootTable: [gold, Roadwarden Vest]
```

## Combat Rules

* Player selects or enters an encounter.
* Enemy appears in combat panel.
* Player attacks using Attack button.
* Damage formula:

```ts
playerDamage = max(1, 8 + effectiveStats.strength - enemy.defense)
```

* Enemy retaliates if still alive.
* Enemy damage formula:

```ts
enemyDamage = max(1, enemy.attack - effectiveStats.defense)
```

* Enemy defeat grants XP and loot.
* Enemy encounter cannot be farmed repeatedly unless explicitly reset. For Phase 3, defeated enemies stay defeated.

## Player Defeat

Keep defeat simple:

* If player health reaches 0, display defeat state.
* Disable movement and attack.
* Show Restart button.
* Restart resets game state.

No death penalties yet.

## Acceptance Criteria

* Multiple enemy encounters work.
* Enemy stats differ by enemy type.
* Player and enemy damage use formulas.
* Equipment changes combat results.
* Defeated enemies grant XP and loot once.
* Player defeat is handled gracefully.

---

# 6. Loot Tables

## Requirement

Implement deterministic or semi-random loot tables.

For Phase 3, deterministic loot is acceptable and easier to test.

## Types

```ts
export interface LootEntry {
  itemId: string;
  quantity: number;
  chance: number;
}

export interface LootTable {
  id: string;
  entries: LootEntry[];
}
```

If randomness is used, inject a random function for testing.

```ts
generateLoot(table: LootTable, random: () => number): Item[]
```

## Gold Handling

Gold may remain a number on player state rather than a normal inventory item.

Represent gold loot explicitly:

```ts
export interface GoldLootEntry {
  min: number;
  max: number;
}
```

## Acceptance Criteria

* Enemies and chests can grant loot.
* Loot is granted once per source.
* Loot messages show what was received.
* Loot generation is testable.

---

# 7. Containers and Shrines

## Requirement

Add more interactable non-enemy objects.

## Containers

Add two containers:

1. Abandoned Chest
2. Roadside Cache

Container behavior:

* Can be opened once.
* Grants loot.
* Updates tile/object state.
* Adds message.

## Shrine

Add one shrine:

**Weathered Shrine**

Shrine behavior:

* Can be activated once.
* Restores 20 health and 10 mana, not beyond max values.
* Adds message.
* Optional: grants `Cracked Ember Charm`.

## Types

```ts
export interface ContainerState {
  id: string;
  name: string;
  opened: boolean;
  lootTableId: string;
}

export interface ShrineState {
  id: string;
  name: string;
  activated: boolean;
  restoreHealth: number;
  restoreMana: number;
  grantItemId?: string;
}
```

## Acceptance Criteria

* Containers open once.
* Shrine activates once.
* Restore effects respect maximum health/mana.
* Interactable state is persistent during the current session.

---

# 8. Quest Chain

## Requirement

Replace or extend the Phase 2 quest with a small quest chain.

## Quest Chain Name

**The Elder Road**

## Quest Stages

### Stage 1 — Recover Supplies

Objectives:

* Open the abandoned chest.
* Find the Old Sword.

### Stage 2 — Clear the Road

Objectives:

* Defeat the Goblin Scout.
* Defeat the Starved Wolf.

### Stage 3 — Break the Ambush

Objectives:

* Defeat the Road Bandit.
* Reach the Elder Stone.

### Completion

When all stages are complete:

* Mark zone completed.
* Show completion panel/message.
* Award 25 bonus XP and 20 gold.

## Quest Types

```ts
export interface QuestStage {
  id: string;
  title: string;
  description: string;
  objectives: QuestObjective[];
  completed: boolean;
}

export interface QuestChain {
  id: string;
  title: string;
  description: string;
  stages: QuestStage[];
  completed: boolean;
}
```

## Behavior

* Current active stage is highlighted.
* Completed stages remain visible but collapsed or visually muted.
* Only active-stage objectives need to be prominent.
* Objective completion should be event-driven by game actions.

## Acceptance Criteria

* Multi-stage quest chain displays correctly.
* Stages complete when their objectives are complete.
* Quest chain completes when all stages are complete.
* Completion rewards are granted once.

---

# 9. UI Updates

## Required UI Additions

Update the UI to include:

* Zone/map panel.
* Player position display.
* Movement controls.
* Equipment panel.
* XP/level display.
* Enemy encounter panel.
* Expanded quest chain tracker.
* Zone completion message.

## Suggested Layout

```text
+---------------------------------------------------+
| Header / Logo / Player Level / Gold               |
+---------------------------+-----------------------+
|                           | Quest Chain           |
|       Zone Map            | Equipment             |
|                           | Enemy / Target        |
+---------------------------+-----------------------+
| Health | Mana | XP | Move | Attack | Inventory     |
+---------------------------------------------------+
| Message Log                                       |
+---------------------------------------------------+
```

## Inventory UI Changes

Inventory item details should now support:

* Equip button for equippable items.
* Use button for consumables.
* Equipped badge for equipped items.
* Stat display for gear.

## Equipment UI

Show equipped items:

```text
Weapon: Old Sword (+2 Strength)
Armor: Roadwarden Vest (+2 Defense, +5 Health)
Trinket: Cracked Ember Charm (+1 Spell Power, +5 Mana)
```

## Acceptance Criteria

* UI remains readable and game-like.
* New systems are visible without overwhelming the screen.
* Inventory and equipment interaction is understandable.
* Quest chain progress is obvious.

---

# 10. Consumables

## Requirement

Implement use behavior for Minor Health Potion.

## Potion Behavior

* Restores 25 health.
* Cannot exceed max health.
* Quantity decreases by 1.
* Item removed when quantity reaches 0.
* If health is already full, either:

  * Disable Use button, or
  * Show warning message and do not consume.

## Required Helper

```ts
useConsumable(player: PlayerState, itemId: string): PlayerState
```

For now, support only health potion behavior through a simple item effect field.

## Acceptance Criteria

* Health potion can be used from inventory.
* Potion heals correctly.
* Potion quantity updates correctly.
* Potion cannot be wasted at full health unless intentionally allowed with message.

---

# 11. Game State Organization

## Requirement

As state grows, move mutation logic away from components.

Recommended structure:

```text
src/game/state/
  initialState.ts
  actions.ts
  reducers.ts
  selectors.ts

src/game/systems/
  combat.ts
  inventory.ts
  equipment.ts
  quests.ts
  zone.ts
  loot.ts
```

This does not require Redux. A React reducer is enough.

## Recommended Action Model

Use a discriminated union for game actions.

```ts
export type GameAction =
  | { type: "MOVE_PLAYER"; direction: Direction }
  | { type: "OPEN_CONTAINER"; containerId: string }
  | { type: "ACTIVATE_SHRINE"; shrineId: string }
  | { type: "START_ENCOUNTER"; encounterId: string }
  | { type: "ATTACK_ENEMY" }
  | { type: "EQUIP_ITEM"; itemId: string }
  | { type: "USE_ITEM"; itemId: string }
  | { type: "SELECT_ITEM"; itemId?: string }
  | { type: "TOGGLE_INVENTORY" }
  | { type: "RESTART_GAME" };
```

## Acceptance Criteria

* Major game state changes are routed through clear actions.
* Reducer or action handlers are easy to test.
* Components dispatch actions instead of directly mutating complex state.

---

# 12. Graphics and Visual Asset Work

## Requirement

Add enough visual polish to support exploration and equipment without requiring a professional sprite pipeline.

## Required Visuals

Create or crop/include assets for:

* Player marker/token.
* Camp tile.
* Road tile.
* Woods tile.
* Shrine tile.
* Ruins tile.
* Elder Stone tile.
* Closed chest.
* Open chest.
* Goblin enemy token/card.
* Wolf enemy token/card.
* Bandit enemy token/card.
* Equipment icons:

  * Old Sword
  * Roadwarden Vest
  * Cracked Ember Charm
  * Minor Health Potion

## Fallback Approach

If custom images are not available yet:

* Use existing Phase 2 assets where possible.
* Use stylized CSS cards with emoji/icons temporarily.
* Keep asset filenames stable so real art can replace placeholders later.

## Suggested Asset Paths

```text
src/assets/zone/camp.png
src/assets/zone/road.png
src/assets/zone/woods.png
src/assets/zone/shrine.png
src/assets/zone/ruins.png
src/assets/zone/elder-stone.png
src/assets/characters/player-token.png
src/assets/enemies/goblin-scout.png
src/assets/enemies/starved-wolf.png
src/assets/enemies/road-bandit.png
src/assets/items/roadwarden-vest.png
src/assets/items/cracked-ember-charm.png
src/assets/items/minor-health-potion.png
```

## Acceptance Criteria

* Zone map has distinct tile visuals.
* Enemy types are visually distinguishable.
* Equipment items have icons or clear placeholders.
* Asset paths are stable and documented.

---

# 13. Message Log Expansion

## Requirement

Message log should now support adventure events.

## Required Event Messages

Movement:

* `You travel north to the Weathered Shrine.`
* `You cannot travel that way.`

Containers:

* `You open the Roadside Cache.`
* `You found Roadwarden Vest.`

Combat:

* `You strike the Road Bandit for 9 damage.`
* `Road Bandit hits you for 5 damage.`
* `Road Bandit is defeated.`

Progression:

* `You gain 35 XP.`
* `You reached level 2.`

Quest:

* `Quest stage complete: Clear the Road.`
* `The Elder Road is secure.`

## Acceptance Criteria

* Important state changes produce messages.
* Messages are not duplicated accidentally.
* Log remains capped to a reasonable number of entries.

---

# 14. Testing Requirements

## Required Test Areas

Add tests for:

### Zone Movement

* Valid movement changes position.
* Invalid movement does not change position.
* Visited tile state updates.

### Equipment

* Equipping item fills correct slot.
* Replacing item returns old item to inventory.
* Derived stats include equipment bonuses.

### Combat

* Damage formula uses strength and defense.
* Enemy retaliation uses defense.
* Enemy defeat grants XP and loot once.
* Player defeat sets defeat state.

### XP / Leveling

* XP increases after combat.
* Level increases at threshold.
* Health/mana max increase on level-up.
* Health/mana restore on level-up.

### Quest Chain

* Objective completion updates stage.
* Stage completion updates chain.
* Completion rewards are granted once.

### Consumables

* Potion heals player.
* Potion quantity decreases.
* Potion is removed at zero quantity.
* Potion cannot exceed max health.

## Acceptance Criteria

* Existing Phase 2 tests still pass.
* New pure helper/system tests pass.
* Test command is documented in README or package scripts.

---

# 15. Implementation Plan

## Step 1 — Refactor State into Game Systems

* Move current state helpers into `src/game/systems`.
* Add reducer/action pattern if not already present.
* Preserve existing Phase 2 behavior while restructuring.

## Step 2 — Add Zone Types and Data

* Create zone types.
* Create Elder Road Outskirts zone data.
* Render static zone map.

## Step 3 — Implement Movement

* Add player position to state.
* Add directional movement.
* Block invalid movement.
* Mark tiles visited.
* Add movement messages.

## Step 4 — Add Encounters

* Create enemy definitions.
* Attach encounters to zone tiles.
* Start encounter when entering or interacting with encounter tile.
* Render active enemy panel.

## Step 5 — Expand Combat

* Add player/enemy damage formulas.
* Add enemy retaliation.
* Add XP rewards.
* Add defeat handling.

## Step 6 — Add Equipment

* Extend item data.
* Add equipment slots.
* Add equip behavior.
* Add derived stat helpers.
* Update UI to show equipment and stats.

## Step 7 — Add Loot Tables

* Add loot table data.
* Grant enemy/container loot once.
* Add loot messages.

## Step 8 — Add Containers and Shrine

* Add two containers.
* Add one shrine.
* Wire interactions to map tiles.

## Step 9 — Add Quest Chain

* Replace/extend current quest model.
* Add stages and objectives.
* Wire quest objective completion to actions.
* Add zone completion reward.

## Step 10 — Add Consumables

* Add minor health potion behavior.
* Add Use button in inventory details.
* Add tests.

## Step 11 — Visual Polish

* Add tile art/placeholders.
* Add enemy visuals.
* Add equipment icons.
* Improve responsive layout.

## Step 12 — Test and Clean Up

* Add required helper tests.
* Run build/test/lint.
* Remove obsolete code paths.
* Keep comments useful and sparse.

---

# 16. Suggested Commit Plan

```text
1. refactor: move game logic into systems and reducer actions
2. feat: add Elder Road Outskirts zone data and map rendering
3. feat: implement player movement and visited tiles
4. feat: add multiple enemy encounters
5. feat: expand combat with retaliation, XP, and defeat state
6. feat: add equipment slots and derived player stats
7. feat: add loot tables for enemies and containers
8. feat: add shrine and expanded map interactions
9. feat: add Elder Road quest chain
10. feat: add consumable item behavior
11. test: cover movement, combat, equipment, loot, and quests
12. style: polish map, enemy, and equipment visuals
```

---

# 17. Acceptance Criteria for Entire Phase

Phase 3 is complete when:

1. The player can move around Elder Road Outskirts.
2. The map has multiple distinct locations.
3. The player can trigger multiple encounters.
4. Combat works against Goblin Scout, Starved Wolf, and Road Bandit.
5. Enemies retaliate and can damage the player.
6. Player defeat is handled with a restart option.
7. Defeated enemies stay defeated.
8. Enemies grant XP and loot once.
9. Player can reach level 2.
10. Player can equip weapon, armor, and trinket.
11. Equipment modifies effective stats.
12. Consumable health potion works.
13. Containers and shrine interactions work once.
14. The Elder Road quest chain progresses across stages.
15. Zone completion grants final reward once.
16. UI clearly shows map, stats, equipment, inventory, quest chain, active enemy, and messages.
17. Required tests pass.
18. Existing Phase 2 functionality still works.

---

# 18. Future Phase Hooks

After Phase 3, the project will be ready for one of these next directions:

## Phase 4 Candidate A — Character Classes and Skills

* Add Warrior, Warden, Arcanist, and Shade classes.
* Add first skill choices.
* Add mana-using abilities.

## Phase 4 Candidate B — Real Loot Identity System

* Add hidden item properties.
* Add identify scrolls.
* Add attunement tracking.
* Add question-mark item powers.

## Phase 4 Candidate C — Dungeon Room System

* Add multiple zones/rooms.
* Add room transitions.
* Add lightweight procedural layouts.

## Phase 4 Candidate D — Ring Souls and Curses

* Add spellcaster soul rings.
* Add powerful benefits and dangerous curses.
* Add personality/lore fragments from ring spirits.

Do not implement these in Phase 3. Just keep the code clean enough that these can be added without a sacrificial rewrite.

---

# 19. Definition of Done

Phase 3 is done when EldersCourage feels like a tiny but real RPG loop:

The player explores Elder Road Outskirts, opens caches, activates a shrine, fights several enemies, equips gear, gains XP, levels up, completes a quest chain, and secures the road.

It should be replayable for a few minutes, understandable without explanation, and structurally ready for deeper ARPG systems.

Small. Solid. Expandable. Dangerous enough to be interesting.
