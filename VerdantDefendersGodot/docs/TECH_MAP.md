# Tech Map (Godot)

## Entry points
- **Start scene**: `Scenes/GameUI.tscn`  (confirm in Project Settings → Run)
- **Main combat**: `Scenes/GameUI.tscn` (combat UI + rendering)

## Autoload singletons (intended; add if missing)
- `DataLayer.gd`, `GameController.gd`, `CombatSystem.gd`, `DeckManager.gd`,
  `CardRules.gd`, `RewardSystem.gd`, `RoomController.gd`, `ShopSystem.gd`, `EnemyAI.gd`

## Important scripts
- `scripts/GameController.gd` — turn order, start/end turn
- `scripts/DeckManager.gd` — draw/discard/reshuffle; starting deck rules
- `scripts/CardRules.gd` — applies card effect verbs (deal_damage, gain_block, etc.)
- `scripts/enemy.gd` — enemy HP/block/status, intent text, click targeting
- `scripts/StatusHandler.gd` — tick statuses
- `scripts/RewardSystem.gd` — post-combat rewards

## Data locations
- Cards: `Data/cards.json` (or CSV)
- Enemies: `Data/enemies.json`
- Sigils: `Data/sigils.json`

## Conventions
- GDScript 2.0 with explicit types where possible
- Signals over polling; use `@onready` and typed vars
- **Do not** rename scene/node paths without approval
