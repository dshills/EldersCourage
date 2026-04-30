# Repository Guidelines

## Project Structure & Module Organization

This repository is currently specification-first. The root contains `go.mod` for future Go tooling and `specs/prototype/SPEC.md` for prototype requirements. Follow the target structure described in the spec as implementation grows:

- `game/` for the Godot 4.x project, including `scenes/`, `scripts/`, `assets/`, `ui/`, and runtime `data/`.
- `tools/` for Go-based validation, loot and combat simulation, balance reports, and content generation.
- `specs/` for design, acceptance criteria, and implementation specifications.

Keep game runtime code, generated or authored content data, and external tools clearly separated.

## Build, Test, and Development Commands

No runnable application or test suite exists yet. Use these commands once the corresponding files are added:

- `go test ./...` runs all Go tooling tests.
- `go run ./cmd/elders ...` runs the future Go tooling CLI.
- `godot --path game` opens or runs the Godot project once `game/project.godot` exists.

Before adding dependencies or commands, document them in `README.md` or this file.

## Coding Style & Naming Conventions

For Go code, use `gofmt` and package names that are short, lowercase, and purpose-driven, such as `validate`, `loot`, or `balance`. Keep exported identifiers descriptive and only export APIs needed across packages.

For Godot code, prefer scene and script names that match gameplay concepts, for example `Player.tscn`, `GraveboundKnight.gd`, or `LootDrop.tscn`. Keep data files organized by domain under `game/data/`, such as `items/`, `enemies/`, `skills/`, and `echoes/`.

## Testing Guidelines

Add Go tests beside the code they cover using `_test.go` files. Prefer table-driven tests for validators, simulations, and deterministic generation. Keep gameplay rules data-driven enough that Go tooling can validate item schemas, enemies, loot tables, and balance constraints.

Run `go test ./...` before submitting Go changes. For Godot changes, include a manual verification note describing the prototype loop tested.

## Commit & Pull Request Guidelines

This checkout does not include Git history, so no repository-specific commit convention is available. Use concise, imperative commit messages, for example `Add loot table validator` or `Implement death echo data schema`.

Pull requests should include a summary, affected areas, test or manual verification steps, and screenshots or short clips for visible gameplay/UI changes. Link related issues or specs when applicable.

## Agent-Specific Instructions

Prioritize the prototype scope in `specs/prototype/SPEC.md`. Do not expand into deferred systems such as multiplayer, trading, town hubs, or multiple classes unless explicitly requested. Favor small, playable, data-driven increments over broad framework work.
