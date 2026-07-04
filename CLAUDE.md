# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A 2D top-down pixel-art space exploration game. Godot 4.7 (Forward Plus renderer), pure GDScript, no external dependencies or package manager. Not a git repository yet.

## Running and tooling

There is no build/lint/test toolchain — everything runs through the Godot editor.

- The Godot executable is **not on PATH** on this machine. Ask the user to launch the editor or provide the exe path rather than hunting for it.
- With a Godot binary available: `godot --path .` runs the game, `godot -e --path .` opens the editor, `godot --headless --path . --check-only -s <script.gd>` syntax-checks a script.
- If the editor is open while you edit `project.godot` or `.tscn` files on disk, the editor can overwrite your changes when it saves. Prefer editing those files while the editor is closed, or ask the user to reload the project afterward.
- `addons/godot_mcp_enhanced/` is a vendored third-party editor plugin that runs an HTTP server on `localhost:3571` (by default) while the editor is open, exposing scene/script/tilemap/screenshot/run operations to MCP bridges. Treat it as tooling, not game code — don't modify it or take architectural cues from it. Optional config: `res://godot_mcp_config.json` (absent = defaults).

## Architecture

**Autoload singletons** hold all global state. They live in `autoloads/` and are registered in the `[autoload]` section of `project.godot`. Autoload scripts must NOT declare `class_name` — a class name identical to the autoload name conflicts with the global it creates.

`GameManager` (`autoloads/game_manager.gd`) is the only autoload so far:

- State: `current_planet: String` (`""` = deep space) and `resources: Dictionary[String, int]` (seeded with fuel/ore/credits).
- Mutate through its methods (`set_current_planet`, `add_resource`, `try_spend_resource`); they emit `planet_changed` / `resource_changed`. UI and other systems react to signals rather than polling.
- Save/load is a placeholder: JSON at `user://save_game.json` (on Windows: `%APPDATA%\Godot\app_userdata\New Game Project\`). Anything that must persist goes through `_collect_save_data()` / `_apply_save_data()` so callers never change.

**Folder conventions:** `scenes/` (.tscn), `scripts/` (non-autoload .gd), `art/sprites/`, `art/tiles/`, `audio/sfx/`, `audio/music/`, `autoloads/`. Empty folders are held by hidden `.gitkeep` files (the Godot FileSystem dock hides dot-files).

## Pixel-art rendering contract

The game is built on a 32×32 pixel grid, and `project.godot` enforces crisp rendering end to end. Breaking any of these degrades the whole game's look:

- Base viewport is **640×360** (20 × 11.25 tiles of 32 px) with `stretch/mode="viewport"`, `scale_mode="integer"`, `aspect="keep"` — scales exactly ×2 to 720p, ×3 to 1080p, ×6 to 4K; odd window sizes letterbox rather than reveal more world. The 1280×720 window override is only the default dev-window size.
- Design all gameplay and UI for the 640×360 canvas, positioned on whole pixels.
- `default_texture_filter` is Nearest project-wide. Never switch a node's texture filter back to Linear; new textures need no per-import filter settings.
- `snap_2d_transforms_to_pixel=true` is on, so cameras/sprites snap to whole pixels automatically.
- TileSet resources must use 32×32 tile size (set per TileSet; there is no project-wide setting for it).

## GDScript conventions

- Godot 4.x syntax, fully typed GDScript (typed dictionaries, typed signal parameters), tabs for indentation, snake_case filenames.
- Cross-system communication is signal-first: the state owner emits, consumers connect.
