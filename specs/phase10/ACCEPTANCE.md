# Phase 10 Acceptance

## Implemented

- Multi-zone runtime state tracks the current zone, unlocked zones, and per-zone position/state.
- Elder Road Outskirts remains the launch zone and keeps the existing scene.
- Elder Stone has a blocked transition to Ashwood Glen until the Elder Road quest stage is complete.
- Ashwood Glen exists as a 5x5 playable second zone.
- Ashwood Glen includes return travel back to Elder Road Outskirts.
- Ashwood Glen preserves its zone position and cleared/opened/activated/completed state across travel.
- Burning Thorn and Cinder Pool hazards are data-defined.
- Burning Thorn triggers on first entry, deals nonlethal damage, and supports defense, resonance, and Ashwood Charm mitigation.
- Cinder Pool triggers on interaction, applies nonlethal resource loss, and can produce Varn/resonance hooks.
- Ashwood enemies are defined and placed: Ember Wisp, Ash Wolf, Cinder Acolyte, and Cinderheart Guardian.
- Ashwood containers, shrine, loot tables, Ash Salve, Ashwood Charm, and Cinderheart Remnant are implemented.
- Ashwood quest chain `ashes_beyond_the_stone` is authored and receives transition, hazard, cairn, encounter, and reward objective updates.
- UI supports current-zone map rendering, transition actions, hazard/lore markers, and active-zone quest focus.
- Phase 10 validation covers zone, hazard, transition, reward, and cross-reference data.
- Pure Go tests cover transition requirements, per-zone position preservation, nonlethal hazard damage, and Burning Thorn mitigation.

## Verification Commands

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

## Manual Verification

Use `specs/phase10/ASHWOOD_GLEN_VERIFICATION.md` for the full playthrough checklist.

## Notes

- Headless Godot checks still emit the existing image import warnings from the current texture-loading path.
- Phase 10 intentionally adds one new zone only. It does not add a world map, save/load, vendors, procedural generation, or a larger crafting economy.
