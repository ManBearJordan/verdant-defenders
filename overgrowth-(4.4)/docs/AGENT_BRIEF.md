# Overgrowth — Agent Brief

## Vision
Single-player roguelike deckbuilder in Godot 4.4. Three card pools:
- **Growth** (heals/armor/engines)
- **Decay** (damage/poison/wither)
- **Elemental** (fire/ice/lightning/wind)

Goal: tight, readable combat; inspired by StS without copying assets/code.

## Core systems
- Deck/Hand/Energy loop (draw → play with energy → end turn → reshuffle)
- Status & Sigils (relics)
- Rooms: combat, shop, events, miniboss, boss; post-combat rewards
- Card/enemy data from JSON/CSV
- Bosses show intentions; UI for energy/hand/intents/end-turn

## Current state
- Project builds; enemies render
- Hand/energy loop partially wired
- Some strict-typing compile errors to fix
- GUT installed; VS Code task **Godot: Run GUT**

## Definition of Done (for any change)
1) Compiles on Godot 4.4.1 (no red errors)  
2) `Godot: Run GUT` passes  
3) Minimal diff; no renaming/deleting existing systems unless approved  
4) Short “what & where changed” summary

## Agent etiquette
- Show a plan + files to modify before editing
- Print full files after edits
- Run tests and paste output
- If something fails: rollback only the failing part; propose a minimal fix
