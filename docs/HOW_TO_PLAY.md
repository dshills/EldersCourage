# How To Play EldersCourage

This guide covers the current Godot prototype loop launched from:

```text
game/scenes/phase3/ElderRoadOutskirts.tscn
```

The current playable path starts in Elder Road Outskirts, then expands into Ashwood Glen after you secure the road.

## Starting The Game

Run the project with Godot:

```bash
godot --path game
```

On macOS, if `godot` is not on your `PATH`:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game
```

When the scene opens, choose one of three classes:

- Roadwarden: durable melee character with high health and defense.
- Ember Sage: fragile caster with strong fire damage and high mana.
- Gravebound Scout: flexible skirmisher with precision damage and self-healing.

Example: choose Ember Sage if you want to use `Ember Bolt` to burn enemies quickly, then use `Kindle` when mana gets low.

## Core Controls

- WASD or arrow keys: move one tile.
- Click an adjacent map tile: move to that tile.
- `E`: interact with the current tile.
- `Space`: attack the active enemy.
- `1` and `2`: use your class skills.
- `I`: open or close inventory.
- `Q`: open or close the quest/log panel.
- `Y` or `T`: open or close talents.
- `F3`: toggle debug location details.
- `Escape`: close panels or cancel identify target mode.

The bottom action dock also has buttons for common actions:

- Primary action: travel, inspect hazards/cairns, open containers, or interact with the tile.
- Activate Shrine: use the shrine on the current tile.
- Attack: start or continue combat.
- Inventory, Talents, Quests: open their panels.

## Choosing A Class

### Roadwarden

Roadwarden starts with:

- Old Sword
- Roadwarden Vest
- Minor Health Potion
- Guarded Strike
- Shield Bash

Example combat pattern:

1. Use `Guarded Strike` to deal damage and gain temporary defense.
2. Use `Shield Bash` when an enemy hits hard, because it weakens the next enemy strike.
3. Use basic attacks when mana is low.

Roadwarden is the easiest class for surviving hazards because defense matters.

### Ember Sage

Ember Sage starts with:

- Ember Staff
- Cracked Ember Charm
- Minor Health Potion
- Ember Bolt
- Kindle

Example combat pattern:

1. Use `Ember Bolt` against tough enemies because it ignores defense.
2. Use `Kindle` when mana runs low.
3. Avoid taking repeated enemy hits; your health is lower than the other classes.

Ember Sage is also the best class for seeing Ashen Ring and fire-resonance interactions early.

### Gravebound Scout

Gravebound Scout starts with:

- Scout Knife
- Traveler's Cloak
- Minor Health Potion
- Piercing Shot
- Grave Touch

Example combat pattern:

1. Use `Piercing Shot` for steady damage.
2. Use `Grave Touch` when hurt, because it damages the enemy and restores health.
3. Manage cooldowns carefully; both skills are stronger than basic attacks but are not always ready.

## First Goal: Secure Elder Road Outskirts

Your first quest chain is `The Elder Road`. The main objectives are to recover supplies, clear threats, and reach the Elder Stone.

Recommended route:

1. Start at Road Camp.
2. Move east to Old Road.
3. Move east to Abandoned Chest.
4. Use the Primary action or press `E` to open the chest.
5. Equip useful gear from the inventory.
6. Fight the Scout Ambush, Starved Wolf, and Road Bandit.
7. Reach the Elder Stone in the southeast corner.

Example: after opening the Abandoned Chest, press `I`, select `Old Sword`, then press `Equip`. If you started as Roadwarden, you may already have one, but other classes can still inspect or carry it.

## Movement And Tiles

The map is tile-based. Your current tile is highlighted. You can move only north, south, east, or west.

Examples:

- If you are on Road Camp at the top-left, pressing `D` moves east to Old Road.
- If you click a diagonal tile, the game tells you that you can only move to adjacent tiles.
- If you step onto a tile with an enemy encounter, combat starts automatically.

## Combat

Combat uses your basic attack, class skills, equipment, talents, and item bonuses.

Basic flow:

1. Move onto an enemy tile or press Attack on an enemy tile.
2. Use `Space` for a basic attack, or press `1`/`2` for skills.
3. The enemy retaliates if it survives.
4. Defeating enemies grants XP, loot, and quest progress.

Example: Ember Sage versus Road Bandit:

1. Move to Bandit Watch.
2. Press `1` to use `Ember Bolt`.
3. If mana drops too low, press `2` to use `Kindle`.
4. Finish with another `Ember Bolt` or basic attacks.

Example: Gravebound Scout while wounded:

1. Start combat with `Piercing Shot`.
2. If health drops, use `Grave Touch`.
3. The damage and healing happen together, letting you recover while progressing the fight.

## Inventory, Equipment, And Consumables

Open inventory with `I`.

Common inventory actions:

- Select an item to inspect it.
- Press `Equip` for weapons, armor, and trinkets.
- Press `Use` for consumables.
- Press `Use` on an Identify Scroll to enter identify target mode.

Example: using a potion:

1. Take damage in combat.
2. Press `I`.
3. Select `Minor Health Potion`.
4. Press `Use`.
5. Health is restored and the potion stack decreases.

Example: using Ash Salve in Ashwood Glen:

1. Trigger Burning Thorn and take damage.
2. Open inventory.
3. Select `Ash Salve`.
4. Press `Use`.
5. It restores 20 health.

## Item Discovery And Identify Scrolls

Some items are unidentified or have hidden properties. Identify Scrolls reveal those properties.

Example:

1. Find or receive an Identify Scroll.
2. Open inventory.
3. Select the Identify Scroll.
4. Press `Use`.
5. Click a highlighted unidentified item.
6. The scroll is consumed and the item reveals new information.

If the selected item has nothing hidden, the scroll refuses and asks you to choose a different target.

## Attunement

Some equipment grows through use. This is called attunement.

Examples:

- Weapon attunement can progress after attacking and winning fights.
- Trinket attunement can progress when using skills.
- Ashen Ring, Ashwood Charm, and Staff of the Ashen Orator can reveal more as attunement rises.

Example: Ashwood Charm:

1. Find Ashwood Charm in Ashwood Glen.
2. Equip it as your trinket.
3. Keep using skills and winning fights.
4. At attunement level 1, its Thornward property can help reduce Burning Thorn damage.
5. At attunement level 2, it can reveal another resource bonus.

## Ring Souls And Varn

Ashen Ring can contain a soul named Varn. Varn is revealed through identify, equip, curse, and attunement events.

Example path:

1. Activate Weathered Shrine on Elder Road.
2. Receive Ashen Ring and, if needed, an Identify Scroll.
3. Identify Ashen Ring.
4. Equip Ashen Ring.
5. Use skills and fight enemies to reveal more of Varn over time.

Varn can whisper during specific events. In Ashwood Glen, Varn may comment when entering the zone, interacting with Cinder Pool, or fighting fire-themed enemies.

## Item Resonance

Resonance happens when specific items interact. Some resonances are helpful, some are dangerous, and some are hidden until triggered.

Example: Coal Remembers Flame

1. Play as Ember Sage.
2. Equip Ember Staff.
3. Acquire and equip Ashen Ring.
4. Use `Ember Bolt`.
5. The resonance can reveal and improve fire-related effects.

Example: Breath Debt

1. Carry Elder Glass Charm.
2. Equip Ashen Ring.
3. Trigger Ashen Ring's Blood Price through skill use.
4. A cursed resonance can reveal.
5. Skill use may cost extra health, but the cost is nonlethal.

In item details, known resonances appear under the `Resonance` section. Hidden cursed resonances are not shown before discovery.

## Item Merging

Phase 9 adds a special merge into Staff of the Ashen Orator.

Example merge path:

1. Play as Ember Sage.
2. Equip Ember Staff and Ashen Ring.
3. Discover `Coal Remembers Flame`.
4. Reveal Varn's name on Ashen Ring.
5. Raise Ashen Ring attunement enough for the recipe.
6. Open inventory.
7. Select Ashen Ring or Ember Staff.
8. Press `Merge`.
9. Press `Prepare`.
10. Press `Confirm Merge`.

The merge consumes the source items, creates Staff of the Ashen Orator, transfers Varn's soul state, and equips the staff.

## Unlocking Ashwood Glen

Ashwood Glen is the second zone. It is locked until the Elder Road is secure.

To unlock it:

1. Complete the Elder Road quest stage `Break the Ambush`.
2. Reach the Elder Stone.
3. Use the Primary action, labeled `Enter Ashwood Glen`.

If the road is not secure, the Elder Stone blocks travel.

Example:

- If the Road Bandit is still alive, the Elder Stone remains cold.
- After the Road Bandit is defeated and the Elder Stone objective is complete, travel opens.

## Playing Ashwood Glen

Ashwood Glen is a 5x5 burned forest zone. It has stronger enemies, hazards, a new quest chain, a shrine, a cache, and a return path.

Important locations:

- Ashwood Entry: where you arrive.
- Cinder Cache: contains useful Ashwood loot.
- Smoke Shrine: restores health and mana once.
- Burning Thorn: hazard that triggers on entry.
- Cinder Pool: hazard that triggers when inspected.
- Broken Cairn: lore/objective interaction.
- Cinderheart: final objective encounter.
- Return Road: travel back to Elder Road Outskirts.

Example Ashwood route:

1. Enter Ashwood Glen from Elder Stone.
2. Move east along Ash Path.
3. Open Cinder Cache to look for Ash Salve and Ashwood Charm.
4. Visit Smoke Shrine if you need recovery.
5. Fight Ember Wisp and Ash Wolf.
6. Interact with Cinder Pool when ready.
7. Investigate Broken Cairn.
8. Defeat Cinder Acolyte.
9. Reach Cinderheart and defeat Cinderheart Guardian.
10. Use Return Road to go back to Elder Road.

## Hazards

Hazards are not enemies. They are environmental dangers.

### Burning Thorn

Burning Thorn triggers the first time you step onto its tile.

Example:

1. Move onto Burning Thorn.
2. It deals 6 damage by default.
3. If your defense is 4 or higher, damage can drop to 3.
4. If `Coal Remembers Flame` is active and discovered, damage can drop further.
5. If Ashwood Charm's Thornward property is revealed, it can reduce damage further.

Burning Thorn cannot reduce health below 1.

### Cinder Pool

Cinder Pool triggers when you interact with it.

Example:

1. Move onto Cinder Pool.
2. Press `E` or use the Primary action.
3. Ember Sage loses mana if mana is available.
4. Other classes generally lose health.
5. Varn may whisper if his soul is revealed and equipped.

Cinder Pool cannot reduce health below 1.

## Leveling And Talents

Defeating enemies and completing quests grant XP. When you level up, you gain stats and talent points.

Example:

1. Defeat the Scout Ambush and Road Bandit.
2. Gain enough XP to level up.
3. Press `Y` or `T` to open talents.
4. Spend an available point on a class talent.

Talent buttons show whether they are available and what level they require.

## Practical Tips

- Open containers before fighting too much. Early gear and potions matter.
- Use shrines after taking damage, not at full health.
- If a skill button says it needs mana, use basic attacks or a recovery skill like `Kindle`.
- Identify suspicious trinkets and rings; many of the strongest effects are hidden.
- Watch the message log. It tells you when quests progress, items reveal properties, resonances trigger, and hazards apply.
- Return to Elder Road from Ashwood Glen if you need to regroup or inspect earlier tiles.

## Example Full Run

One practical Ember Sage run:

1. Choose Ember Sage.
2. Open the Abandoned Chest.
3. Fight the Scout Ambush with `Ember Bolt`.
4. Use `Kindle` when mana is low.
5. Activate Weathered Shrine to receive Ashen Ring and an Identify Scroll.
6. Identify Ashen Ring.
7. Equip Ashen Ring.
8. Use `Ember Bolt` to reveal fire-related ring behavior.
9. Defeat Starved Wolf and Road Bandit.
10. Reach Elder Stone and enter Ashwood Glen.
11. Open Cinder Cache and equip Ashwood Charm if found.
12. Use Smoke Shrine after taking damage.
13. Clear Burning Thorn and Cinder Pool.
14. Defeat Ember Wisp, Ash Wolf, and Cinder Acolyte.
15. Defeat Cinderheart Guardian.
16. Claim Cinderheart Remnant and return to Elder Road.

This route exercises movement, combat, skills, inventory, identifying, ring souls, resonance, hazards, zone travel, and quest progression.
