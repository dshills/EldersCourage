
# EldersCourage — Phase 4 SPEC.md

## Phase Name

**Phase 4: Character Classes, Active Skills, Passive Talents, and Build Identity**

## Purpose

Phase 3 created the first repeatable RPG loop: movement, encounters, loot, equipment, XP, leveling, containers, shrines, and a multi-stage quest chain.

Phase 4 adds the first real layer of character identity. The player should no longer feel like a generic fantasy intern with a sword and a health bar. This phase introduces selectable classes, class-specific active skills, passive talents, skill points, mana costs, cooldowns, and a small but expandable build system.

This is not the full massive skill tree yet. It is the foundation for one.

---

# Primary Goal

Implement a class and skill system that allows the player to choose a class, unlock and use class-specific abilities, spend skill points on passive talents, and feel meaningfully different in combat depending on those choices.

The player should be able to:

1. Choose a character class at game start.
2. See class identity reflected in UI and stats.
3. Use at least 2 active skills for the selected class.
4. Spend skill points on passive talents.
5. Gain skill points through leveling.
6. See cooldowns and mana costs enforced.
7. See skill effects in combat messages and enemy/player state.
8. Reset and restart with a different class.
9. Complete the existing Phase 3 zone using class skills.

---

# Recommended Target

Continue using the current browser implementation.

Expected stack:

* Vite
* React
* TypeScript
* Existing Phase 3 state/reducer/systems structure
* Existing fantasy UI styling

Do not rewrite the game loop. Extend the existing systems.

---

# Non-Goals

Do **not** implement yet:

* Full branching skill trees with dozens of nodes
* Multi-classing
* Respec economy
* Procedural skill generation
* Animation-heavy spell effects
* Full status-effect engine beyond what this phase needs
* Deep item-skill synergy system
* Identified/hidden item powers
* Ring souls and curses
* Multiple zones
* Save/load persistence
* Networked play

This phase builds the skeleton for future complexity without making the codebase wheeze like an asthmatic dragon.

---

# Deliverables

## 1. Class Selection Screen

### Requirement

Add a class selection step before entering the game.

The user should choose one of three starting classes:

1. **Roadwarden**
2. **Ember Sage**
3. **Gravebound Scout**

The selected class determines:

* Starting stats
* Starting equipment
* Available active skills
* Available passive talents
* Class portrait/icon
* Class description/flavor text

### Class Selection Flow

On app launch:

1. If no class has been selected, show class selection screen.
2. Player selects a class.
3. Player clicks **Begin Journey**.
4. Game initializes with class-specific state.
5. Game enters Elder Road Outskirts.

Restarting the game should return to class selection or provide an explicit **Restart Same Class** and **Choose New Class** option.

### Acceptance Criteria

* Class selection appears before gameplay.
* Each class has a visible name, description, stat preview, and starting skill preview.
* Choosing a class initializes the game state correctly.
* Restart supports choosing another class.

---

# 2. Character Classes

## Required Types

Create:

```text
src/game/types/classes.ts
src/game/data/classes.ts
```

```ts
export type CharacterClassId = "roadwarden" | "ember_sage" | "gravebound_scout";

export interface CharacterClassDefinition {
  id: CharacterClassId;
  name: string;
  subtitle: string;
  description: string;
  portrait: string;
  baseStats: PlayerStats;
  startingHealth: number;
  startingMana: number;
  startingGold: number;
  startingItemIds: string[];
  startingSkillIds: string[];
  talentTreeId: string;
}
```

## Class Definitions

### Roadwarden

**Subtitle:** Shield of the Elder Road

**Fantasy:** A hardened frontier guardian who survives through armor, discipline, and heavy strikes.

**Role:** Durable melee fighter.

Starting stats:

```ts
baseStats: {
  strength: 4,
  defense: 3,
  spellPower: 0,
  maxHealthBonus: 10,
  maxManaBonus: 0,
}
startingHealth: 120
startingMana: 25
startingGold: 5
startingItemIds: ["old-sword", "roadwarden-vest", "minor-health-potion"]
startingSkillIds: ["guarded-strike", "shield-bash"]
```

### Ember Sage

**Subtitle:** Keeper of the First Flame

**Fantasy:** A fragile scholar of old fire magic who spends mana to deal high damage and manipulate battlefield pressure.

**Role:** Offensive caster.

Starting stats:

```ts
baseStats: {
  strength: 1,
  defense: 1,
  spellPower: 5,
  maxHealthBonus: -5,
  maxManaBonus: 25,
}
startingHealth: 85
startingMana: 75
startingGold: 8
startingItemIds: ["ember-staff", "cracked-ember-charm", "minor-health-potion"]
startingSkillIds: ["ember-bolt", "kindle"]
```

### Gravebound Scout

**Subtitle:** Listener at the Edge of Death

**Fantasy:** A nimble hunter touched by old grave magic, relying on precision, evasion, and life-draining strikes.

**Role:** Agile hybrid striker.

Starting stats:

```ts
baseStats: {
  strength: 3,
  defense: 1,
  spellPower: 2,
  maxHealthBonus: 0,
  maxManaBonus: 10,
}
startingHealth: 100
startingMana: 50
startingGold: 10
startingItemIds: ["scout-knife", "travelers-cloak", "minor-health-potion"]
startingSkillIds: ["piercing-shot", "grave-touch"]
```

### Acceptance Criteria

* All three class definitions exist as data.
* Class data is used to initialize player state.
* UI does not hard-code class-specific behavior except visual presentation.
* Class-specific starting items and skills are correctly granted.

---

# 3. Player State Expansion

## Requirement

Expand player state to support classes, skills, talents, cooldowns, and skill points.

## Required Fields

Extend `PlayerState`:

```ts
export interface PlayerSkillState {
  knownSkillIds: string[];
  cooldowns: Record<string, number>;
}

export interface PlayerTalentState {
  availablePoints: number;
  spentPoints: number;
  unlockedTalentIds: string[];
}

export interface PlayerState {
  name: string;
  classId: CharacterClassId;
  level: number;
  xp: number;
  xpToNextLevel: number;
  health: number;
  maxHealth: number;
  mana: number;
  maxMana: number;
  gold: number;
  baseStats: PlayerStats;
  inventory: Item[];
  equipment: EquipmentSlots;
  skills: PlayerSkillState;
  talents: PlayerTalentState;
  selectedItemId?: string;
  selectedSkillId?: string;
  position: ZonePosition;
}
```

### Skill Points

For Phase 4:

* Player starts with 0 available talent points.
* Player gains 1 talent point each level after level 1.
* Reaching level 2 grants 1 talent point.
* If Phase 3 allows level 3, reaching level 3 grants another point.

### Acceptance Criteria

* Player state includes class, known skills, cooldowns, and talents.
* Existing player systems continue to work.
* Level-up grants talent points.
* UI displays available talent points.

---

# 4. Active Skill System

## Requirement

Implement active skills that can be used in combat.

## Skill Type Definitions

Create:

```text
src/game/types/skills.ts
src/game/data/skills.ts
src/game/systems/skills.ts
```

```ts
export type SkillTargetType = "enemy" | "self";

export type SkillResource = "mana" | "health" | "none";

export type SkillEffectType =
  | "damage"
  | "heal"
  | "restore_mana"
  | "buff"
  | "debuff";

export interface SkillEffect {
  type: SkillEffectType;
  amount: number;
  scalingStat?: keyof PlayerStats;
  scalingMultiplier?: number;
  durationTurns?: number;
}

export interface ActiveSkillDefinition {
  id: string;
  classId: CharacterClassId;
  name: string;
  description: string;
  icon: string;
  targetType: SkillTargetType;
  resource: SkillResource;
  resourceCost: number;
  cooldownTurns: number;
  effects: SkillEffect[];
  messageTemplate: string;
}
```

## Cooldown Model

Use turn-based cooldowns.

* Cooldowns are stored as remaining turns.
* When a skill is used, set its cooldown to `cooldownTurns`.
* After enemy retaliation and turn resolution, decrement active cooldowns by 1.
* A skill with cooldown 0 or missing from cooldown map is usable.

Example:

```ts
cooldowns: {
  "shield-bash": 1,
  "ember-bolt": 0
}
```

## Resource Cost Rules

* Mana skills require enough mana.
* If insufficient mana, do not use the skill.
* Show a warning message.
* Mana cannot go below 0.

## Required Helpers

```ts
canUseSkill(player: PlayerState, skill: ActiveSkillDefinition): boolean
getSkillResourceFailureReason(player: PlayerState, skill: ActiveSkillDefinition): string | undefined
applySkill(state: GameState, skillId: string): GameState
reduceCooldowns(player: PlayerState): PlayerState
calculateSkillEffectAmount(player: PlayerState, effect: SkillEffect): number
```

### Acceptance Criteria

* Known skills appear in the UI.
* Skills can be selected or clicked directly.
* Skills respect mana costs.
* Skills respect cooldowns.
* Skill use adds meaningful combat messages.
* Cooldowns visibly update after turns.
* Basic attack still works as a fallback.

---

# 5. Required Class Skills

## Roadwarden Skills

### Guarded Strike

```ts
id: "guarded-strike"
name: "Guarded Strike"
targetType: "enemy"
resource: "mana"
resourceCost: 5
cooldownTurns: 0
effects: [
  {
    type: "damage",
    amount: 8,
    scalingStat: "strength",
    scalingMultiplier: 1.2,
  },
  {
    type: "buff",
    amount: 2,
    durationTurns: 1,
  }
]
```

Behavior:

* Deals moderate damage.
* Grants temporary +2 defense until after the next enemy retaliation.

Message:

```text
You drive forward with a guarded strike, dealing {damage} damage.
```

### Shield Bash

```ts
id: "shield-bash"
name: "Shield Bash"
targetType: "enemy"
resource: "mana"
resourceCost: 8
cooldownTurns: 2
effects: [
  {
    type: "damage",
    amount: 5,
    scalingStat: "strength",
    scalingMultiplier: 0.8,
  },
  {
    type: "debuff",
    amount: 2,
    durationTurns: 1,
  }
]
```

Behavior:

* Deals light damage.
* Reduces enemy attack by 2 for the next retaliation.

Message:

```text
Your shield crashes into the enemy, staggering it for {damage} damage.
```

## Ember Sage Skills

### Ember Bolt

```ts
id: "ember-bolt"
name: "Ember Bolt"
targetType: "enemy"
resource: "mana"
resourceCost: 10
cooldownTurns: 0
effects: [
  {
    type: "damage",
    amount: 10,
    scalingStat: "spellPower",
    scalingMultiplier: 1.5,
  }
]
```

Behavior:

* Deals strong magic damage.
* Ignores enemy defense for Phase 4.

Message:

```text
An ember bolt tears through the air, burning the enemy for {damage} damage.
```

### Kindle

```ts
id: "kindle"
name: "Kindle"
targetType: "self"
resource: "none"
resourceCost: 0
cooldownTurns: 3
effects: [
  {
    type: "restore_mana",
    amount: 15,
    scalingStat: "spellPower",
    scalingMultiplier: 0.5,
  }
]
```

Behavior:

* Restores mana.
* Cannot exceed max mana.
* Enemy still retaliates if the player is in combat and the enemy is alive.

Message:

```text
You kindle the old flame and recover {amount} mana.
```

## Gravebound Scout Skills

### Piercing Shot

```ts
id: "piercing-shot"
name: "Piercing Shot"
targetType: "enemy"
resource: "mana"
resourceCost: 7
cooldownTurns: 1
effects: [
  {
    type: "damage",
    amount: 7,
    scalingStat: "strength",
    scalingMultiplier: 1.0,
  }
]
```

Behavior:

* Deals damage.
* Ignores 1 point of enemy defense.

Message:

```text
Your shot finds a gap in the enemy's guard for {damage} damage.
```

### Grave Touch

```ts
id: "grave-touch"
name: "Grave Touch"
targetType: "enemy"
resource: "mana"
resourceCost: 12
cooldownTurns: 2
effects: [
  {
    type: "damage",
    amount: 6,
    scalingStat: "spellPower",
    scalingMultiplier: 1.0,
  },
  {
    type: "heal",
    amount: 5,
    scalingStat: "spellPower",
    scalingMultiplier: 0.5,
  }
]
```

Behavior:

* Deals shadow damage.
* Heals player for a small amount.
* Healing cannot exceed max health.

Message:

```text
Grave-cold power drains the enemy for {damage} damage and restores {healing} health.
```

### Acceptance Criteria

* Each class starts with exactly 2 active skills.
* Roadwarden skills feel defensive.
* Ember Sage skills feel magical and mana-driven.
* Gravebound Scout skills feel hybrid and evasive/draining.
* Skill behavior is deterministic and tested.

---

# 6. Temporary Buff/Debuff Support

## Requirement

Add minimal temporary modifier support for skill effects.

This does not need to become a full status-effect engine yet.

## Types

```ts
export type ModifierTarget = "player" | "enemy";
export type ModifierStat = "strength" | "defense" | "spellPower" | "attack";

export interface TemporaryModifier {
  id: string;
  sourceSkillId: string;
  target: ModifierTarget;
  stat: ModifierStat;
  amount: number;
  remainingTurns: number;
}
```

## Game State Addition

Add to `GameState`:

```ts
temporaryModifiers: TemporaryModifier[];
```

## Behavior

* Guarded Strike adds temporary player defense.
* Shield Bash adds temporary enemy attack reduction.
* Modifiers apply during the current combat turn.
* Modifiers expire when `remainingTurns` reaches 0.
* Expiration should happen predictably at end of turn.

## Required Helpers

```ts
getActiveModifiersForTarget(state: GameState, target: ModifierTarget): TemporaryModifier[]
getModifiedPlayerStats(state: GameState): PlayerStats
getModifiedEnemyAttack(state: GameState, enemyId: string): number
advanceTurnModifiers(state: GameState): GameState
```

### Acceptance Criteria

* Temporary buffs/debuffs affect combat calculations.
* Temporary modifiers expire correctly.
* Expired modifiers do not continue affecting stats.
* Tests cover modifier application and expiration.

---

# 7. Passive Talent System

## Requirement

Add a small passive talent system for each class.

This should be a compact list/tree, not a giant Path of Exile constellation. The goal is proof of structure.

## Types

Create:

```text
src/game/types/talents.ts
src/game/data/talents.ts
src/game/systems/talents.ts
```

```ts
export type TalentEffectType =
  | "stat_bonus"
  | "skill_damage_bonus"
  | "resource_cost_reduction"
  | "cooldown_reduction";

export interface TalentEffect {
  type: TalentEffectType;
  stat?: keyof PlayerStats;
  skillId?: string;
  amount: number;
}

export interface TalentNode {
  id: string;
  classId: CharacterClassId;
  name: string;
  description: string;
  maxRank: number;
  requiredLevel: number;
  prerequisiteTalentIds: string[];
  effects: TalentEffect[];
}

export interface TalentTree {
  id: string;
  classId: CharacterClassId;
  name: string;
  nodes: TalentNode[];
}
```

## Talent Rank Storage

Replace `unlockedTalentIds` with rank-aware storage if needed:

```ts
export interface PlayerTalentState {
  availablePoints: number;
  spentPoints: number;
  ranks: Record<string, number>;
}
```

If the current implementation already used `unlockedTalentIds`, migrate cleanly.

## Required Talent Rules

* Spending a talent point increases a talent rank by 1.
* Cannot exceed max rank.
* Cannot spend without available points.
* Cannot spend below required level.
* Cannot spend unless prerequisites are met.
* Talent effects apply immediately.

## Required Helpers

```ts
canSpendTalentPoint(player: PlayerState, talent: TalentNode, tree: TalentTree): boolean
spendTalentPoint(player: PlayerState, talentId: string, tree: TalentTree): PlayerState
getTalentRank(player: PlayerState, talentId: string): number
getTalentEffects(player: PlayerState, tree: TalentTree): TalentEffect[]
getTalentStatBonuses(player: PlayerState, tree: TalentTree): PlayerStats
```

### Acceptance Criteria

* Player gains talent points from leveling.
* Player can spend talent points in the UI.
* Talent prerequisites and level requirements are enforced.
* Talent effects modify stats or skill behavior.
* Talent state survives during the current session.

---

# 8. Required Passive Talents

Each class should have 4 passive talents.

## Roadwarden Talent Tree: Road Oaths

### Iron Posture

```ts
id: "iron-posture"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "defense", amount: 1 }]
```

Each rank grants +1 defense.

### Veteran Arm

```ts
id: "veteran-arm"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "strength", amount: 1 }]
```

Each rank grants +1 strength.

### Stalwart Guard

```ts
id: "stalwart-guard"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["iron-posture"]
effects: [{ type: "resource_cost_reduction", skillId: "guarded-strike", amount: 2 }]
```

Reduces Guarded Strike mana cost by 2.

### Crushing Bash

```ts
id: "crushing-bash"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["veteran-arm"]
effects: [{ type: "skill_damage_bonus", skillId: "shield-bash", amount: 3 }]
```

Shield Bash deals +3 damage.

## Ember Sage Talent Tree: Ember Memory

### Living Flame

```ts
id: "living-flame"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "spellPower", amount: 1 }]
```

Each rank grants +1 spell power.

### Deep Breath

```ts
id: "deep-breath"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "maxManaBonus", amount: 5 }]
```

Each rank grants +5 max mana.

### Focused Ember

```ts
id: "focused-ember"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["living-flame"]
effects: [{ type: "skill_damage_bonus", skillId: "ember-bolt", amount: 4 }]
```

Ember Bolt deals +4 damage.

### Efficient Kindle

```ts
id: "efficient-kindle"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["deep-breath"]
effects: [{ type: "cooldown_reduction", skillId: "kindle", amount: 1 }]
```

Kindle cooldown reduced by 1 turn.

## Gravebound Scout Talent Tree: Grave Tracks

### Quiet Step

```ts
id: "quiet-step"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "defense", amount: 1 }]
```

Each rank grants +1 defense.

### Killing Angle

```ts
id: "killing-angle"
maxRank: 2
requiredLevel: 2
prerequisiteTalentIds: []
effects: [{ type: "stat_bonus", stat: "strength", amount: 1 }]
```

Each rank grants +1 strength.

### Barbed Shot

```ts
id: "barbed-shot"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["killing-angle"]
effects: [{ type: "skill_damage_bonus", skillId: "piercing-shot", amount: 3 }]
```

Piercing Shot deals +3 damage.

### Hungry Grave

```ts
id: "hungry-grave"
maxRank: 1
requiredLevel: 3
prerequisiteTalentIds: ["quiet-step"]
effects: [{ type: "skill_damage_bonus", skillId: "grave-touch", amount: 2 }]
```

Grave Touch deals +2 damage. Optional: also increases healing by 1 if simple to implement.

### Acceptance Criteria

* Each class has 4 passive talents.
* Level 2 talents are reachable in this phase.
* Level 3 talents are available if the player reaches level 3 or can be tested directly.
* Talent UI displays rank, max rank, requirement, and prerequisites.
* Talent effects influence stats or skills.

---

# 9. Skill and Talent UI

## Requirement

Add UI panels for active skills and passive talents.

## Active Skill Bar

Add a skill bar near the existing action bar.

For each known skill, show:

* Icon or fallback symbol
* Name
* Mana/resource cost
* Cooldown remaining
* Disabled state if unusable

Example:

```text
[Guarded Strike] 5 Mana
[Shield Bash] 8 Mana | Cooldown: 1
[Basic Attack]
```

## Skill Details

On hover or selection, show:

* Name
* Description
* Cost
* Cooldown
* Effect summary

## Talent Panel

Add a talent panel accessible from the main UI.

It should show:

* Class talent tree name
* Available talent points
* Talent nodes/cards
* Current rank / max rank
* Required level
* Prerequisites
* Spend button
* Locked/unlocked/spendable states

## Talent Visual States

```text
Locked: prerequisite or level unmet
Available: can spend point
Ranked: has at least one point spent
Maxed: rank equals maxRank
```

## Acceptance Criteria

* Skill bar is visible in combat.
* Skills show disabled state when on cooldown or lacking mana.
* Talent panel can open/close.
* Talent points can be spent through UI.
* Talent changes are reflected in stats/skills immediately.

---

# 10. Combat Integration

## Requirement

Integrate skills into the existing combat system.

## Turn Flow

When player uses Basic Attack:

1. Calculate attack damage.
2. Apply damage to enemy.
3. If enemy defeated, resolve victory.
4. If enemy alive, enemy retaliates.
5. Advance turn modifiers/cooldowns.

When player uses Active Skill:

1. Validate skill is known.
2. Validate target exists if target type is enemy.
3. Validate resource cost.
4. Validate cooldown.
5. Spend resource.
6. Apply skill effect(s).
7. Add messages.
8. If enemy defeated, resolve victory.
9. If enemy alive and skill consumed a combat turn, enemy retaliates.
10. Advance modifiers/cooldowns.

For Phase 4, all active skills consume a combat turn.

## Enemy Retaliation Exceptions

* If enemy is defeated, no retaliation.
* If using a self skill during active combat, enemy retaliates unless the skill explicitly says otherwise.

## Acceptance Criteria

* Existing attack still works.
* Active skills work during combat.
* Active skills are blocked outside combat if they require an enemy target.
* Self skills can be used in combat if valid.
* Combat messages clearly indicate skill use and outcomes.

---

# 11. Mana and Resource UI

## Requirement

Mana should become more important now that skills exist.

Update UI to show:

* Current mana / max mana.
* Mana bar changes after skill use.
* Mana restoration messages.
* Disabled skill state when mana is insufficient.

## Optional Rest Behavior

If needed for balance, add a simple rest action at camp only:

* Can only rest at Camp tile.
* Rest restores health and mana to full.
* Adds message.
* Does not reset enemies or containers.

This is optional. Do not implement rest if shrine and potions are enough.

### Acceptance Criteria

* Mana costs are visible.
* Skill use reduces mana.
* Mana restoration works.
* UI accurately reflects mana changes.

---

# 12. Item Additions for Class Starts

## Requirement

Add missing starter items for the new classes.

## Required Items

### Ember Staff

```ts
{
  id: "ember-staff",
  name: "Ember Staff",
  type: "weapon",
  equipmentSlot: "weapon",
  equippable: true,
  stackable: false,
  stats: { spellPower: 2, maxManaBonus: 5 },
}
```

### Scout Knife

```ts
{
  id: "scout-knife",
  name: "Scout Knife",
  type: "weapon",
  equipmentSlot: "weapon",
  equippable: true,
  stackable: false,
  stats: { strength: 1, spellPower: 1 },
}
```

### Traveler's Cloak

```ts
{
  id: "travelers-cloak",
  name: "Traveler's Cloak",
  type: "armor",
  equipmentSlot: "armor",
  equippable: true,
  stackable: false,
  stats: { defense: 1, maxManaBonus: 5 },
}
```

## Starter Equipment Behavior

Class starting equipment should either:

1. Begin equipped automatically, or
2. Begin in inventory with clear equip prompts.

Preferred for Phase 4:

* Automatically equip starting weapon and armor.
* Put consumables in inventory.
* Show a message listing starting gear.

### Acceptance Criteria

* All class starter item IDs resolve to valid items.
* Starting weapon/armor are equipped automatically.
* Starting consumables appear in inventory.
* Effective stats include starter equipment.

---

# 13. Class-Specific Flavor Messages

## Requirement

Add small class-specific text feedback to make classes feel distinct.

## Examples

Roadwarden start:

```text
You tighten the straps of your road-worn armor. The Elder Road will hold.
```

Ember Sage start:

```text
A coal-bright ember stirs in your palm. Old fire remembers you.
```

Gravebound Scout start:

```text
The dead are quiet today. That usually means they are listening.
```

Level-up examples:

Roadwarden:

```text
Your oath hardens. You reached level {level}.
```

Ember Sage:

```text
The flame within you grows brighter. You reached level {level}.
```

Gravebound Scout:

```text
A whisper from below guides your hand. You reached level {level}.
```

### Acceptance Criteria

* Class selection adds a class-specific start message.
* Level-up can use class-specific text.
* Skill messages are class-appropriate.

---

# 14. Game Balance Pass

## Requirement

Adjust Phase 3 enemy stats if necessary so all classes can complete Elder Road Outskirts.

## Balance Goals

* Roadwarden should survive well but kill slower.
* Ember Sage should kill quickly but care about mana and health.
* Gravebound Scout should feel flexible but not dominant.

## Suggested Adjustments

If current Phase 3 enemies are too punishing:

* Keep Goblin Scout easy.
* Keep Starved Wolf dangerous to Ember Sage if careless.
* Keep Road Bandit as the hardest encounter.

Recommended enemy health range remains:

```text
Goblin Scout: 30 health
Starved Wolf: 24 health
Road Bandit: 45 health
```

If skills trivialize combat, increase Road Bandit health to 55.

## Acceptance Criteria

* Each class can complete the zone with reasonable play.
* No class is soft-locked by mana starvation or low damage.
* Combat still carries some risk.

---

# 15. State Architecture Requirements

## Requirement

Keep skill/talent logic out of React components.

Recommended structure:

```text
src/game/systems/
  combat.ts
  inventory.ts
  equipment.ts
  quests.ts
  zone.ts
  loot.ts
  skills.ts
  talents.ts
  classes.ts

src/game/data/
  classes.ts
  skills.ts
  talents.ts
  items.ts
  enemies.ts
  zones.ts
```

## Reducer Actions

Add or extend actions:

```ts
export type GameAction =
  | { type: "SELECT_CLASS"; classId: CharacterClassId }
  | { type: "USE_SKILL"; skillId: string }
  | { type: "SELECT_SKILL"; skillId?: string }
  | { type: "SPEND_TALENT_POINT"; talentId: string }
  | { type: "OPEN_TALENT_PANEL" }
  | { type: "CLOSE_TALENT_PANEL" }
  | { type: "TOGGLE_TALENT_PANEL" }
  // existing Phase 3 actions remain
```

## Acceptance Criteria

* Components dispatch skill/talent/class actions.
* Systems contain the actual rules.
* Tests can call systems directly without rendering UI.

---

# 16. Testing Requirements

## Required Test Areas

Add tests for:

### Class Initialization

* Roadwarden initializes with correct stats, skills, and equipment.
* Ember Sage initializes with correct stats, skills, and equipment.
* Gravebound Scout initializes with correct stats, skills, and equipment.
* Invalid class ID is handled safely if applicable.

### Skill Validation

* Cannot use unknown skill.
* Cannot use skill without enough mana.
* Cannot use skill while on cooldown.
* Cannot use enemy-targeted skill without active enemy.

### Skill Effects

* Damage skills reduce enemy health.
* Heal skills restore health without exceeding max.
* Mana restore skills restore mana without exceeding max.
* Skill scaling uses effective player stats.

### Cooldowns

* Skill use sets cooldown.
* Cooldowns decrement after turn.
* Skills become usable when cooldown reaches 0.

### Temporary Modifiers

* Guarded Strike increases defense for enemy retaliation.
* Shield Bash reduces enemy attack for retaliation.
* Modifiers expire after correct turn count.

### Talents

* Cannot spend point without available points.
* Cannot spend below required level.
* Cannot spend without prerequisite.
* Cannot exceed max rank.
* Talent stat bonuses affect derived stats.
* Talent skill bonuses affect skill results.

### Level-Up Skill Points

* Level-up grants talent point.
* Talent point count is accurate after spending.

### Integration

* Each class can defeat Goblin Scout in a deterministic test.
* Each class can complete at least one encounter using a class skill.

## Acceptance Criteria

* Existing Phase 2 and Phase 3 tests still pass.
* New systems have meaningful unit coverage.
* Build and test commands pass.

---

# 17. UI Acceptance Checklist

Phase 4 UI is complete when:

1. Class selection screen exists.
2. Class cards show useful information.
3. Current class is visible during gameplay.
4. Skill bar displays known active skills.
5. Skill buttons show cost and cooldown.
6. Skill buttons disable correctly.
7. Talent panel opens and closes.
8. Talent panel shows available points.
9. Talent nodes show ranks and locked states.
10. Spending a point updates stats or skill behavior.
11. Combat log shows skill-specific messages.
12. Mana bar updates after skill usage.
13. Restart allows choosing a new class.

---

# 18. Implementation Plan

## Step 1 — Add Class Data and Selection Screen

* Add class types and definitions.
* Add class selection UI.
* Add class initialization system.
* Wire restart/new class flow.

## Step 2 — Expand Player State

* Add class ID, skill state, talent state, and selected skill.
* Update initial state generation to require class selection.
* Ensure existing systems still compile.

## Step 3 — Add Starter Items

* Add Ember Staff, Scout Knife, and Traveler's Cloak.
* Auto-equip starter gear.
* Add class start messages.

## Step 4 — Add Active Skill Data

* Add skill types and definitions.
* Add the six required class skills.
* Add skill lookup helpers.

## Step 5 — Implement Skill System

* Implement skill validation.
* Implement resource costs.
* Implement damage/heal/mana restore effects.
* Implement cooldowns.
* Integrate with combat turn flow.

## Step 6 — Add Temporary Modifiers

* Add modifier types and state.
* Implement Guarded Strike defense buff.
* Implement Shield Bash enemy attack debuff.
* Add expiration behavior.

## Step 7 — Add Skill Bar UI

* Render known skills.
* Add disabled states.
* Add skill details.
* Wire skill button clicks to game actions.

## Step 8 — Add Talent Data

* Add talent types and definitions.
* Add all three class talent trees.
* Add talent lookup helpers.

## Step 9 — Implement Talent System

* Add talent point gain on level-up.
* Implement spend validation.
* Apply stat bonuses and skill modifiers.

## Step 10 — Add Talent Panel UI

* Render class-specific talent tree.
* Show points, ranks, requirements, and prerequisites.
* Wire spend button.

## Step 11 — Balance Pass

* Play through each class.
* Adjust enemy stats or starting resources if needed.
* Keep changes small and documented.

## Step 12 — Tests and Cleanup

* Add class, skill, cooldown, modifier, and talent tests.
* Run full test suite.
* Remove obsolete assumptions from Phase 3.

---

# 19. Suggested Commit Plan

```text
1. feat: add class definitions and class selection screen
2. feat: initialize player state from selected class
3. feat: add starter equipment for new classes
4. feat: add active skill definitions and skill state
5. feat: implement skill validation, costs, effects, and cooldowns
6. feat: integrate active skills into combat flow
7. feat: add temporary combat modifiers
8. feat: add skill bar and skill detail UI
9. feat: add passive talent definitions and talent state
10. feat: implement talent point spending and derived bonuses
11. feat: add talent panel UI
12. test: cover classes, skills, cooldowns, modifiers, and talents
13. balance: tune first zone for all classes
```

---

# 20. Acceptance Criteria for Entire Phase

Phase 4 is complete when:

1. Player must choose a class before starting.
2. Roadwarden, Ember Sage, and Gravebound Scout are playable.
3. Each class starts with appropriate stats, gear, and two skills.
4. Existing Elder Road Outskirts gameplay still works.
5. Player can use active skills in combat.
6. Skills consume mana where applicable.
7. Skills enforce cooldowns.
8. Skill effects include damage, healing, mana restoration, and temporary modifiers.
9. Basic attack remains available.
10. Player gains talent points on level-up.
11. Player can spend talent points in a class-specific talent tree.
12. Talent requirements and prerequisites are enforced.
13. Talent bonuses affect stats or skills.
14. UI clearly displays class, skills, mana, cooldowns, talents, and talent points.
15. Each class can complete Elder Road Outskirts.
16. Tests cover the new class, skill, cooldown, modifier, and talent systems.
17. Code remains structured for future expansion.

---

# 21. Future Phase Hooks

After Phase 4, the project will be ready for one of these next milestones:

## Phase 5 Candidate A — Item Identity, Identify Scrolls, and Attunement

* Hidden item powers.
* Question-mark attributes.
* Identify scrolls.
* Attunement tracking.
* Item powers revealed by level, use, or scroll.

## Phase 5 Candidate B — Dungeon Rooms and Zone Transitions

* Multiple zones.
* Room-to-room travel.
* More encounters.
* Environmental hazards.

## Phase 5 Candidate C — Ring Souls and Curses

* Rings as trapped spellcaster souls.
* Powerful benefits.
* Dangerous curses.
* Personality/lore messages.

## Phase 5 Candidate D — Skill Tree Expansion

* Larger branching trees.
* Class specialization paths.
* Skill upgrades.
* Synergy unlocks.

Do not implement these in Phase 4. Keep interfaces flexible enough to support them.

---

# 22. Definition of Done

Phase 4 is done when EldersCourage has real build identity.

A Roadwarden should feel sturdy and martial. An Ember Sage should feel dangerous and mana-hungry. A Gravebound Scout should feel precise, strange, and hard to pin down.

The player should not just win because numbers went up. The player should win because they made class-specific choices, used skills at the right time, and spent talent points in a way that changed how combat feels.

Small system. Real decisions. No fake complexity wearing a wizard hat.
