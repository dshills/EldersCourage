# EldersCourage — Phase 6 SPEC.md

## Phase Name

**Phase 6: UI Polish, Game Feel, Layout Refinement, and Presentation Pass**

## Purpose

The current implementation has the core RPG structure working: branded header, zone map, movement controls, equipment, stats, quest tracking, messages, inventory, talents, class skills, combat actions, and location-based interactions.

That is the hard part mechanically. Now the game needs to feel more like a game and less like a functional debug interface wearing fantasy pants.

Phase 6 focuses on visual hierarchy, layout refinement, game feel, readability, feedback, and UI consistency. It should not introduce major gameplay systems. It should make the existing systems clearer, more immersive, and easier to use.

The goal is to turn the current prototype screen into a polished playable interface suitable for continuing deeper ARPG mechanics.

---

# Primary Goal

Improve the existing UI/UX so EldersCourage feels like a cohesive fantasy RPG interface rather than a raw implementation prototype.

The player should be able to:

1. Understand their current location at a glance.
2. Understand available actions without guessing.
3. Read quests, stats, equipment, and messages comfortably.
4. Distinguish map tiles visually.
5. Recognize current position, visited tiles, encounters, containers, shrines, and objectives.
6. Use movement, combat, skills, inventory, talents, and quests through a consistent fantasy UI style.
7. See clearer combat, loot, discovery, and quest feedback.
8. Play the current loop without debug-like clutter.

---

# Current UI Observations

The current screen successfully includes the expected elements:

* EldersCourage logo
* Header status line
* Elder Road Outskirts map
* Tile-based movement
* Current tile highlight
* Right-side status panel
* Equipment summary
* Quest tracker
* Message log
* Bottom action controls
* Attack button
* Class skill buttons
* Inventory button
* Talents button
* Quests button

However, several areas need refinement:

1. Header contains too much raw status/debug text.
2. Map is crowded in the upper-left of a large empty panel.
3. Tile labels dominate tile visuals.
4. Side panel sections are cramped.
5. Buttons use mixed visual styles.
6. Disabled actions look dead instead of intentionally unavailable.
7. Position coordinates are useful for developers but not players.
8. Message log lacks enough visual separation and event priority.
9. Skills and utility buttons do not visually match the fantasy UI assets.
10. The screen has strong bones but weak hierarchy.

This phase fixes those problems.

---

# Non-Goals

Do **not** implement in this phase:

* New zones
* New classes
* New skill trees
* New item discovery mechanics
* New enemies unless needed for UI testing
* Save/load persistence
* Procedural generation
* Vendor/shop systems
* Complex animation systems
* Full responsive mobile redesign
* Deep accessibility audit
* New combat formulas
* Major game balance changes

Small balance tweaks are acceptable only if needed to support UX testing.

---

# Deliverables

## 1. Header Redesign

### Requirement

Replace the current debug-like single-line header status with a structured game header.

Current style to avoid:

```text
Elder Road Outskirts | Ember Sage | Level 1 | XP 0/50 | Talent Pts 0 | Gold 8 | Position 0,0 | Road Camp
```

This is useful, but it reads like a log line escaped containment.

## New Header Layout

The header should contain:

* EldersCourage logo on the left.
* Current zone name.
* Character class and level.
* Gold display.
* Optional compact XP bar.

Recommended layout:

```text
+--------------------------------------------------------------+
| Logo        Elder Road Outskirts        Ember Sage Lv. 1     |
|             XP [########------] 0/50     Gold: 8             |
+--------------------------------------------------------------+
```

## Remove from Default Header

Remove or hide:

* Raw position coordinates.
* Current tile ID/coordinates.
* Verbose pipe-separated status text.

## Debug Mode

If coordinates are still useful, add a small debug toggle.

```ts
interface UiState {
  debugMode: boolean;
}
```

When debug mode is enabled, show:

```text
Position: 0,0 | Tile: road-camp | Encounter: none
```

Debug mode should be off by default.

### Acceptance Criteria

* Header is readable and game-like.
* Player-facing information is prioritized.
* Debug coordinates are hidden by default.
* XP and gold are still visible.
* Header works at common desktop widths.

---

# 2. Main Screen Layout Refinement

## Requirement

Rebalance the main layout so the map, status panel, and actions feel intentionally placed.

## Target Desktop Layout

Recommended structure:

```text
+-------------------------------------------------------------------+
| Header                                                            |
+---------------------------------------------+---------------------+
|                                             | Character Summary   |
|              Zone Map                       | Equipment           |
|                                             | Quest Tracker       |
|                                             | Message Log         |
+---------------------------------------------+---------------------+
| Movement | Context Actions | Combat | Skills | Inventory/Talents   |
+-------------------------------------------------------------------+
```

## Layout Rules

* The map should occupy the visual center of the screen.
* The side panel should have clear internal sections.
* The bottom action bar should align related controls into groups.
* Avoid large unused empty space unless reserved for location art/details.

## Suggested CSS Structure

```text
.game-root
  .game-header
  .game-main
    .map-panel
    .right-panel
  .action-dock
```

Use CSS Grid for the primary layout.

Example:

```css
.game-main {
  display: grid;
  grid-template-columns: minmax(720px, 1fr) 380px;
  gap: 12px;
}
```

Adjust based on current implementation.

### Acceptance Criteria

* Map is no longer awkwardly tucked in the upper-left with excessive empty space.
* Right panel does not feel cramped.
* Bottom controls are grouped logically.
* Layout remains stable when inventory/talent/quest panels open.

---

# 3. Map Panel Upgrade

## Requirement

Make the zone map more visually readable and game-like.

## Tile Visual Hierarchy

Each tile should clearly communicate:

* Terrain/location type
* Current player position
* Visited state
* Available interaction
* Enemy/container/shrine/objective marker
* Locked/blocked state if applicable

## Tile Content Structure

Recommended tile layout:

```text
+----------------------+
| [terrain artwork]    |
|                      |
|    marker/icon       |
|                      |
| Location Name        |
+----------------------+
```

Current labels are too dominant. Art and markers should carry more of the visual load.

## Tile Size

Increase tile size if screen space allows.

Recommended minimum:

```text
140px wide x 96px tall
```

Better target:

```text
160px wide x 110px tall
```

## Tile States

Visual states required:

### Current Tile

* Strong gold border.
* Subtle glow.
* Player marker/token.
* Label: `You are here` or player icon.

### Visited Tile

* Normal brightness.
* Small visited marker or softened border.

### Unvisited Visible Tile

* Slightly dimmer.
* Still readable.

### Enemy Tile

* Enemy marker/icon.
* Red or danger accent.
* Tooltip or text: `Enemy`.

### Container Tile

* Chest/cache marker.
* If unopened: visible chest marker.
* If opened: muted/open marker.

### Shrine Tile

* Shrine marker.
* If activated: muted/used marker.

### Objective Tile

* Quest marker accent.
* Should be visually distinct from generic interaction markers.

## Optional Location Details Area

Use empty map-panel space for a current-location detail card.

Example:

```text
Road Camp
The last safe fire before the Elder Road bends into ash woods.
Available: Travel east, travel south.
```

This is preferred if the map itself does not fill the panel.

### Acceptance Criteria

* Current location is obvious at a glance.
* Tile art is more visible than tile text.
* Enemy/container/shrine tiles are distinguishable.
* Opened/cleared states are visually distinct.
* Map panel feels intentionally composed.

---

# 4. Right Panel Redesign

## Requirement

Split the right-side parchment/status panel into clear stacked sections.

## Required Sections

1. Character Summary
2. Equipment
3. Quest Tracker
4. Message Log

## Character Summary

Show:

* Class name
* Level
* Health bar
* Mana bar
* XP bar
* Primary stats

Recommended display:

```text
Ember Sage — Level 1
Health 85/85 [##########]
Mana   85/85 [##########]
XP      0/50 [----------]

STR 1   DEF 1   SPELL 8
```

## Equipment Section

Current equipment should be compact but readable:

```text
Weapon   Ember Staff
Armor    Empty
Trinket  Cracked Ember Charm
```

Empty slots should be styled as empty slots, not plain text.

## Quest Tracker Section

Only the active quest stage should be expanded by default.

Example:

```text
The Elder Road
> Recover Supplies
  ☐ Open the abandoned chest
  ☐ Find the Old Sword

Clear the Road
Break the Ambush
```

Completed stages should collapse or dim.

## Message Log Section

Messages should have:

* Type styling
* Better spacing
* Maximum visible count
* Optional timestamp/turn index only in debug mode

Message types:

```ts
"info" | "success" | "warning" | "combat" | "loot" | "discovery" | "curse"
```

### Acceptance Criteria

* Sections are visually separated.
* Health/mana/XP are easier to scan.
* Equipment is readable.
* Active quest objective is obvious.
* Messages are legible and not crammed.

---

# 5. Action Dock Redesign

## Requirement

Replace the uneven bottom controls with a grouped action dock.

## Action Groups

The action dock should have these groups:

1. Movement
2. Location Actions
3. Combat Actions
4. Class Skills
5. Panels

Recommended layout:

```text
+------------------------------------------------------------------------+
| Move: [N] [W][E] [S] | Location: [Open] [Shrine] | Combat: [Attack]   |
| Skills: [Ember Bolt] [Kindle] | Panels: [Inventory] [Talents] [Quests] |
+------------------------------------------------------------------------+
```

Alternatively use one horizontal row if space permits.

## Button Consistency

All buttons should use a shared fantasy button component.

Create:

```text
src/game/components/ui/FantasyButton.tsx
```

Suggested props:

```ts
interface FantasyButtonProps {
  children: React.ReactNode;
  variant?: "primary" | "danger" | "magic" | "utility" | "disabled";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  selected?: boolean;
  title?: string;
  onClick?: () => void;
}
```

## Image Buttons

Existing asset buttons like Attack, Inventory, and Quests may stay, but they should be wrapped or styled consistently so they do not clash with plain CSS buttons.

## Disabled Buttons

Disabled buttons must:

* Remain visible.
* Show a frame/border.
* Use reduced opacity, not vanish into black.
* Provide tooltip/title explaining why unavailable.
* Optionally add helper message on click if using soft-disabled behavior.

Examples:

```text
Open Container — disabled tooltip: No unopened container here.
Activate Shrine — disabled tooltip: No unused shrine here.
```

### Acceptance Criteria

* Bottom controls feel like one coherent UI system.
* Disabled controls are understandable.
* Skill buttons visually match the rest of the action dock.
* Movement controls remain quick and obvious.

---

# 6. Skill Button Polish

## Requirement

Improve class skill display and feedback.

## Skill Button Must Show

* Skill name
* Mana cost
* Cooldown state
* Disabled reason
* Optional icon/fallback symbol

Example:

```text
Ember Bolt
10 Mana
```

Cooldown example:

```text
Kindle
CD 2
```

Insufficient mana example:

```text
Ember Bolt
Need 10 Mana
```

## Skill Details Tooltip/Card

On hover or selection, show:

* Description
* Cost
* Cooldown
* Effect summary

Example:

```text
Ember Bolt
An ember bolt tears through the air.
Cost: 10 Mana
Cooldown: None
Effect: Deals fire damage scaling with Spell.
```

## Skill Visual Variants

Use class styling:

* Roadwarden: steel/gold accents
* Ember Sage: ember/red/orange accents
* Gravebound Scout: green/gray/violet accents

Do not hard-code too much styling into business logic. Use class ID to apply CSS class names.

### Acceptance Criteria

* Skills are readable.
* Disabled states explain why.
* Cooldowns are obvious.
* Skill buttons feel visually connected to class identity.

---

# 7. Inventory, Talent, and Quest Panels

## Requirement

Improve modal/panel presentation for secondary systems.

## Panel Behavior

Inventory, Talents, and Quests should open as overlay panels or anchored panels that do not destroy the main layout.

Recommended shared component:

```text
src/game/components/ui/FantasyPanel.tsx
```

Props:

```ts
interface FantasyPanelProps {
  title: string;
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
  size?: "md" | "lg" | "xl";
}
```

## Inventory Panel

Must clearly show:

* Inventory grid
* Selected item detail
* Equip/use/identify actions
* Equipped marker
* Unknown/locked/cursed states if Phase 5 is implemented

## Talent Panel

Must clearly show:

* Available points
* Talent nodes/cards
* Rank/max rank
* Locked/available/maxed state
* Prerequisite explanation

## Quest Panel

Must show:

* Full quest chain
* Active stage
* Completed stages
* Rewards if known
* Optional lore text

### Acceptance Criteria

* Panels look like part of the same game.
* Panels can be closed easily.
* Main gameplay state remains visible or recoverable.
* Panel content has enough spacing.

---

# 8. Typography and Color System

## Requirement

Define a small UI theme system so styling is consistent.

## Theme Tokens

Create CSS variables or theme constants for:

```css
--color-bg-deep: #080604;
--color-panel-dark: #120d09;
--color-panel-parchment: #c49a57;
--color-border-gold: #b9852d;
--color-text-primary: #f5e6bf;
--color-text-muted: #b8a27a;
--color-danger: #b5422d;
--color-success: #2f9e44;
--color-magic: #3f88c5;
--color-curse: #8e44ad;
```

Exact colors may be adjusted. The point is consistency.

## Typography Rules

* Headers use fantasy/display styling if available.
* Body text must remain readable.
* Do not use tiny text for critical game info.
* Use clear hierarchy:

  * Screen title
  * Section heading
  * Label
  * Value
  * Help text

## Text Size Targets

```text
Header zone/class: 20–24px
Panel heading: 18–22px
Body text: 14–16px
Small helper text: 12–13px minimum
```

### Acceptance Criteria

* Theme values are centralized.
* Major components use theme variables.
* Text contrast is acceptable.
* Typography hierarchy is clear.

---

# 9. Location Description and Context Feedback

## Requirement

Add a current-location detail card.

This can appear:

* Inside the map panel under/beside the map, or
* At the top of the side panel, or
* As a dedicated panel below the map.

## Location Detail Must Show

* Location name
* Description
* Available exits
* Available action(s)
* Encounter/container/shrine status if relevant

Example:

```text
Road Camp
The last safe fire before the Elder Road turns east into ash and old stone.

Exits: East, South
Available actions: None
```

For a chest tile:

```text
Abandoned Chest
A half-buried chest leans against a cracked milestone.

Available actions: Open Container
```

After opened:

```text
The chest hangs open. Whatever courage it once guarded is now yours.
```

### Acceptance Criteria

* Player always knows where they are.
* Available location actions are clear.
* Cleared/opened/activated states update descriptions.
* Location detail reduces reliance on tile text.

---

# 10. Feedback and Microinteractions

## Requirement

Add small visual feedback for key actions.

## Required Feedback

### Movement

* Current tile highlight moves smoothly or updates clearly.
* Add movement message.
* Optional brief tile glow.

### Invalid Movement

* Button shake or warning message.
* Do not silently fail.

### Combat

* Enemy tile/card flashes or animates briefly on hit.
* Health changes visibly.
* Combat message appears.

### Loot

* Loot message appears.
* Optional small item pop/floating text.

### Quest Completion

* Success message.
* Objective checkmark update.
* Optional brief glow on quest tracker.

### Level Up

* Strong success message.
* Level display updates with brief emphasis.

### Curses / Discovery If Implemented

* Curse reveal should feel alarming.
* Discovery reveal should feel special.

## Implementation Guidance

Use lightweight CSS transitions/animations.

Avoid introducing heavy animation libraries unless already installed.

Example CSS animation names:

```css
.hit-flash
.quest-complete-pulse
.tile-enter-glow
.curse-reveal-shudder
```

### Acceptance Criteria

* Major actions have visible feedback.
* Animations are brief and not annoying.
* Feedback improves clarity without slowing play.

---

# 11. Message Log Upgrade

## Requirement

Make the message log easier to scan.

## Message Presentation

Each message should show:

* Type label or icon
* Text
* Distinct styling by type

Example:

```text
[Info] Elder Road Outskirts opens before you.
[Class] A coal-bright ember stirs in your palm.
[Loot] You found an Identify Scroll.
[Combat] Ember Bolt burns Goblin Scout for 18 damage.
[Quest] Objective complete: Open the abandoned chest.
[Curse] Curse revealed: Blood Price.
```

## Message Ordering

Choose one and keep it consistent:

* Newest at top, or
* Newest at bottom

Preferred: newest at top for compact side panel.

## Message Limits

Show last 6–8 messages in side panel.

Full message history can be shown in expanded Quests/Log panel later. Not required.

### Acceptance Criteria

* Messages are clearly grouped by type.
* Important messages stand out.
* Log does not become a wall of same-colored text.
* Message order is consistent.

---

# 12. UI State Model

## Requirement

Centralize UI state so panels, debug mode, selected tile, and interaction modes are predictable.

## Required Type

```ts
export interface UiState {
  activePanel?: "inventory" | "talents" | "quests" | "log";
  debugMode: boolean;
  selectedTileId?: string;
  lastAnimation?: UiAnimationEvent;
}

export interface UiAnimationEvent {
  id: string;
  type:
    | "movement"
    | "hit"
    | "loot"
    | "quest_complete"
    | "level_up"
    | "discovery"
    | "curse";
  targetId?: string;
  createdAt: number;
}
```

## Actions

```ts
export type GameAction =
  | { type: "OPEN_PANEL"; panel: UiState["activePanel"] }
  | { type: "CLOSE_PANEL" }
  | { type: "TOGGLE_DEBUG_MODE" }
  | { type: "SELECT_TILE"; tileId?: string }
  | { type: "PUSH_UI_ANIMATION"; event: UiAnimationEvent }
  // existing actions
```

### Acceptance Criteria

* Only one major overlay panel is active at a time unless intentionally changed.
* Debug mode is centralized.
* UI animation triggers are state-driven or otherwise cleanly managed.
* Components do not maintain conflicting local panel state.

---

# 13. Component Refactor

## Requirement

Extract repeated visual patterns into reusable UI components.

## Required Components

```text
src/game/components/ui/FantasyButton.tsx
src/game/components/ui/FantasyPanel.tsx
src/game/components/ui/StatBar.tsx
src/game/components/ui/SectionCard.tsx
src/game/components/ui/IconLabel.tsx
src/game/components/ui/Tooltip.tsx
```

## Game Components To Refine

```text
HeaderBar
ZoneMap
ZoneTile
LocationDetails
RightPanel
CharacterSummary
EquipmentSummary
QuestTracker
MessageLog
ActionDock
MovementControls
ContextActions
CombatActions
SkillBar
InventoryPanel
TalentPanel
QuestPanel
```

## Acceptance Criteria

* Button styling is not duplicated across many components.
* Stat bars share one implementation.
* Panels share one implementation.
* Section cards share spacing/border behavior.
* Existing functionality remains intact.

---

# 14. Accessibility and Usability

## Requirement

Improve basic usability and keyboard support.

## Keyboard Controls

Required:

* WASD or arrow keys move player.
* `I` toggles inventory.
* `T` toggles talents.
* `Q` toggles quests.
* `Escape` closes active panel or cancels target mode.
* `1`, `2`, `3`, etc. trigger skill slots if in combat.

## Focus Behavior

* Buttons must have visible focus state.
* Overlay panels should focus their close button or heading on open.
* Escape closes panels.

## Tooltips / Titles

Buttons should explain disabled states.

Examples:

```text
No container at this location.
No shrine at this location.
No active enemy target.
Not enough mana.
Skill is on cooldown.
```

## Text Contrast

* Ensure text is readable on parchment and dark panels.
* Avoid low-contrast muted text for important values.

### Acceptance Criteria

* Keyboard shortcuts work.
* Focus state is visible.
* Escape behavior is consistent.
* Disabled actions explain why unavailable.
* Important text is readable.

---

# 15. Responsive Desktop Scaling

## Requirement

Support common desktop and laptop widths.

Target widths:

```text
1920px wide
1680px wide
1440px wide
1366px wide
```

This does not need a full mobile layout yet.

## Behavior

At narrower desktop widths:

* Map tiles may shrink slightly.
* Right panel width may reduce.
* Action dock may wrap to two rows.
* Header should not overflow.

## Avoid

* Horizontal scrolling at normal desktop widths.
* Header text overflow.
* Buttons overlapping.
* Panels opening off-screen.

### Acceptance Criteria

* UI works at 1366px width.
* Action dock wraps gracefully.
* Right panel remains usable.
* No major clipping/overlap.

---

# 16. Optional Art Pass

## Requirement

If time allows, improve the visual assets used by the UI.

## Optional Assets

Create or improve:

```text
src/assets/ui/panel-frame-dark.png
src/assets/ui/panel-frame-parchment.png
src/assets/ui/button-frame-gold.png
src/assets/ui/button-frame-red.png
src/assets/ui/button-frame-green.png
src/assets/ui/button-frame-blue.png
src/assets/ui/quest-marker.png
src/assets/ui/enemy-marker.png
src/assets/ui/chest-marker.png
src/assets/ui/shrine-marker.png
src/assets/ui/player-marker.png
```

## Guidance

Use CSS first. Only add image assets where they make a meaningful difference.

Do not spend this entire phase slicing decorative corners while the UI remains confusing. Pretty nonsense is still nonsense, just with trim.

### Acceptance Criteria

* If new assets are added, they have stable names and paths.
* UI can still run if optional assets are missing and fallbacks exist.
* Art improves clarity, not just decoration.

---

# 17. Testing Requirements

This is mostly a UI phase, but still add tests for behavior that can break.

## Required Test Areas

### UI State

* Opening inventory sets active panel to inventory.
* Opening talents replaces inventory as active panel.
* Closing panel clears active panel.
* Escape action closes active panel.
* Debug mode toggles.

### Disabled Actions

* Open container disabled when no unopened container exists.
* Activate shrine disabled when no unused shrine exists.
* Attack disabled or warns when no enemy is active.
* Skill disabled when cooldown or mana prevents use.

### Selectors

* Header view model hides debug fields by default.
* Location details selector returns correct actions.
* Tile view model returns correct visual state.
* Message log selector caps visible messages.

### Keyboard Shortcuts

If keyboard handling is easily testable:

* WASD/arrow dispatches movement.
* I/T/Q open correct panels.
* Escape closes panel.

## Acceptance Criteria

* Existing game logic tests still pass.
* UI selector tests cover key view model behavior.
* New UI state reducer tests pass.
* No test depends on fragile exact CSS class ordering.

---

# 18. Implementation Plan

## Step 1 — Add UI State Model

* Add `UiState` to game state.
* Add panel/debug/selected tile actions.
* Replace scattered panel state with centralized state.

## Step 2 — Create Shared UI Components

* Add `FantasyButton`.
* Add `FantasyPanel`.
* Add `StatBar`.
* Add `SectionCard`.
* Add `Tooltip` or use native title attributes initially.

## Step 3 — Redesign Header

* Replace pipe-separated status line.
* Add structured zone/class/level/gold/XP display.
* Hide coordinates behind debug mode.

## Step 4 — Rework Main Layout

* Use CSS Grid for main screen.
* Rebalance map and right panel.
* Ensure 1366px width works.

## Step 5 — Upgrade Map Tiles

* Increase tile size.
* Improve tile content hierarchy.
* Add marker states for player/enemy/container/shrine/objective.
* Add visited/current/cleared styling.

## Step 6 — Add Location Details

* Add current location card.
* Show exits and available actions.
* Reflect opened/cleared/activated states.

## Step 7 — Redesign Right Panel

* Split into Character Summary, Equipment, Quest Tracker, Message Log.
* Add stat bars.
* Improve spacing and section borders.

## Step 8 — Redesign Action Dock

* Group movement, location actions, combat, skills, and panels.
* Wrap existing image buttons in consistent styling or replace with shared component.
* Improve disabled button states.

## Step 9 — Polish Skill UI

* Show cost/cooldown/disabled reason.
* Add skill details tooltip/card.
* Apply class-themed variants.

## Step 10 — Improve Panels

* Standardize Inventory, Talents, and Quests panels.
* Ensure close/Escape works.
* Improve spacing and readability.

## Step 11 — Add Feedback Animations

* Add lightweight CSS animations for movement, hits, loot, quest complete, level up.
* Trigger from game actions or derived animation events.

## Step 12 — Improve Message Log

* Add type labels/icons.
* Style message types.
* Cap visible messages.

## Step 13 — Keyboard and Accessibility Pass

* Add keyboard shortcuts.
* Add focus states.
* Add disabled titles/tooltips.
* Verify contrast.

## Step 14 — Tests and Cleanup

* Add UI state tests.
* Add selector tests.
* Run full build/test.
* Remove obsolete debug display.

---

# 19. Suggested Commit Plan

```text
1. feat: add centralized UI state for panels and debug mode
2. feat: add shared fantasy UI components
3. refactor: redesign game header and hide debug coordinates
4. refactor: rebalance main game layout
5. feat: upgrade zone map tile visual states
6. feat: add current location details panel
7. refactor: split right panel into readable sections
8. refactor: redesign action dock and disabled button states
9. feat: polish skill buttons with cost cooldown and details
10. refactor: standardize inventory talent and quest panels
11. feat: add lightweight feedback animations
12. feat: improve message log type styling
13. feat: add keyboard shortcuts and focus behavior
14. test: cover UI state selectors and disabled action view models
15. style: final desktop responsive polish
```

---

# 20. Acceptance Criteria for Entire Phase

Phase 6 is complete when:

1. Header no longer looks like a debug/status dump.
2. Zone, class, level, XP, and gold are clearly displayed.
3. Coordinates are hidden unless debug mode is enabled.
4. Main layout is balanced and uses screen space well.
5. Map tiles are larger and visually distinct.
6. Current player location is obvious.
7. Enemy/container/shrine/objective markers are clear.
8. Current location details are visible.
9. Right panel has readable sections.
10. Health, mana, and XP use shared stat bars.
11. Equipment display is compact and clear.
12. Quest tracker highlights active objectives.
13. Message log is easier to scan by type.
14. Action dock groups controls logically.
15. Buttons share a consistent fantasy style.
16. Disabled actions explain why they are unavailable.
17. Skill buttons show cost, cooldown, and disabled state.
18. Inventory, Talent, and Quest panels share common presentation.
19. Basic keyboard shortcuts work.
20. UI remains usable at 1366px desktop width.
21. Existing gameplay systems still work.
22. Existing tests still pass.
23. New UI state/selector tests pass.

---

# 21. Future Phase Hooks

After this phase, EldersCourage will be better positioned for deeper gameplay work.

Good next phase candidates:

## Phase 7 Candidate A — Ring Souls

* Rings contain trapped spellcaster souls.
* Attunement unlocks memories.
* Rings whisper advice, lies, threats, and bargains.
* Ring curses become personality-driven.

## Phase 7 Candidate B — Multi-Zone Expansion

* Add second and third zones.
* Add zone transitions.
* Add broader quest progression.
* Add more enemy types and environmental hazards.

## Phase 7 Candidate C — Item Synergies and Merging

* Items combine or resonate.
* Some synergies are explicit.
* Some require scrolls.
* Some are discovered through combat/use.
* Some create curses.

## Phase 7 Candidate D — Expanded Class Trees

* More active skills.
* Skill upgrades.
* Talent branches.
* Build specialization.

Do not implement these during Phase 6. This phase is about making the existing game feel coherent enough to deserve more systems.

---

# 22. Definition of Done

Phase 6 is done when the player can look at the screen and immediately understand:

* Where they are
* Who they are
* What they can do
* What is dangerous
* What matters next
* What just happened

The game should still be small, but it should feel intentional.

Not final. Not AAA. Not fake-polished.

Just clear, readable, fantasy-rich, and ready for the next layer of trouble.
