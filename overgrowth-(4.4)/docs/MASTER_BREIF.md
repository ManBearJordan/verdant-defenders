Overgrowth — Master Design Brief
1) High-level overview

Genre/engine/targets: Roguelike deckbuilder in Godot 4.x for desktop. Core loop: build deck → pick rooms from a “room deck” → resolve (combat/shops/events/trials/treasure) → defeat mini-bosses → defeat layer boss → meta-progression.

Top-level modules: Data layer; Move/Ability system; Combat system; Room-Deck & Dungeon flow; Sigils & rewards; Events/Trials; Shop; UI/UX; Audio/VFX; Save/Load; Analytics; CI/testing.

2) Core combat rules

Turn structure: State machine PLAYER_TURN → ENEMY_TURN → END_TURN_CHECK → NEXT_ROOM. Player controller handles energy refill, hand draw, card play, block reset. Enemy controller iterates all enemies to execute one move each. UI shows HP, charge, block, energy.

Deck/hand/energy baseline: 30-card deck; draw 5 at turn start; 3 energy/turn (unused energy doesn’t carry). Discard reshuffles into draw when empty.

Card types & roles:

Strikes (damage), Tactics (block/utility/status/traps), Rituals (persistent or end-of-turn effects), Filler (0-cost thinners). Some cards grant Runes (Growth/Decay/Elemental).

Statuses (examples/names): Poison (DoT, stacks); Elemental: Burn/Chill/Shock; renamed debuffs: Sap (weakness) and Fragile (vulnerable).

Growth seeds (archetype token): Stackable “Seeds” persist for the combat; other cards check thresholds (≥2/≥3/≥4) to unlock bonuses (extra draw, AoE, damage). Seeds aren’t spent.

3) Enemies, intents, scaling

Enemy turn: Each enemy resolves its current intent once per enemy phase; patterns vary over depth.

Depth scaling & pacing: HP/intent strength scale with depth; pattern length grows every 5 floors; fights should average ~2–3 turns (adjust HP ±10–20% to tune pacing).

Balance baseline: Starter output ≈ 12–18 dmg/turn; most foes hit 4–8; dual-enemy rooms can spike 10–15 unblocked if you neglect block.

Mini-bosses

Where/when: 2–3 per act as special nodes in the room deck.

Mechanics: Visible Charge meter (+1/turn). At threshold (≈4), next move is an empowered signature; many fights flip behavior/mini-deck at ~50% HP (two-phase).

4) Dungeon & “room deck” exploration

Layers & length: 4 themed layers (Growth, Decay, Elemental, Final); each has 15 rooms; room 15 is always the boss.

Room deck flow: Before each room, reveal 3 face-up room cards from a shuffled deck; pick one to resolve; discard it; refill to 3 (reshuffle when empty). Keeps planning tension and run variety.

Room type mix & frequencies: Shops (~3/layer, not first room); Events (~2/layer); Treasure (~2/layer, not adjacent to events); Elites 1 optional in rooms 7–11 (20% chance); remaining are Combat.

5) Cards & pools (example: Growth)

Pool structure: Each archetype aims for ~45 cards (15 Strikes/15 Tactics/15 Rituals) with a shared 0-cost filler set and a 30-card starter recipe (10/10/5 plus 5 filler).

Growth pool samples: strikes like Thorn Lash, Blossom Strike, Vine Whip, etc., and tactics like Seed Shield, Vine Trap, Sprout Heal; rituals like Growth Aura, Seed Surge. (Full tabulation is in the pool PDF.)

6) Sigils (relics)

What & when: Passive bonuses acquired in shops or after boss fights; each layer adds one. Examples include energy, block, or seed-granting effects.

Data: sigils.json with tier/rarity/effect text; selection UIs after mini-boss/boss/trial. Effects parsed/executed by an effect runner.

7) Data layer & loaders

Schemas (stored in res://data/): enemy_moves.json, mini_bosses.json, layer_bosses.json, sigils.json, room_deck.json, shop_data.json, event_data.json, treasure_data.json.

Loader: DataLoader.gd singleton reads & validates JSON into typed dictionaries; on error, logs the exact field path.

8) Bosses

Per layer: Growth (Thorn King), Decay (Blight Colossus), Elemental (Storm Wyrm), Final (Verdant Overlord), plus Run-End boss (World Tree). Multi-phase at HP thresholds.

9) UI/UX scaffolding

Core scenes: HUD.tscn (hand/deck/discard/energy/HP/block), RoomChoice.tscn (3 room cards face-up), SigilChoice.tscn, EventDialog.tscn, ShopDialog.tscn, TrialDialog.tscn.

Flow at runtime: Run start → choose seed, init DungeonController → room selection (draw 3, pick 1) → resolve → reward UIs → boss nodes → end-run summary.

10) Ops: Save/Load, analytics, CI

Save format: JSON per run (deck, sigils, room_index, seed, gold); also preferences.

Analytics hooks: emit signals on room choice, sigil pick, combat result, boss defeat, run end; optional external analytics or local CSV.

Automation: headless tests; scene load tests; GH Actions steps for headless Godot test on push.

11) Balancing targets

Win-rate & efficiency: Aim ~30–40% win rate; 3 energy baseline; ~6 “impact per energy” guideline; HP/damage scale by layer.

Sanity checks: DPS/TTK, damage vs. block, depth scaling formula, playtest metrics (avg turns to kill / damage taken).

12) Art inventory (current assets)

A comprehensive list of ~247 PNGs exists (cards, icons, sigils, units, UI). Representative entries include card_back.png, button_end_turn.9.png, lots of art_*.png for card illustrations, and sigil_*.png for relics. (See the inventory file for the full list.)

What this means for implementation (Cline-ready checklist)

Data contracts: Use the JSON schemas above; load via DataLoader.gd (fail early with field-path).

Combat loop: Implement the TurnManager state machine, with player energy/draw and per-enemy single move execution each enemy phase.

Room deck: Build DungeonController that maintains a shuffled room deck and presents 3 choices each room.

Sigils: Hook reward UI after mini-boss/boss/trial; parse effect text to runtime triggers.

Enemies/intents: Depth scaling, patterns, and (for elites) Charge → signature + possible 2-phase flips.

Tests/CI: Keep GUT headless tests and scene-load checks; wire GH Actions per doc.

Open decisions / clarifications to lock with you

Final names/values for renamed statuses (“Sap”, “Fragile”) and whether they replace or coexist with classic Weak/Vulnerable terms in UI.

Exact counts for shop/event/treasure frequencies per layer in the first public build vs. later tuning.

Growth/Decay/Elemental seed/rune interactions beyond what’s listed (some cards reference runes; confirm global effects)

you may create new files as needed for the game to work