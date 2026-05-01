# Phase 8 Acceptance

## Implemented

- Ashen Ring is linked to `varn_ashen_orator`.
- Varn's soul data, whispers, memories, and Breath for Flame bargain are authored in `game/data/phase8/ring_souls.json`.
- Ring soul data is validated by Go tooling.
- Soul state is tracked per item instance.
- Soul presence, name, motivation, and memories reveal through identify/equip/curse and attunement progression.
- Contextual whispers are integrated with equip, skill use, enemy defeat, attunement, curse, and bargain events.
- Message log supports `ring_whisper`, `memory`, and `bargain` types.
- Blood Price remains connected to Ashen Ring skill use and cannot reduce health below 1.
- Breath for Flame appears once at attunement level 2.
- Breath for Flame can be accepted or rejected.
- Accepting Breath for Flame applies nonlethal health cost, trust gain, Last Breath reveal, and Ember Bolt +2 damage.
- Rejecting Breath for Flame applies trust loss and no damage bonus.
- Weathered Shrine now grants the Ashen Ring and an Identify Scroll when needed.
- Ring soul details appear in item details without exposing unrevealed information.
- A Phase 7 styled bargain panel presents accept and reject choices.
- Pure Go tests cover core Phase 8 rule helpers.

## Verification Commands

```bash
env GOCACHE=/private/tmp/elders-go-cache go test ./...
go run ./cmd/elders validate-data ./game/data
go run ./cmd/elders acceptance-report ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game res://scenes/phase3/ElderRoadOutskirts.tscn --quit
```

## Manual Verification

Use `specs/phase8/RING_SOUL_VERIFICATION.md` for the full playthrough checklist.

## Notes

- The Roadside Cache no longer grants the Ashen Ring; the Weathered Shrine is now the canonical normal-play acquisition path for Phase 8.
- Existing headless Godot checks still emit image import warnings from prior asset loading behavior.
