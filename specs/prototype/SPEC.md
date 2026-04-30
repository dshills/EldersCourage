# EldersCourage Playable Prototype Specification

**Project Name:** EldersCourage
**Prototype Codename:** Ashen Catacombs
**Document Type:** Coding-agent-ready implementation specification
**Primary Goal:** Build a small, playable ARPG prototype proving the core combat, loot, cursed ring, attunement, and echo systems.

---

## 1. Executive Summary

EldersCourage is a dark action RPG inspired by games like Diablo, but with a distinct identity built around dangerous equipment, cursed soul-rings, hidden item power, attunement progression, synergies, and world memory.

The prototype must not attempt to build the full game. It must deliver one complete playable loop:

> Enter a dungeon room, fight enemies, collect loot, equip items, attune cursed gear, trigger echoes, die or survive, and repeat with meaningful progression.

This first implementation should prioritize playability over breadth. It should prove whether the game's signature mechanics are fun before expanding into more classes, dungeons, questlines, crafting, towns, or deep narrative systems.

---

## 2. Design Pillars

### 2.1 Power Has Memory

Items, locations, enemies, and death can retain supernatural traces of prior events. These traces are represented as **Echoes**.

### 2.2 Every Powerful Item Is Suspicious

The best items should feel exciting and dangerous. A strong ring may contain a dead spellcaster's soul. A weapon may grow stronger through use but later reveal a curse.

### 2.3 Discovery Beats Disclosure

Not every property is visible immediately. Items reveal deeper properties through use, identification, attunement, and experimentation.

### 2.4 Failure Changes the World

Death and failed objectives should create consequences. These consequences should create new gameplay, not simple punishment.

### 2.5 Builds Emerge From Relationships

The most interesting builds should arise from relationships between skills, gear, ring souls, echoes, and hidden synergies.

---

## 3. Prototype Scope

### 3.1 In Scope

The prototype shall include:

- One playable character class
- One dungeon environment
- One basic procedural or semi-random room flow
- Real-time ARPG combat
- Three regular enemy types
- One elite enemy modifier system
- One boss encounter
- Loot drops
- Inventory and equipment
- Weapon, armor, and two ring slots
- Cursed soul-rings
- Item attunement
- Hidden item properties
- Identify scrolls
- Item echoes
- Death echoes
- Basic skill tree
- Basic save/load
- Data-driven content files

### 3.2 Out of Scope

The prototype shall not include:

- Multiplayer
- Online services
- Trading
- Town hubs
- Multiple classes
- Full campaign story
- Full quest system
- Voice acting
- Cinematics
- Crafting beyond basic loot generation
- Gems or sockets
- Complex economy
- Controller support unless easy in the chosen engine
- Advanced procedural world generation
- Full balancing across many builds

These are explicitly deferred. Do not implement them unless all prototype acceptance criteria are already complete.

---

## 4. Recommended Technical Approach

### 4.1 Engine Recommendation

Use **Godot 4.x** for the playable prototype.

Reasoning:

- Fast iteration
- Good 2D and lightweight 3D support
- Open source
- Practical for solo/small-team prototyping
- Data-driven workflows are straightforward
- Avoids wasting early effort on custom engine development

### 4.2 Tooling Recommendation

Use **Go** for external tooling:

- Data validation
- Loot simulation
- Combat simulation
- Balance reports
- Content generation

The game itself should not be delayed by writing a custom Go engine. Go is excellent here as the supporting forge, not the entire castle.

### 4.3 Repository Layout

```text
elderscourage/
  README.md
  SPEC.md
  ACCEPTANCE.md
  DECISIONS.md
  game/
    project.godot
    scenes/
    scripts/
    assets/
    ui/
    data/
      classes/
      skills/
      items/
      enemies/
      echoes/
      synergies/
      dungeons/
      loot/
  tools/
    go.mod
    cmd/
      elders/
    internal/
      validate/
      loot/
      sim/
      balance/
    schema/
```

If the implementation uses a different engine, preserve the same conceptual separation between game runtime, data, and tools.

---

## 5. Core Gameplay Loop

The playable loop shall be:

1. Player starts at dungeon entrance.
2. Player enters combat room.
3. Enemies spawn and attack.
4. Player uses attacks and skills to kill enemies.
5. Enemies drop gold, scrolls, and equipment.
6. Player equips items.
7. Equipped items change stats and behavior.
8. Items gain attunement experience through use.
9. Hidden item properties reveal at attunement thresholds.
10. Rings may reveal curses or echoes.
11. Player continues deeper into dungeon.
12. Player fights boss.
13. Player wins, dies, or retreats.
14. Death creates a Death Echo that changes the room until reclaimed.

---

## 6. Player Class

### 6.1 Class Name

**Gravebound Knight**

### 6.2 Class Fantasy

A melee-focused warrior bound to old battlefield spirits. The class uses heavy strikes, blood cost abilities, spectral echoes, and cursed equipment better than ordinary mortals.

### 6.3 Core Stats

The player shall have these stats:

```json
{
  "level": 1,
  "experience": 0,
  "maxHealth": 100,
  "currentHealth": 100,
  "maxWill": 50,
  "currentWill": 50,
  "baseDamage": 10,
  "attackSpeed": 1.0,
  "movementSpeed": 1.0,
  "criticalChance": 0.05,
  "criticalMultiplier": 1.5,
  "armor": 0,
  "fireResistance": 0,
  "coldResistance": 0,
  "bloodResistance": 0,
  "voidResistance": 0
}
```

### 6.4 Resource

The prototype shall use **Will** as the skill resource.

- Basic attacks generate small amounts of Will.
- Skills consume Will.
- Some cursed items may alter Will generation or consumption.

### 6.5 Controls

Minimum controls:

| Action | Input |
|---|---|
| Move | WASD or click-to-move |
| Basic attack | Left mouse button |
| Skill 1 | Q |
| Skill 2 | W or E, depending on movement choice |
| Skill 3 | R |
| Dodge | Space |
| Inventory | I |
| Character sheet | C |
| Interact/pick up | F or mouse click |
| Pause/menu | Esc |

If WASD conflicts with skill bindings, prefer WASD movement and bind skills to mouse right button, Q, E, and R.

---

## 7. Player Abilities

### 7.1 Basic Attack: Grave Strike

A melee attack using the equipped weapon.

Requirements:

- Deals weapon damage plus player bonuses.
- Can critically hit.
- Generates 5 Will on hit.
- Has a short attack animation or placeholder timing.

### 7.2 Skill 1: Blood Cleave

A short frontal arc attack.

Requirements:

- Costs 15 Will.
- Hits all enemies in a cone or arc.
- Deals 140% weapon damage.
- Applies Bleed for 3 seconds.

### 7.3 Skill 2: Grave Step

A short dash/evade.

Requirements:

- Costs 10 Will or uses cooldown only.
- Moves the player quickly in the aimed or movement direction.
- Briefly avoids collision or reduces incoming damage.
- Cooldown: 4 seconds.

### 7.4 Skill 3: Bell of the Dead

A spectral area effect.

Requirements:

- Costs 30 Will.
- Creates a circular area around the player.
- Damages enemies after a short delay.
- Enemies killed by this skill have a chance to generate an Echo trigger.
- Cooldown: 10 seconds.

---

## 8. Skill Tree

The prototype shall include a small passive skill tree with 12 nodes.

### 8.1 Skill Points

- Player gains 1 skill point per level.
- Prototype level cap: 10.
- Skill nodes may require previous nodes.

### 8.2 Required Nodes

Implement these nodes:

| ID | Name | Effect |
|---|---|---|
| `node_bone_training` | Bone Training | +10 max health |
| `node_grave_blade` | Grave Blade | +8% melee damage |
| `node_blood_hunger` | Blood Hunger | Bleed kills restore 3 health |
| `node_hardened_soul` | Hardened Soul | +5% resistance to curses |
| `node_bell_toller` | Bell Toller | Bell of the Dead cooldown -1 sec |
| `node_echo_listener` | Echo Listener | +10% attunement XP gain |
| `node_iron_vow` | Iron Vow | +10 armor |
| `node_death_bargain` | Death Bargain | When below 30% health, +15% damage |
| `node_quick_graves` | Quick Graves | Grave Step cooldown -1 sec |
| `node_deep_wounds` | Deep Wounds | Bleed damage +20% |
| `node_ringbearer` | Ringbearer | Ring curses are 10% weaker |
| `node_last_oath` | Last Oath | Once per dungeon, survive fatal damage at 1 HP |

---

## 9. Combat System

### 9.1 Damage Flow

When an attack lands:

1. Determine base damage.
2. Apply skill multiplier.
3. Apply item stat modifiers.
4. Roll for critical hit.
5. Apply enemy armor/resistance.
6. Apply status effects.
7. Apply echo triggers.
8. Display damage number.
9. Check death.

### 9.2 Status Effects

Implement the following status effects:

| Status | Effect |
|---|---|
| Bleed | Damage over time for physical/blood effects |
| Burn | Damage over time for ash/fire effects |
| Chill | Slows enemy movement and attack speed |
| Vulnerable | Increases damage taken |

### 9.3 Death

When the player dies:

- Stop combat input.
- Display death screen.
- Create a Death Echo in the room.
- Respawn player at dungeon entrance or checkpoint.
- Preserve the Death Echo until reclaimed.

---

## 10. Enemy System

### 10.1 Enemy Types

Implement three regular enemies.

#### Bone Thrall

- Basic melee enemy
- Low health
- Moves directly toward player
- Attacks in melee range

#### Ash Witch

- Ranged caster
- Fires slow projectile
- Low armor
- Attempts to keep distance

#### Hollowed Brute

- Slow heavy melee enemy
- High health
- Telegraphs a slam attack
- Can knock the player back

### 10.2 Elite Modifiers

Implement at least three elite modifiers:

| Modifier | Effect |
|---|---|
| Burning | Leaves burning ground periodically |
| Vampiric | Heals for a percentage of damage dealt |
| Echoing | Repeats one attack after a short delay at reduced damage |

Elite enemies should have:

- Increased health
- Increased damage
- Visual indicator
- Better loot chance

---

## 11. Boss Encounter

### 11.1 Boss Name

**The Bell-Ringer Below**

### 11.2 Boss Fantasy

A corrupted keeper of burial rites who rings a cracked iron bell to awaken the dead and punish oath-breakers.

### 11.3 Boss Mechanics

The boss shall have at least three attacks:

1. **Bell Slam**
   - Large melee area attack.
   - Clear telegraph.
   - High damage.

2. **Call the Buried**
   - Summons Bone Thralls.
   - Used periodically.

3. **Echo Toll**
   - Creates delayed spectral copies of prior attack zones.
   - Teaches the player the Echo concept mechanically.

### 11.4 Boss Victory

On death, the boss shall drop:

- One guaranteed Relic or Accursed item
- Gold
- One Identify Scroll
- Chance for a unique ring: `ring_bellringers_oath`

---

## 12. Loot System

### 12.1 Equipment Slots

Implement these equipment slots:

- Weapon
- Armor
- Ring 1
- Ring 2

### 12.2 Item Rarities

| Rarity | Description |
|---|---|
| Worn | Basic low-power item |
| Forged | Standard item with one modifier |
| Relic | Strong item with multiple modifiers |
| Accursed | Strong item with curse and possible hidden power |
| Mythic Echoed | Prototype may include one, but not required |

### 12.3 Item Fields

Each item definition shall support:

```json
{
  "id": "string",
  "name": "string",
  "type": "weapon | armor | ring",
  "rarity": "worn | forged | relic | accursed | mythic_echoed",
  "description": "string",
  "visibleStats": [],
  "hiddenStats": [],
  "curse": null,
  "echoes": [],
  "attunement": {
    "enabled": true,
    "xp": 0,
    "level": 0,
    "maxLevel": 5
  },
  "synergyTags": []
}
```

### 12.4 Required Prototype Content

Implement at least:

- 10 weapons
- 8 armor pieces
- 10 rings
- 5 curses
- 5 item echoes
- 5 synergies

---

## 13. Ring System

### 13.1 Core Concept

Every ring contains the soul or fragment of a dead spellcaster. Rings are powerful, dangerous, and narratively important.

### 13.2 Ring Fields

A ring shall support:

```json
{
  "id": "ring_veyra_mourning_band",
  "name": "Veyra's Mourning Band",
  "type": "ring",
  "rarity": "accursed",
  "soul": {
    "name": "Veyra",
    "school": "ash",
    "temperament": "vengeful",
    "whispers": [
      "They burned me first.",
      "Ash remembers the hand that scattered it."
    ]
  },
  "visibleStats": [
    {
      "stat": "fire_damage_percent",
      "value": 12
    }
  ],
  "hiddenStats": [
    {
      "attunementLevel": 2,
      "stat": "cooldown_recovery_percent",
      "value": 5
    }
  ],
  "curse": {
    "id": "curse_cold_vulnerability",
    "revealAttunementLevel": 3
  },
  "echoes": [
    {
      "id": "echo_spectral_ember",
      "unlockAttunementLevel": 4
    }
  ],
  "synergyTags": ["ash", "ring", "vengeful_soul"]
}
```

### 13.3 Required Rings

Implement these prototype rings:

| ID | Name | School | Theme |
|---|---|---|---|
| `ring_veyra_mourning_band` | Veyra's Mourning Band | Ash | Fire damage and vengeance |
| `ring_orren_blood_debt` | Orren's Blood Debt | Blood | Life steal with health cost |
| `ring_maelis_cold_vow` | Maelis' Cold Vow | Frost | Chill and control |
| `ring_thorn_of_nara` | Thorn of Nara | Rot | Poison/decay effects |
| `ring_bellringers_oath` | Bell-Ringer's Oath | Bone | Echo effects and summons |

---

## 14. Attunement System

### 14.1 Purpose

Attunement replaces traditional level requirements for special items. Items may be equipped immediately, but their full power is revealed only through use.

### 14.2 Attunement XP Sources

Items gain attunement XP when equipped and:

- Player kills enemies
- Player kills elites
- Player defeats boss
- Player reclaims Death Echo
- Player uses item-linked damage type or skill tag

### 14.3 Attunement Levels

Prototype maximum attunement level: 5.

Example thresholds:

| Level | XP Required |
|---|---:|
| 1 | 100 |
| 2 | 250 |
| 3 | 500 |
| 4 | 900 |
| 5 | 1400 |

### 14.4 Unlock Rules

At attunement thresholds, items may reveal:

- Hidden stat
- Curse
- Echo
- Whisper/lore
- Synergy hint

### 14.5 UI Requirement

The inventory UI shall display:

- Current attunement level
- Attunement progress bar
- Revealed properties
- Unrevealed property slots as `????`
- Curse status if known

---

## 15. Identify Scrolls

### 15.1 Purpose

Identify Scrolls reveal information without requiring full attunement.

### 15.2 Scroll Behavior

Using an Identify Scroll on an item may reveal one of:

- One hidden property
- One curse
- One synergy tag
- One echo
- One soul whisper

### 15.3 Prototype Rules

- Scrolls are consumable.
- Scrolls drop from elites, boss, and rare chests.
- Scrolls should not always reveal the best hidden property.
- If the item has no hidden properties, the scroll should say so and not be consumed, unless intentionally designed otherwise.

---

## 16. Echo System

### 16.1 Echo Definition

An Echo is a delayed, remembered, or spectral repetition of power.

### 16.2 Echo Types in Prototype

Implement two echo types:

1. Item Echoes
2. Death Echoes

### 16.3 Item Echo Example

```json
{
  "id": "echo_spectral_ember",
  "name": "Spectral Ember",
  "trigger": "enemy_killed_by_fire",
  "effect": {
    "type": "summon_orb",
    "damageType": "fire",
    "durationSeconds": 4,
    "damagePerSecond": 5
  }
}
```

### 16.4 Death Echo Behavior

When the player dies:

- Create a Death Echo at the death location.
- Mark the room as haunted.
- Enemies in that room gain a modifier until the echo is reclaimed.
- Player may reclaim the echo by interacting with it or clearing the room.
- Reclaiming grants bonus attunement XP.

### 16.5 Death Echo Data

```json
{
  "id": "death_echo_last_breath",
  "name": "Echo of Your Last Breath",
  "effectsUntilReclaimed": [
    {
      "target": "enemies_in_room",
      "stat": "damage_percent",
      "value": 10
    },
    {
      "target": "enemies_in_room",
      "stat": "movement_speed_percent",
      "value": 5
    }
  ],
  "reclaimReward": {
    "attunementXpMultiplier": 1.25,
    "durationSeconds": 120
  }
}
```

---

## 17. Synergy System

### 17.1 Synergy Types

Implement three discovery types:

| Type | Meaning |
|---|---|
| Explicit | Shown directly in UI |
| Scroll-Revealed | Requires Identify Scroll or special reveal |
| Hidden | Discovered by experimentation |

### 17.2 Synergy Rule Model

```json
{
  "id": "synergy_ash_bone_rising",
  "name": "Ashes Remember the Bone",
  "discoveryType": "hidden",
  "requiredTags": ["ash", "bone"],
  "effect": {
    "trigger": "enemy_killed_by_burning_bleed",
    "action": "summon_temporary_skeleton",
    "durationSeconds": 8
  }
}
```

### 17.3 Required Synergies

Implement at least five synergies:

| ID | Discovery | Required Tags | Effect |
|---|---|---|---|
| `synergy_ash_bone_rising` | Hidden | ash, bone | Burning bleed kills summon temporary skeleton |
| `synergy_blood_oath` | Explicit | blood, ring | Bleed kills restore extra Will |
| `synergy_frost_grave` | Scroll-Revealed | frost, grave | Chilled enemies take more Bell damage |
| `synergy_rotting_edge` | Explicit | rot, weapon | Critical hits apply decay |
| `synergy_echo_chain` | Hidden | echo, ring | Item echoes have chance to repeat once |

---

## 18. Dungeon System

### 18.1 Dungeon Name

**The Ashen Catacombs**

### 18.2 Dungeon Structure

The dungeon shall contain:

- Entrance room
- 3 to 5 combat rooms
- 1 elite room
- 1 treasure or shrine room
- 1 boss room

Room order may be fixed for the first milestone, then randomized later.

### 18.3 Room Requirements

Each room shall have:

- Spawn points
- Door/exit trigger
- Enemy encounter definition
- Loot table reference
- Optional echo/shrine state

### 18.4 Dungeon Completion

The dungeon is complete when:

- Boss is defeated
- Reward chest appears
- Exit portal appears

---

## 19. Economy

### 19.1 Currency

Prototype currency: **Grave Marks**.

### 19.2 Use Cases

In the prototype, Grave Marks may be used to:

- Buy Identify Scrolls from a simple menu/vendor placeholder
- Pay to cleanse a known curse from an item, if implemented
- Reroll one visible item modifier, if implemented

### 19.3 MVP Requirement

For the first prototype, currency only needs to be collectable and displayed. Spending may be deferred unless easy.

---

## 20. Inventory and UI

### 20.1 Required Screens

Implement these screens:

- Main HUD
- Inventory
- Character stats
- Skill tree
- Item tooltip
- Death screen
- Dungeon complete screen

### 20.2 HUD Requirements

HUD shall show:

- Health
- Will
- Skill cooldowns
- Current level
- Experience bar
- Grave Marks

### 20.3 Item Tooltip Requirements

Item tooltip shall show:

- Name
- Rarity
- Slot/type
- Visible stats
- Revealed hidden stats
- Unrevealed hidden slots as `????`
- Known curse
- Known echoes
- Attunement level and progress
- Synergy tags only if discovered/revealed

---

## 21. Save/Load

### 21.1 Save Data

The prototype shall persist:

- Player level
- Experience
- Skill allocations
- Inventory
- Equipped items
- Item attunement states
- Known item reveals
- Active Death Echoes
- Grave Marks

### 21.2 Save Format

Use JSON for prototype save files.

### 21.3 Save Timing

Save when:

- Player exits dungeon
- Player completes dungeon
- Player changes equipment
- Player levels up
- Player dies

---

## 22. Data-Driven Content

### 22.1 Content File Format

Use JSON for initial content definitions.

### 22.2 Required Data Directories

```text
game/data/
  classes/
  skills/
  items/
  enemies/
  echoes/
  synergies/
  dungeons/
  loot/
```

### 22.3 Validation

The project shall include a Go CLI tool capable of validating content files.

Command:

```bash
elders validate-data ./game/data
```

Validation should check:

- Required fields exist
- IDs are unique
- References point to existing objects
- Stat names are valid
- Rarity values are valid
- Echo triggers are valid
- Synergy tags are valid
- No malformed JSON

---

## 23. Go Tooling Specification

### 23.1 Tool Name

`elders`

### 23.2 Commands

Implement these commands eventually:

```bash
elders validate-data ./game/data
elders generate-loot --level 5 --rarity relic
elders simulate-combat --class gravebound_knight --enemy hollowed_brute
elders check-synergies ./game/data
elders balance-report ./game/data
```

### 23.3 Required for First Prototype

Only this command is required initially:

```bash
elders validate-data ./game/data
```

### 23.4 Go Requirements

- Use Go 1.22 or newer.
- Prefer standard library.
- External dependencies allowed only when clearly justified.
- Use `os.ReadFile`, not deprecated `ioutil` APIs.
- Tests required for validation logic.

---

## 24. Milestones

### Milestone 1: Combat Arena

Goal: Player can fight enemies in a single room.

Deliverables:

- Player movement
- Camera
- Basic attack
- Health and death
- One enemy type
- Damage numbers or hit feedback
- One skill

Acceptance:

- Player can kill an enemy.
- Enemy can damage player.
- Player can die.
- Combat loop runs without crashes.

### Milestone 2: Skills and Enemy Variety

Goal: Combat becomes meaningfully varied.

Deliverables:

- Three player skills
- Three enemy types
- Cooldowns
- Will resource
- Status effects

Acceptance:

- Each skill works and has a visible gameplay effect.
- Each enemy behaves differently.
- Player can survive or lose based on play.

### Milestone 3: Loot and Equipment

Goal: Loot changes the player's behavior or power.

Deliverables:

- Loot drops
- Inventory
- Equipment slots
- Item tooltips
- Stat modifiers
- At least 10 items

Acceptance:

- Player can pick up, inspect, equip, and unequip items.
- Equipped items affect combat stats.
- Loot drops from enemies and boss placeholder.

### Milestone 4: Rings and Attunement

Goal: Items reveal power through use.

Deliverables:

- Ring items
- Soul metadata
- Attunement XP
- Hidden property reveal
- Curse reveal
- Identify Scroll

Acceptance:

- Equipped item gains attunement XP.
- Hidden property unlocks at threshold.
- Curse can be revealed.
- Identify Scroll reveals valid hidden information.

### Milestone 5: Echoes and Death Consequences

Goal: The world remembers failure and item power.

Deliverables:

- Item Echoes
- Death Echoes
- Haunted room modifier
- Reclaim behavior
- Attunement reward for reclaiming

Acceptance:

- Death creates a Death Echo.
- Room changes while Death Echo exists.
- Player can reclaim Death Echo.
- Item Echo triggers during combat.

### Milestone 6: Ashen Catacombs Vertical Slice

Goal: A complete short dungeon run.

Deliverables:

- Entrance room
- Combat rooms
- Elite room
- Boss room
- Boss encounter
- Dungeon completion
- Reward chest
- Save/load

Acceptance:

- Player can start and complete a dungeon run.
- Boss can be defeated.
- Rewards are granted.
- Save/load preserves player state.

---

## 25. Acceptance Criteria

The prototype is considered successful when all of the following are true:

1. A player can launch the game and start a dungeon.
2. The player can move, attack, use skills, and dodge.
3. Enemies can pursue, attack, and kill the player.
4. The player can kill enemies and receive loot.
5. The player can equip weapons, armor, and rings.
6. Equipped items change player stats or behavior.
7. Rings contain soul metadata and can have curses.
8. Items can gain attunement XP.
9. Attunement can reveal hidden properties.
10. Identify Scrolls can reveal hidden item information.
11. At least one Item Echo works during combat.
12. Player death creates a Death Echo.
13. Death Echoes affect the room until reclaimed.
14. The player can fight and defeat the boss.
15. The dungeon can be completed.
16. Save/load preserves meaningful state.
17. Content is loaded from data files rather than being fully hardcoded.
18. The Go validator can check the content data.

---

## 26. Codex Implementation Guidance

### 26.1 Recommended First Prompt

Use this as the initial Codex prompt:

```text
Read SPEC.md and implement Milestone 1 only. Do not implement later systems yet. Create the smallest playable Godot prototype that satisfies Milestone 1 acceptance criteria. Preserve a clean project structure, keep placeholder assets simple, and add brief implementation notes to DECISIONS.md. After implementation, list exactly what works, what is stubbed, and what should be done next.
```

### 26.2 Recommended Agent Rules

Create a `CODEX.md` or similar instruction file with:

```text
You are implementing EldersCourage from SPEC.md.

Rules:
- Implement one milestone at a time.
- Do not add out-of-scope systems.
- Prefer simple placeholder visuals over asset hunting.
- Keep game content data-driven where practical.
- Update DECISIONS.md when making architectural choices.
- Update ACCEPTANCE.md with pass/fail status after each milestone.
- Do not silently skip acceptance criteria.
- Avoid speculative abstractions until at least two concrete uses exist.
- Keep commits small and milestone-oriented.
```

### 26.3 Suggested Codex Task Sequence

1. Create Godot project structure and placeholder scene.
2. Implement player movement and camera.
3. Implement basic attack and enemy dummy.
4. Implement enemy AI and damage.
5. Implement player death.
6. Implement three skills.
7. Implement loot and inventory.
8. Implement rings.
9. Implement attunement.
10. Implement echoes.
11. Implement dungeon room flow.
12. Implement boss.
13. Implement save/load.
14. Polish and balance.

---

## 27. Non-Functional Requirements

### 27.1 Performance

Prototype should maintain stable performance with:

- 20 enemies active
- 30 dropped items in scene
- Multiple damage numbers/effects

### 27.2 Maintainability

- Systems should be separated by responsibility.
- Data definitions should not be duplicated across code.
- Avoid hardcoding item IDs except for test/demo bootstrap.
- Use clear naming.

### 27.3 Testability

At minimum:

- Go data validator must have unit tests.
- Loot generation should be deterministic when given a seed.
- Core formulas should be isolated enough to test where practical.

---

## 28. Open Design Questions

These are intentionally unresolved and should not block Milestone 1:

1. Should final game be 2D, 2.5D, or 3D?
2. Should movement be WASD or click-to-move by default?
3. Should cursed items be cleanseable or only manageable?
4. Should rings speak through UI text, audio, or event triggers?
5. Should death echoes persist forever or expire?
6. Should hidden synergies be documented after discovery?
7. Should item attunement be per item instance or item type?

For the prototype, make pragmatic choices and document them in `DECISIONS.md`.

---

## 29. First Implementation Target

The immediate target is **Milestone 1: Combat Arena**.

Do not begin by implementing the full item system.

Build this first:

- One room
- One player
- One enemy
- One attack
- One skill
- Health
- Damage
- Death

If this is not fun, the rest of the game does not matter. The cathedral can wait. First, make the goblin bonk satisfying.

## Engine and Output Target

The primary deliverable is a runnable Godot 4.x project.

The prototype must be playable in the Godot editor using a top-down 2D presentation with placeholder assets. The implementation should prioritize combat feel, movement responsiveness, enemy behavior, loot drops, equipment changes, cursed rings, attunement, and death echoes.

Go may be used for optional developer tooling, data validation, loot simulation, and balance reporting, but Go is not the primary runtime for the playable prototype.

Browser-based UI is out of scope for the initial prototype.
Terminal-only gameplay is out of scope.
