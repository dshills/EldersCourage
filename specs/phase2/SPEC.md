
# EldersCourage — Next Phase SPEC.md

## Phase Name

**Phase 2: Asset Integration, Playable UI Shell, and First Adventure Loop**

## Purpose

This phase turns the current prototype from a static or partially implemented visual experiment into a small playable vertical slice. The goal is not to build the whole game. The goal is to create a working foundation where the player can launch the game, see the branded fantasy interface, move through a simple scene, interact with objects, collect items, open inventory, trigger an attack action, and complete a tiny quest loop.

This phase should establish the project structure, asset pipeline, UI conventions, and core gameplay primitives that later phases can expand.

## Current Assumptions

The project currently has:

* A basic playable or displayable implementation already started.
* A generated asset sheet containing fantasy RPG UI, terrain blocks, items, character portraits, resource icons, action buttons, health/mana bars, and inventory frame art.
* A project title/working name: **EldersCourage**.
* A desired fantasy ARPG tone with old-world adventure, treasure, gear, magic, and dangerous exploration.

The game should remain simple enough for rapid implementation by a coding agent. Do not introduce complex systems before the first loop works.

## Primary Goal

Implement a playable browser-based vertical slice using the current fantasy asset direction.

The player should be able to:

1. Start the game.
2. See a main game screen with fantasy UI elements.
3. Navigate a small map or scene.
4. Click/interact with at least one object.
5. Pick up at least one item.
6. Open and close an inventory panel.
7. Use a basic attack action against a simple enemy or target dummy.
8. Complete a short quest objective.
9. See feedback when the objective is complete.

## Recommended Output Target

Use a **browser-based implementation** unless the existing project already chose another target.

Preferred stack:

* Vite
* React
* TypeScript
* Canvas or layered HTML/CSS depending on current implementation
* Plain CSS/Tailwind if already configured

If the current implementation is not React/Vite, adapt to the existing project rather than rewriting everything for sport. Rewrites are where prototypes go to die wearing a tiny little helmet.

## Non-Goals

Do **not** implement these yet:

* Full Diablo-style loot generation
* Deep skill trees
* Character classes
* Save/load persistence
* Procedural maps
* Networked play
* Complex combat math
* Multiple zones
* Full animation system
* Sound/music pipeline
* Real quest scripting engine
* Equipment stat scaling
* Spell systems
* NPC dialogue trees

This phase is about foundation and proof of playability.

---

# Deliverables

## 1. Asset Pipeline

### Requirement

Create a sane structure for game assets.

Recommended structure:

```text
src/
  assets/
    raw/
    sprites/
    ui/
    items/
    portraits/
    terrain/
  game/
    components/
    data/
    systems/
    types/
  styles/
```

### Asset Sheet Handling

The generated asset sheet should be added to:

```text
src/assets/raw/elders-courage-assets.png
```

Then either:

1. Manually crop key assets into separate PNG files, or
2. Use CSS background-position/image clipping if speed matters.

For this phase, separate cropped files are preferred because they make the rest of the code much easier to reason about.

### Minimum Cropped Assets

Create or include the following assets:

```text
src/assets/ui/logo.png
src/assets/ui/button-attack.png
src/assets/ui/button-inventory.png
src/assets/ui/button-quests.png
src/assets/ui/health-bar-frame.png
src/assets/ui/mana-bar-frame.png
src/assets/ui/inventory-panel.png
src/assets/ui/parchment-panel.png

src/assets/items/gold-coins.png
src/assets/items/chest.png
src/assets/items/sword.png
src/assets/items/potion-blue.png
src/assets/items/fire-rune.png

src/assets/portraits/elder-hooded.png
src/assets/portraits/elder-warrior.png
src/assets/portraits/elf-scout.png

src/assets/terrain/grass-tile.png
src/assets/terrain/stone-tile.png
src/assets/terrain/lava-tile.png
src/assets/terrain/ice-tile.png
```

If exact cropping is not practical, create placeholder cropped assets from the sheet or use simple generated placeholders with clear names. Do not block implementation waiting for perfect art.

### Acceptance Criteria

* Assets are stored in predictable folders.
* UI references import assets from the asset folder, not random public paths scattered like goblin droppings.
* Missing assets degrade gracefully with fallback styles or placeholder elements.

---

# 2. Game Screen Layout

## Requirement

Build a main game screen that feels like a fantasy RPG interface.

The screen should include:

* Game logo/title area.
* Main play area.
* Bottom or side action panel.
* Health and mana bars.
* Quest button.
* Attack button.
* Inventory button.
* Inventory panel that can open/close.
* Quest/status text panel.

## Suggested Layout

```text
+------------------------------------------------+
| Logo / Header                                  |
+-----------------------------+------------------+
|                             | Character /      |
|       Play Area             | Quest Info       |
|                             |                  |
+-----------------------------+------------------+
| Health | Mana | Quests | Attack | Inventory    |
+------------------------------------------------+
```

For mobile responsiveness, stack panels vertically.

## Visual Requirements

* Use dark fantasy colors: charcoal, aged parchment, bronze, muted gold, deep red, icy blue, emerald green.
* Buttons should feel heavy, beveled, and game-like.
* Inventory panel should look like a framed grid.
* Quest/status area should resemble parchment.
* UI should not look like a SaaS admin dashboard. No offense to dashboards. They know what they did.

## Acceptance Criteria

* The game loads into a visually recognizable RPG screen.
* Buttons have hover/active states.
* Inventory button opens/closes the inventory panel.
* Quest button toggles or focuses the quest/status area.
* Attack button triggers visible feedback.

---

# 3. Core Types

Create a small set of TypeScript types to support this phase.

## Required Types

```ts
export type ItemType = "currency" | "weapon" | "consumable" | "quest" | "rune";

export interface Item {
  id: string;
  name: string;
  type: ItemType;
  description: string;
  icon: string;
  quantity: number;
}

export interface PlayerState {
  name: string;
  health: number;
  maxHealth: number;
  mana: number;
  maxMana: number;
  gold: number;
  inventory: Item[];
  selectedItemId?: string;
}

export interface QuestObjective {
  id: string;
  label: string;
  completed: boolean;
}

export interface Quest {
  id: string;
  title: string;
  description: string;
  objectives: QuestObjective[];
  completed: boolean;
}

export interface EnemyState {
  id: string;
  name: string;
  health: number;
  maxHealth: number;
  defeated: boolean;
}

export interface GameMessage {
  id: string;
  text: string;
  type: "info" | "success" | "warning" | "combat" | "loot";
  createdAt: number;
}
```

## Acceptance Criteria

* Types live in `src/game/types` or equivalent.
* UI components use these types instead of ad hoc object shapes.
* State updates are readable and easy to extend.

---

# 4. Initial Game State

Create a deterministic initial game state.

## Player

```ts
const initialPlayer: PlayerState = {
  name: "The Wanderer",
  health: 100,
  maxHealth: 100,
  mana: 40,
  maxMana: 40,
  gold: 0,
  inventory: [],
};
```

## Enemy / Target

For this phase, use a simple enemy or training dummy.

```ts
const initialEnemy: EnemyState = {
  id: "goblin-scout-001",
  name: "Goblin Scout",
  health: 30,
  maxHealth: 30,
  defeated: false,
};
```

## Quest

```ts
const initialQuest: Quest = {
  id: "first-courage",
  title: "First Courage",
  description: "Recover the old sword from the abandoned chest and defeat the goblin scout near the elder road.",
  objectives: [
    {
      id: "open-chest",
      label: "Open the abandoned chest",
      completed: false,
    },
    {
      id: "recover-sword",
      label: "Recover the old sword",
      completed: false,
    },
    {
      id: "defeat-goblin",
      label: "Defeat the goblin scout",
      completed: false,
    },
  ],
  completed: false,
};
```

## Acceptance Criteria

* Game starts with stable state.
* Refreshing the page resets state for now.
* Quest objectives update based on player actions.

---

# 5. Play Area

## Requirement

Create a simple interactive scene.

Minimum scene elements:

* A small tiled or illustrated background.
* A chest object.
* A goblin/enemy object or target dummy.
* A player marker or portrait/card.

The play area does not need full free movement yet. A click-to-interact scene is enough.

## Interaction Model

* Clicking the chest opens it once.
* Opening the chest gives the player:

  * Old Sword
  * 10 gold
  * Optional blue potion
* Clicking the enemy selects or targets it.
* Pressing Attack damages the enemy.
* When enemy health reaches 0, it is marked defeated.

## Scene Object States

Chest states:

```ts
closed | opened
```

Enemy states:

```ts
idle | targeted | damaged | defeated
```

## Acceptance Criteria

* Chest visually changes or displays an opened state after interaction.
* Loot is added to inventory once, not repeatedly.
* Enemy health decreases after attacks.
* Enemy cannot be attacked after defeated.
* Quest updates after chest and enemy actions.

---

# 6. Inventory System

## Requirement

Implement a basic inventory panel with a grid.

## Inventory Behavior

* Inventory button toggles panel visibility.
* Items appear in inventory slots.
* Each item shows icon, name, and quantity.
* Clicking an item selects it.
* Selected item displays details.

## Minimum Inventory Slots

Use a 5x4 grid or similar.

```text
[ ][ ][ ][ ][ ]
[ ][ ][ ][ ][ ]
[ ][ ][ ][ ][ ]
[ ][ ][ ][ ][ ]
```

## Item Details

When selected, show:

* Name
* Type
* Description
* Quantity

## Acceptance Criteria

* Inventory opens and closes.
* Looted items appear in the grid.
* Selecting an item shows item details.
* Gold can either appear as inventory item or as a separate currency display.

---

# 7. Combat Slice

## Requirement

Implement one simple attack action.

## Combat Rules

* Attack button requires a living target.
* Basic attack deals 10 damage.
* If the player has the Old Sword, attack deals 15 damage.
* Enemy health cannot go below 0.
* Defeated enemy updates quest objective.
* Combat messages appear in the message log.

## Example Messages

* `You strike the Goblin Scout for 10 damage.`
* `The Old Sword bites deep for 15 damage.`
* `Goblin Scout is defeated.`
* `There is nothing left to attack.`

## Optional Enemy Retaliation

If included, keep it very simple:

* Enemy retaliates for 3 damage after each player attack.
* Enemy does not retaliate if defeated.
* Player health cannot go below 0.

This is optional for Phase 2. Do not let retaliation derail the slice.

## Acceptance Criteria

* Attack button visibly changes enemy health.
* Combat messages are shown.
* Enemy defeat completes the relevant quest objective.
* Combat is deterministic and testable.

---

# 8. Quest System Slice

## Requirement

Implement a tiny quest tracker.

## Behavior

* Quest title and description are visible.
* Objectives show complete/incomplete state.
* Completing all objectives marks quest complete.
* Quest complete triggers a success message.

## Visual State

Incomplete objective:

```text
☐ Open the abandoned chest
```

Complete objective:

```text
☑ Open the abandoned chest
```

## Acceptance Criteria

* Quest objectives update immediately after corresponding actions.
* Quest completion is computed from objective state, not hard-coded in a random click handler.
* Quest complete message appears once.

---

# 9. Message Log

## Requirement

Create a message log for player feedback.

## Message Types

* `info`
* `success`
* `warning`
* `combat`
* `loot`

## Behavior

* New messages appear at the top or bottom consistently.
* Keep the most recent 5–10 messages visible.
* Messages should include enough feedback that the player understands what happened.

## Acceptance Criteria

* Opening chest creates loot messages.
* Attacking creates combat messages.
* Quest completion creates success message.
* Invalid actions create warning messages.

---

# 10. Component Breakdown

Recommended components:

```text
App
  GameShell
    HeaderBar
    PlayArea
      SceneObject
      EnemyCard
      ChestObject
    StatusPanel
      PlayerStats
      QuestTracker
      MessageLog
    ActionBar
      GameButton
      HealthManaBars
    InventoryPanel
      InventoryGrid
      InventorySlot
      ItemDetails
```

## Component Responsibilities

### GameShell

Owns top-level game state and action handlers.

### PlayArea

Renders the interactive scene and scene objects.

### ActionBar

Renders primary player actions.

### InventoryPanel

Renders inventory state and handles item selection.

### QuestTracker

Displays quest state only. It should not own quest mutation logic.

### MessageLog

Displays game messages only.

## Acceptance Criteria

* Components are small and readable.
* State mutation is not duplicated across unrelated components.
* Game actions are easy to find and test.

---

# 11. Game Actions

Implement explicit game action functions.

Required actions:

```ts
openChest(): void
selectEnemy(enemyId: string): void
attackSelectedEnemy(): void
toggleInventory(): void
selectInventoryItem(itemId: string): void
addMessage(message: Omit<GameMessage, "id" | "createdAt">): void
completeQuestObjective(objectiveId: string): void
```

## Acceptance Criteria

* User interactions call named actions.
* Named actions update state in one predictable place.
* Invalid actions are handled gracefully.

---

# 12. Styling Requirements

## General Direction

The UI should feel like a painted fantasy RPG prototype.

Use:

* Parchment panels
* Stone or carved borders
* Red attack button
* Green/gold inventory button
* Blue mana bar
* Red health bar
* Darkened play field
* Slight glow effects for magic/runes

Avoid:

* Generic white cards
* Bootstrap-looking buttons
* Corporate dashboard spacing
* Tiny unreadable text
* Overly modern glassmorphism unless intentionally mixed with fantasy

## Accessibility

* Buttons must be keyboard focusable.
* Text must remain readable against textured backgrounds.
* Do not rely on color alone for quest objective status.
* Use `aria-label` for icon-only buttons.

## Acceptance Criteria

* UI looks intentionally game-like.
* Controls remain readable and usable.
* Basic keyboard focus visibility exists.

---

# 13. Testing Requirements

Add tests where practical.

At minimum, isolate and test pure state helpers.

Recommended helper tests:

* `addItemToInventory`
* `completeQuestObjective`
* `isQuestComplete`
* `damageEnemy`
* `hasItem`

## Example Test Cases

### Inventory

* Adding a new item inserts it.
* Adding an existing stackable item increments quantity.
* Adding sword only adds one sword.

### Quest

* Completing one objective updates only that objective.
* Quest is incomplete if any objective remains incomplete.
* Quest is complete only when all objectives are complete.

### Combat

* Enemy health decreases by damage value.
* Enemy health does not drop below zero.
* Enemy becomes defeated at zero health.

## Acceptance Criteria

* Test command exists and runs successfully.
* Pure game logic has meaningful coverage.
* UI tests are optional for this phase.

---

# 14. Data Files

Move static game data into files where useful.

Recommended:

```text
src/game/data/items.ts
src/game/data/quests.ts
src/game/data/enemies.ts
```

## Acceptance Criteria

* Initial quest/item/enemy data is not deeply buried inside JSX.
* Future content can be added without rewriting components.

---

# 15. Implementation Plan

## Step 1 — Organize Assets

* Add generated asset sheet to `src/assets/raw`.
* Create folders for UI, items, portraits, and terrain.
* Crop or create placeholder assets for required minimum list.

## Step 2 — Create Game Types and Data

* Add TypeScript interfaces.
* Add initial player, quest, enemy, and item data.

## Step 3 — Build Game Shell Layout

* Create main screen layout.
* Add header/logo.
* Add play area.
* Add action bar.
* Add status/quest panel.

## Step 4 — Implement Inventory Panel

* Toggle inventory visibility.
* Render grid.
* Add item selection/details.

## Step 5 — Implement Chest Interaction

* Render chest object.
* Clicking chest opens it.
* Add sword/gold/potion to inventory.
* Complete chest and sword quest objectives.
* Add loot messages.

## Step 6 — Implement Enemy and Attack

* Render enemy card/object.
* Select enemy.
* Attack enemy.
* Update health.
* Complete defeat quest objective.
* Add combat messages.

## Step 7 — Implement Quest Completion

* Track objective completion.
* Compute quest completion.
* Show completion message once.

## Step 8 — Polish Visuals

* Apply fantasy styling.
* Add hover states.
* Add selected/targeted states.
* Add simple transitions.

## Step 9 — Add Tests

* Extract pure helper functions.
* Add unit tests for helper functions.
* Ensure build/test passes.

---

# 16. Acceptance Criteria for Entire Phase

This phase is complete when:

1. The app launches without runtime errors.
2. The game screen has a clear fantasy RPG layout.
3. The generated visual direction is represented in the UI.
4. The player can open a chest.
5. The player receives loot.
6. Loot appears in inventory.
7. The inventory panel opens/closes.
8. The player can select an inventory item.
9. The player can attack a simple enemy.
10. Enemy health decreases and enemy can be defeated.
11. Quest objectives update correctly.
12. Quest completion is shown once all objectives are complete.
13. Message log provides clear player feedback.
14. Game logic helpers have basic tests.
15. The code remains organized enough for later expansion.

---

# 17. Suggested Commit Plan

Use small commits.

```text
1. chore: add asset folders and raw EldersCourage asset sheet
2. feat: add core game types and initial data
3. feat: build fantasy game shell layout
4. feat: add inventory panel and item selection
5. feat: implement chest interaction and loot pickup
6. feat: implement enemy targeting and basic attack
7. feat: add quest tracker and completion flow
8. test: add unit tests for game state helpers
9. style: polish fantasy UI styling and responsive layout
```

---

# 18. Future Phase Hooks

Leave room for these later systems, but do not implement them yet:

* Character classes
* Skill trees
* Leveling
* Equipment identification
* Item attunement
* Ring spirits
* Cursed items
* Echoes system
* Discoverable synergies
* Scroll-based item revelations
* Dark failure consequences
* Procedural dungeons
* Save/load

Add comments only where they clarify extension points. Do not litter the code with TODO confetti.

---

# 19. Definition of Done

Phase 2 is done when the result feels like the first playable minute of EldersCourage:

The player arrives, sees the fantasy interface, opens the chest, gets the sword, attacks the goblin, completes the quest, and understands what happened through clear visual and textual feedback.

It should be small, sturdy, and expandable.

Not huge. Not perfect. Playable.
