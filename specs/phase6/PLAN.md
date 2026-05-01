# EldersCourage Phase 6 Implementation Plan

## Purpose

This plan converts `specs/phase6/SPEC.md` into an implementation sequence for the current repository.

The Phase 6 spec describes React/CSS components, but EldersCourage is currently Godot-first. Phase 1 through Phase 5 are implemented in Godot, the launch scene is `game/scenes/phase3/ElderRoadOutskirts.tscn`, and the current play surface is built in `game/scripts/phase3/elder_road_outskirts.gd` with state in `game/scripts/phase3/phase3_state.gd`. Phase 6 should polish that existing Godot UI rather than introducing a browser stack.

The target is presentation quality: a clearer header, balanced layout, readable map, structured right panel, grouped action dock, better skill and inventory presentation, location details, message styling, keyboard usability, and light feedback. No new major gameplay systems should be added.

## Guiding Principles

- Keep the launch scene stable and continue using `ElderRoadOutskirts.tscn`.
- Improve readability and game feel without changing combat, item, class, talent, or quest rules.
- Prefer Godot controls, themes, styleboxes, and small helper functions over broad scene rewrites.
- Centralize UI state for panels, debug mode, selected tile, and feedback events.
- Keep Phase 1, Phase 2, and Phase 3 direct scene loads working.
- Keep asset loading tolerant of fresh clones with no `.godot/imported` cache.
- Add Go helper tests only for deterministic UI view models and state selectors, not for exact visual styling.
- Avoid major animation frameworks, new zones, new systems, and balance churn.

## Target Structure

Extend the existing layout:

```text
game/
  scripts/
    phase3/
      elder_road_outskirts.gd
      phase3_state.gd
  assets/
    ui/
      existing UI assets and optional new marker/button assets
```

If the UI script becomes too large, split reusable UI helpers into:

```text
game/
  scripts/
    phase6/
      phase6_theme.gd
      phase6_view_models.gd
      phase6_ui_helpers.gd
```

Add pure helper tests under:

```text
internal/phase6/
```

Use this package for view-model logic such as header display data, location action availability, tile visual state, message filtering, and UI panel state.

## Baseline Check

### Tasks

Run:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
```

### Exit Criteria

- Existing tests and validation pass.
- Phase 1, Phase 2, and Phase 3 scenes load headlessly.
- The current Phase 3 launch scene loads on a fresh import cache path.
- Current visual issues are noted before edits begin.

## Milestone 1: Centralized UI State

### Goal

Replace scattered panel flags with a single predictable UI state model.

### Implementation Tasks

1. Add `ui` state to `phase3_state.gd`:
   - `activePanel`: `""`, `inventory`, `talents`, `quests`, or `log`
   - `debugMode`: false by default
   - `selectedTileId`
   - `lastAnimation` or a small animation event dictionary
2. Keep existing inventory/talent booleans as compatibility shims only if needed during migration.
3. Add state actions:
   - `open_panel(panel_id)`
   - `close_panel()`
   - `toggle_panel(panel_id)`
   - `toggle_debug_mode()`
   - `select_tile(tile_id)`
   - `push_ui_animation(type, target_id)`
4. Wire `I`, talent toggle, quest button, and close behavior through the centralized state.
5. Add `Escape` behavior:
   - cancel identify target mode first
   - close active panel next
6. Add `internal/phase6` tests for:
   - opening inventory sets active panel
   - opening talents replaces inventory
   - closing clears panel
   - debug mode toggles

### Exit Criteria

- Only one major overlay panel is active at a time.
- Existing inventory and talent toggles still work.
- UI state helper tests pass.
- Scene loads headlessly.

## Milestone 2: Theme and Shared UI Helpers

### Goal

Centralize styling so buttons, panels, section cards, stat bars, and message labels share one visual language.

### Implementation Tasks

1. Add theme constants or helper functions in `elder_road_outskirts.gd` or `phase6_theme.gd` for:
   - deep background
   - dark panel
   - parchment panel
   - gold border
   - primary text
   - muted text
   - danger
   - success
   - magic
   - curse
2. Add reusable helper builders:
   - fantasy button
   - image button frame
   - section card
   - stat bar row
   - icon/label row
   - closeable overlay panel
3. Convert existing plain text buttons to use the shared button helper.
4. Preserve image buttons, but wrap or style them consistently.
5. Add visible disabled style with border and reduced opacity.
6. Add focus style for keyboard navigation.

### Exit Criteria

- Button styling is not duplicated across many code paths.
- Disabled controls remain visible and readable.
- Existing controls still invoke the same state actions.

## Milestone 3: Header Redesign

### Goal

Replace the current pipe-separated status line with a structured player-facing header.

### Implementation Tasks

1. Keep the EldersCourage logo on the left.
2. Add separate header labels/rows for:
   - zone name
   - current class and level
   - XP progress
   - gold
3. Add a compact XP progress bar.
4. Remove raw position and tile text from the default header.
5. Add debug row or compact debug label shown only when `debugMode` is enabled:
   - position
   - tile ID/name
   - encounter ID if present
6. Add Go view-model test for header data hiding debug fields by default.

### Exit Criteria

- Header no longer reads like a debug dump.
- Zone, class, level, XP, and gold remain visible.
- Coordinates are hidden by default.
- Header fits at common desktop widths.

## Milestone 4: Main Layout Rebalance

### Goal

Recompose the screen so map, right panel, and action dock feel intentionally placed.

### Implementation Tasks

1. Rework the root layout into:
   - header
   - main content row
   - action dock
2. Make the map panel the visual center and main focus.
3. Set right panel width with a stable minimum and maximum.
4. Make the action dock wrap or use two rows at narrower desktop widths.
5. Avoid large unused blank space in the map panel.
6. Check layout at:
   - 1920 width
   - 1680 width
   - 1440 width
   - 1366 width
7. If needed, reduce side padding and button widths for 1366px.

### Exit Criteria

- Map is no longer visually tucked into a corner.
- Right panel does not feel cramped.
- Bottom controls do not overlap.
- No normal desktop width needs horizontal scrolling.

## Milestone 5: Map Tile Visual Upgrade

### Goal

Make zone tiles communicate terrain, current position, interactions, enemies, and cleared states more clearly.

### Implementation Tasks

1. Increase tile minimum size toward 140x96 or larger where layout allows.
2. Reduce label dominance and let texture/icon/marker carry more meaning.
3. Add tile marker text or icons for:
   - current player position
   - enemy
   - unopened container
   - opened container
   - shrine
   - activated shrine
   - objective/elder stone
4. Add clear visual states:
   - current tile with gold border and glow
   - visited tile
   - unvisited visible tile
   - danger/enemy tile
   - cleared/opened/activated tile
5. Add tooltips that summarize tile action/status.
6. Add a Go tile view-model test for current/enemy/container/shrine state selection.

### Exit Criteria

- Current location is obvious at a glance.
- Enemy, container, shrine, and objective tiles are distinguishable.
- Opened and activated states read differently from available states.
- Tile art is more visible than tile text.

## Milestone 6: Current Location Details

### Goal

Add a readable current-location detail card to reduce reliance on dense tile labels.

### Implementation Tasks

1. Add a location details panel inside or adjacent to the map panel.
2. Show:
   - location name
   - location description
   - available exits
   - available actions
   - encounter/container/shrine state
3. Update details after movement, container open, shrine activation, encounter completion, and quest completion.
4. Add helper methods for:
   - valid exits from current tile
   - available actions at current tile
   - cleared/opened/activated state text
5. Add Go selector tests for location actions.

### Exit Criteria

- Player always has a readable description of the current location.
- Available actions are clear before pressing buttons.
- Cleared states update location details.

## Milestone 7: Right Panel Redesign

### Goal

Split the parchment/status area into readable stacked sections.

### Implementation Tasks

1. Replace the single cramped side panel contents with section cards:
   - Character Summary
   - Equipment
   - Quest Tracker
   - Message Log
2. Add stat bars for:
   - health
   - mana
   - XP
3. Keep primary stats in a compact row:
   - Strength
   - Defense
   - Spell
4. Rework equipment display:
   - slot label
   - item display name
   - styled empty slot
5. Show only the active quest stage expanded by default.
6. Dim completed stages.
7. Add a visible enemy card or preserve existing enemy panel as a combat subsection.

### Exit Criteria

- Health, mana, and XP are easier to scan.
- Equipment is compact and readable.
- Active quest objectives are obvious.
- Message log has enough spacing.

## Milestone 8: Message Log Upgrade

### Goal

Make recent events easier to scan and prioritize.

### Implementation Tasks

1. Standardize message types:
   - info
   - success
   - warning
   - combat
   - loot
   - discovery
   - curse
2. Show type label or icon on every visible message.
3. Style each type with color and label, not color alone.
4. Pick a single ordering and keep it consistent.
5. Prefer newest messages at top for compact side panel.
6. Cap visible messages to 6 to 8 in the side panel.
7. Add optional full log panel if cheap after centralized UI state.
8. Add Go selector test for visible message capping and ordering.

### Exit Criteria

- Important messages stand out.
- Curse and discovery messages are visibly distinct.
- Message log does not become a wall of same-colored text.

## Milestone 9: Action Dock Redesign

### Goal

Group controls into a coherent bottom action dock.

### Implementation Tasks

1. Split controls into groups:
   - Movement
   - Location
   - Combat
   - Skills
   - Panels
2. Add group labels with restrained text size.
3. Use shared button styling for movement, location, talents, restart, and utility buttons.
4. Frame Attack, Inventory, and Quest image buttons consistently or replace them with styled text/icon buttons.
5. Improve disabled tooltips:
   - no container here
   - shrine unavailable
   - no active enemy
   - not enough mana
   - cooldown remaining
6. Consider soft-disabled behavior only if Godot tooltips are insufficient.

### Exit Criteria

- Bottom controls feel like one UI system.
- Disabled states explain why an action is unavailable.
- Related actions are grouped together.
- Action dock remains usable at 1366px width.

## Milestone 10: Skill Button Polish

### Goal

Make class skills readable, class-flavored, and self-explanatory.

### Implementation Tasks

1. Update skill buttons to show:
   - skill name
   - mana cost or no-cost state
   - cooldown state
   - disabled reason
2. Add skill tooltip/detail text:
   - description
   - cost
   - cooldown
   - simple effect summary
3. Add class visual variants:
   - Roadwarden: steel/gold
   - Ember Sage: ember/red/orange
   - Gravebound Scout: green/gray/violet
4. Keep class style mapping in one helper, keyed by class ID.
5. Add keyboard shortcuts for skill slots `1`, `2`, etc. when usable.

### Exit Criteria

- Skill state is understandable without trial and error.
- Cooldowns and insufficient mana are obvious.
- Skill buttons match the action dock visual language.

## Milestone 11: Inventory, Talent, and Quest Panel Polish

### Goal

Make secondary panels feel like a consistent part of the game interface.

### Implementation Tasks

1. Convert inventory and talent panels to a shared overlay frame helper.
2. Add a close button and Escape support.
3. Improve inventory:
   - equipped marker
   - selected item details spacing
   - Identify target mode banner
   - valid/invalid identify target styling
   - unknown/locked/cursed/attuned states from Phase 5
4. Improve talents:
   - available point emphasis
   - locked/available/ranked/maxed styling
   - prerequisite explanation
5. Add a quest panel if not already present:
   - full quest chain
   - active stage
   - completed stages
   - reward summary if present
6. Ensure panels stay on-screen at 1366px width.

### Exit Criteria

- Panels share one visual frame.
- Panels close predictably.
- Inventory and talents are readable.
- Main gameplay state remains recoverable.

## Milestone 12: Feedback and Microinteractions

### Goal

Add lightweight visual feedback for important actions without slowing play.

### Implementation Tasks

1. Add UI animation event state or simple one-shot style state.
2. Add brief feedback for:
   - movement/current tile change
   - invalid movement
   - enemy hit
   - loot pickup
   - quest completion
   - level up
   - discovery reveal
   - curse reveal
3. Use lightweight Godot timers/tweens or style changes.
4. Keep animations short and non-blocking.
5. Ensure headless scene load still passes without requiring rendered animation timing.

### Exit Criteria

- Major actions have visible feedback.
- Feedback is brief and does not obscure controls.
- Curse and discovery events feel distinct.

## Milestone 13: Keyboard and Usability Pass

### Goal

Improve basic keyboard support, focus visibility, and disabled-state clarity.

### Implementation Tasks

1. Keep WASD and arrow movement.
2. Keep `I` for inventory.
3. Add or align:
   - `T` or existing `Y` for talents, based on README/control consistency
   - `Q` for quests/log panel
   - `Escape` to close panel or cancel target mode
   - number keys for skill slots
4. Add visible focus state on buttons.
5. Ensure overlay panels set focus to close button or heading.
6. Add disabled tooltips for all unavailable actions.
7. Review text contrast on dark and parchment panels.
8. Update README controls if key bindings change.

### Exit Criteria

- Keyboard shortcuts work and are documented.
- Escape behavior is consistent.
- Focus states are visible.
- Important text remains readable.

## Milestone 14: Desktop Responsive Polish

### Goal

Verify and tune the UI at common desktop/laptop widths.

### Implementation Tasks

1. Use Godot window sizing or screenshots to inspect:
   - 1920px wide
   - 1680px wide
   - 1440px wide
   - 1366px wide
2. Tune:
   - tile size
   - right panel width
   - action dock wrapping
   - panel positions
   - text sizes
3. Avoid:
   - overlapping controls
   - clipped header text
   - off-screen overlays
   - unreadably tiny text
4. Document any dimensions that are not fully supported.

### Exit Criteria

- 1366px desktop width is usable.
- Header does not overflow.
- Action dock wraps or compresses gracefully.
- Panels stay on-screen.

## Milestone 15: Final Verification and Documentation

### Goal

Close Phase 6 with verification, README updates, and an acceptance record.

### Implementation Tasks

1. Run full verification commands.
2. Add `specs/phase6/ACCEPTANCE.md`.
3. Update `README.md` with:
   - Phase 6 UI polish summary
   - updated controls
   - debug mode if included
   - verification commands if changed
4. Confirm Phase 1, Phase 2, and Phase 3 scenes still load directly.
5. Confirm Phase 4 class selection and Phase 5 item discovery remain usable.
6. Commit final documentation.

### Exit Criteria

- Working tree is clean.
- Phase 6 acceptance record exists.
- Automated checks pass.
- Manual UI checklist is documented.

## Verification Commands

Run these after each milestone:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase2/FirstAdventureLoop.tscn --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/dungeons/AshenCatacombsRun.tscn --quit
git diff --check
```

Manual verification should cover:

- Launch Elder Road and choose each class.
- Confirm header shows zone, class, level, XP, and gold without coordinates.
- Toggle debug mode and confirm coordinates appear only there.
- Move across the map and confirm current tile state is obvious.
- Open a container, activate a shrine, defeat an enemy, and complete a quest objective.
- Confirm location details update after each action.
- Use basic attack and both class skills.
- Confirm skill disabled states explain mana/cooldown/target issues.
- Open and close inventory, talents, quests/log, and identify target mode.
- Confirm Escape closes panels or cancels target mode.
- Verify messages for combat, loot, quest, discovery, and curse are visually distinct.
- Check the UI at 1366px desktop width.

## Suggested Commit Plan

Use small commits:

1. `Add phase 6 implementation plan`
2. `Add phase 6 UI state helpers`
3. `Centralize Elder Road panel state`
4. `Add shared fantasy UI styling helpers`
5. `Redesign Elder Road header`
6. `Rebalance Elder Road layout`
7. `Upgrade Elder Road map tiles`
8. `Add current location details`
9. `Redesign Elder Road right panel`
10. `Improve message log styling`
11. `Redesign Elder Road action dock`
12. `Polish class skill buttons`
13. `Standardize inventory talent and quest panels`
14. `Add lightweight UI feedback events`
15. `Improve keyboard shortcuts and focus states`
16. `Tune desktop layout scaling`
17. `Document phase 6 acceptance status`

## Deferred Scope

Do not implement these in Phase 6:

- new zones
- new classes
- new skills or talent trees
- new item discovery mechanics
- new enemies except temporary testing fixtures
- save/load persistence
- procedural generation
- vendor/shop systems
- complex animation systems
- full mobile redesign
- deep accessibility audit
- combat formula changes
- major balance changes
- large art-production pass

## Risks and Mitigations

- Godot UI polish can become a broad rewrite. Mitigate by keeping milestones scoped to the existing launch scene and committing each section separately.
- The current UI script is already large. Mitigate by extracting helper scripts only when repeated UI code becomes hard to maintain.
- Asset preloads can fail on fresh clones without `.godot/imported` cache. Mitigate by preserving runtime-safe texture loading or adding explicit import-cache verification.
- Visual changes can break core interactions. Mitigate with headless scene checks after every milestone and manual checks for class selection, inventory, talents, skills, and item discovery.
- Responsive desktop tuning can consume the whole phase. Mitigate by targeting common desktop widths only and deferring mobile layout.
- UI state migration can conflict with Phase 5 identify target mode. Mitigate by preserving identify mode priority over panel close/toggle behavior.
