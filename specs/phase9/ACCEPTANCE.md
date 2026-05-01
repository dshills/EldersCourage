# Phase 9 Acceptance

## Implemented

- Phase 9 resonance definitions are authored in `game/data/phase9/item_resonances.json`.
- Phase 9 merge definitions are authored in `game/data/phase9/item_merges.json`.
- Resonance and merge data are validated by Go tooling, including item, skill, soul, result item, and resonance references.
- Run-level resonance state tracks discovered resonances and trigger counts.
- Equipped and carried item combinations can produce active, hinted, discovered, and cursed resonances.
- Resonance discovery is processed from equip, identify, skill use, enemy defeat, curse, and attunement events.
- Discovered beneficial resonance effects apply through existing stat, skill damage, healing, and mana cost calculations.
- Discovered cursed resonance health costs are nonlethal.
- Breath Debt supports the current one-trinket equipment model by requiring Ashen Ring equipped and Elder Glass Charm carried.
- Item details show known active resonances, inactive discovered resonances, and safe hints without exposing hidden curses early.
- Staff of the Ashen Orator is authored as the first merged item.
- Ashen Ring plus Ember Staff can merge after the required resonance, attunement, and Varn reveal conditions are met.
- The merge consumes source items, transfers Varn's soul state, equips the resulting staff, and carries forward revealed Blood Price risk.
- Inventory UI includes merge hints, a Merge button, and a two-step merge confirmation overlay.
- Pure Go tests cover Phase 9 resonance activation, discovery dedupe, conditional bonuses, nonlethal health cost, and merge requirements.

## Verification Commands

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

## Manual Verification

Use `specs/phase9/ITEM_RESONANCE_VERIFICATION.md` for the full playthrough checklist.

## Notes

- Headless Godot checks still emit existing image import warnings from the current texture-loading path.
- The first merge remains intentionally narrow. This phase does not add materials, vendors, sockets, broad crafting, or merge tiers.
