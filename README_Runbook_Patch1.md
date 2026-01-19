# Overgrowth – Patch 1 (Godot 4.4.1)

This patch supplies **complete, minimal** Data and core scripts to get a playable loop:
Start Screen → Dungeon → Fight(s) → Floor clear or defeat.

## What’s included
- Data/*.json: small, valid datasets (cards, enemies, dungeon, shop, relics, sigils, Characters)
- scripts/*.gd: robust loaders and minimal implementations
  - DataLayer.gd (safe JSON loading, economy filename fallback)
  - GameController.gd (run state + summaries)
  - CombatSystem.gd (energy, block, damage, thorns, poison)
  - DungeonController.gd (single-layer progression)
  - RoomController.gd (spawns fights; stubs events/shop)
  - StartScreen.gd (auto-starts a Growth run for now)

## File paths
Place these files into your project at:
```
VerdantDefendersGodot/Data/*.json
VerdantDefendersGodot/scripts/*.gd
```
(They match your existing structure.)

> **Note:** Your repo had a filename mismatch: `economy_congfig.json` vs `economy_config.json`.
The loader now checks **both**. Keep only one spelling later; recommended: `economy_config.json`.

## How to test
1. Open the project in **Godot 4.4.1**.
2. Ensure **AutoLoad** singletons (Project Settings → Autoload) include:
   - `DataLayer` → `res://scripts/DataLayer.gd` (Singleton, Enable)
   - `GameController` → `res://scripts/GameController.gd`
   - `CombatSystem` → `res://scripts/CombatSystem.gd`
   - `DungeonController` → `res://scripts/DungeonController.gd`
   - `RoomController` → `res://scripts/RoomController.gd`
3. Set your `StartScreen.tscn` to use `StartScreen.gd` **or** open a blank Control scene that instantiates `StartScreen`.
4. Press **Play**. A basic fight should start. You can call `CombatSystem.play_card()` from a temporary UI button or the remote inspector to verify actions.

## Next steps (Phase 2)
- Hook up your existing UI scenes (CardUI, DeckView, RewardsUI) to call into `CombatSystem` and `GameController`.
- Implement reward drops and shop interactions using `shop_data.json`.
- Add event handling (Event.tscn) and enemy AI scripts (EnemyIntent.gd) as per your docs.
- Expand the card list using your design doc; the engine already supports `damage`, `block`, and `apply.poison` examples.

If you want, I can produce Phase 2 with UI wiring and a richer card/effect system next.
