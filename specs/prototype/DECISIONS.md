# Prototype Decisions

## D001: Implement Milestones Sequentially

The first implementation covers Phase 0 and Phase 1 only. Later systems remain deferred to avoid building item and dungeon complexity before the combat loop is playable.

## D002: Use Root Go Module

The repository keeps the existing root `go.mod` and places the initial CLI at `cmd/elders`. This avoids nested module overhead while the tool surface is small.

## D003: Use Godot-Drawn Placeholder Visuals

The combat arena uses simple `Node2D` drawing rather than external art assets. This keeps the prototype runnable without asset acquisition and makes combat readability the first priority.

## D004: Use WASD Movement

The prototype starts with WASD movement, left mouse basic attack, `Q` Blood Cleave, `E` Grave Step, `R` Bell of the Dead, and `T` restart. This follows the spec preference when WASD conflicts with skill bindings.

## D005: Keep Phase 2 Combat Script-Local

Status effects are implemented directly on current combatants for Phase 2. A shared combat component should be extracted later, after loot and equipment clarify what combat modifiers need to support.

## D006: Reserve R for Bell of the Dead

Phase 2 uses left mouse for Grave Strike, `Q` for Blood Cleave, `E` for Grave Step, `R` for Bell of the Dead, and `T` to restart the arena. This keeps skills close to the spec while preserving a test restart key.

## D007: Use JSON Content Before Full Schemas

Phase 3 uses JSON item and loot files plus Go validation rules instead of a separate schema language. This keeps validation executable and easy to evolve as attunement, curses, and echoes arrive.

## D008: Use Keyboard-Driven Inventory for Prototype Speed

The first inventory UI is text-based: press `I` to show items and `1`-`4` to equip visible inventory entries. This is enough to verify pickup, tooltip, equipment slots, and stat application before building richer UI.

## D009: Use Per-Instance Attunement State

Loot pickups duplicate item definitions and add reveal fields to each item instance. This supports different copies of the same ring having different attunement progress and discoveries.

## D010: Identify First Unknown Property

Phase 4 uses `Z` to consume an Identify Scroll and reveal the first unknown property on equipped items, then inventory items. This avoids adding selection UI before the item discovery loop is proven.

## D011: Trigger Item Echoes on Any Enemy Kill

Phase 5 treats revealed item echoes as enemy-kill triggers with a chance to activate. This proves the echo loop before implementing narrower trigger taxonomies such as fire-only or skill-specific kills.

## D012: Respawn Without Reloading for Death Echo Testing

When the player dies, `T` respawns the player in the same arena if a Death Echo exists. This keeps the haunted-room state alive so reclaim behavior can be tested before full dungeon checkpoints exist.

## D013: Use Fixed Dungeon Order First

Phase 6 implements the Ashen Catacombs as a fixed room sequence navigated with `N`. This proves room flow, encounters, rewards, boss completion, and save/load before adding procedural ordering.

## D014: Save Through `user://`

The prototype writes JSON save data to `user://elders_save.json`, preserving player inventory, equipment, attunement, reveal state, room progress, completion state, and Death Echo state.

## D015: Enforce Prototype Content Counts in Go

Phase 7 keeps content completeness in the validator rather than a separate checklist. Count requirements are enforced when validating `game/data`, while small unit-test fixtures can still validate isolated rules.

## D016: Add Deterministic Loot Generation

`elders generate-loot` reads item JSON and selects a matching rarity using an explicit or stable seed. This provides the first deterministic simulation hook without introducing external dependencies.

## D017: Separate Static and Runtime Acceptance

Phase 8 adds `elders acceptance-report` for content/tooling checks that can run without Godot. Runtime gameplay acceptance remains explicit manual verification because this environment does not include the Godot executable.
