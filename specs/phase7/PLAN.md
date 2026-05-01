# EldersCourage Phase 7 Implementation Plan

## Purpose

This plan converts `specs/phase7/SPEC.md` into an implementation sequence for the current Godot project.

Phase 7 is a UI cleanup and presentation phase. The existing launch scene is `game/scenes/phase3/ElderRoadOutskirts.tscn`, the screen is built mostly in `game/scripts/phase3/elder_road_outskirts.gd`, and gameplay state lives in `game/scripts/phase3/phase3_state.gd`. Phase 6 already added a structured header, map tiles, right panel sections, action dock groups, panel state, keyboard shortcuts, and initial feedback. Phase 7 should refine that work into a cohesive UI without adding new gameplay systems.

The target is a cleaner, more deliberate Godot-native interface: consistent spacing, shared theme resources, clearer visual hierarchy, stronger disabled/action states, less cramped side information, better map/location presentation, consistent buttons and overlays, and a small motion pass.

## Guiding Principles

- Keep the launch scene stable and continue using `ElderRoadOutskirts.tscn`.
- Do not add new gameplay systems, classes, zones, enemies, item mechanics, save/load, controller support, or mobile-specific UI.
- Treat Phase 7 as a presentation refactor over the existing Phase 3 through Phase 6 loop.
- Prefer Godot `Control` nodes, containers, `Theme`, `StyleBoxFlat`, scenes, and small scripts over browser/web concepts.
- Centralize style and display-state logic where it reduces duplication, but avoid a full UI rewrite.
- Preserve all current controls, keyboard shortcuts, inventory/talent/quest overlays, combat flow, item discovery behavior, and quest behavior.
- Keep Phase 1 and Phase 2 direct scene loads working.
- Add automated tests only for pure Go view models/state helpers or deterministic GDScript-adjacent logic mirrored in Go; do not force visual automation.
- Manual UI verification is required because this phase is mostly visual.

## Current Implementation Notes

The current UI is concentrated in:

```text
game/scripts/phase3/elder_road_outskirts.gd
game/scripts/phase3/phase3_state.gd
game/scenes/phase3/ElderRoadOutskirts.tscn
game/assets/ui/
game/assets/terrain/
game/assets/items/
```

Existing strengths to preserve:

- Header with logo, zone, class/level, XP, talent points, gold, and debug toggle.
- Map grid with tile textures, current/enemy/objective/container/shrine states, and location details.
- Right panel with character summary, equipment, quest focus, enemy panel, and messages.
- Grouped action dock with movement, location, combat, skills, and panels.
- Central UI state for active panel and debug mode.
- Inventory, talents, and quest overlays.
- Keyboard shortcuts for movement, interact, combat, panels, debug, skills, and cancel.

Current risks:

- `elder_road_outskirts.gd` is large and mixes construction, styling, view-model formatting, refresh logic, and interactions.
- Styling is mostly inline helper code rather than a project-level theme.
- Buttons and image buttons use different visual systems.
- Overlay panels use fixed positions and sizes.
- Location details, disabled reasons, message presentation, and tile state formatting are partially duplicated in UI code.

## Target Structure

Introduce reusable UI resources incrementally. Do not create every scene listed in the spec unless it removes real duplication.

Recommended additions:

```text
game/
  resources/
    themes/
      elders_courage_theme.tres
  scenes/
    ui/
      FantasyButton.tscn
      FantasyTextureButton.tscn
      FantasyPanel.tscn
      SectionCard.tscn
      StatBar.tscn
      MessageRow.tscn
      ActionGroup.tscn
  scripts/
    ui/
      fantasy_button.gd
      fantasy_texture_button.gd
      stat_bar.gd
      message_row.gd
      ui_view_models.gd
```

If scene extraction slows progress, use script helper builders first and extract scenes only after the behavior is stable. The important outcome is consistency and maintainability, not a particular file count.

Add optional pure helper tests under:

```text
internal/phase7/
```

Use `internal/phase7` for deterministic selectors such as action availability, message limits, tile visual state, location details, and header display data if those helpers are mirrored in Go.

## Baseline Check

### Tasks

Run:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

### Visual Baseline

Capture or note the current state at common desktop sizes:

```text
1920x1080
1680x1050
1440x900
1366x768
```

Record the most visible problems before editing:

- Header balance and unused space.
- Map panel spacing and tile readability.
- Right panel crowding.
- Action dock height and button consistency.
- Overlay positions and clipping.
- Disabled button clarity.

### Exit Criteria

- Existing Go tests and data validation pass.
- Phase 1, Phase 2, and Phase 3 scenes load headlessly.
- The current UI issues are written down before visual changes begin.

## Milestone 1: Theme and Spacing Foundation

### Goal

Create a central visual language so colors, font sizes, panel borders, padding, and disabled states do not drift across the screen.

### Implementation Tasks

1. Create or refine:

   ```text
   game/resources/themes/elders_courage_theme.tres
   ```

2. Define shared intent colors:
   - deep background
   - dark panel
   - muted parchment panel
   - aged gold/bronze border
   - primary off-white text
   - secondary muted tan text
   - heading gold
   - danger red/orange
   - success green
   - magic blue/cyan
   - curse purple
   - disabled desaturated brown/gray
3. Define shared font sizes:
   - header zone title
   - section heading
   - tile name
   - tile subtitle/type
   - body text
   - button label
   - button sublabel
   - status tag/message type
4. Normalize spacing constants in helper functions or the theme:
   - 8-12px outer margins
   - 10-14px panel padding
   - 8-12px section spacing
   - 8-10px button group gaps
   - 8-10px tile gaps
5. Apply the theme to the root scene or primary root control.
6. Reduce repeated inline stylebox creation where theme overrides can carry the style.
7. Keep helper functions such as `_stylebox` only where dynamic state-specific style is needed.

### Exit Criteria

- Major UI controls use the shared theme or shared helper style constants.
- Panel parchment is less saturated and no longer flattens hierarchy.
- Text contrast remains strong.
- Spacing values are consistent across header, map panel, right panel, dock, and overlays.
- Scene still loads headlessly.

## Milestone 2: Shared UI Components

### Goal

Introduce reusable controls for the repeated UI patterns that currently live directly in `elder_road_outskirts.gd`.

### Implementation Tasks

1. Add or emulate `FantasyButton` with support for:
   - label
   - sublabel
   - icon
   - variants: `primary`, `secondary`, `danger`, `magic`, `success`, `panel`
   - states: normal, hovered, pressed, disabled, selected, attention
   - disabled reason via tooltip or sublabel
2. Add or emulate `FantasyTextureButton` for attack, inventory, and quest image buttons:
   - consistent size
   - matching frame
   - hover/focus/disabled visuals
   - tooltip support
3. Add or emulate `FantasyPanel` and `SectionCard`:
   - consistent padding
   - consistent border weights
   - strong outer panels, subtler inner cards
4. Add `StatBar` helper or scene:
   - label
   - current/max text
   - progress fill
   - variant color
5. Add `MessageRow` helper or scene:
   - type tag
   - message text
   - subtle type color
6. Add `ActionGroup` helper or scene for dock groups:
   - heading
   - stable padding
   - aligned group heights
7. Migrate one area at a time:
   - action dock buttons first
   - right panel stat/message rows next
   - overlay buttons last

### Exit Criteria

- Most buttons use one shared code path or scene.
- Image buttons and text buttons feel related.
- Disabled reason handling is consistent.
- Section card and stat bar presentation is reusable.
- Existing button actions still call the same state methods.

## Milestone 3: UI View Models and Selectors

### Goal

Move display decisions out of node-building code where practical, especially disabled reasons, tile state, message limits, and location details.

### Implementation Tasks

1. Add:

   ```text
   game/scripts/ui/ui_view_models.gd
   ```

2. Implement small selectors:
   - `get_header_view_model(state)`
   - `get_character_summary_view_model(state)`
   - `get_equipment_view_model(state)`
   - `get_active_quest_view_model(state)`
   - `get_visible_messages(state, limit := 5)`
   - `get_tile_view_model(state, tile)`
   - `get_location_details_view_model(state)`
   - `get_action_availability_view_model(state)`
   - `get_skill_button_view_models(state)`
3. Keep selectors read-only.
4. Preserve existing state methods for actual gameplay actions.
5. Use selectors first in new/refactored UI areas; avoid converting the entire file in one pass.
6. Add Go tests in `internal/phase7` only if the selector logic is mirrored in Go. Prioritize:
   - header hides debug fields by default
   - messages cap at 4-6 in the right panel
   - location actions match current tile
   - disabled reasons distinguish no target, cooldown, no mana, no container, and no shrine
   - tile state distinguishes current, enemy, cache, shrine, objective, cleared, opened, and normal

### Exit Criteria

- Disabled reasons come from shared logic.
- Message limiting and labeling are centralized.
- Tile visual state is computed in one place.
- Location detail text and action availability agree.
- Tests exist for pure selector logic where practical.

## Milestone 4: Header Polish

### Goal

Refine the header into a composed HUD element that makes zone, class, level, XP, and gold clear without exposing debug data by default.

### Implementation Tasks

1. Keep the logo on the left, scaled consistently.
2. Compose text as:

   ```text
   Elder Road Outskirts
   Ember Sage · Level 1      XP 0/50      Gold 8
   ```

3. Add a subtle divider or accent line under the zone title.
4. Keep the compact XP bar, but align it with the meta row.
5. Group class and level together.
6. Add a small gold label/icon treatment if available; otherwise use text with the shared accent style.
7. Hide coordinates, raw tile IDs, and encounter IDs unless debug mode is enabled.
8. Verify header height remains compact at 1366x768.

### Exit Criteria

- Header looks intentionally composed.
- Logo and text align vertically.
- Zone title is prominent.
- Class/level/XP/gold are readable but secondary.
- Debug-only fields remain hidden by default.

## Milestone 5: Map Panel and Location Details

### Goal

Make the map feel less like a text-heavy debug board and more like a compact fantasy route map with an integrated location card.

### Implementation Tasks

1. Prefer a map + detail split if width allows:

   ```text
   Map Grid | Location Details
   ```

2. If the split causes crowding at smaller widths, fall back to location details below the map.
3. Increase the importance of tile icon/art and location name.
4. Make tile type/subtitle smaller and secondary.
5. Replace loud borders on normal road tiles with quieter styling.
6. Strengthen only meaningful states:
   - current tile: gold border, subtle warm glow, clear marker
   - enemy tile: red accent/marker
   - container tile: bronze/cache marker, muted once opened
   - shrine tile: green/teal marker, muted once activated
   - objective tile: purple/blue marker
   - cleared tile: visibly quieter
7. Create or normalize marker assets if needed:

   ```text
   game/assets/ui/markers/
   ```

8. If new art is not worth the time, use styled labels or small generated `Control` markers with stable helper names.
9. Upgrade current location details to a section card showing:
   - name
   - description
   - exits
   - available actions
   - tile status
   - nearby objective or danger when relevant
10. Ensure the detail card updates after opening containers, activating shrines, clearing encounters, and moving.

### Exit Criteria

- Tile hierarchy prioritizes icon/art and location identity.
- Current, enemy, cache, shrine, objective, opened, activated, cleared, and normal states are visually clear.
- Map panel uses space better.
- Location details look like part of the same UI system.
- Location details and action dock availability match.

## Milestone 6: Right Panel Cleanup

### Goal

Make the right-side information panel easier to scan and less visually heavy.

### Implementation Tasks

1. Rebuild right panel sections as `SectionCard`-style components:
   - Character Summary
   - Equipment
   - Quest Focus
   - Enemy, only when active
   - Messages
2. Reduce parchment saturation and border weight inside the panel.
3. Character Summary:
   - show class/name and level
   - pair Health/Mana/XP labels directly with bars
   - align STR/DEF/SPELL as a compact stat row
4. Equipment:
   - use slot rows
   - align slot label and item name
   - mute empty slots
   - mark equipped/selected only where relevant
5. Quest Focus:
   - show only active stage prominently
   - align objective checkboxes
   - mute completed objectives
   - keep next step clear
6. Messages:
   - show 4-6 messages
   - use `[Type] Message text`
   - style type tags subtly
   - improve row spacing
7. Keep the active enemy panel readable and visually distinct without overpowering the rest of the side panel.

### Exit Criteria

- Right panel no longer feels cramped.
- Character stats and bars are directly associated.
- Equipment rows align cleanly.
- Active quest objective is obvious.
- Message log is readable and does not dominate the panel.

## Milestone 7: Action Dock Cleanup

### Goal

Normalize the bottom action dock so movement, location actions, combat, skills, and panels feel like one UI system.

### Implementation Tasks

1. Keep existing groups:
   - Move
   - Location
   - Combat
   - Skills
   - Panels
2. Rebuild groups with shared `ActionGroup` style:
   - consistent heading
   - consistent internal padding
   - aligned heights
   - stable button sizes
3. Movement:
   - center the D-pad
   - use equal-sized controls
   - consider arrow glyphs if they read better than letters
4. Location:
   - show unavailable state cleanly
   - include visible sublabel or tooltip reason
5. Combat:
   - keep Attack visually primary
   - scale attack texture to match group height
   - show no-target disabled reason
6. Skills:
   - use class-themed accent
   - show readiness, need target, cooldown, or mana issue
   - keep labels and sublabels consistent
7. Panels:
   - make Inventory, Talents, Quests, and Restart consistent in sizing
   - show active selected state for open Inventory/Talents/Quests
8. Make the dock wrap predictably at 1366px without overlap.

### Exit Criteria

- Action dock groups align cleanly.
- Button styles are consistent across groups.
- Image buttons do not overpower text buttons.
- Disabled actions are clear and attractive enough.
- Dock takes less visual attention than map and right panel.

## Milestone 8: Disabled, Hover, Focus, and Selection States

### Goal

Make every interactive state understandable without relying only on color.

### Implementation Tasks

1. Define common disabled behavior:
   - button remains visible and framed
   - native disabled only when click behavior is unnecessary
   - tooltip or sublabel explains reason
2. Define soft-disabled behavior only if the button should emit warning messages on click.
3. Add disabled reasons for:
   - no unopened container
   - no unused shrine
   - no active enemy target
   - skill needs target
   - skill on cooldown
   - insufficient mana
   - no assigned skill
4. Add hover visuals:
   - slight brighten
   - border highlight
   - no layout shift
5. Add keyboard focus visuals:
   - visible focus ring or accent border
   - works for map tiles and dock buttons
6. Add active/selected visuals:
   - current tile
   - selected tile, if selection is retained
   - open panel button
   - selected inventory slot
7. Ensure current, selected, and hovered states cannot be confused.

### Exit Criteria

- Disabled actions do not look broken.
- Disabled reason is visible or available via tooltip.
- Hover and keyboard focus are visible.
- Active panel buttons show selected state.
- Current/selected/hovered map states are distinct.

## Milestone 9: Overlay Panel Cleanup

### Goal

Make Inventory, Talents, Quests, and class selection overlays feel consistent with the main UI and fit common desktop viewports.

### Implementation Tasks

1. Apply shared `FantasyPanel` and `SectionCard` styles.
2. Replace fixed absolute positioning where practical with centered anchors or viewport-relative placement.
3. Add a subtle dim/background frame if it improves focus.
4. Ensure every overlay has:
   - clear title
   - close button
   - consistent padding
   - bounded size
   - Escape behavior through `state.handle_escape()`
5. Inventory:
   - align slots
   - keep selected item detail in its own section
   - clearly mark equipped items
   - mute empty slots
6. Talents:
   - align talent rows/cards
   - distinguish locked, available, and maxed states
   - keep available points prominent
7. Quests:
   - keep active stage prominent
   - mute completed objectives
   - align objective rows
8. Class selection:
   - verify class cards fit at 1366x768
   - avoid clipped text or buttons

### Exit Criteria

- Overlays match the main UI language.
- Only one major overlay opens at a time.
- Escape and close buttons work consistently.
- Overlay content does not exceed screen bounds at target resolutions.

## Milestone 10: Minimal Motion Pass

### Goal

Add restrained feedback for important UI events without changing gameplay timing.

### Implementation Tasks

1. Use Godot `Tween` or `AnimationPlayer`.
2. Add short 100-400ms feedback for:
   - movement/current tile pulse
   - enemy tile or enemy card hit flash
   - invalid action message/button pulse
   - quest objective completion highlight
   - level up or major success header/summary glow
3. Reuse existing `state.ui.lastAnimation` or replace it with a small event queue if needed.
4. Ensure animations do not block input.
5. Avoid long chains or repeated loud pulses.
6. Keep animation optional/tolerant when a target node is not present.

### Exit Criteria

- Movement has visible feedback.
- Combat hits have visible feedback.
- Quest completion has visible feedback.
- Invalid actions feel acknowledged.
- Animations remain subtle and do not disrupt readability.

## Milestone 11: Desktop Scaling Pass

### Goal

Make the UI usable at common desktop resolutions, including 1366x768.

### Implementation Tasks

1. Check:

   ```text
   1920x1080
   1680x1050
   1440x900
   1366x768
   ```

2. Verify:
   - no horizontal scrolling
   - header does not overflow
   - map tiles remain readable
   - right panel remains usable
   - action dock wraps cleanly
   - overlays fit within viewport
   - text does not overlap or clip
3. Adjust:
   - min sizes
   - container size flags
   - action dock wrapping
   - right panel width min/max
   - tile sizes
   - overlay anchors
4. Keep hard-coded pixel positioning only where unavoidable.

### Exit Criteria

- Game screen is usable at 1366x768.
- Panels scale or wrap predictably.
- No major controls overlap.
- No critical text is clipped.

## Milestone 12: Verification Checklist and Acceptance Record

### Goal

Close the phase with explicit manual verification notes because visual quality cannot be proven by Go tests alone.

### Implementation Tasks

1. Add:

   ```text
   specs/phase7/UI_VERIFICATION.md
   specs/phase7/ACCEPTANCE.md
   ```

2. `UI_VERIFICATION.md` should include checks for:
   - header readability
   - map tile states
   - location detail card
   - right panel sections
   - action dock groups
   - disabled reasons
   - hover/focus/selected states
   - overlay open/close behavior
   - keyboard shortcuts
   - combat feedback
   - quest update feedback
   - message log readability
   - 1920x1080
   - 1680x1050
   - 1440x900
   - 1366x768
3. `ACCEPTANCE.md` should record:
   - implemented changes
   - verification commands
   - manual checks completed
   - known limitations
   - deferred polish
4. Run final verification:

   ```bash
   go test ./...
   go run ./cmd/elders validate-data ./game/data
   go run ./cmd/elders acceptance-report ./game/data
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
   ```

### Exit Criteria

- Manual UI verification checklist exists.
- Acceptance record exists.
- Existing tests and validation pass.
- Godot headless scene loads pass.
- Known remaining visual/manual risks are documented.

## Suggested Implementation Order

1. Baseline verification and visual notes.
2. Shared theme, colors, font sizes, and spacing constants.
3. Reusable button, texture button, panel, section, stat bar, message row, and action group helpers.
4. View-model/selectors for header, tile state, location details, actions, skills, and messages.
5. Header polish.
6. Map panel and location detail cleanup.
7. Right panel cleanup.
8. Action dock cleanup.
9. Disabled, hover, focus, selected, and active panel states.
10. Overlay cleanup.
11. Minimal motion pass.
12. Desktop scaling pass.
13. UI verification checklist and acceptance record.
14. Final automated checks and manual verification notes.

## Suggested Commit Plan

```text
1. Add shared Phase 7 UI theme and spacing constants
2. Add reusable fantasy UI controls
3. Extract UI view model helpers
4. Polish header presentation
5. Improve map tile hierarchy and location details
6. Clean up right panel sections
7. Normalize action dock groups and button states
8. Standardize overlays and panel active states
9. Add subtle UI feedback animations
10. Add Phase 7 UI verification and acceptance docs
11. Fix desktop scaling issues
```

## Phase Acceptance Criteria

Phase 7 is complete when:

1. The UI still contains all existing gameplay controls and information.
2. The launch scene remains `game/scenes/phase3/ElderRoadOutskirts.tscn`.
3. Header layout is composed, readable, and free of default debug data.
4. Map panel uses space better than the Phase 6 version.
5. Map tiles are less text-heavy and state-driven.
6. Current, enemy, cache, shrine, objective, opened, activated, cleared, and normal tile states are clear.
7. Location details are presented as a clean card.
8. Right panel sections are easier to scan.
9. Health, mana, and XP bars are directly associated with labels.
10. Equipment rows are aligned and readable.
11. Active quest objectives are obvious.
12. Message rows are visually distinct by type.
13. Action dock groups align cleanly.
14. Button styles are consistent across text and image controls.
15. Disabled buttons explain why they are unavailable.
16. Skill buttons distinguish ready, need target, cooldown, and insufficient mana states.
17. Inventory, Talents, Quests, and class selection overlays look consistent.
18. Hover, focus, active, selected, and current states are visible.
19. Minimal motion feedback exists for movement, combat, invalid actions, quest updates, and major success.
20. UI works at 1920x1080, 1680x1050, 1440x900, and 1366x768 without major overlap or clipping.
21. Phase 1, Phase 2, and Phase 3 scenes still load headlessly.
22. `go test ./...` passes.
23. `go run ./cmd/elders validate-data ./game/data` passes.
24. `go run ./cmd/elders acceptance-report ./game/data` passes.
25. `specs/phase7/UI_VERIFICATION.md` exists.
26. `specs/phase7/ACCEPTANCE.md` exists.

## Deferred Work

Do not include these in Phase 7 unless explicitly requested after the UI cleanup is accepted:

- Ring soul systems.
- Multi-zone expansion.
- New classes, skills, enemies, or quests.
- New item discovery mechanics.
- Save/load work.
- Mobile UI.
- Controller support.
- Full animation system.
- Deep inventory, talent, or quest redesign.
- Large art production pass.

## Definition of Done

Phase 7 is done when the same playable screen feels intentionally designed rather than merely functional. The mechanics should be unchanged, but the screen should have clearer hierarchy, cleaner spacing, more consistent controls, better map readability, easier side-panel scanning, clearer disabled reasons, and enough feedback to make movement, combat, quest progress, and panel interactions feel responsive.
