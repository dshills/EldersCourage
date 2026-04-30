# EldersCourage — Next Items Prototype Spec

## Purpose

This document defines the next implementation phase after the initial playable combat prototype. The goal is to move from a functional combat arena into a small but recognizable action RPG vertical slice with loot, equipment, cursed rings, attunement, death echoes, and an initial graphics pass.

This spec is written for a coding agent such as Codex. It assumes an existing Godot 4.x project already contains basic player movement, basic attacks, enemies, damage, death, and a runnable test scene.

The next phase should remain small, playable, and data-driven. Do not attempt to build the full game.

---

## Current Baseline Assumption

The existing prototype includes:

- A runnable Godot project.
- A top-down 2D player controller.
- Basic movement.
- Basic attack or skill action.
- At least one enemy type.
- Basic health and damage.
- A test arena or room scene.
- Player death or failure handling.

If any of these are missing, implement the missing baseline pieces before starting the tasks below.

---

## Primary Goal for This Phase

Create a playable prototype where the player can:

1. Enter a small dungeon test area.
2. Fight enemies.
3. Pick up loot.
4. Equip weapons, armor, and rings.
5. See equipment affect combat stats.
6. Use cursed rings with visible benefits and drawbacks.
7. Gain attunement progress on equipped items.
8. Trigger at least one item echo.
9. Die, leave behind a death echo, and reclaim it.
10. Experience a basic visual identity through custom placeholder graphics.

---

## Engine and Output Target

The primary deliverable is a runnable Godot 4.x project.

The prototype must be playable in the Godot editor using a top-down 2D presentation. Browser output and terminal-only gameplay are out of scope.

Developer tooling may use Go or scripts later, but this phase should prioritize the playable Godot client.

---

## Non-Goals

Do not implement:

- Multiple player classes.
- Networked multiplayer.
- A full campaign.
- A complete procedural world.
- Dozens of enemies.
- Full character creation.
- Complex crafting.
- Shops or vendors.
- Save-game cloud sync.
- Final production art.
- Voice acting.
- Large cinematic systems.

This phase is about proving the next layer of gameplay, not building a gothic cathedral out of TODO comments.

---

# Milestone 2 — Loot, Inventory, and Equipment

## Goal

Add loot drops and a minimal equipment system so combat rewards the player with items that change gameplay.

## Required Features

### 2.1 Item Data Model

Create a data-driven item definition format. JSON is preferred.

Recommended location:

```text
/data/items/items.json
/data/items/rings.json
/data/items/loot_tables.json
```

Each item should support:

```json
{
  "id": "weapon_rust_cleaver",
  "name": "Rust-Bitten Cleaver",
  "type": "weapon",
  "rarity": "worn",
  "description": "A crude blade with a stubborn edge.",
  "icon": "res://assets/icons/items/weapon_rust_cleaver.png",
  "stats": [
    {
      "stat": "attack_damage",
      "value": 5
    }
  ],
  "tags": ["weapon", "blade", "physical"]
}
```

Supported item types for this milestone:

- `weapon`
- `armor`
- `ring`
- `consumable`

Supported rarities:

- `worn`
- `forged`
- `relic`
- `accursed`

### 2.2 Equipment Slots

Implement equipment slots:

- Weapon
- Armor
- Ring 1
- Ring 2

Equipping an item should update player stats immediately.

Minimum supported stats:

- `max_health`
- `attack_damage`
- `attack_speed`
- `move_speed`
- `armor`
- `critical_chance`
- `echo_power`

### 2.3 Inventory UI

Implement a simple inventory panel.

Required behavior:

- Toggle inventory with `I`.
- Show collected items in a list or grid.
- Show item name, rarity, type, and stats.
- Allow equipping an item by clicking or pressing a clear action button.
- Show currently equipped items.
- Allow unequipping items.

Placeholder UI is acceptable. Functionality matters more than beauty.

### 2.4 Loot Drops

Enemies should be able to drop items.

Required behavior:

- When an enemy dies, it has a chance to drop loot.
- Loot appears visually in the world.
- Player can pick up loot by moving near it and pressing an interaction key, or by automatic pickup if simpler.
- Picked-up loot enters the inventory.

Minimum loot content:

- 5 weapons
- 3 armor pieces
- 5 rings
- 2 consumables

### 2.5 Loot Table

Create at least one loot table:

```json
{
  "id": "loot_table_ashen_catacombs_basic",
  "drops": [
    {
      "itemId": "weapon_rust_cleaver",
      "weight": 30
    },
    {
      "itemId": "ring_veyra_mourning_band",
      "weight": 5
    }
  ]
}
```

The system should select drops by weighted probability.

## Acceptance Criteria

Milestone 2 is complete when:

- The player can kill enemies and see loot drop.
- The player can pick up loot.
- The player can open an inventory UI.
- The player can equip a weapon, armor, and two rings.
- Equipment changes player stats.
- At least one weapon visibly changes damage output.
- At least one armor piece changes survivability.
- At least one ring applies a meaningful stat change.

---

# Milestone 3 — Cursed Rings and Attunement

## Goal

Implement the first version of the game’s signature item identity: powerful rings that contain dead spellcaster souls, reveal properties over time, and may carry curses.

## Required Features

### 3.1 Ring Data Model

Ring definitions should extend the item data model.

Example:

```json
{
  "id": "ring_veyra_mourning_band",
  "name": "Veyra's Mourning Band",
  "type": "ring",
  "rarity": "accursed",
  "description": "A blackened ring still warm from an impossible fire.",
  "icon": "res://assets/icons/items/ring_veyra_mourning_band.png",
  "soul": {
    "name": "Veyra",
    "school": "ash",
    "temperament": "vengeful"
  },
  "stats": [
    {
      "stat": "attack_damage",
      "value": 3
    }
  ],
  "hiddenStats": [
    {
      "attunementLevel": 2,
      "stat": "echo_power",
      "value": 10
    }
  ],
  "curse": {
    "id": "curse_cold_vulnerability",
    "revealAttunementLevel": 3,
    "description": "You take more damage while slowed or chilled.",
    "effects": [
      {
        "stat": "armor",
        "value": -2
      }
    ]
  },
  "echo": {
    "id": "echo_spectral_ember",
    "unlockAttunementLevel": 2
  },
  "whispers": [
    "The flame remembers what the flesh denies.",
    "Strike again. Mercy is a colder death."
  ],
  "tags": ["ring", "ash", "soul", "accursed"]
}
```

### 3.2 Attunement Progression

Equipped rings should gain attunement XP while used.

Attunement XP sources:

- Enemy killed while ring is equipped.
- Elite enemy killed while ring is equipped.
- Player reclaims a death echo while ring is equipped.

Required attunement levels:

- Level 0: visible base item only.
- Level 1: minor flavor reveal or whisper.
- Level 2: hidden stat or echo unlock.
- Level 3: curse reveal.

Use simple thresholds for now:

```text
Level 1: 25 attunement XP
Level 2: 75 attunement XP
Level 3: 150 attunement XP
```

### 3.3 Attunement UI

Inventory or equipment UI should display:

- Ring attunement level.
- Current attunement XP.
- Progress to next level.
- Revealed properties.
- Unknown locked properties as `???`.

Example display:

```text
Veyra's Mourning Band
Accursed Ring
Soul: Veyra, Ash Witch
Attunement: Level 1 / 3
Progress: 42 / 75

Visible:
+3 Attack Damage

Dormant:
??? Unlocks at Attunement 2
??? Reveals at Attunement 3
```

### 3.4 Ring Whispers

When a ring reaches a new attunement level, display a short whisper message.

Implementation can be simple:

- Floating text near player.
- UI notification.
- Console/log fallback only if necessary.

### 3.5 Curses

At least two rings must reveal curses at attunement level 3.

Curses should be real mechanical tradeoffs, not fake flavor.

Example curses:

- Reduced armor.
- Reduced max health.
- Increased damage taken while below 30% health.
- Reduced movement speed after using a skill.

## Acceptance Criteria

Milestone 3 is complete when:

- Rings gain attunement XP while equipped.
- Ring attunement level increases at defined thresholds.
- Hidden properties remain hidden until unlocked.
- At least one ring unlocks a hidden stat.
- At least one ring unlocks an item echo.
- At least two rings reveal curses.
- The UI clearly communicates visible, hidden, and revealed properties.
- A ring whisper appears when an attunement level is reached.

---

# Milestone 4 — Item Echoes and Death Echoes

## Goal

Implement the first version of echoes: supernatural repeated effects and world memory caused by equipment and death.

## Required Features

### 4.1 Echo Data Model

Create echo definitions:

Recommended location:

```text
/data/echoes/item_echoes.json
/data/echoes/death_echoes.json
```

Example item echo:

```json
{
  "id": "echo_spectral_ember",
  "name": "Spectral Ember",
  "description": "On kill, release a small ember that damages a nearby enemy.",
  "trigger": "enemy_killed",
  "cooldownSeconds": 4,
  "effects": [
    {
      "type": "damage_nearest_enemy",
      "damage": 8,
      "range": 160
    }
  ],
  "vfx": "res://scenes/vfx/SpectralEmber.tscn"
}
```

### 4.2 Item Echo Runtime

Implement at least two item echoes:

1. `Spectral Ember`
   - Trigger: enemy killed.
   - Effect: damages nearest enemy.
   - Visual: small ember projectile or burst.

2. `Last Duel`
   - Trigger: player basic attack hit.
   - Effect: delayed second hit for reduced damage.
   - Visual: ghost slash or afterimage.

### 4.3 Death Echo Runtime

When the player dies:

- Spawn a Death Echo marker at the death location.
- Respawn the player at a safe location.
- Enemies near the Death Echo become slightly stronger until the echo is reclaimed.
- Player can reclaim the echo by interacting with it.
- Reclaiming the echo grants attunement XP to equipped rings.

Example effect:

```json
{
  "id": "death_echo_last_breath",
  "name": "Echo of Your Last Breath",
  "effectsUntilReclaimed": [
    {
      "target": "nearby_enemies",
      "stat": "attack_damage",
      "value": 2
    }
  ],
  "reclaimReward": {
    "attunementXp": 25
  }
}
```

### 4.4 Death Echo UI/VFX

The Death Echo should be visually obvious.

Minimum acceptable visual:

- Pulsing marker.
- Dark aura circle.
- Floating label.
- Interaction prompt.

## Acceptance Criteria

Milestone 4 is complete when:

- At least one ring can unlock and trigger an item echo.
- At least two item echoes exist and work.
- Player death creates a Death Echo marker.
- Death Echo empowers nearby enemies or the room.
- Player can reclaim the Death Echo.
- Reclaiming grants attunement XP.
- Visual effects clearly distinguish item echoes from death echoes.

---

# Milestone 5 — Initial Graphics Pass

## Goal

Replace purely abstract prototype visuals with an original, readable, dark fantasy placeholder art style suitable for playtesting.

This is not final production art. The objective is to create a coherent visual language so the prototype feels like a game instead of a debug accident with ambition.

## Visual Direction

Style:

- Top-down 2D dark fantasy.
- Gothic, cursed, ancient, ruined.
- Readable silhouettes over detail.
- Strong contrast between interactable objects and background.
- Slightly exaggerated shapes.
- No copyrighted assets.
- No AI-generated images unless explicitly approved and committed as original project assets.

Mood references in words:

- Ashen catacombs.
- Bone dust.
- Black iron.
- Faint ember light.
- Old stone.
- Haunted gold.
- Ritual markings.
- Dead spellcaster souls.

## Required Graphics Assets

Create original placeholder graphics for the following.

### 5.1 Player Sprite

Asset:

```text
/assets/sprites/player/gravebound_knight.png
```

Requirements:

- Top-down or three-quarter top-down sprite.
- Readable facing direction if feasible.
- Can be a simple original pixel/sprite drawing.
- Should include a dark armor silhouette.
- Weapon visible if simple to add.

Minimum acceptable implementation:

- Static sprite with simple animation through movement bob, rotation, or frame swapping.

Better implementation:

- Idle animation.
- Walk animation.
- Attack animation.

### 5.2 Enemy Sprites

Create sprites for:

```text
/assets/sprites/enemies/bone_thrall.png
/assets/sprites/enemies/ash_witch.png
/assets/sprites/enemies/hollow_brute.png
```

Enemy visual requirements:

- Bone Thrall: small skeleton-like melee enemy.
- Ash Witch: ranged caster silhouette with ember/ash theme.
- Hollow Brute: larger heavy enemy.

Each enemy should be visually distinguishable by size, shape, and color/value contrast.

### 5.3 Dungeon Tiles

Create a small tileset or individual floor/wall textures:

```text
/assets/tiles/ashen_catacombs_floor.png
/assets/tiles/ashen_catacombs_wall.png
/assets/tiles/ashen_catacombs_cracked_floor.png
/assets/tiles/ashen_catacombs_blood_mark.png
```

Requirements:

- Usable in a Godot TileMap or manually placed as sprites.
- Clearly separates walkable floor from blocking wall.
- Includes at least one floor variation.
- Includes at least one ritual/blood/marking decoration.

### 5.4 Loot Icons

Create icons for item categories:

```text
/assets/icons/items/weapon_generic.png
/assets/icons/items/armor_generic.png
/assets/icons/items/ring_generic.png
/assets/icons/items/consumable_generic.png
/assets/icons/items/ring_accursed.png
```

Requirements:

- Small readable icons for inventory.
- Different silhouettes per category.
- Accursed ring should look more dangerous than generic ring.

### 5.5 World Loot Sprites

Create in-world loot pickup visuals:

```text
/assets/sprites/loot/loot_weapon.png
/assets/sprites/loot/loot_armor.png
/assets/sprites/loot/loot_ring.png
/assets/sprites/loot/loot_consumable.png
```

Requirements:

- Readable on the dungeon floor.
- Slight glow/pulse animation preferred.
- Rarity can be represented by a ring, aura, label, or beam.

### 5.6 VFX Assets

Create simple VFX scenes or sprites for:

```text
/scenes/vfx/HitSpark.tscn
/scenes/vfx/SpectralEmber.tscn
/scenes/vfx/GhostSlash.tscn
/scenes/vfx/DeathEchoAura.tscn
/scenes/vfx/AttunementPulse.tscn
```

Requirements:

- Hit spark appears on successful attacks.
- Spectral ember appears when the Spectral Ember echo triggers.
- Ghost slash appears when Last Duel echo triggers.
- Death Echo Aura marks the player’s death location.
- Attunement Pulse appears when an item levels up.

VFX may use Godot particles, simple sprites, animated opacity, scaling circles, or Line2D/Polygon2D shapes.

### 5.7 UI Styling

Create a basic UI theme:

```text
/assets/ui/theme/elders_theme.tres
```

Requirements:

- Inventory panel should feel dark fantasy.
- Equipped slots should be visually distinct.
- Item rarity should be visually indicated.
- Tooltips should be readable.
- Unknown item properties should display as `???`.

## Graphics Implementation Options

The coding agent may create graphics using any of these approaches:

1. Hand-authored simple PNGs committed into the repository.
2. SVG source files exported or loaded by Godot.
3. Procedurally generated PNGs using a script.
4. Godot scenes composed from Polygon2D, Sprite2D, ColorRect, Line2D, and particles.

Preferred approach for speed:

- Use simple original SVG or generated PNG assets.
- Keep source files under `/art/source` if generated.
- Commit final usable assets under `/assets`.

Required asset organization:

```text
/art/source/
/assets/sprites/player/
/assets/sprites/enemies/
/assets/sprites/loot/
/assets/icons/items/
/assets/tiles/
/assets/ui/theme/
/scenes/vfx/
```

## Graphics Acceptance Criteria

Milestone 5 is complete when:

- The player is represented by an original sprite or composed visual.
- At least three enemy types have distinct visuals.
- Dungeon floor and wall graphics are present.
- Loot pickups have visible in-world graphics.
- Inventory item icons exist.
- Hit and echo effects are visible during combat.
- Death Echo has a distinct visual marker.
- Attunement level-up has a visible pulse or notification effect.
- No external copyrighted assets are used.
- The project remains runnable in Godot.

---

# Milestone 6 — Small Dungeon Run

## Goal

Create a short dungeon experience that connects combat, loot, rings, attunement, echoes, death, and graphics into a single replayable loop.

## Required Features

### 6.1 Dungeon Scene

Create:

```text
/scenes/dungeons/AshenCatacombsRun.tscn
```

The dungeon should contain:

- Start room.
- 3 combat rooms.
- 1 elite room.
- 1 boss room.
- Exit or completion shrine.

Rooms may be manually authored. Full procedural generation is not required yet.

### 6.2 Enemy Placement

Use at least three enemy types:

- Bone Thrall.
- Ash Witch.
- Hollow Brute.

Each combat room should use a different mixture.

### 6.3 Elite Enemy

Add one elite modifier.

Example:

```text
Ash-Touched Elite
- More health.
- Leaves burning ground or fires a slow projectile.
- Better loot chance.
```

### 6.4 Boss Prototype

Add a simple boss:

```text
The Bell-Ringer Below
```

Boss requirements:

- Larger than normal enemies.
- Has more health.
- Uses at least two attack patterns.
- Drops guaranteed rare or accursed loot.

Suggested attacks:

1. Bell Slam
   - Area damage around boss after windup.

2. Summon Thralls
   - Spawns 2 Bone Thralls.

3. Toll of Ash
   - Slow projectile or cone attack.

Only two are required.

### 6.5 Completion Reward

After defeating the boss:

- Spawn a reward chest or shrine.
- Drop at least one guaranteed ring or relic item.
- Display a completion message.

## Acceptance Criteria

Milestone 6 is complete when:

- Player can start a dungeon run.
- Player can clear multiple rooms.
- Loot drops throughout the run.
- Equipped gear affects combat.
- Rings gain attunement during the run.
- Death Echo works if the player dies.
- Boss can be defeated.
- Completion reward appears.
- The run can be replayed without restarting the editor manually beyond pressing Play again.

---

# Required Content for This Phase

## Items

Create at least 15 item definitions:

### Weapons

1. Rust-Bitten Cleaver
2. Grave Iron Sword
3. Ash Hook Axe
4. Pilgrim's War Mace
5. Bell-Tower Blade

### Armor

1. Cracked Mail
2. Gravebound Plate
3. Ash-Stained Mantle

### Rings

1. Veyra's Mourning Band
2. Orun's Bone Signet
3. The Choirless Ring
4. Ember-Eaten Loop
5. Pale Gold of the Drowned Saint

### Consumables

1. Minor Blood Flask
2. Scroll of First Knowing

## Ring Requirements

At least three rings must have:

- A named soul.
- A magic school.
- At least one visible stat.
- At least one hidden stat or echo.
- At least one curse.
- At least two whisper lines.

## Echoes

Create at least three echoes:

1. Spectral Ember
2. Last Duel
3. Bone Memory

Only two need to be fully implemented if time is constrained, but all three should exist in data.

## Enemies

Create or update enemy definitions for:

1. Bone Thrall
2. Ash Witch
3. Hollow Brute
4. Ash-Touched Elite variant
5. The Bell-Ringer Below

---

# Suggested File Structure

Adapt this to the existing project structure if necessary, but keep the result organized.

```text
/project.godot
/scenes
  /player
    Player.tscn
  /enemies
    BoneThrall.tscn
    AshWitch.tscn
    HollowBrute.tscn
    BellRingerBelow.tscn
  /items
    LootPickup.tscn
  /dungeons
    AshenCatacombsRun.tscn
  /vfx
    HitSpark.tscn
    SpectralEmber.tscn
    GhostSlash.tscn
    DeathEchoAura.tscn
    AttunementPulse.tscn
/scripts
  /player
  /combat
  /items
  /inventory
  /attunement
  /echoes
  /enemies
  /ui
/data
  /items
    items.json
    rings.json
    loot_tables.json
  /echoes
    item_echoes.json
    death_echoes.json
  /enemies
    enemies.json
/assets
  /sprites
    /player
    /enemies
    /loot
  /icons
    /items
  /tiles
  /ui
    /theme
/art
  /source
```

---

# Implementation Guidance for Codex

## General Rules

- Read the existing project before modifying it.
- Preserve existing working behavior.
- Implement one milestone at a time.
- Prefer small, testable commits or logical change groups.
- Do not rewrite the project from scratch unless the existing project is unusable.
- Keep placeholder art simple and original.
- Avoid external asset dependencies.
- Keep data definitions human-readable.
- Add comments only where behavior is non-obvious.
- Record architectural decisions in `DECISIONS.md`.

## Suggested Implementation Order

1. Inspect existing Godot project.
2. Confirm current runnable scene.
3. Add item data loading.
4. Add inventory and equipment model.
5. Add loot pickup scene.
6. Add inventory/equipment UI.
7. Add ring-specific data.
8. Add attunement XP and level tracking.
9. Add curses and hidden properties.
10. Add item echoes.
11. Add death echo.
12. Add graphics assets.
13. Replace debug visuals with new placeholder assets.
14. Add small dungeon run.
15. Add boss prototype.
16. Run project and fix errors.
17. Update `DECISIONS.md` and `IMPLEMENTATION_NOTES.md`.

## Recommended First Codex Prompt

```text
Read the existing Godot project and this spec. Implement Milestone 2 only: loot, inventory, equipment slots, item data, loot drops, and basic item icons/placeholders if needed. Do not implement rings, attunement, echoes, boss, or dungeon expansion yet except for stubs required by Milestone 2. Preserve existing working combat. After implementation, update DECISIONS.md and IMPLEMENTATION_NOTES.md with what changed, what works, and what remains stubbed.
```

## Recommended Second Codex Prompt

```text
Continue from the current project state. Implement Milestone 3 only: cursed rings, ring souls, attunement XP, hidden properties, curses, ring whispers, and attunement UI. Do not implement the dungeon boss or full graphics pass yet. Preserve Milestone 2 behavior. Update DECISIONS.md and IMPLEMENTATION_NOTES.md.
```

## Recommended Third Codex Prompt

```text
Continue from the current project state. Implement Milestone 4 and Milestone 5: item echoes, death echoes, and the initial original graphics pass. Create simple original placeholder sprites, icons, tiles, and VFX assets inside the repository. Do not use external copyrighted assets. Preserve existing combat, inventory, equipment, and attunement behavior. Update DECISIONS.md and IMPLEMENTATION_NOTES.md.
```

## Recommended Fourth Codex Prompt

```text
Continue from the current project state. Implement Milestone 6: a short Ashen Catacombs dungeon run with multiple rooms, three enemy types, one elite variant, The Bell-Ringer Below boss prototype, and a completion reward. Preserve all existing systems. Update DECISIONS.md and IMPLEMENTATION_NOTES.md.
```

---

# Testing and Validation

## Manual Playtest Checklist

Before considering this phase complete, manually verify:

- The project opens in Godot without import errors.
- The main playable scene runs.
- Player can move and attack.
- Enemies can damage the player.
- Enemies can die.
- Loot drops are visible.
- Loot can be picked up.
- Inventory opens and closes.
- Items can be equipped.
- Equipment affects stats.
- Rings gain attunement.
- Hidden ring properties unlock.
- Curses reveal and apply.
- Item echoes trigger.
- Player death creates a Death Echo.
- Death Echo can be reclaimed.
- At least one VFX appears during combat.
- Dungeon visuals are not just raw debug shapes.
- Boss can be defeated.
- Completion reward appears.

## Debug Tools

Add simple debug controls if useful:

- Spawn item.
- Grant attunement XP.
- Kill player.
- Spawn enemy.
- Reset room.

Debug controls should be easy to remove or disable later.

---

# Definition of Done

This phase is done when the game has a playable loop with:

- Combat.
- Loot.
- Inventory.
- Equipment.
- Cursed rings.
- Attunement progression.
- Item echoes.
- Death echoes.
- Original placeholder graphics.
- A short dungeon run.
- A simple boss.

The result does not need to be pretty. It needs to be playable, coherent, and weird enough that the game’s identity is visible.

The player should be able to say:

> I killed monsters, found a suspicious ring, equipped it, unlocked hidden power, discovered it was cursed, died, reclaimed my death echo, and beat a boss in a haunted catacomb.

That is the vertical slice.

