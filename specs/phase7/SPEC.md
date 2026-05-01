# EldersCourage — Phase 7 SPEC.md

## Phase Name

**Phase 7: UI Cleanup, Visual Hierarchy, Spacing, and Interaction Clarity**

## Canonical Implementation Target

This is a **Godot project**.

All implementation should use Godot-native systems:

- Godot 4.x
- Scenes / `.tscn` files
- Control nodes
- Container nodes
- Themes / StyleBox resources
- TextureButton / Button nodes
- GridContainer / HBoxContainer / VBoxContainer / PanelContainer / MarginContainer
- Tween / AnimationPlayer for feedback
- InputMap for shortcuts
- GDScript unless the project already uses C#

Any older React, Vite, TypeScript, CSS, or browser references from prior specs are obsolete implementation details. Preserve the design intent, not the web stack.

---

# Purpose

The current UI is functional and heading in the right direction. It has the important parts: logo, header, zone map, player status, equipment, quest tracker, message log, movement controls, location actions, combat, skills, inventory, talents, and quests.

It is not terrible. It is also not great yet.

The main problem is not missing functionality. The problem is presentation: spacing, hierarchy, alignment, visual weight, inconsistent panel styles, crowded right-side information, and map/action areas that still feel more like a prototype than an intentional fantasy RPG interface.

This phase focuses only on UI cleanup and usability polish. Do not add new gameplay systems. The goal is to make the existing game screen feel clean, deliberate, readable, and pleasant to play.

---

# Current UI Assessment

The current screen is a solid functional prototype.

What works:

- The logo looks good and gives the game identity.
- The header is much cleaner than the earlier debug pipe-line version.
- The zone map is understandable.
- Tile categories are clearer: road, cache, shrine, enemy, objective.
- Current location is obvious.
- The side panel contains the right information.
- The action dock is grouped into Move, Location, Combat, Skills, and Panels.
- Skill buttons now show state such as `Need target` and `Ready`.
- The location detail block is useful.

What still needs work:

- The screen has too many similar rectangular boxes competing for attention.
- The right panel is readable but visually heavy and a little cramped.
- The map tiles still feel text-heavy and board-game-like.
- The bottom action dock takes a lot of vertical space but still feels under-designed.
- Some panels have inconsistent padding and border weight.
- The header has unused dark space and could be more polished.
- The parchment panel color is strong and flattens the information hierarchy.
- The map area has unused empty space below/right of the map grid.
- Buttons mix image assets and flat text controls in a way that almost works but not quite.
- There is not enough distinction between primary, secondary, disabled, and contextual actions.

This phase should clean that up without blowing up the working implementation.

---

# Primary Goal

Improve the overall UI presentation so the existing screen feels like a cohesive fantasy RPG interface rather than a prototype layout.

The player should immediately understand:

1. Where they are.
2. What state their character is in.
3. What tile matters next.
4. What actions are available.
5. What actions are disabled and why.
6. What quest objective is active.
7. What just happened.
8. Which controls are primary versus secondary.

---

# Non-Goals

Do **not** implement in this phase:

- New gameplay systems
- New classes
- New skills
- New zones
- New enemies
- New item discovery mechanics
- Save/load
- Procedural generation
- Full animation system
- Mobile UI
- Controller support
- Inventory redesign beyond visual cleanup
- Talent tree redesign beyond visual cleanup
- Quest system redesign beyond visual cleanup

Small UI-facing data additions are allowed only when they support presentation, such as tile subtitles, short descriptions, icon paths, or disabled reasons.

---

# Design Direction

The UI should feel like:

- Dark fantasy
- Parchment and carved wood
- Old road maps
- Heavy buttons
- Clear game controls
- Readable information panels
- Practical, not ornamental sludge

Avoid:

- Corporate dashboard layout
- Too many same-weight boxes
- Giant empty regions
- Overly noisy frames
- Tiny text
- Debug labels
- Color-only status communication
- Excessive decorative borders around every single thing

The UI should be more polished, but not overdecorated. It should feel like a game, not a medieval tax form.

---

# Deliverables

## 1. Theme Cleanup

### Requirement

Create or refine a centralized Godot theme for the game UI.

Recommended file:

```text
res://resources/themes/elders_courage_theme.tres
```

If a theme already exists, refine it instead of creating a duplicate.

## Theme Should Define

- Default font sizes
- Panel styles
- Button styles
- Label colors
- Section heading styles
- Tooltip style
- Progress bar style
- Disabled control styling

## Color Tokens / Style Targets

Use a consistent palette. Exact values can vary, but establish named intent:

```text
Deep Background: near-black warm brown
Panel Dark: dark brown/black
Panel Parchment: muted parchment, less saturated than current
Border Gold: aged gold / bronze
Text Primary: warm off-white
Text Secondary: muted tan
Text Heading: gold
Danger: red/orange
Success: green
Magic: blue/cyan
Curse: purple
Disabled: desaturated brown/gray
```

### Acceptance Criteria

- Major UI controls use the shared theme.
- Panel colors are less visually overpowering.
- Text contrast remains strong.
- Repeated inline styling is reduced.
- Theme can be adjusted from one place.

---

# 2. Global Spacing and Layout Rules

## Requirement

Normalize spacing across the screen.

## Target Spacing

Use consistent margins/padding:

```text
Outer screen margin: 8–12 px
Panel internal padding: 10–14 px
Section spacing: 8–12 px
Button group gap: 8–10 px
Tile gap: 8–10 px
```

## Layout Rules

- Align major panel edges.
- Keep border widths consistent.
- Avoid tiny differences in panel positioning.
- Avoid multiple nested borders unless they communicate hierarchy.
- Give high-density panels more internal spacing.

## Godot Implementation Notes

Use:

- `MarginContainer` for consistent panel padding.
- `VBoxContainer` / `HBoxContainer` `separation` values.
- `GridContainer` constants for map gaps.
- Theme constants where possible.

### Acceptance Criteria

- Header, map panel, right panel, and action dock align cleanly.
- Padding feels consistent across panels.
- UI no longer looks like every section invented spacing independently.
- No important text hugs panel borders.

---

# 3. Header Polish

## Requirement

Improve the header so it feels like a polished game HUD, not just a logo plus text.

## Current Issues

- Logo is strong, but the rest of the header feels sparse.
- There is unused dark space across the header.
- Zone title and stats are functional but could be better composed.

## Desired Header Layout

Recommended structure:

```text
+---------------------------------------------------------------+
| [Logo]  Elder Road Outskirts                                  |
|         Ember Sage · Level 1      XP 0/50      Gold 8          |
+---------------------------------------------------------------+
```

Enhance with:

- Subtle horizontal divider under zone title.
- Small icon or label for gold.
- Compact XP bar or slim progress line.
- Class and level grouped together.
- Optional class color accent.

## Do Not Show

- Raw coordinates
- Debug tile IDs
- Encounter IDs
- Excessive separators

Those belong behind debug mode.

### Acceptance Criteria

- Header looks intentionally composed.
- Zone title is prominent.
- Class/level/xp/gold are readable but secondary.
- Logo and text align vertically.
- Header height is not excessive.

---

# 4. Map Panel Cleanup

## Requirement

Improve the map panel presentation and reduce the board-game/debug feeling.

## Current Issues

- Tiles are understandable but text-heavy.
- Tile type labels like `Road`, `Cache`, `Enemy`, `Objective` compete with location names.
- Icons are small and sometimes feel decorative rather than informative.
- Map grid occupies only part of the large map panel.
- Location details sit at the bottom-left with a lot of unused surrounding space.

## Desired Direction

The map should feel like a compact illustrated adventure board or old route map.

Each tile should prioritize:

1. Location identity
2. Icon/art
3. State marker
4. Interaction marker
5. Type label only if necessary

## Tile Content Revision

Current style:

```text
Cache
Abandoned Chest
```

Preferred style:

```text
[Chest Icon]
Abandoned Chest
Cache
```

Or:

```text
[Icon] Abandoned Chest
Cache
```

Tile type should be smaller and secondary.

## Tile Visual States

Refine these states:

### Current Tile

- Gold border
- Slight warm glow
- Player marker or `YOU` badge
- Keep it obvious but not huge

### Enemy Tile

- Red border/accent
- Enemy marker
- Location name readable
- Optional subtle pulse only when active/nearby

### Container Tile

- Bronze/gold accent
- Chest/cache marker
- Muted if opened

### Shrine Tile

- Green/teal accent
- Shrine marker
- Muted if activated

### Objective Tile

- Purple/blue accent
- Quest marker
- Should stand out from normal route tiles

### Normal Road Tile

- Lower visual weight
- No loud border unless current/hovered/selected

## Map Panel Space Use

Choose one of these approaches:

### Option A — Larger Centered Map

- Increase tile size.
- Center map grid in the available panel.
- Keep location details below map.

### Option B — Map + Location Detail Split

Use map panel as two columns:

```text
+-------------------------------------------+
| Map Grid                 Location Details |
|                          Available Actions|
|                          Nearby Threats   |
+-------------------------------------------+
```

For the current screen, **Option B is preferred** because there is unused horizontal space.

## Location Details Upgrade

Location detail should look like a real card, not plain text at the bottom.

Show:

- Location name
- Short description
- Exits
- Available actions
- Nearby warning/objective if relevant

Example:

```text
Road Camp
A cold camp at the edge of the elder road.

Exits: South, East
Available: None
Nearby: Abandoned Chest to the east
```

### Acceptance Criteria

- Tile text hierarchy is improved.
- Tile icons are larger/more meaningful.
- Map panel uses space better.
- Location details are visually integrated.
- Current, enemy, cache, shrine, and objective states are obvious.

---

# 5. Right Panel Cleanup

## Requirement

Improve the right-side panel readability and reduce visual heaviness.

## Current Issues

- Parchment background is strong and makes all sections compete.
- Section borders are clear but a bit heavy.
- Character Summary, Equipment, Quest, and Messages all have similar weight.
- Progress bars are present but not labeled clearly enough.
- Message log is cramped.

## Desired Structure

Right panel should be a vertical stack of distinct section cards:

```text
Character Summary
Equipment
Quest Focus
Messages
```

Each section should have:

- Clear heading
- Internal padding
- Consistent heading style
- Slight separation from other sections
- Less heavy border than the outer panel

## Character Summary Improvements

Current:

```text
Health 85/85  Mana 85/85
XP 0/50
STR 1 DEF 1 SPELL 8
[bar]
[bar]
[bar]
```

Preferred:

```text
Ember Sage — Level 1
Health  85/85  [bar]
Mana    85/85  [bar]
XP       0/50  [bar]

STR 1   DEF 1   SPELL 8
```

Bars should be directly associated with labels.

## Equipment Improvements

Current equipment is readable, but should use slot rows:

```text
Weapon   Ember Staff
Armor    Empty
Trinket  Cracked Ember Charm
```

Empty slots should be visually muted, not same weight as equipped items.

## Quest Focus Improvements

Show only the active quest stage prominently.

Example:

```text
The Elder Road
Recover Supplies
☐ Open the abandoned chest
☐ Find the Old Sword

Next: Clear the Road
```

Completed or inactive stages can be smaller/collapsed.

## Message Log Improvements

Messages should be easier to scan:

```text
[Info] Elder Road Outskirts opens before you.
[Success] A coal-bright ember stirs in your palm.
```

Use message type styling, but keep it subtle.

### Acceptance Criteria

- Right panel feels less cramped.
- Character stats and bars are easier to scan.
- Equipment rows align cleanly.
- Active quest objective is obvious.
- Messages are readable and visually separated.

---

# 6. Action Dock Cleanup

## Requirement

Improve the bottom action dock so it feels consistent, compact, and intentional.

## Current Issues

- Grouping is good, but the dock is visually bulky.
- Movement buttons, disabled location buttons, image buttons, skill buttons, and panel buttons all feel like different UI systems.
- Inventory and Quest image buttons look good but are oversized relative to neighboring controls.
- Location action buttons look flat and weak.
- Disabled buttons are readable but not attractive.

## Desired Action Dock Structure

Keep grouped sections:

1. Move
2. Location
3. Combat
4. Skills
5. Panels

But normalize visual treatment.

## Dock Rules

- Each group gets a small heading.
- Each group uses consistent padding.
- Group heights align.
- Buttons inside groups share consistent height where practical.
- Image buttons are scaled to match the row.
- Disabled buttons retain frame and tooltip.

## Movement Group

Improve the directional pad:

- Center the D-pad within its group.
- Use equal-sized buttons.
- Add hover/focus state.
- Consider arrow glyphs instead of letters if clearer.

Acceptable:

```text
    N
W       E
    S
```

Better if icons/glyphs are available:

```text
    ↑
←       →
    ↓
```

## Location Group

Disabled buttons should show clear unavailable state:

```text
Open Container
No container here
```

Or use tooltip only, but the state must be understandable.

## Combat Group

Attack button should remain visually primary, but not overpower the entire dock.

- Scale attack texture to fit group height.
- Add disabled state if no target.
- Add tooltip: `No enemy target`.

## Skills Group

Skill buttons should look more polished:

```text
Ember Bolt
Need target
```

```text
Kindle
Ready
```

Use class-themed accent for skill buttons.

## Panels Group

Inventory / Talents / Quests should use consistent sizing.

If image buttons remain:

- Scale image buttons to similar height.
- Put Talent button in matching framed style.
- Avoid one plain button sitting awkwardly between image buttons.

### Acceptance Criteria

- Action dock groups align cleanly.
- Button styles are consistent across groups.
- Image buttons do not overpower neighboring buttons.
- Disabled actions are clear and attractive enough.
- Dock takes less visual attention than map and right panel.

---

# 7. Button System Cleanup

## Requirement

Create or refine a reusable fantasy button scene.

Recommended scene:

```text
res://scenes/ui/FantasyButton.tscn
res://scripts/ui/fantasy_button.gd
```

## Button Variants

Support variants:

```text
primary
secondary
danger
magic
success
panel
disabled
```

## Button States

Support states:

```text
normal
hovered
pressed
disabled
selected
attention
```

## Button API

Suggested script methods/properties:

```gdscript
@export var label_text: String
@export var sublabel_text: String
@export var variant: String = "secondary"
@export var icon: Texture2D
@export var disabled_reason: String = ""

func set_disabled_with_reason(disabled: bool, reason: String = "") -> void
func set_selected(selected: bool) -> void
func configure(label: String, sublabel: String = "", new_variant: String = "secondary") -> void
```

## Texture Buttons

For existing asset buttons, either:

1. Wrap them inside a common framed container, or
2. Create `FantasyTextureButton.tscn` with matching sizing, hover, disabled, and tooltip behavior.

Recommended:

```text
res://scenes/ui/FantasyTextureButton.tscn
```

### Acceptance Criteria

- Most buttons use shared button scenes.
- Button labels/sublabels are consistent.
- Disabled reason is exposed via tooltip or helper text.
- Image buttons have matching interaction states.

---

# 8. Panel System Cleanup

## Requirement

Create or refine reusable section/panel scenes.

Recommended scenes:

```text
res://scenes/ui/FantasyPanel.tscn
res://scenes/ui/SectionCard.tscn
res://scenes/ui/StatBar.tscn
```

## FantasyPanel

Used for large panels:

- Header
- Map panel
- Right panel
- Action dock groups
- Inventory/Talents/Quests overlays

## SectionCard

Used inside larger panels:

- Character Summary
- Equipment
- Quest Focus
- Messages
- Location Details

## StatBar

Used for:

- Health
- Mana
- XP
- Enemy health
- Attunement progress if present

## StatBar Requirements

Should show:

- Label
- Current value
- Max value
- Progress fill
- Optional color variant

Example API:

```gdscript
func configure(label: String, current: int, maximum: int, variant: String) -> void
```

### Acceptance Criteria

- Panels and section cards have consistent padding/borders.
- Stat bars are reusable and aligned.
- Right panel uses SectionCard-style components.
- Location detail card uses same section style.

---

# 9. Typography Cleanup

## Requirement

Improve text hierarchy.

## Text Categories

Define consistent styles for:

```text
Game title / logo image
Screen title
Section heading
Subheading
Body text
Muted/helper text
Button label
Button sublabel
Status tag
Message type label
```

## Font Sizes

Suggested sizes:

```text
Header zone title: 22–26 px
Section heading: 16–18 px
Tile location name: 14–16 px
Tile type/subtitle: 11–12 px
Body text: 13–15 px
Button label: 14–16 px
Button sublabel: 11–13 px
```

Use Godot theme font sizes where possible.

## Text Rules

- Avoid all important info using the same gold color.
- Use gold for headings/accent, not every piece of data.
- Use white/off-white for primary readable text.
- Use muted tan for secondary labels.
- Keep warning/danger colors reserved for meaningful danger.

### Acceptance Criteria

- Headings stand out from body text.
- Secondary labels are visibly secondary.
- Tile names are readable.
- Button text is readable.
- Message types are distinguishable.

---

# 10. Icon and Marker Cleanup

## Requirement

Improve map and UI icon consistency.

## Required Marker Types

Create or normalize markers for:

```text
player/current location
enemy
container/cache
shrine
quest objective
opened/cleared
locked/unavailable
```

Recommended paths:

```text
res://assets/ui/markers/player_marker.png
res://assets/ui/markers/enemy_marker.png
res://assets/ui/markers/container_marker.png
res://assets/ui/markers/shrine_marker.png
res://assets/ui/markers/objective_marker.png
res://assets/ui/markers/cleared_marker.png
```

If art is unavailable, use styled labels or simple ColorRect/icon placeholders with stable file paths or scene names.

## Marker Rules

- Markers should be small but clear.
- Do not rely only on border color.
- Enemy markers should not look like quest markers.
- Objective markers should feel special.
- Cleared/opened markers should be visibly muted.

### Acceptance Criteria

- Map states are understandable without reading every label.
- Icons/markers feel consistent.
- Objective and enemy markers are not confused.
- Marker system is reusable.

---

# 11. Reduce Visual Noise

## Requirement

Reduce the number of competing borders, colors, and same-weight boxes.

## Cleanup Rules

- Outer panels may have strong borders.
- Inner sections should use lighter borders or subtle backgrounds.
- Not every tile needs a loud border.
- Use accent borders only for meaningful state.
- Use consistent corner radius.
- Reduce parchment saturation if it overwhelms text.
- Avoid too many bright colors visible at once.

## Specific Targets

- Right panel inner cards should have subtler borders than the outer panel.
- Normal map tiles should be quieter.
- Enemy/objective/current tiles should carry stronger accents.
- Bottom dock group borders should be slightly less dominant.

### Acceptance Criteria

- The eye is drawn first to map/current state, then right panel, then actions.
- Normal/non-action elements fade slightly into the background.
- Important/actionable elements stand out.
- UI feels less noisy overall.

---

# 12. Current Location Detail Upgrade

## Requirement

Make current location details more useful and better positioned.

## Detail Content

Show:

- Location name
- Description
- Exits
- Available actions
- Tile status
- Nearby objective or danger if applicable

Example:

```text
Road Camp
A cold camp at the edge of the elder road.

Exits: South, East
Available: None
Nearby: Abandoned Chest east, Scout Ambush southeast
```

For active action locations:

```text
Abandoned Chest
A half-buried chest leans against a cracked milestone.

Available: Open Container
Quest: Recover Supplies
```

For enemy locations:

```text
Scout Ambush
A goblin scout waits low in the ditch grass.

Threat: Goblin Scout
Available: Attack
```

## Placement

Prefer placing this beside the map grid if screen space allows.

If not, keep below the map but style as a section card.

### Acceptance Criteria

- Location detail is visually prominent enough to be useful.
- Available actions match action dock enabled states.
- Text updates after opening/clearing/activating.
- Detail card uses shared SectionCard styling.

---

# 13. Message Log Cleanup

## Requirement

Make message log easier to scan and less cramped.

## Message Row Format

Each row should have:

```text
[Type] Message text
```

Examples:

```text
[Info] Elder Road Outskirts opens before you.
[Success] A coal-bright ember stirs in your palm.
[Combat] Ember Bolt burns the Goblin Scout for 18 damage.
[Quest] Objective complete: Open the abandoned chest.
```

## Message Type Styling

Use subtle styles:

```text
Info: muted tan
Success: green accent
Warning: amber accent
Combat: red/orange accent
Loot: gold accent
Discovery: blue/magic accent
Curse: purple accent
Quest: gold/white accent
```

Do not make every message a glowing carnival float.

## Limits

- Show 4–6 messages in the right panel.
- Newest first or newest last, but be consistent.
- If there is a full log panel, it can show more. Not required.

### Acceptance Criteria

- Message types are distinguishable.
- Message spacing is improved.
- Important messages stand out.
- Log does not dominate the right panel.

---

# 14. Disabled and Unavailable States

## Requirement

Make unavailable actions understandable and visually intentional.

## Current Problem

Disabled actions such as Open Container and Activate Shrine are technically understandable, but they feel visually weak and a little dead.

## Required Behavior

For any unavailable action:

- Button remains visible.
- Button is visually disabled but framed.
- Tooltip or sublabel explains why.
- Optional click on disabled button may add a warning message, but this is not required.

## Examples

```text
Open Container
No container here
```

```text
Activate Shrine
No shrine here
```

```text
Attack
No target
```

```text
Ember Bolt
Need target
```

## Godot Notes

Godot disabled buttons may not emit pressed signals. If the desired UX is to show a warning on click, use a soft-disabled custom state instead of the native disabled property.

### Acceptance Criteria

- Disabled actions do not look broken.
- Disabled reason is visible or available via tooltip.
- Skill disabled states distinguish between no target, cooldown, and insufficient mana.
- Location action disabled states match current tile state.

---

# 15. Hover, Focus, and Selection States

## Requirement

Add clearer hover/focus/selection states.

## Required States

### Map Tile Hover

- Slight brighten or border highlight.
- Optional location preview in detail card if selected/hovered behavior exists.

### Current Tile

- Strong persistent current state.

### Selected Tile

- If tile selection exists, selected tile should differ from current tile.

### Button Hover

- Slight brightness increase.
- Border or scale change.

### Keyboard Focus

- Visible focus ring or border.
- Should not be ugly. But ugly focus is better than invisible focus. Barely.

### Active Panel Button

- Inventory/Talents/Quests button should indicate when its panel is open.

### Acceptance Criteria

- Hovering interactive elements provides feedback.
- Keyboard focus is visible.
- Active/selected/current states are not confused.
- Panel buttons reflect active panel state.

---

# 16. Panel Overlay Cleanup

## Requirement

If Inventory, Talents, or Quests open as overlays, clean up their presentation.

## Overlay Requirements

- Dim or frame the background subtly.
- Panel has clear title and close button.
- Escape closes the overlay.
- Panel content has consistent padding.
- Panel does not exceed screen bounds.
- Only one major overlay should be open at a time.

## Inventory Visual Cleanup

- Inventory slots should align cleanly.
- Selected item detail should have its own section.
- Equipped items should be clearly marked.
- Empty slots should be quiet.

## Talent Visual Cleanup

- Talent nodes/cards should align consistently.
- Locked/available/maxed states should be clear.
- Available points should be prominent.

## Quest Visual Cleanup

- Active stage prominent.
- Completed stages muted/collapsed.
- Objective checkboxes aligned.

### Acceptance Criteria

- Overlays look like part of the same UI system.
- Escape and close buttons work consistently.
- Overlay content spacing is improved.
- Opening panels does not distort the main layout.

---

# 17. Minimal Motion Pass

## Requirement

Add restrained motion to improve game feel.

## Required Microinteractions

Use Godot `Tween` or `AnimationPlayer`.

### Movement

- Current tile glow/pulse briefly after movement.

### Hit Feedback

- Enemy tile/card flashes briefly on hit.

### Invalid Action

- Button or message area gives subtle shake/pulse.

### Quest Objective Complete

- Quest tracker row briefly highlights.

### Level Up / Major Success

- Header or character summary briefly glows.

## Motion Rules

- Animations should be short: 100–400 ms.
- Do not block input.
- Do not chain long sequences.
- Respect readability.

### Acceptance Criteria

- Movement has feedback.
- Combat hit has feedback.
- Quest completion has feedback.
- Animations feel helpful, not noisy.

---

# 18. Desktop Scaling Pass

## Requirement

Make the UI behave well across common desktop sizes.

## Target Resolutions

Test manually at:

```text
1920x1080
1680x1050
1440x900
1366x768
```

## Rules

- No horizontal scrolling/clipping.
- Header should not overflow.
- Action dock should remain usable.
- Right panel should remain readable.
- Map tiles may shrink at smaller widths but should not become unreadable.
- Overlays should fit within viewport.

## Godot Notes

Use Control anchors, containers, size flags, and minimum sizes carefully.

Avoid hard-coded pixel positioning except where absolutely necessary.

### Acceptance Criteria

- Game screen is usable at 1366x768.
- No major overlapping controls.
- Panels scale or wrap predictably.
- Action dock remains readable.

---

# 19. Optional Asset Cleanup

## Requirement

Only if time allows, improve or normalize image assets.

## Possible Improvements

- Crop logo more cleanly if needed.
- Normalize button image sizes.
- Create smaller versions of Attack/Inventory/Quest button textures.
- Add marker icons for map states.
- Add subtle panel background textures.

## Important Rule

Do not waste this phase chasing perfect art. Layout and readability matter more.

A clean UI with placeholder art beats a beautiful mess. The mess just has nicer shoes.

### Acceptance Criteria

- Any new assets have stable `res://assets/...` paths.
- Image buttons are scaled consistently.
- Marker icons improve clarity.
- Missing optional assets do not break the scene.

---

# 20. Godot Scene Targets

## Requirement

Refactor or create scenes as needed to support cleanup.

## Recommended Scene List

```text
res://scenes/ui/HeaderBar.tscn
res://scenes/ui/FantasyPanel.tscn
res://scenes/ui/SectionCard.tscn
res://scenes/ui/FantasyButton.tscn
res://scenes/ui/FantasyTextureButton.tscn
res://scenes/ui/StatBar.tscn
res://scenes/ui/MessageRow.tscn
res://scenes/ui/ActionGroup.tscn

res://scenes/map/ZoneMap.tscn
res://scenes/map/ZoneTile.tscn
res://scenes/map/LocationDetails.tscn

res://scenes/ui/RightPanel.tscn
res://scenes/ui/ActionDock.tscn
res://scenes/ui/CharacterSummary.tscn
res://scenes/ui/EquipmentSummary.tscn
res://scenes/ui/QuestFocus.tscn
res://scenes/ui/MessageLog.tscn
```

Do not create every scene if the current project already has a reasonable equivalent. Refactor incrementally.

### Acceptance Criteria

- Reusable UI patterns are extracted where duplication exists.
- Scene naming is consistent.
- Scripts are attached where behavior is needed.
- Scene hierarchy remains understandable.

---

# 21. UI View Model / Selector Cleanup

## Requirement

Avoid putting formatting logic directly inside UI nodes wherever practical.

Create helper methods/selectors for display data.

Recommended file:

```text
res://scripts/systems/ui_view_models.gd
```

## Suggested Helpers

```gdscript
func get_header_view_model(game_state) -> Dictionary
func get_character_summary_view_model(game_state) -> Dictionary
func get_equipment_view_model(game_state) -> Array
func get_active_quest_view_model(game_state) -> Dictionary
func get_visible_messages(game_state, limit: int = 5) -> Array
func get_tile_view_model(game_state, tile_id: String) -> Dictionary
func get_location_details_view_model(game_state) -> Dictionary
func get_action_availability_view_model(game_state) -> Dictionary
func get_skill_button_view_models(game_state) -> Array
```

## Benefit

This makes the UI easier to clean up without breaking game logic.

### Acceptance Criteria

- UI nodes consume prepared display data where useful.
- Disabled reasons come from shared logic.
- Tile visual state comes from shared logic.
- Message limits and formatting are centralized.

---

# 22. Testing / Verification Requirements

This is mostly a presentation phase, but it still needs verification.

## Required Manual Verification

Create or update a checklist file:

```text
UI_VERIFICATION.md
```

Checklist should include:

- Header readability
- Map tile states
- Right panel sections
- Action dock groups
- Disabled reasons
- Panel open/close behavior
- Keyboard shortcuts
- Resolution checks
- Combat feedback
- Quest update feedback
- Message log readability

## Automated Tests If Existing Test Setup Allows

Test pure logic/view-model helpers:

- Header view model hides debug fields by default.
- Location details show correct exits and available actions.
- Tile view model returns correct state for current/enemy/cache/shrine/objective.
- Action availability returns disabled reasons.
- Message log caps visible messages.
- Skill button model shows target/cooldown/mana state.

Do not force heavy UI automation if the project does not already have it.

### Acceptance Criteria

- Manual UI verification checklist exists.
- View model helpers are tested where practical.
- Existing gameplay tests still pass.
- No new UI cleanup breaks movement/combat/inventory/quests.

---

# 23. Implementation Plan

## Step 1 — Establish Theme and Spacing Rules

- Create/refine shared Godot Theme.
- Normalize panel padding and container separation.
- Define common colors and font sizes.

## Step 2 — Refactor Shared UI Components

- Add/refine FantasyButton.
- Add/refine FantasyTextureButton.
- Add/refine FantasyPanel.
- Add/refine SectionCard.
- Add/refine StatBar.
- Add/refine MessageRow.

## Step 3 — Header Cleanup

- Improve alignment of logo/title/status.
- Add compact XP presentation.
- Reduce empty feeling in header.
- Ensure debug-only fields remain hidden.

## Step 4 — Map Panel Cleanup

- Improve tile hierarchy.
- Make icons/markers more meaningful.
- Reduce normal tile visual noise.
- Improve current/enemy/cache/shrine/objective states.
- Reposition or restyle location details.

## Step 5 — Right Panel Cleanup

- Split into cleaner section cards.
- Improve Character Summary bars.
- Align equipment rows.
- Simplify quest focus.
- Improve message rows.

## Step 6 — Action Dock Cleanup

- Normalize group heights and padding.
- Improve movement D-pad.
- Improve location buttons.
- Scale image buttons consistently.
- Improve skill buttons.
- Improve active panel button state.

## Step 7 — Disabled State Cleanup

- Add disabled reasons to buttons.
- Use tooltips/sublabels consistently.
- Differentiate no target, no mana, cooldown, unavailable location.

## Step 8 — Overlay Panel Cleanup

- Standardize inventory/talents/quests panel presentation.
- Improve close/Escape behavior if needed.
- Ensure only one major panel opens at a time.

## Step 9 — Minimal Motion Pass

- Add movement glow.
- Add hit flash.
- Add quest completion pulse.
- Add invalid-action feedback.

## Step 10 — Desktop Scaling Pass

- Test target resolutions.
- Adjust minimum sizes and wrapping.
- Fix clipping/overflow.

## Step 11 — View Model Cleanup

- Extract display helpers where the UI is doing too much logic.
- Add tests if project test setup supports it.

## Step 12 — Verification and Cleanup

- Add `UI_VERIFICATION.md`.
- Run project.
- Verify movement/combat/skills/inventory/talents/quests still work.
- Remove obsolete styling or duplicated UI code.

---

# 24. Suggested Commit Plan

```text
1. style: add shared Godot UI theme and spacing constants
2. refactor: introduce reusable fantasy panel button and stat bar scenes
3. refactor: polish header layout and status presentation
4. refactor: improve map tile hierarchy and marker states
5. refactor: upgrade location details card
6. refactor: clean up right panel section layout
7. refactor: normalize action dock groups and button sizing
8. refactor: improve disabled action states and tooltips
9. refactor: standardize inventory talent and quest overlays
10. feat: add lightweight movement combat and quest feedback animations
11. refactor: add UI view model helpers for display state
12. docs: add UI verification checklist
13. fix: desktop scaling and final UI polish
```

---

# 25. Acceptance Criteria for Entire Phase

Phase 7 is complete when:

1. The UI still contains all existing gameplay controls and information.
2. The header feels composed and polished.
3. The map panel uses space better.
4. Map tiles are less text-heavy.
5. Current/enemy/cache/shrine/objective states are visually clear.
6. Location details are presented as a clean card.
7. Right panel sections are easier to scan.
8. Health, mana, and XP bars are directly associated with labels.
9. Equipment rows are aligned and readable.
10. Active quest objectives are obvious.
11. Message log rows are visually distinct by type.
12. Action dock groups align cleanly.
13. Button styles are more consistent.
14. Image buttons are scaled consistently with other controls.
15. Disabled buttons explain why they are unavailable.
16. Skill buttons show readiness, target requirement, cooldown, or mana issue clearly.
17. Inventory/Talents/Quests overlays look consistent.
18. Hover/focus/selected states are visible.
19. Minimal motion feedback exists for movement/combat/quest updates.
20. UI works at common desktop resolutions, including 1366x768.
21. Existing gameplay behavior still works.
22. Any existing automated tests still pass.
23. A manual UI verification checklist exists.

---

# 26. Future Phase Hooks

After this UI cleanup phase, the game should be ready for deeper content and systems.

Good next phase candidates:

## Candidate A — Ring Souls

- Rings contain trapped spellcaster souls.
- Rings whisper, bargain, lie, and remember.
- Attunement reveals soul fragments and curses.

## Candidate B — Multi-Zone Expansion

- Add a second explorable zone.
- Add zone transitions.
- Add stronger quest progression.

## Candidate C — Item Synergies and Merging

- Equipment combinations unlock hidden effects.
- Scrolls reveal synergies.
- Some combinations create curses.

## Candidate D — Expanded Combat Presentation

- Enemy cards.
- Better attack/spell feedback.
- Floating combat text.
- Turn/encounter summary.

Do not start these during Phase 7. Clean the table before serving the next course.

---

# 27. Definition of Done

Phase 7 is done when the UI no longer merely works, but feels deliberately designed.

It should still be the same game screen, with the same mechanics, but cleaner:

- Better spacing
- Better hierarchy
- Better button consistency
- Better map readability
- Better right-panel scanning
- Better action clarity
- Better feedback

The goal is not perfection. The goal is to remove the prototype smell.

A little smell is fine. This is game development, not a candle shop. But less of it.

