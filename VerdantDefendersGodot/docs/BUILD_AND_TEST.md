```md
# Build & Test

## Run tests (GUT)
- VS Code task: **Godot: Run GUT**
- Or run from the project folder (VerdantDefendersGodot):

```powershell
"C:\Users\jorda\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe" --headless --path . --script addons/gut/gut_cmdln.gd -gdir "res://tests" -gexit
## Smoke run
1) In the Godot editor: **Project → Project Settings → Run**.
2) Set **Main Scene** to `res://Scenes/GameUI.tscn` → **Close**.
3) Press the **Play** ▶️ button (top-right) to launch the game.

## Export (later)
### One-time setup
1) In Godot: **Editor → Manage Export Templates…** → **Download and Install** (if not installed).
2) **Project → Export…** → **Add…** → **Windows Desktop** → (leave defaults) → **Save**.

### Command-line export (from the `VerdantDefendersGodot` folder)
**PowerShell:**
```powershell
& "C:\Users\jorda\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe" --headless --path . --export-release "Windows Desktop" build\VerdantDefenders.exe
