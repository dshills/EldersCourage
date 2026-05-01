# Phase 8 Ring Soul Manual Verification

Use the Phase 3 Elder Road scene and start as Ember Sage for the primary pass.

## Primary Path

- [ ] Start a new run as Ember Sage.
- [ ] Move to the Weathered Shrine.
- [ ] Activate the Weathered Shrine.
- [ ] Verify health and mana restore still occurs.
- [ ] Verify Ashen Ring is granted.
- [ ] Verify an Identify Scroll is granted if the player did not already have one.
- [ ] Verify the shrine message appears: `At the shrine's base, ash gathers around a blackened ring.`
- [ ] Open inventory and inspect Ashen Ring.
- [ ] Verify hidden soul data is not fully exposed before reveal.
- [ ] Use Identify Scroll on Ashen Ring.
- [ ] Verify soul presence is revealed without Varn's name.
- [ ] Equip Ashen Ring.
- [ ] Verify Varn's equip whisper appears once.
- [ ] Use Ember Bolt while the ring is equipped.
- [ ] Verify Blood Price reveals and costs health.
- [ ] Verify Blood Price cannot reduce health below 1.
- [ ] Defeat an enemy with the ring equipped.
- [ ] Verify an enemy-defeat whisper can appear.
- [ ] Reach attunement level 1.
- [ ] Verify Varn's name and Hall of Cinders memory reveal.
- [ ] Reach attunement level 2.
- [ ] Verify Varn's motivation and Failed Binding memory reveal.
- [ ] Verify Breath for Flame bargain panel appears.
- [ ] Accept Breath for Flame.
- [ ] Verify health cost is applied and cannot reduce health below 1.
- [ ] Verify trust increases by 1.
- [ ] Verify Last Breath memory reveals.
- [ ] Verify Ember Bolt gains the bargain damage bonus.

## Reject Path

- [ ] Restart or reset before accepting Breath for Flame.
- [ ] Reach the bargain again.
- [ ] Reject Breath for Flame.
- [ ] Verify trust decreases by 1.
- [ ] Verify no bargain damage bonus is applied.
- [ ] Verify rejection message and whisper appear.
- [ ] Verify the bargain does not appear again for the same ring instance.

## Class Smoke Checks

- [ ] Start as Roadwarden.
- [ ] Acquire and equip Ashen Ring.
- [ ] Use skills and verify Blood Price remains nonlethal.
- [ ] Confirm Roadwarden can ignore or use the ring without blocking progress.
- [ ] Start as Gravebound Scout.
- [ ] Acquire and equip Ashen Ring.
- [ ] Use skills and verify Blood Price remains nonlethal.
- [ ] Confirm Gravebound Scout can ignore or use the ring without blocking progress.

## UI Checks

- [ ] Ring soul section appears only on soul-bound ring details.
- [ ] Unrevealed soul name, motivation, memories, and bargain results stay hidden.
- [ ] Revealed memories remain readable in item details.
- [ ] Bargain panel has clear accept and reject buttons.
- [ ] Ring whisper, memory, bargain, and curse messages are visually distinguishable.
- [ ] Existing Phase 7 layout remains readable with the added ring text and bargain panel.
