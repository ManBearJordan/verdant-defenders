# Agent Rules

1. Before editing, list a plan and **files to modify**.
2. Do **not** delete working systems or rename scene/node paths unless asked.
3. Print **full file contents** for any modified file (no partial diffs).
4. After edits, run **Godot: Run GUT** and paste output.
5. If tests or build fail, **rollback only the failing part**; propose a minimal fix.
6. Keep changes scoped; prefer adding small functions over big refactors.
   Paths: Use forward slashes for all paths. Treat paths as relative to the project root.
7. Godot resource paths must be res://… with forward slashes.
8. Do not introduce backslashes (\\) or leading slashes (/scripts/...) in file references.
