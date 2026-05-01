# EldersCourage Phase 7 UI Verification Checklist

## Automated Checks

- [x] `go test ./...`
- [x] `go run ./cmd/elders validate-data ./game/data`
- [x] `go run ./cmd/elders acceptance-report ./game/data`
- [x] `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit`

## Manual UI Checks

- [ ] Header reads clearly with logo, zone, class, level, XP, and gold.
- [ ] Debug position/tile details remain hidden until debug mode is toggled.
- [ ] Map tile labels prioritize location names over tile types.
- [ ] Current, enemy, cache, shrine, objective, opened, activated, cleared, and normal tile states are distinguishable.
- [ ] Current location details appear as an integrated card beside the map.
- [ ] Location detail actions match enabled/disabled action dock buttons.
- [ ] Character Summary pairs Health, Mana, and XP labels with their bars.
- [ ] Equipment rows align and empty slots are visually muted.
- [ ] Active quest objective is easy to find.
- [ ] Message rows are readable and type-colored without dominating the panel.
- [ ] Move, Location, Combat, Skills, and Panels action groups align cleanly.
- [ ] Disabled action buttons explain why they are unavailable.
- [ ] Skill buttons distinguish ready, need target, cooldown, and mana states.
- [ ] Inventory, Talents, Quests, and class selection overlays are centered and stay within bounds.
- [ ] Escape closes overlays and cancels identify target mode.
- [ ] Keyboard shortcuts still work: movement, interact, attack, inventory, talents, quests, debug, skill slots, and cancel.
- [ ] Hover and keyboard focus states are visible for map tiles and action buttons.
- [ ] Inventory, Talents, and Quests buttons show active selected state when open.
- [ ] Movement produces a subtle map pulse.
- [ ] Combat hits produce a subtle enemy feedback pulse.
- [ ] Invalid actions produce a subtle message feedback pulse.
- [ ] Quest stage completion produces a subtle quest feedback pulse.
- [ ] Level-up produces a subtle header feedback pulse.

## Desktop Resolution Checks

- [ ] 1920x1080: no overlap, clipping, or excessive empty space.
- [ ] 1680x1050: no overlap, clipping, or excessive empty space.
- [ ] 1440x900: no overlap, clipping, or excessive empty space.
- [ ] 1366x768: no overlap or critical text clipping; action dock remains usable.

## Gameplay Regression Checks

- [ ] Select each class and begin the Elder Road.
- [ ] Move with keyboard and adjacent tile clicks.
- [ ] Open the abandoned chest.
- [ ] Activate a shrine.
- [ ] Start and resolve an encounter.
- [ ] Use class skills from buttons and keyboard slots.
- [ ] Open inventory, select an item, equip it, and use a consumable.
- [ ] Use Identify Scroll target mode and cancel it.
- [ ] Open talents, spend a point when available, and close the panel.
- [ ] Open quest/log panel and close it.
- [ ] Complete the Elder Road quest chain.

## Notes

Headless Godot verifies import, scene load, and script compilation. It does not prove layout quality, hover/focus feel, animation feel, or full interactive completion. Those remain manual verification tasks.
