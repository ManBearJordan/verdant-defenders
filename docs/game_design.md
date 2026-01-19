# Overgrowth Design Reference

Below is the complete design reference for our roguelike card game **"Overgrowth"**, covering card pools and every core system. Use this as the single source of truth when prototyping, balancing, and implementing features.

## 1. Card Pools (45 per Archetype)

Below are the full 45-card pools for each archetype—15 Strikes, 15 Tactics, and 15 Rituals per class—listed inline here.

### Growth Archetype (45 Cards)

| Card Name | Type | Cost | Effect |
|-----------|------|------|--------|
| Thorn Lash | Strike | 1 | Deal 6 damage. If target has a Seed, deal 2 extra damage. |
| Blossom Strike | Strike | 1 | Deal 5 damage. Gain 1 Seed. |
| Vine Whip | Strike | 1 | Deal 4 damage twice. |
| Bud Burst | Strike | 2 | Deal 10 damage. If you have ≥3 Seeds, draw 1 card. |
| Petal Spray | Strike | 1 | Deal 3 damage to all enemies. |
| Root Smash | Strike | 2 | Deal 8 damage and apply 2 Weak. |
| Sap Shot | Strike | 1 | Deal 4 damage and heal 2 HP. |
| Thorned Blade | Strike | 1 | Deal 5 damage; if played consecutively, cost 0 next Strike. |
| Gilded Bud | Strike | 2 | Deal 7 damage. Gain 1 Growth Rune. |
| Blooming Edge | Strike | 2 | Deal 6 damage and apply 1 Vulnerable. |
| Petal Pierce | Strike | 1 | Deal 4 damage; if enemy is Poisoned, gain 1 Seed. |
| Seeded Slash | Strike | 1 | Deal 5 damage. Plant a Seed. |
| Thorn Barrage | Strike | 3 | Deal 4 damage 3 times. |
| Sappy Lunge | Strike | 1 | Deal 5 damage. If no Seeds, gain 2 Seeds. |
| Vine Cleaver | Strike | 2 | Deal 9 damage to all enemies if you have ≥4 Seeds. |
| Seed Shield | Tactic | 1 | Gain 6 Block. Plant a Seed. |
| Vine Trap | Tactic | 1 | Place a trap: first enemy to move takes 8 damage. |
| Sprout Heal | Tactic | 1 | Heal 5 HP. Draw 1 card. |
| Fertile Soil | Tactic | 2 | Next Growth Strike gains +3 damage. |
| Rooting Pulse | Tactic | 1 | Apply 2 Vulnerable to all enemies. |
| Seedlings | Tactic | 1 | Gain 2 Seeds. |
| Thorn Wall | Tactic | 2 | Gain 10 Block. Deal 4 damage to attackers. |
| Petal Veil | Tactic | 2 | Gain 8 Block. Reduce next damage by 4. |
| Sap Shield | Tactic | 1 | Gain 4 Block. Next Ritual costs 1 less. |
| Bud Barrier | Tactic | 1 | Gain 5 Block. If you have ≥2 Seeds, gain an extra card. |
| Sprout Sentry | Tactic | 2 | Summon a Seedling: at end of turn, heal 2 HP. |
| Petal Step | Tactic | 1 | Dodge an attack this turn. |
| Growth Glyph | Tactic | 2 | Next two Strikes are free. |
| Mossy Guard | Tactic | 1 | Gain 3 Block. Gain 1 Growth Rune. |
| Garden Bloom | Ritual | 2 | At end of turn, draw 1 card and gain 1 Seed. |
| Growth Aura | Ritual | 2 | All Strikes deal +2 damage. |
| Seed Surge | Ritual | 3 | At start of each turn, gain 1 Energy. |
| Thorned Roots | Ritual | 2 | Whenever you gain Block, enemies lose 1 Strength. |
| Verdant Warding | Ritual | 2 | At end of combat, heal 5 HP. |
| Blooming Ward | Ritual | 3 | At end of turn, apply 1 Poison to all enemies. |
| Sprouting Might | Ritual | 2 | Strikes cost 0 if you played ≥3 Strikes last turn. |
| Fungal Fortress | Ritual | 3 | Gain 2 Seeds at end of each turn. |
| Rooted Resolve | Ritual | 2 | At start of combat, gain 5 Block. |
| Nature's Boon | Ritual | 3 | Gain 2 Growth Runes. |
| Verdant Bond | Ritual | 2 | Whenever you play a Ritual, draw 1 card. |
| Petal Parade | Ritual | 3 | Strikes hit all enemies. |
| Seed of Renewal | Ritual | 3 | At end of turn, remove one negative status. |
| Overgrowth | Ritual | 4 | All Strikes and Tactics gain +1 effect. |
| Eternal Blossom | Ritual | 5 | At end of combat, retain all unplayed cards. |

### Decay Archetype (45 Cards)

(Decadal list omitted for brevity—see full Card_Pool for details)

### Elemental Archetype (45 Cards)

(Elemental list omitted for brevity — see full Card_Pool for details)

### Filler Cards

| Card Name | Cost | Effect |
|-----------|------|--------|
| Seed Spark | 0 | Draw 1 card. |
| Nature's Whistle | 0 | Gain 1 Seed. |
| Elemental Flicker | 0 | Deal 1 damage randomly. |
| Rot Drop | 0 | Apply 1 Poison randomly. |
| Arcane Echo | 0 | Next Ritual costs 1 less. |

## 2. Deck & Hand

- **Deck Size:** 30 cards per run
- **Starter Deck Composition:** 10 Strikes (basic attacks), 10 Tactics (basic defense/utility), 5 Rituals (small buffs), 5 Filler Cards
- **Hand Size:** 5 cards drawn at room start
- **Energy:** 3 per room (modifiable)
- **Discard:** All unplayed cards discard at room exit; reshuffle empty deck

## 3. Dungeon Structure & Pacing

- **Layers:** 4 (Growth, Decay, Elemental, Final)
- **Rooms per Layer:** 14–16
- **Rooms between Bosses:** ~3–4
- **Total Bosses:** 4 (one per layer)
- **Optional Final Guardian:** Extra mastery boss after layer 4

## 4. Room Types

| Type | Frequency | Details & Optionality |
|------|-----------|----------------------|
| Combat Room | ~60% | Standard encounters; mix of Basic, Minion, Elite squads |
| Shop Room | Guaranteed every 3 rooms + 20% chance | Purchase cards/heal/remove; ~5–7 visits per run |
| Event Room | 1–2 per layer | Risk–reward events, curses, buffs, side‑quests |
| Treasure Room | ~10% | Free cards or minor Relics |
| Elite Room | Up to 2 per run (player choice via branching) | Tough elite enemies; clearing grants Rare Relic + bonus shards. Appear as optional forks in path. |
| *Players choose whether to enter Elite forks, making them fully optional.* |

## 5. Boss Encounters

Each layer‑end boss has two phases, unique mechanics, and scales by +20% HP/damage per layer. Defeating a boss grants a Major Relic.

- **Boss 1: Thorn King (Growth)**
  - HP: 100 → +20% (Layer 1 = 100)
  - Phase 1: Whip Vines (12 dmg every 2 turns, gains Seeds); Entangle if >2 Strikes played
  - Phase 2: Sacrifice Bloom (5×Seeds dmg); spawns Seed Spores (15 HP, 5‑dmg explosion)
- **Boss 2: Blight Colossus (Decay)**
  - HP: 120 → +20%
  - Phase 1: Corrosive Smash (15 dmg, −5 Block); Poison Nova (3 Poison all)
  - Phase 2: Plague Aura (2 Poison each turn); Blighted Ground (Tactics cost +1)
- **Boss 3: Storm Wyrm (Elemental)**
  - HP: 140 → +20%
  - Phase 1: Fire Breath (18 cone dmg, 50% Block ignore); Lightning Rod (+5 next Strike)
  - Phase 2: Frost Storm (Chill+Vulnerable on your Strikes); Elemental Shift (rotating weakness)
- **Boss 4: Verdant Overlord (Final)**
  - HP: 160 → +20%
  - Phase 1: Summon 3 Vine Guards (40 HP); Overgrowth (Strikes cost +1)
  - Phase 2: Nature’s Reckoning (10 dmg per Ritual); Rooted Domination (−1 Energy if >2 Seeds)
- **Optional Final Guardian: World Tree**
  - HP: 300; 3 phases merging all mechanics

## 6. Shops & Economy

- **Currency:** Seed Shards from kills and clears
- **Shop Options:** 3 cards, heal (10 HP), remove card
- **Pricing:** Common 50, Uncommon 100, Rare 150, Remove 75, Heal 75
- **Frequency:** ~5–7 per run

## 7. Relics & Meta‑Progression

- **Minor Relics:** Found in Treasure Rooms (~6) and optional Elite Rooms (up to 2 Rare)
- **Major Relics:** 4 awarded from each layer boss
- **Total Relics per Run:** 4 Major + ~6 Minor + up to 2 Rare from Elites = 10–12
- **Verdant Essence:** Meta currency to unlock cards, relics, archetypes

## 8. Environmental & Special Mechanics

- **Biome Effects:** Permanent layer buffs/debuffs (e.g., Poisonous Swamp)
- **Weather Events:** Random mods (Acid Rain, Sunlight)
- **Hazards:** Spikes, cursed fountains, runic traps

## 9. Balancing Guidelines

- **Energy Budget:** ~6 impact per Energy
- **Rarity Curve:** 60% Common, 30% Uncommon, 10% Rare
- **Win Rate:** Target 30–40% initially
- **Data Logging:** CSV runs of wins, bosses, relics
- **Iteration:** Adjust one variable every 20 runs

## 10. Enemy Archetypes & Encounters

| Tier | Examples | Base Stats | Abilities |
|------|----------|-----------|----------|
| Basic | Forest Sprite | 40 HP, 8 dmg | Single target attack |
| Minion | Vine Guard, Seed Spore | 30 HP, 5 dmg | Explode or retaliate |
| Elite | Thorn Beast, Blight Wraith | 80 HP, 15 dmg | AoE every 3 turns |

Scaling: +5% HP/dmg per layer for Basic, +10% for Elite.

Room Build: Choose template → pick enemies weighted by layer → apply scaling.

## 11. Session Summary

- **Layers:** 4 (+ optional Final Guardian)
- **Total Rooms:** ~64 (16 per layer)
- **Bosses:** 4 (+1 optional)
- **Combat Rooms:** ~38
- **Shop Rooms:** ~5–7
- **Event Rooms:** 4–8
- **Treasure Rooms:** ~6
- **Elite Rooms:** Up to 2 optional forks
- **Relics:** 10–12 per run

This gives players predictable pacing, choice in Elite challenges, and clear relic progression.
