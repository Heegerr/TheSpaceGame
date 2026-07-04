# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"The Space Game" — a 2D top-down pixel-art space exploration game: fly a ship between procedural planets, land, gather resources on foot, fight aliens, return to the ship. Godot 4.7 (Forward Plus), pure GDScript, no external dependencies. Everything visual/audible is generated at runtime (polygons, `_draw()`, runtime tile textures, synthesized SFX) — there are no art or audio assets yet; `art/` and `audio/` hold placeholders for when real assets land. Remote: https://github.com/Heegerr/TheSpaceGame. See `PROGRESS.md` for build-phase status.

## Running and tooling

There is no build/lint/test toolchain — everything runs through the Godot editor.

- The Godot executable is **not on PATH** on this machine. Ask the user to launch the editor or provide the exe path rather than hunting for it. Code here is written without an editor check, so on first open fix whatever the editor reports.
- With a Godot binary available: `godot --path .` runs the game, `godot -e --path .` opens the editor, `godot --headless --path . --check-only -s <script.gd>` syntax-checks a script.
- If the editor is open while you edit `project.godot` or `.tscn` files on disk, the editor can overwrite your changes when it saves. Prefer editing those files while the editor is closed, or ask the user to reload the project afterward.
- The first editor open generates `.uid` files and may normalize hand-written `.tscn`/`project.godot`; commit those artifacts as their own commit.
- `addons/godot_mcp_enhanced/` is a vendored third-party editor plugin that runs an HTTP server on `localhost:3571` (by default) while the editor is open, exposing scene/script/screenshot/run operations to MCP bridges. Treat it as tooling, not game code — don't modify it or take architectural cues from it.
- Controls: WASD/arrows move, E interact, Space/LMB attack, R respawn.

## Architecture

**Autoloads** (order matters — `Inventory` must stay registered before `GameManager` in `project.godot`, which reads it during `load_game()`):
- `Inventory` (`autoloads/inventory.gd`) — resource counts (`ore`, `plant`, `scrap`); `add`/`count`/`try_spend`, emits `changed`. Persists across scene changes by virtue of being an autoload.
- `GameManager` (`autoloads/game_manager.gd`) — galaxy seed, current planet, ship state, and the space<->surface scene flow (`land_on_planet()`, `return_to_space()`); saves/loads JSON at `user://save_game.json` (Windows: `%APPDATA%\Godot\app_userdata\The Space Game\`) on every transition.
- `Sfx` (`autoloads/sfx.gd`) — placeholder sounds synthesized as PCM and pushed through `AudioStreamGenerator`; one-shots via `play_laser/footstep/pickup/hit`, continuous engine hum via `set_engine_thrust(0..1)`.
- Autoload scripts must NOT declare `class_name` — a class name identical to the autoload name conflicts with the global it creates.

**Determinism/seeds:** everything procedural derives from `GameManager.galaxy_seed`: planet positions (`planet_field.gd`), each planet's seed (`hash("galaxy:index")`), and from that `PlanetData.make()` (name, biome, palette, radius). Surface terrain uses the planet seed; resource scatter uses seed+1; enemy placement uses seed+2. Same seed in = same world out; visit-local randomness (gather amounts, respawn timers) is intentionally unseeded.

**Scene flow:** `scenes/space/space.tscn` (main scene) -> `GameManager.land_on_planet(data, ship)` -> `scenes/planet/planet_surface.tscn` -> interact with the landed ship -> back to space with ship position restored. `space.gd` owns planet proximity/landing input; only the nearest in-range planet is highlighted. `planet_surface.gd` orchestrates generation: runtime `TileSet` from `TileSetBuilder.build()` (4 variants x 3 biomes, variant 3 collides), noise thresholds -> tile variants, landing pad cleared, then resources/enemies scattered.

**Physics layers** (named in `project.godot`): 1 world (terrain), 2 player, 3 enemy, 4 interactable, 5 projectile. The interactable contract: an `Area2D` on layer "interactable" exposing `interact()`, `get_prompt()`, and optionally `can_interact()`; the walker's `InteractRange` picks the nearest and shows its prompt (resources and the landed ship both implement it).

**HUD** (`scenes/ui/hud.tscn`, instanced in both space and surface, group `"hud"`): binds itself to `Inventory`/`GameManager` signals; gameplay code reaches it via `get_first_node_in_group("hud")` for `show_hint`/`hide_hint`, and the surface calls `bind_player()` for the health bar and `show_game_over()`.

**Damage pattern:** anything hittable exposes `take_damage(amount, from_position)` (player and enemies); projectiles hit whatever body they touch that has the method. Hit feedback = red `modulate` flash tweened back + `FloatingText.spawn()` (also used for pickups).

## Pixel-art rendering contract

The game is built on a 32×32 pixel grid, and `project.godot` enforces crisp rendering end to end. Breaking any of these degrades the whole game's look:

- Base viewport is **640×360** (20 × 11.25 tiles of 32 px) with `stretch/mode="viewport"`, `scale_mode="integer"`, `aspect="keep"` — scales exactly ×2 to 720p, ×3 to 1080p, ×6 to 4K; odd window sizes letterbox rather than reveal more world. The 1280×720 window override is only the default dev-window size.
- Design all gameplay and UI for the 640×360 canvas, positioned on whole pixels (HUD fonts are sized 8–10 for this reason).
- `default_texture_filter` is Nearest project-wide. Never switch a node's texture filter back to Linear; new textures need no per-import filter settings.
- `snap_2d_transforms_to_pixel=true` is on, so cameras/sprites snap to whole pixels automatically.
- TileSets use 32×32 tiles — currently built in code by `TileSetBuilder`; when real tile art arrives in `art/tiles/`, replace the builder's generated texture, keeping tile size and the variant/biome atlas layout.

## GDScript conventions

- Godot 4.x syntax, fully typed GDScript (typed dictionaries, typed signal parameters), tabs for indentation, snake_case filenames.
- Cross-system communication is signal-first: the state owner emits, consumers connect. Nodes find each other via groups (`player_on_foot`, `player_ship`, `enemies`, `hud`), never hard node paths across scenes.
- Keep files ASCII-safe when editing via shell tools; prefer the Edit/Write tools (a PowerShell `Set-Content` once corrupted UTF-8 punctuation).
