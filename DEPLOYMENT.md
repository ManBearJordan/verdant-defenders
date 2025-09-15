# Verdant Defenders - Deployment Guide

This guide documents which files are essential for running the Verdant Defenders game versus development artifacts.

## Essential Files (Required for Game to Function)

### Core Game Files
- `VerdantDefendersGodot/` - Main Godot project directory
  - `project.godot` - Godot project configuration
  - `icon.svg` - Game icon
  - `.editorconfig` - Editor configuration
  - `.gitattributes` - Git configuration for binary files

### Game Logic & Scripts
- `VerdantDefendersGodot/scripts/` - All .gd files contain the game logic:
  - Core controllers: `GameController.gd`, `DungeonController.gd`, `TurnManager.gd`
  - Card system: `Card.gd`, `CardData.gd`, `CardDatabase.gd`, `CardUI.gd`
  - Game entities: `Enemy.gd`, `Boss.gd`
  - Game systems: `DataLoader.gd`, `EffectRunner.gd`, `RelicController.gd`
  - Room management: `RoomController.gd`, `EventController.gd`, `ShopController.gd`

### Game Scenes
- `VerdantDefendersGodot/Scenes/` - All .tscn files define the game UI and structure:
  - `Main.tscn`, `Game.tscn`, `Room.tscn`
  - `Enemy.tscn`, `Boss.tscn`, `CardUI.tscn`
  - `Event.tscn`, `Shop.tscn`

### Game Data
- `VerdantDefendersGodot/Data/` - JSON files containing game configuration:
  - `boss_phases.json` - Boss encounter data
  - `dungeon.json` - Dungeon structure
  - `enemy_data.json` - Enemy statistics and abilities
  - `event_data.json` - Random event definitions
  - `relic_data.json` - Relic effects and descriptions
  - `room_templates.json` - Room layout templates
  - `shop_data.json` - Shop pricing and inventory

### Documentation (Keep in Repository)
- `README.md` - Project overview and setup instructions
- `docs/game_design.md` - Complete game design reference
- `LICENSE` - MIT license

### Development Files (Keep in Repository, Exclude from Deployment)
- `tests/` - Test files for development validation
- `test.sh` - Test runner script
- `setup-godot.sh` - Development environment setup
- `.git/` - Version control history
- `.gitignore` - Files to ignore in version control

## Removed Development Artifacts

The following types of files were cleaned up as they are not needed for the game to function:

### Backup Files (Removed)
- `*.orig` files - Backup copies from merge conflicts/patches
- `*.rej` files - Rejected patch applications
- `*.patch` files - Development debugging patches

### Metadata Files (Removed)
- `*.uid` files - Godot editor metadata (auto-regenerated)

## Deployment Best Practices

### For Production/Distribution:
1. Include only the essential files listed above
2. Exclude the `tests/`, development scripts, and git history
3. The core game requires approximately:
   - 17 .gd script files
   - 6 .tscn scene files  
   - 6 .json data files
   - 1 project.godot configuration

### For Development:
1. Keep all files including tests and documentation
2. The updated `.gitignore` will prevent future accumulation of development artifacts
3. Use version control for backup instead of keeping `.orig` files

## File Size Impact

The cleanup removed 31 development artifact files, reducing repository clutter by over 4,000 lines of unnecessary content while preserving all functional game code.