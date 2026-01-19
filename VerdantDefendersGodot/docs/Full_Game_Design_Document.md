# Overgrowth: Full Game Design Document

## Overview
Overgrowth is a roguelike deckbuilder built with the Godot Engine. Players explore four themed layers—Growth, Decay, Elemental, and Final Challenge—battling enemies, purchasing cards and Sigils, and facing a boss at the end of each layer.

### Key Systems:
- **Deck & Hand:** 30-card deck; 5 cards drawn per room; 3 energy per turn.
- **Rooms:** Combat, Shop, Event, or Treasure.
- **Dungeon:** 4 layers × 15 rooms each, including a boss room at the end.
- **Cards:** Three archetypes (Growth, Decay, Elemental), each with 45 unique cards; plus 5 zero-cost filler cards shared.
- **Sigils:** Passive bonuses gained in shops or after boss fights.

## Archetypes & Card Pools
Each archetype has:
- 45 unique cards: 15 Strikes, 15 Tactics, 15 Rituals
- Starter deck composition: 10 Strikes, 10 Tactics, 5 Rituals, 5 filler cards
- Detailed card lists will be developed separately.

## Dungeon Structure
The dungeon comprises four sequential layers (Growth, Decay, Elemental, Final + Bonus World Tree Layer for End Run Boss Only), each with 15 rooms. Room order is generated at the start of a run using a weighted random selection to ensure pacing and variety.

### Room Sequence Generation
Ditch the static branching map—instead use a “Room Deck” mechanic. Before each room, reveal three room cards drawn from a shuffled deck of encounters. Choose one to resolve; then shuffle used cards into the discard.

**Room Card Types:**
- Combat (70% of deck)
- Mini-Boss (2–3 per Act)
- Event (Flavor choices, small boons/banes)
- Shop (Buy cards, Sigils, remove cards)
- Rest (Heal or upgrade)
- Treasure (Bonus gold or small Sigil–style loot)
- Trial (Optional challenge—e.g. “Only Skills” or “Win in 8 turns”; success grants an extra small Sigil slot, failure refunds nothing)

**Flow:**
- Draw 3 cards from Room Deck
- Pick one to enter (face-up choices keep planning tension)
- Resolve, then discard that Room Card
- Refill to 3 before next decision (reshuffle when deck is empty)

This creates a dynamic, roguelike feel—every run the sequence of Combat/Shop/Trial/Mini-Boss is shuffled differently, and the player always has to weigh short-term risk (Trials) vs long-term gains (Sigils).

**Layer Boss Room Placement:** Room 15 of each layer is always the boss.
**Shop Frequency:** Shops appear 1 time every 4–5 rooms (exact count per layer = 3 shops), spaced randomly but not in the first room.
**Event Rooms:** 2 per layer, appearing after every 3–6 rooms on average.
**Treasure Rooms:** 2 per layer, independent placement, but not adjacent to events.
**Combat Rooms:** Fill remaining slots (typically 7–8 per layer).
**Elite Rooms:** 1 optional elite in rooms 7–11, indicated by a special icon. Elite chance = 20% per non-shop, non-event, non-boss room.

### Room Type Mechanics
**Combat:**
- Enemy Tier scales by layer (e.g., HP and damage +20% each layer).
- Room size: 1–3 enemies. Standard combat transitions to next room once all enemies die.

**Shop:**
- 3 randomized card offerings (common/uncommon/rare tiers).
- Options: Remove card (cost 75 gold), Heal 20% max HP (cost 75 gold).
- Purchasing consumes gold; remaining gold carries between layers.

**Event:**
- Narrative encounter with 2–3 choices loaded from event_data.json.
- Choices can grant rewards or impose penalties.

**Treasure:**
- Guaranteed reward: either 50–100 gold, a random Sigil, or a rare card.

**Elite:**
- Stronger foes and mini-boss mechanics.
- Higher chance to drop sigil or extra gold.

### Transition & Replayability
After clearing a room, players see the next room type indicator but not details until entry.
Room pool is regenerated when entering a new layer, preserving unpredictability.

## Bosses
One boss per layer with unique multi-phase mechanics:
• Growth: Thorn King
• Decay: Blight Colossus
• Elemental: Storm Wyrm
• Final: Verdant Overlord
• Run End Boss: World Tree

Boss mechanics will be detailed separately.

## Shops & Sigils
• Currency: gained from defeating enemies
• Shop options per visit: 3 items (common/uncommon/rare cards), plus remove and heal options
• Sigils: passive bonuses granted after boss fights or found in rooms. Each layer adds 1 Sigil.

## Events
• Event pool: narrative scenarios with 2–3 choices
• Effects: gain items, gold, status alterations, or risk-based outcomes

## Balancing Guidelines
• Target win rate: 30–40%
• Energy: 3 per turn is baseline
• Card cost/value ratio: ~6 total impact per energy
• Enemy HP & Damage: scale by layer (+20% each layer)
• Boss difficulty: multi-phase transitions triggered at HP thresholds
