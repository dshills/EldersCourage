# EldersCourage Phase 1 Implementation Plan

## Purpose

This plan converts `specs/phase1/SPEC.md` into an implementation sequence for the next playable vertical-slice phase. The target is a small, runnable Godot 4.x action RPG prototype where combat, loot, equipment, cursed rings, attunement, item echoes, death echoes, placeholder graphics, and a short dungeon run all work together.

Phase 1 should build on the existing Godot project and Go tooling. Preserve working combat behavior and improve it incrementally.

## Guiding Principles

- Keep every milestone playable before moving to the next one.
- Prefer data-driven content for items, rings, loot tables, echoes, enemies, and dungeon encounters.
- Keep placeholder art original, simple, and readable.
- Reuse existing scenes, scripts, and JSON data where they already satisfy the spec.
- Avoid broad rewrites unless a subsystem is blocking the milestone.
- Update validation and tests when content contracts change.
- Document important implementation choices in `specs/prototype/DECISIONS.md` or a phase-specific notes file if one is added.

## Current Baseline Check

Before implementing new work, verify the actual repository state against the phase spec assumptions.

### Tasks

1. Run `go test ./...`.
2. Run `go run ./cmd/elders validate-data ./game/data`.
3. Run Godot headless import/script validation:

   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
   ```

4. Open the playable scene in Godot and confirm:
   - Player movement works.
   - Basic attacks or skills damage enemies.
   - Enemies can damage or kill the player.
   - Loot, echoes, and dungeon flow that already exist still behave as expected.

### Exit Criteria

- Existing failures are recorded before changes begin.
- Any missing baseline feature from `SPEC.md` is either implemented first or explicitly called out as a blocker.

## Milestone 2: Loot, Inventory, and Equipment

### Goal

Ensure combat rewards the player with item drops that can be picked up, inspected, equipped, unequipped, and used to change combat stats.

### Implementation Tasks

1. Normalize item data under the existing `game/data/items/` and `game/data/loot/` structure.
2. Ensure supported item types exist: `weapon`, `armor`, `ring`, and `consumable`.
3. Ensure supported rarities exist: `worn`, `forged`, `relic`, and `accursed`.
4. Add or update at least:
   - 5 weapons
   - 3 armor pieces
   - 5 rings
   - 2 consumables
5. Implement or harden weighted loot table selection.
6. Ensure enemy deaths can spawn visible loot pickups in the world.
7. Ensure pickups enter the player inventory.
8. Implement equipment slots:
   - Weapon
   - Armor
   - Ring 1
   - Ring 2
9. Apply equipped stat modifiers immediately to player combat calculations.
10. Update inventory UI so it can:
    - Toggle with `I`.
    - List collected items.
    - Show name, rarity, type, description, and stats.
    - Equip selected items.
    - Unequip equipped items.
    - Show current equipment.
11. Extend Go validation for item types, rarities, required fields, stat names, loot table references, and unique IDs.

### Exit Criteria

- Killing enemies can drop loot.
- Player can pick up loot and see it in inventory.
- Player can equip a weapon, armor, and two rings.
- Equipment changes damage, survivability, speed, or another supported stat.
- At least one weapon visibly changes damage output.
- At least one armor piece visibly changes survivability.
- At least one ring applies a meaningful stat change.
- `go test ./...` and `validate-data` pass.

## Milestone 3: Cursed Rings and Attunement

### Goal

Implement the signature cursed soul-ring loop: rings have souls, hidden properties, attunement progress, whispers, and revealed curses.

### Implementation Tasks

1. Extend ring data to support:
   - `soul`
   - `hiddenStats`
   - `curse`
   - `echo`
   - `whispers`
   - attunement unlock thresholds
2. Ensure at least three rings have:
   - named soul
   - magic school
   - visible stat
   - hidden stat or echo
   - curse
   - at least two whisper lines
3. Add item-instance state for equipped rings:
   - attunement XP
   - attunement level
   - revealed hidden stats
   - revealed curse state
   - unlocked echo state
4. Implement attunement thresholds:
   - Level 1 at 25 XP
   - Level 2 at 75 XP
   - Level 3 at 150 XP
5. Award attunement XP when:
   - An enemy dies while a ring is equipped.
   - An elite enemy dies while a ring is equipped.
   - A Death Echo is reclaimed while a ring is equipped.
6. Reveal level-gated ring properties at the correct thresholds.
7. Apply revealed hidden stats and curses to player stats or combat hooks.
8. Show ring attunement UI in inventory/equipment details:
   - level
   - current XP
   - progress to next threshold
   - visible properties
   - revealed properties
   - locked properties as `???`
9. Display a ring whisper or attunement notification on level up.
10. Extend validation for ring soul metadata, hidden stat thresholds, curse references, echo references, and whisper content.

### Exit Criteria

- Equipped rings gain attunement XP.
- Rings level at 25, 75, and 150 XP.
- Hidden properties remain hidden until unlocked.
- At least one ring unlocks a hidden stat.
- At least one ring unlocks an item echo.
- At least two rings reveal real mechanical curses.
- UI clearly distinguishes visible, revealed, and unknown properties.
- A whisper or notification appears when a ring gains an attunement level.

## Milestone 4: Item Echoes and Death Echoes

### Goal

Make equipment and death leave supernatural gameplay traces that are visible and mechanically relevant.

### Implementation Tasks

1. Normalize echo data under `game/data/echoes/`.
2. Add data definitions for:
   - Spectral Ember
   - Last Duel
   - Bone Memory
3. Implement item echo trigger dispatch for at least:
   - `enemy_killed`
   - `basic_attack_hit`
4. Implement `Spectral Ember`:
   - Trigger: enemy killed.
   - Effect: damage nearest enemy within range.
   - Feedback: ember burst, projectile, or clear placeholder VFX.
5. Implement `Last Duel`:
   - Trigger: player basic attack hit.
   - Effect: delayed reduced-damage second hit.
   - Feedback: ghost slash or afterimage.
6. Ensure item echoes only activate after the associated ring property is unlocked.
7. On player death:
   - Spawn a Death Echo marker at the death location.
   - Respawn the player at a safe location.
   - Empower nearby enemies or the room until reclaimed.
8. Implement Death Echo reclaim interaction.
9. Grant attunement XP to equipped rings when the Death Echo is reclaimed.
10. Extend validation for echo IDs, triggers, cooldowns, effect payloads, and VFX references where practical.

### Exit Criteria

- At least one ring can unlock and trigger an item echo.
- Spectral Ember and Last Duel work in combat.
- Death creates a visible Death Echo marker.
- Death Echo makes nearby enemies or the room more dangerous until reclaimed.
- Player can reclaim the Death Echo.
- Reclaiming grants attunement XP.
- Item echo and Death Echo visuals are clearly distinct.

## Milestone 5: Initial Graphics Pass

### Goal

Replace abstract debug visuals with an original, readable dark fantasy placeholder style.

### Implementation Tasks

1. Create or update original player sprite assets:
   - `game/assets/sprites/player/gravebound_knight.png`
2. Create or update original enemy sprites:
   - `game/assets/sprites/enemies/bone_thrall.png`
   - `game/assets/sprites/enemies/ash_witch.png`
   - `game/assets/sprites/enemies/hollow_brute.png`
3. Create dungeon tile or texture assets:
   - `game/assets/tiles/ashen_catacombs_floor.png`
   - `game/assets/tiles/ashen_catacombs_wall.png`
   - `game/assets/tiles/ashen_catacombs_cracked_floor.png`
   - `game/assets/tiles/ashen_catacombs_blood_mark.png`
4. Create item icons:
   - `game/assets/icons/items/weapon_generic.png`
   - `game/assets/icons/items/armor_generic.png`
   - `game/assets/icons/items/ring_generic.png`
   - `game/assets/icons/items/consumable_generic.png`
   - `game/assets/icons/items/ring_accursed.png`
5. Create world loot sprites:
   - `game/assets/sprites/loot/loot_weapon.png`
   - `game/assets/sprites/loot/loot_armor.png`
   - `game/assets/sprites/loot/loot_ring.png`
   - `game/assets/sprites/loot/loot_consumable.png`
6. Add VFX scenes or composed Godot effects:
   - `game/scenes/vfx/HitSpark.tscn`
   - `game/scenes/vfx/SpectralEmber.tscn`
   - `game/scenes/vfx/GhostSlash.tscn`
   - `game/scenes/vfx/DeathEchoAura.tscn`
   - `game/scenes/vfx/AttunementPulse.tscn`
7. Add or update UI theme:
   - `game/assets/ui/theme/elders_theme.tres`
8. Store source art under `game/art/source/` or `art/source/` if generated.
9. Wire sprites, icons, tiles, VFX, and UI theme into existing scenes.
10. Confirm no external copyrighted assets are introduced.

### Exit Criteria

- Player has an original readable sprite or composed visual.
- Three enemy types are visually distinct.
- Dungeon floor and wall visuals exist.
- Loot pickups are readable on the dungeon floor.
- Inventory item icons exist.
- Hit and echo effects are visible during combat.
- Death Echo marker is visually distinct.
- Attunement level-up has a visible pulse or notification.
- Godot project remains runnable.

## Milestone 6: Small Dungeon Run

### Goal

Connect the phase systems into one short replayable Ashen Catacombs run.

### Implementation Tasks

1. Create or update:

   ```text
   game/scenes/dungeons/AshenCatacombsRun.tscn
   ```

2. Implement a manually authored room sequence:
   - Start room
   - 3 combat rooms
   - 1 elite room
   - 1 boss room
   - Exit shrine, portal, or completion reward area
3. Use all three enemy types across the combat rooms:
   - Bone Thrall
   - Ash Witch
   - Hollow Brute
4. Add one elite variant:
   - Ash-Touched Elite
   - increased health
   - burning ground, slow projectile, or similar modifier
   - improved loot chance
5. Implement or harden boss prototype:
   - The Bell-Ringer Below
   - larger visual scale
   - increased health
   - at least two attack patterns
   - guaranteed rare or accursed loot
6. Add completion reward:
   - reward chest or shrine
   - guaranteed ring or relic item
   - completion message
7. Ensure dungeon rooms can be cleared in sequence without restarting the editor.
8. Ensure the run can be replayed by pressing Play again.
9. Add dungeon data validation for room IDs, encounter definitions, enemy IDs, loot table references, and boss references.

### Exit Criteria

- Player can start a dungeon run.
- Player can clear multiple rooms.
- Loot drops throughout the run.
- Equipped gear affects combat throughout the run.
- Rings gain attunement during the run.
- Death Echo works if the player dies.
- Boss can be defeated.
- Completion reward appears.
- The run is replayable without manual editor reset beyond pressing Play again.

## Required Content Checklist

### Items

- Rust-Bitten Cleaver
- Grave Iron Sword
- Ash Hook Axe
- Pilgrim's War Mace
- Bell-Tower Blade
- Cracked Mail
- Gravebound Plate
- Ash-Stained Mantle
- Veyra's Mourning Band
- Orun's Bone Signet
- The Choirless Ring
- Ember-Eaten Loop
- Pale Gold of the Drowned Saint
- Minor Blood Flask
- Scroll of First Knowing

### Echoes

- Spectral Ember
- Last Duel
- Bone Memory

### Enemies

- Bone Thrall
- Ash Witch
- Hollow Brute
- Ash-Touched Elite variant
- The Bell-Ringer Below

## Validation and Test Plan

Run these checks after each milestone:

```bash
go test ./...
go run ./cmd/elders validate-data ./game/data
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit
```

Add or update Go tests when changing:

- JSON validation contracts.
- Loot table weighting.
- Item stat parsing.
- Echo reference validation.
- Dungeon encounter validation.

Manual Godot verification should cover:

- Kill enemy and loot drop.
- Pick up and equip item.
- Compare damage or survivability before and after equipment.
- Gain ring attunement XP.
- Unlock hidden ring property.
- Trigger item echo.
- Die and reclaim Death Echo.
- Clear the dungeon run and collect boss reward.

## Suggested Work Order

1. Baseline verification.
2. Content and validator cleanup for phase-required data.
3. Loot, inventory, and equipment hardening.
4. Ring attunement and cursed property reveal.
5. Echo runtime and Death Echo reclaim loop.
6. Placeholder graphics and UI theme.
7. Dungeon run, elite, boss, and completion reward.
8. Final acceptance pass and documentation update.

## Final Acceptance Pass

Phase 1 is complete when every milestone exit criterion is satisfied or a specific exception is documented with a reason and follow-up. The final pass should include:

1. Fresh run of all automated checks.
2. Manual playthrough from dungeon start to boss reward.
3. Manual death and Death Echo reclaim verification.
4. Inventory and equipment interaction check.
5. Attunement unlock and whisper check.
6. Confirmation that no out-of-scope systems were added.
