# EldersCourage — Phase 8 SPEC.md

## Phase Name

**Phase 8: Ring Souls, Whispers, Memories, Bargains, and Living Curses**

## Canonical Implementation Target

This is a **Godot project**.

All implementation should use Godot-native systems:

- Godot 4.x
- `.tscn` scenes
- Control nodes for UI
- Resources, dictionaries, or lightweight GDScript data definitions
- Autoloads where appropriate
- Signals for game events and UI updates
- Tween / AnimationPlayer for feedback
- InputMap for player controls
- GDScript unless the project already uses C#

Any prior React/Vite/TypeScript/browser wording from earlier specs is obsolete implementation-target noise. Preserve design intent; implement using Godot.

---

## Purpose

Previous phases established the core loop: exploration, combat, classes, skills, talents, loot, item identification, attunement, curses, and UI cleanup.

Phase 8 introduces one of EldersCourage’s defining item fantasies:

**Every powerful ring contains the soul, echo, or fractured remnant of a dead spellcaster.**

Rings are not passive stat sticks. They remember. They whisper. They bargain. They lie. They help. They curse. Some want freedom. Some want a body. Some want revenge. Some are just ancient magical weirdos stuck in jewelry, which frankly would make anyone difficult.

This phase adds the first playable version of Ring Souls.

---

## Primary Goal

Implement rings as semi-living artifacts with named soul personalities, attunement-based memory reveals, contextual whispers, beneficial powers, curses, and simple player choices/bargains.

The player should be able to:

1. Find or receive a soul-bound ring.
2. Identify the ring enough to discover that a soul is inside.
3. Equip the ring.
4. Gain attunement through combat and use.
5. Receive contextual whispers from the ring.
6. Unlock memories as attunement increases.
7. Reveal ring powers and curses through identification/attunement/triggers.
8. Encounter at least one ring bargain choice.
9. Accept or reject a bargain.
10. See ring personality reflected in messages, UI, and effects.

---

## Non-Goals

Do **not** implement in this phase:

- Full dialogue trees
- Voice acting
- Complex reputation systems
- Multiple ring slots
- Ring fusion/merging
- Permanent branching campaign consequences
- Full companion AI
- Procedural soul generation
- Complex morality alignment
- Save/load persistence unless already present
- Full cutscene system

This phase should prove the Ring Soul system with a small, durable implementation.

---

## Design Pillars

### 1. Rings Are Dangerous

A soul-bound ring should feel powerful but suspicious. Equipping one is a choice, not automatic optimization.

### 2. Rings Have Personality

Each ring has a distinct voice, motivation, and style of message.

### 3. Attunement Reveals Truth

As the player uses the ring, more memories, powers, and curses surface.

### 4. Curses Are Part of the Identity

Curses should not feel like random penalties. They should reflect the soul inside the ring.

### 5. Choices Should Be Small But Meaningful

The first bargain system should be simple: accept/reject a ring’s offer and receive consequences.

---

## Deliverables

## 1. Ring Soul Data Model

### Requirement

Extend the item discovery system so certain ring/trinket items can reference a soul definition.

Recommended files:

```text
res://scripts/types/ring_soul_types.gd
res://scripts/data/ring_soul_defs.gd
res://scripts/systems/ring_souls.gd
res://scenes/ui/RingSoulPanel.tscn
res://scenes/ui/RingWhisperToast.tscn
```

Use existing project conventions if file paths differ.

### Required Concepts

A ring soul should define:

- Soul ID
- Display name
- Title/epithet
- Personality tags
- Former magical discipline
- Motivation
- Trust state
- Whisper lines
- Memory fragments
- Bargains
- Associated item properties

### Suggested GDScript Dictionary Shape

```gdscript
const RING_SOULS := {
    "varn_ashen_orator": {
        "id": "varn_ashen_orator",
        "name": "Varn",
        "epithet": "The Ashen Orator",
        "discipline": "Ember rhetoric and binding flame",
        "personality_tags": ["eloquent", "vain", "hungry", "persuasive"],
        "motivation": "To feel living breath again, even borrowed.",
        "default_trust": 0,
        "whispers": [],
        "memories": [],
        "bargains": [],
    }
}
```

### Ring Item Link

Extend item definitions with optional soul binding:

```gdscript
"soul_id": "varn_ashen_orator"
```

Only soul-bound rings need this field.

### Acceptance Criteria

- Ring soul data exists separately from generic item data.
- A ring item can link to a soul definition.
- Existing non-soul trinkets still work.
- UI can resolve item instance → item definition → ring soul definition.

---

## 2. Ring Soul State

### Requirement

Track per-ring-instance relationship/progression state.

The same soul-bound ring definition may produce an instance with its own reveal state and bargain choices.

### Required State

Add to item instance or a related state map:

```gdscript
{
    "item_instance_id": "uuid-or-instance-id",
    "soul_id": "varn_ashen_orator",
    "soul_revealed": false,
    "trust": 0,
    "memory_ids_revealed": [],
    "whisper_ids_seen": [],
    "bargain_ids_offered": [],
    "bargain_ids_accepted": [],
    "bargain_ids_rejected": []
}
```

### Trust Range

Use a small integer range:

```text
-3 to +3
```

Trust affects which whispers/bargains may occur later.

For Phase 8, trust only needs to affect available messages and one bargain outcome.

### Acceptance Criteria

- Ring soul state is tracked per item instance.
- Soul reveal state is separate from generic item identification state.
- Trust can increase/decrease.
- Memory and bargain state does not duplicate.

---

## 3. Required Soul-Bound Ring

### Requirement

Implement one fully playable soul-bound ring.

## Ring: Ashen Ring

If Ashen Ring already exists from Phase 5, extend it rather than replacing it.

### Item Definition

```gdscript
{
    "id": "ashen_ring",
    "name": "Ashen Ring",
    "unidentified_name": "Unidentified Ring",
    "type": "trinket",
    "equipment_slot": "trinket",
    "equippable": true,
    "attunable": true,
    "max_attunement_level": 3,
    "soul_id": "varn_ashen_orator",
    "description": "A blackened ring warm to the touch. It feels like a coal that forgot how to die."
}
```

## Soul: Varn, The Ashen Orator

### Identity

```text
Name: Varn
Epithet: The Ashen Orator
Former Discipline: Ember rhetoric and binding flame
Personality: eloquent, vain, hungry, persuasive, wounded
Motivation: To feel living breath again, even borrowed.
```

### Voice Direction

Varn should speak like a refined, manipulative spellcaster who believes the player is underusing his brilliance.

Tone examples:

```text
Softly theatrical
Condescending but useful
Hungry for sensation
Flattering when it benefits him
Bitter when ignored
```

Do not overdo the prose. Whispers should be short and flavorful.

### Acceptance Criteria

- Ashen Ring is linked to Varn.
- Varn has data-driven whispers, memories, and at least one bargain.
- Ring UI shows Varn once the soul is revealed.

---

## 4. Soul Reveal Rules

### Requirement

The player should not immediately know everything about the ring soul.

### Reveal Stages

#### Stage 0 — Unknown Ring

Before identification:

```text
Unidentified Ring
A blackened ring warm to the touch.
Properties: ???
```

No soul name shown.

#### Stage 1 — Soul Presence Revealed

Triggered by Identify Scroll or first curse/whisper trigger.

Display:

```text
Soul Presence: Unknown
Something inside the ring listens.
```

#### Stage 2 — Soul Name Revealed

Triggered by attunement level 1.

Display:

```text
Varn, The Ashen Orator
A dead ember-mage bound in gold-black ash.
```

#### Stage 3 — Soul Motivation Revealed

Triggered by attunement level 2.

Display:

```text
Motivation: To feel living breath again, even borrowed.
```

#### Stage 4 — Deeper Memory Revealed

Triggered by bargain or attunement level 3.

Display memory/lore fragment.

### Required Helpers

```gdscript
func reveal_soul_presence(game_state, item_instance_id: String) -> Dictionary
func reveal_soul_name(game_state, item_instance_id: String) -> Dictionary
func reveal_soul_motivation(game_state, item_instance_id: String) -> Dictionary
func get_soul_reveal_stage(game_state, item_instance_id: String) -> int
```

### Acceptance Criteria

- Soul information reveals progressively.
- Ring details panel does not spoil unrevealed soul identity.
- Attunement level 1 reveals Varn’s name.
- Attunement level 2 reveals motivation.
- Reveal messages are shown once.

---

## 5. Ring Whispers

### Requirement

Add contextual ring whispers as short messages triggered by gameplay events.

Whispers should appear in the message log and optionally as a small toast/overlay.

### Whisper Event Types

Support these triggers:

```text
on_equip
on_combat_start
on_skill_use
on_low_health
on_enemy_defeated
on_attunement_level_up
on_curse_trigger
on_idle_or_location_entered
```

For Phase 8, implement at least:

- on_equip
- on_skill_use
- on_enemy_defeated
- on_attunement_level_up
- on_curse_trigger

### Whisper Definition

```gdscript
{
    "id": "varn_equip_001",
    "trigger": "on_equip",
    "min_reveal_stage": 1,
    "min_trust": -3,
    "max_trust": 3,
    "once": true,
    "text": "Ah. Warmth. Crude hands, yes, but warmth all the same."
}
```

### Required Varn Whispers

#### On Equip

```text
Ah. Warmth. Crude hands, yes, but warmth all the same.
```

#### On Skill Use

```text
Spend the flame boldly. Hoarding embers is for peasants and undertakers.
```

#### On Enemy Defeated

```text
There. See? Fire clarifies all arguments.
```

#### On Attunement Level 1

```text
Varn. You may call me Varn. Try not to sound impressed.
```

#### On Attunement Level 2

```text
Do you know what I miss most? Breath. The theft of it. The luxury.
```

#### On Curse Trigger

```text
A sip. Barely a sip. Do not be dramatic.
```

#### Low Trust Whisper

```text
Ignore me if you must. Many corpses were also stubborn.
```

#### High Trust Whisper

```text
There may be promise in you. Do not ruin it by becoming humble.
```

### Whisper Frequency Rules

Avoid spam.

- Once-only whispers should never repeat.
- Repeatable whispers should have a cooldown.
- Only one ring whisper should fire from a single gameplay event.
- Ring whisper should not replace normal combat/loot messages.

### Required Helpers

```gdscript
func get_available_whispers(game_state, trigger: String) -> Array
func select_whisper(game_state, trigger: String) -> Dictionary
func process_ring_whisper_trigger(game_state, trigger: String) -> Dictionary
func mark_whisper_seen(game_state, item_instance_id: String, whisper_id: String) -> Dictionary
```

### Acceptance Criteria

- Equipping Ashen Ring can trigger a whisper.
- Skill use can trigger a whisper without spamming every time.
- Enemy defeat can trigger a whisper.
- Attunement reveal triggers a specific whisper.
- Curse trigger can trigger a curse-related whisper.
- Message log distinguishes ring whispers from normal messages.

---

## 6. Ring Memory Fragments

### Requirement

Add memory fragments revealed through attunement.

Memory fragments are short lore entries, not full cutscenes.

### Memory Definition

```gdscript
{
    "id": "varn_memory_001",
    "title": "The Hall of Cinders",
    "reveal_requirement": {
        "type": "attunement",
        "value": 1
    },
    "text": "A hall of black glass. Apprentices kneel in ash. A man with Varn's voice teaches them that flame is not destruction. It is persuasion."
}
```

### Required Varn Memories

#### Memory 1 — The Hall of Cinders

Requirement: Attunement Level 1

```text
A hall of black glass. Apprentices kneel in ash. A man with Varn's voice teaches them that flame is not destruction. It is persuasion.
```

#### Memory 2 — The Failed Binding

Requirement: Attunement Level 2

```text
A circle breaks. Gold melts. Someone screams Varn's name, not in fear but betrayal. The ring remembers being a prison before it remembers being jewelry.
```

#### Memory 3 — The Last Breath

Requirement: Attunement Level 3 or bargain accepted

```text
Varn gasps once through another person's lungs. He laughs. Then the ring closes around the sound forever.
```

### UI Requirement

Ring details panel should show a **Memories** section once any memory is revealed.

Example:

```text
Memories
- The Hall of Cinders
- The Failed Binding
```

Selecting a memory should show the full text in the ring panel or a popup.

### Acceptance Criteria

- Memories reveal at attunement thresholds.
- Memory reveal messages appear once.
- Ring panel lists revealed memories.
- Memory text is readable and not buried in the message log only.

---

## 7. Ring Bargain System

### Requirement

Implement a small bargain choice system.

A bargain is a ring-initiated offer with accept/reject options and consequences.

### Bargain Definition

```gdscript
{
    "id": "varn_bargain_breath_for_flame",
    "title": "Breath for Flame",
    "trigger": "on_attunement_level_2",
    "once": true,
    "offer_text": "Let me taste one living breath and I will teach your flame to bite deeper.",
    "accept_text": "Give Varn a breath.",
    "reject_text": "Refuse him.",
    "accept_effects": [],
    "reject_effects": []
}
```

### Required Bargain: Breath for Flame

#### Trigger

Offer after Ashen Ring reaches attunement level 2.

#### Offer Text

```text
Let me taste one living breath and I will teach your flame to bite deeper.
```

#### Accept

Player accepts.

Effects:

- Player loses 5 current health immediately, not below 1.
- Trust +1.
- Reveal Memory 3 if not already revealed.
- Add permanent revealed property to Ashen Ring:
  - Ember Bolt deals +2 damage.

Message:

```text
Varn drinks a single breath. Your flame sharpens.
```

#### Reject

Player rejects.

Effects:

- Trust -1.
- No damage bonus.
- Varn low-trust whisper may appear.

Message:

```text
The ring cools against your hand. Varn says nothing, which is somehow worse.
```

### Bargain UI

Create:

```text
res://scenes/ui/RingBargainPanel.tscn
```

The panel should show:

- Ring/soul name if known
- Bargain title
- Offer text
- Accept button
- Reject button
- Consequence hint, if known

For Phase 8, it is acceptable to show clear mechanical consequences. Later phases can obscure consequences if desired.

### Required Helpers

```gdscript
func should_offer_bargain(game_state, item_instance_id: String, trigger: String) -> bool
func offer_bargain(game_state, item_instance_id: String, bargain_id: String) -> Dictionary
func accept_bargain(game_state, item_instance_id: String, bargain_id: String) -> Dictionary
func reject_bargain(game_state, item_instance_id: String, bargain_id: String) -> Dictionary
```

### Acceptance Criteria

- Bargain appears once at the correct trigger.
- Player can accept or reject.
- Accept effects apply correctly.
- Reject effects apply correctly.
- Bargain state is stored and does not repeat.
- UI clearly communicates the choice.

---

## 8. Ring Curse Integration

### Requirement

Integrate existing curse behavior with ring soul personality.

If Ashen Ring already has `Blood Price`, keep it and connect it to Varn.

### Blood Price Curse

#### Behavior

- Trigger: player uses a skill while Ashen Ring is equipped.
- Effect: player loses 2 health.
- First trigger reveals the curse if hidden.
- Curse cannot reduce player below 1 health in Phase 8.
- Varn whisper may trigger on first reveal.

### Curse Presentation

When curse reveals:

```text
Curse revealed: Blood Price.
Varn drinks a sliver of your life through the ring.
```

In ring panel:

```text
Curse: Blood Price
Lose 2 health when using a skill. Varn insists this is "symbolic taxation."
```

### Trust Interaction

Optional but recommended:

- If player accepts Breath for Flame bargain, Blood Price still remains.
- Trust does not remove curse.
- High trust may reduce whisper hostility, not mechanical penalty.

### Acceptance Criteria

- Curse is associated with Varn thematically.
- Curse reveal message references ring soul if known.
- Blood Price remains mechanically consistent.
- Curse does not kill player directly in Phase 8.
- Ring panel displays curse in soul-aware language.

---

## 9. Ring Soul UI

### Requirement

Add a dedicated way to inspect ring soul information.

This can be part of item details or a separate panel.

Recommended scene:

```text
res://scenes/ui/RingSoulPanel.tscn
```

### Ring Soul Panel Sections

#### Identity

Before reveal:

```text
Soul Presence: Unknown
Something inside the ring listens.
```

After reveal:

```text
Varn, The Ashen Orator
Ember rhetoric and binding flame
Trust: 0
```

#### Attunement

```text
Attunement Level 2
5 / 9 points to Level 3
```

#### Known Powers

Show revealed beneficial properties.

#### Known Curses

Show revealed curses.

#### Memories

List revealed memory titles.

#### Bargains

Show accepted/rejected bargain history.

Example:

```text
Bargains
Breath for Flame — Accepted
```

### UI Access

Player can access this through:

- Item detail panel when selecting a soul-bound ring.
- Optional `Inspect Soul` button.

### Acceptance Criteria

- Selecting Ashen Ring shows soul-related section once relevant.
- Unrevealed soul data remains hidden.
- Attunement, memories, curses, and bargains are visible when revealed.
- UI uses existing fantasy panel style from UI cleanup phase.

---

## 10. Ring Whisper Toast / Presentation

### Requirement

Ring whispers should feel special but not intrusive.

Add optional whisper toast scene:

```text
res://scenes/ui/RingWhisperToast.tscn
```

### Presentation

A whisper toast should:

- Appear briefly near message log or lower screen.
- Use soul/ring styling.
- Fade in/out using Tween or AnimationPlayer.
- Not block gameplay.
- Also log the message in the message log.

Example:

```text
Varn whispers:
"Fire clarifies all arguments."
```

### Message Type

Add or reuse message type:

```text
ring_whisper
```

### Acceptance Criteria

- Ring whispers are visually distinct.
- Whispers still appear in message log.
- Toast does not interrupt player actions.
- Whisper spam is prevented.

---

## 11. Event Hooks

### Requirement

Ring souls need hooks into existing gameplay events.

### Required Hooks

Add ring soul processing after these events:

#### On Equip Item

- If soul-bound ring equipped, maybe reveal presence.
- Trigger on_equip whisper.

#### On Use Skill

- Process Blood Price curse.
- Trigger on_skill_use whisper if eligible.
- Process skill-related attunement.

#### On Enemy Defeated

- Trigger on_enemy_defeated whisper.
- Process combat victory attunement.

#### On Attunement Level Up

- Reveal soul stage/memories/properties.
- Trigger attunement whisper.
- Check bargain trigger.

#### On Curse Revealed

- Trigger curse whisper.

### Godot Signal Suggestion

If event routing is getting messy, introduce signals from `GameState` or `MessageBus`:

```gdscript
signal item_equipped(item_instance_id)
signal skill_used(skill_id)
signal enemy_defeated(enemy_id)
signal item_attunement_leveled(item_instance_id, level)
signal curse_revealed(item_instance_id, curse_id)
signal bargain_offered(item_instance_id, bargain_id)
```

Do not over-engineer. Use signals if they clarify; direct system calls are fine if the codebase is still small.

### Acceptance Criteria

- Ring soul processing happens automatically from existing game actions.
- UI does not manually decide ring soul outcomes.
- Whispers/reveals/bargains do not duplicate.
- Combat and item systems still work without a soul-bound ring equipped.

---

## 12. Message Types

### Requirement

Expand message types if needed.

Recommended message types:

```text
info
success
warning
combat
loot
discovery
curse
quest
ring_whisper
bargain
memory
```

### Message Styling

- `ring_whisper`: muted purple/ember accent
- `bargain`: gold/purple accent
- `memory`: blue/gray ghostly accent
- `curse`: purple/red accent

### Acceptance Criteria

- Ring messages are distinguishable.
- Bargain choices create clear messages.
- Memory reveals are not lost among combat spam.
- Message log remains capped/readable.

---

## 13. Class Interactions

### Requirement

Ashen Ring should interact best with Ember Sage but remain usable by other classes.

### Expected Class Feel

#### Ember Sage

- Strong synergy with Ember Bolt.
- Blood Price is risky because skill use is frequent.
- Breath for Flame bargain is tempting.

#### Roadwarden

- Can use the ring but gains less value.
- Blood Price punishes occasional skill use.
- Varn may insult blunt martial habits.

#### Gravebound Scout

- Can offset Blood Price somewhat with Grave Touch.
- Varn may be uneasy around grave magic.

### Optional Class-Specific Whispers

Add only if simple.

Roadwarden:

```text
Armor, oaths, posture. Yes, yes. But have you considered fire?
```

Ember Sage:

```text
Ah, you have studied flame. Not well, perhaps, but enough to begin.
```

Gravebound Scout:

```text
Grave-magic. How damp. Still, useful in desperate rooms.
```

### Acceptance Criteria

- Ring is usable by all classes.
- Ember Sage has the clearest synergy.
- Ring does not make any class unable to complete current content.
- Optional class-specific whispers do not spam.

---

## 14. Content Placement

### Requirement

Ensure the player can acquire Ashen Ring during normal play.

### Suggested Placement Options

Choose one:

#### Option A — Elder Stone Reward

After completing The Elder Road quest chain, player receives Ashen Ring.

Pros:

- Dramatic reward.
- Phase 8 content starts after current zone completion.

Cons:

- Less time to use the ring in current zone.

#### Option B — Roadside Cache

Roadside Cache contains Ashen Ring and Identify Scroll.

Pros:

- Player can use ring during existing zone.
- Attunement can progress naturally.

Cons:

- Ring may appear early and complicate balance.

#### Option C — Weathered Shrine Event

Activating the shrine reveals or grants the Ashen Ring.

Pros:

- Thematic.
- Feels mysterious.

Cons:

- Requires shrine interaction to be clear.

### Recommended

Use **Option C — Weathered Shrine Event**.

When player activates Weathered Shrine for the first time:

- Shrine restores health/mana as before.
- Player finds Ashen Ring.
- Player receives one Identify Scroll if they do not already have one.
- Message:

```text
At the shrine's base, ash gathers around a blackened ring.
```

### Acceptance Criteria

- Ashen Ring is obtainable in normal play.
- Player has a way to identify it.
- Acquisition message is flavorful.
- Existing shrine behavior still works.

---

## 15. Balance Requirements

### Requirement

Ring powers should be noticeable but not overpower the current game.

### Suggested Mechanical Values

#### Ember Memory

- +1 Spell Power

#### Hungry Spark

- Ember Bolt +3 damage at attunement level 2

#### Blood Price

- Lose 2 health on skill use
- Cannot reduce below 1 health

#### Breath for Flame Bargain

- Immediate -5 health, not below 1
- Ember Bolt +2 additional damage
- Trust +1

Total possible Ember Bolt bonus from ring:

```text
+5 damage after attunement/bargain
```

This is strong but acceptable because Blood Price creates cost.

### Acceptance Criteria

- Ring feels powerful.
- Ring has a real drawback.
- Blood Price does not make the game frustrating.
- Ember Sage benefits but does not trivialize all combat.
- Roadwarden and Gravebound Scout can still use or ignore ring safely.

---

## 16. UI / UX Acceptance Checklist

Phase 8 UI is complete when:

1. Soul-bound ring item details show soul section when relevant.
2. Unrevealed soul data is hidden.
3. Varn’s name appears after reveal.
4. Attunement progress is visible.
5. Revealed memories are visible and selectable/readable.
6. Revealed curses are visible.
7. Bargain panel appears when triggered.
8. Accept/reject buttons are clear.
9. Ring whispers are distinguishable from normal messages.
10. Whisper toast, if implemented, is readable and non-blocking.
11. Message log handles ring_whisper, memory, bargain, and curse messages.
12. UI remains consistent with Phase 7 styling.

---

## 17. Testing / Verification Requirements

## Required Automated Tests If Test Setup Exists

Test pure logic where possible.

### Ring Soul State

- Soul state initializes for soul-bound ring.
- Non-soul item does not create soul state.
- Trust changes stay within -3 to +3.
- Seen whispers do not repeat when once-only.

### Soul Reveals

- Soul presence reveals without revealing name.
- Attunement level 1 reveals name.
- Attunement level 2 reveals motivation.
- Reveals happen once.

### Whispers

- on_equip whisper triggers once.
- on_skill_use whisper respects cooldown/seen rules.
- low/high trust filters work.
- no whisper fires when no soul-bound ring is equipped.

### Memories

- Attunement level 1 reveals Memory 1.
- Attunement level 2 reveals Memory 2.
- Bargain accept reveals Memory 3.
- Revealed memory does not duplicate.

### Bargain

- Bargain offered at attunement level 2.
- Bargain does not repeat after accepted/rejected.
- Accept applies health cost, trust gain, damage bonus.
- Reject applies trust loss and no damage bonus.

### Curse

- Blood Price reveals on trigger.
- Blood Price costs health on skill use.
- Blood Price does not reduce health below 1.
- Curse message appears on reveal.

### Combat Integration

- Ember Bolt damage includes revealed ring bonus.
- Hidden ring bonus does not apply.
- Bargain bonus applies after accepted.

## Required Manual Verification

Add to `UI_VERIFICATION.md` or create:

```text
RING_SOUL_VERIFICATION.md
```

Checklist:

- Acquire Ashen Ring from Weathered Shrine.
- Identify Ashen Ring.
- Equip Ashen Ring.
- Trigger Varn equip whisper.
- Use skill and trigger Blood Price.
- Gain attunement level 1 and reveal Varn name.
- Gain attunement level 2 and reveal motivation/memory.
- See Breath for Flame bargain.
- Accept bargain and verify effects.
- Repeat with reject path if reset is easy.

### Acceptance Criteria

- Existing gameplay tests still pass.
- Ring soul logic tests pass where available.
- Manual verification file exists or is updated.
- No ring feature breaks non-ring items.

---

## 18. Implementation Plan

### Step 1 — Add Ring Soul Data

- Create ring soul definitions.
- Add Varn, The Ashen Orator.
- Add whispers, memories, and bargain definitions.

### Step 2 — Link Ashen Ring to Soul

- Extend Ashen Ring item definition with `soul_id`.
- Ensure existing Ashen Ring item properties remain intact.

### Step 3 — Add Ring Soul State

- Track soul state per item instance.
- Initialize state when soul-bound ring is created or acquired.

### Step 4 — Add Soul Reveal Logic

- Implement reveal stages.
- Reveal presence on identify/equip/curse if appropriate.
- Reveal name at attunement level 1.
- Reveal motivation at attunement level 2.

### Step 5 — Add Whispers

- Implement whisper selection/filtering.
- Add anti-spam/once-only handling.
- Add message log integration.
- Add optional whisper toast.

### Step 6 — Add Memories

- Reveal memory fragments from attunement/bargain.
- Add memory list to ring UI.

### Step 7 — Add Bargain System

- Add bargain trigger after attunement level 2.
- Add RingBargainPanel.
- Implement accept/reject effects.

### Step 8 — Integrate Curse Personality

- Connect Blood Price to Varn.
- Update curse messages.
- Ensure curse cannot directly kill player.

### Step 9 — Add Ring Soul UI

- Extend item details or add RingSoulPanel.
- Show identity, attunement, memories, curses, bargains.
- Hide unrevealed data.

### Step 10 — Add Shrine Acquisition Event

- Add Ashen Ring reward to Weathered Shrine activation.
- Grant Identify Scroll if needed.
- Add acquisition message.

### Step 11 — Combat Hook Integration

- Process ring soul events after equip, skill use, enemy defeat, attunement level-up, and curse reveal.
- Apply revealed/bargain bonuses.

### Step 12 — Testing and Verification

- Add logic tests if possible.
- Update manual verification checklist.
- Play through as Ember Sage.
- Smoke test Roadwarden and Gravebound Scout.

---

## 19. Suggested Commit Plan

```text
1. feat: add ring soul definitions and Varn data
2. feat: link Ashen Ring to ring soul state
3. feat: implement soul reveal stages
4. feat: add ring whisper selection and message integration
5. feat: add ring memory fragments and reveal logic
6. feat: add Breath for Flame bargain flow
7. feat: integrate Blood Price curse with Varn personality
8. feat: add RingSoulPanel and ring whisper presentation
9. feat: add Ashen Ring shrine acquisition event
10. feat: integrate ring soul hooks with combat and attunement
11. test: cover ring soul reveals whispers memories bargains and curses
12. docs: add ring soul manual verification checklist
```

---

## 20. Acceptance Criteria for Entire Phase

Phase 8 is complete when:

1. Ashen Ring is obtainable during normal play.
2. Ashen Ring is linked to Varn, The Ashen Orator.
3. Ring soul state is tracked per item instance.
4. Soul presence can be revealed without revealing full identity.
5. Varn’s name reveals through attunement.
6. Varn’s motivation reveals through deeper attunement.
7. Varn can whisper through the message system.
8. Whispers are contextual and do not spam.
9. At least three Varn memory fragments exist.
10. Memories reveal through attunement or bargain.
11. Ring UI displays revealed soul information.
12. Blood Price curse is soul-aware and cannot directly kill the player.
13. Breath for Flame bargain appears once.
14. Player can accept or reject the bargain.
15. Accept/reject consequences apply correctly.
16. Ring powers/curses affect combat only when revealed or triggered according to rules.
17. Existing item discovery, attunement, combat, class, and UI systems still work.
18. Manual verification checklist exists or is updated.

---

## 21. Future Phase Hooks

After Phase 8, good next phases include:

### Candidate A — Additional Ring Souls

- Add 2–3 more named ring souls.
- Give each unique discipline, powers, curses, and bargains.
- Add soul personality variety.

### Candidate B — Item Synergies and Merging

- Soul-bound rings react to specific weapons/armor.
- Some item combinations reveal hidden properties.
- Some synergies create curses.

### Candidate C — Multi-Zone Expansion

- Add a new zone where ring whispers provide clues.
- Add ring-specific environmental reactions.

### Candidate D — Deeper Bargain Consequences

- Multiple bargain chains.
- Trust-gated offers.
- Long-term ring behavior changes.

Do not implement these during Phase 8. This phase proves the first ring soul well.

---

## 22. Definition of Done

Phase 8 is done when Ashen Ring no longer feels like an item.

It should feel like a problem the player decided to wear.

The player should find it, wonder about it, identify it, equip it, hear it, benefit from it, suffer from it, and eventually realize there is someone inside who very much has opinions.

That is the target.

Not just loot.

A relationship with bad boundaries.
