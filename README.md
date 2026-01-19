# Verdant Defenders

Verdant Defenders is a roguelike deckbuilder built with the Godot Engine. Players explore four themed layers, building a deck from Growth, Decay, and Elemental cards while battling bosses and collecting relics.

This repository contains an early prototype. The current Godot project lives in VerdantDefendersGodot/.
The demo now supports basic turns with energy, card play, and an end-turn button.
Enemies are loaded from Data/enemy_data.json and spawned each room so strikes can damage and defeat them.

## Setup
If you're using a headless environment, run ./setup-godot.sh to install a local Godot binary. After running it, source your shell profile and verify with godot --version.
1. Install [Godot 4](https://godotengine.org/) (tested with Godot 4.1 or newer).
2. Open the project at VerdantDefendersGodot/ in the editor.
3. Run the Main scene to start the prototype.

## Repository Structure
- VerdantDefendersGodot/ – Godot project files.
- docs/ – Design documentation.

## Design Reference
The full game design is documented in [docs/game_design.md](docs/game_design.md). This file contains the complete reference for cards, dungeon structure, bosses, shops, and balance guidelines.

## License
This project is released under the MIT License. See [LICENSE](LICENSE) for details.

