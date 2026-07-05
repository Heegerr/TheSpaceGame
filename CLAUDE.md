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
- Controls: WASD/arrows move, E interact, Space/LMB attack, R respawn, B build mode (surface), Tab switch ship (space), Esc pause menu.

## Architecture

**Autoloads** (order matters — `Inventory` must stay registered before `GameManager` in `project.godot`, which reads it during `load_game()`):
- `Inventory` (`autoloads/inventory.gd`) — resource counts (`ore`, `plant`, `scrap`); `add`/`count`/`try_spend`, emits `changed`. Persists across scene changes by virtue of being an autoload.
- `GameManager` (`autoloads/game_manager.gd`) — galaxy seed, current planet, ship state, and the space<->surface scene flow (`land_on_planet()`, `return_to_space()`); saves/loads JSON at `user://save_game.json` (Windows: `%APPDATA%\Godot\app_userdata\The Space Game\`) on every transition.
- `Sfx` (`autoloads/sfx.gd`) — placeholder sounds synthesized as PCM and pushed through `AudioStreamGenerator`; one-shots via `play_laser/footstep/pickup/hit`, continuous engine hum via `set_engine_thrust(0..1)`.
- Autoload scripts must NOT declare `class_name` — a class name identical to the autoload name conflicts with the global it creates.

**Determinism/seeds:** everything procedural derives from `GameManager.galaxy_seed`: star system centers and each system's 2-6 orbiting planets (`planet_field.gd`, `StarSystemData`), each planet's seed (`hash("galaxy:flat_index")`), and from that `PlanetData.make()` (name, biome, palette, radius). Surface terrain uses the planet seed; resource scatter uses seed+1; enemy placement uses seed+2. Same seed in = same world out; visit-local randomness (gather amounts, respawn timers) is intentionally unseeded.

**Star systems (Milestone 9):** `PlanetField` scatters `SYSTEM_COUNT` systems far apart (`SYSTEM_MIN_DISTANCE`) and places each system's planets in tight orbits (`ORBIT_BASE_RADIUS`/`ORBIT_STEP`) around a purely-visual `Star` node, so intra-system travel is quick and inter-system travel is a long haul, using the same continuous space scene and ship physics as before (no separate galaxy/system scene transition). `planet_field.planets` stays a flat `Array[SpacePlanet]` across all systems, so `encounter_manager.gd`/`wave_manager.gd`/`space.gd` (nearest/random planet) are unaffected by the grouping. `PlanetField.system_of(planet_seed)` finds a planet's system for anything system-aware (star type, minimap).

**Star system types (Milestone 10):** `StarSystemTypes` (6 types: Yellow Star, Red Dwarf, Blue Giant, Binary, Neutron Star, Nebula) defines each type's `Star` visuals (color/size/nebula tint/binary companion/pulse) and a `biome_weights` table. `StarSystemData.star_type` is derived deterministically from `system_seed` (`StarSystemTypes.type_for_seed`), so like planet biome it needs no dedicated save field to stay consistent on revisit. `PlanetField` passes the system's `biome_weights` into `PlanetData.make()`, which does a weighted pick instead of a uniform one.

**Biome variety (Milestone 11):** `PlanetData.Biome` has 10 entries (grass, desert, ice, volcanic, swamp, crystal, barren, toxic, forest, tundra), each with a `SPACE_PALETTE` (space-view planet colors), `TILE_PALETTE` (feeds `TileSetBuilder`, which already loops over `PlanetData.BIOME_COUNT` generically), and an `AMBIENT_TINT` applied via the surface scene's `CanvasModulate` node (`AmbientTint` in `planet_surface.tscn`). `planet_surface.gd`'s `BIOME_RESOURCE_WEIGHTS` gives each new biome its own exclusive gatherable resource (obsidian/biomass/crystal/silicate/acid/resin/cryo_ore — new `Inventory.RESOURCE_TYPES` entries, drawn in `resource_node.gd`); the original 3 biomes keep sharing ore/plant/scrap. The HUD only adds a resource row the first time a player collects one of the new ones, so the panel stays compact until a biome-exclusive resource is actually found.

**Scene flow:** `scenes/space/space.tscn` (main scene) -> `GameManager.land_on_planet(data, ship)` -> `scenes/planet/planet_surface.tscn` -> interact with the landed ship -> back to space with ship position restored. `space.gd` owns planet proximity/landing input; only the nearest in-range planet is highlighted. `planet_surface.gd` orchestrates generation: runtime `TileSet` from `TileSetBuilder.build()` (4 variants x 3 biomes, variant 3 collides), noise thresholds -> tile variants, landing pad cleared, then resources/enemies scattered.

**Physics layers** (named in `project.godot`): 1 world (terrain), 2 player, 3 enemy, 4 interactable, 5 projectile. The interactable contract: an `Area2D` on layer "interactable" exposing `interact()`, `get_prompt()`, and optionally `can_interact()`; the walker's `InteractRange` picks the nearest and shows its prompt (resources and the landed ship both implement it).

**HUD** (`scenes/ui/hud.tscn`, instanced in both space and surface, group `"hud"`): binds itself to `Inventory`/`GameManager` signals; gameplay code reaches it via `get_first_node_in_group("hud")` for `show_hint`/`hide_hint`, and the surface calls `bind_player()` for the health bar and `show_game_over()`.

**Damage pattern:** anything hittable exposes `take_damage(amount, from_position)` (player and enemies); projectiles hit whatever body they touch that has the method. Hit feedback = red `modulate` flash tweened back + `FloatingText.spawn()` (also used for pickups). Space combat mirrors this with `take_ship_damage()` and faction-masked `ship_bolt.tscn` (player bolts hit layer 6 "hostile_ship", hostile bolts hit layer 2).

**Second-wave systems** (see PROGRESS.md for milestone status):
- *Colony building:* `structure.gd` DEFS is the source of truth for the 4 structure types; placements live in `GameManager.planets` (keyed `str(planet_seed)`) and rebuild on landing; `build_controller.gd` owns build mode (B); Habitats define "colonized", Silos + cargo tiers feed `Inventory.set_cap_bonus` via `GameManager.recompute_capacity()`.
- *Save slots:* 3 JSON slots in `user://saves/slot_N.json` (schema v3), driven by `main_menu.tscn` (New/Continue/Load) and the Esc pause menu (manual save); autosave on every land/return. `current_slot == -1` (running a scene directly from the editor) skips file writes but keeps in-memory state.
- *Ship upgrades & fleet:* `ShipUpgrades` statics read/write `GameManager.ship_upgrades`; the ship menu opens by boarding the landed ship. `space.gd` owns the roster: flagship + `fleet_size` escorts, Tab switches pilot, the scene-level Camera2D follows the active ship, group `player_fleet` = all friendly ships, `player_ship` = piloted one only (saves read it).
- *Space combat:* `encounter_manager.gd` (seeded patrols) and `wave_manager.gd` (campaign waves vs colonized planets, boss at stage 5, infinite mode after) both expose engagement flags; `space.gd` aggregates them into `set_combat()` which slows all fleet ships. Wave failure removes a random structure on the target planet.
- *Story planets:* `StoryRegistry` claims planet-field slot indices (2, 5) and swaps in hand-authored `StoryPlanet` scenes — terrain from ASCII maps, `dialogue_trigger.gd` NPCs, one-time rewards tracked as `story_done` in the planet record. Golden atmosphere ring marks them in space.
- *Steam:* `SteamBridge` autoload wraps the optional GodotSteam extension (not vendored; see `docs/steam.md`) — everything no-ops without it. Achievements unlock via `SteamBridge.unlock(id)` from GameManager/wave_manager hooks.

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
