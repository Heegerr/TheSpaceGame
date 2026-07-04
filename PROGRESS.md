# Build Progress

Phased build of the space exploration game. Each phase is committed and pushed to
https://github.com/Heegerr/TheSpaceGame when complete.

To resume in a new session: read this file, `CLAUDE.md`, and `git log --oneline`,
then continue with the first unchecked phase.

- [x] Phase 0 - git init, remote wired, initial push
- [x] Phase 1 - Player ship & space movement (ship, starfield parallax, smooth camera, input map)
- [x] Phase 2 - Planet generation & landing (planets in space, FastNoiseLite tile surface, on-foot player)
- [x] Phase 3 - Resource gathering (Inventory autoload, gatherable nodes, HUD)
- [x] Phase 4 - Basic combat (alien enemy AI, player projectile, health, game over/respawn)
- [x] Phase 5 - Return to ship & loop closure (surface -> space, persistent inventory, new seeds)
- [x] Phase 6 - Placeholder audio (AudioStreamGenerator SFX: laser, footsteps, pickup, hit, engine)

All six phases are complete.

## Milestones (second build wave)

- [x] Milestone 1 - Colony building (build mode B, 4 structures with costs, per-planet persistence, build menu UI)
- [x] Milestone 2 - Save/load system (3 slots, main menu New/Continue/Load, autosave on return, manual save via pause menu)
- [x] Milestone 3 - Ship upgrades (engine/hull/weapon/cargo tiers) + fleet escorts with follow AI and ship switching
- [x] Milestone 4 - Tactical ship combat (combat mode, energy weapons, shields, 3 enemy ship types, escorts join, loot)
- [x] Milestone 5 - Wave/threat escalation campaign, boss wave, infinite mode unlock + notifications
- [x] Milestone 6 - Hand-crafted story planets injected into the procedural galaxy (2 scenes, dialogue triggers, rewards)
- [ ] Milestone 7 - Grid-based ship builder from parts (stats additive, validation, designs stored in save)
- [x] Milestone 8 - GodotSteam integration scaffold (SteamBridge autoload with offline fallback, achievement hooks, docs/steam.md; the binary GDExtension itself must be downloaded per docs, it is not vendored)

Notes:
- M1 stores structures in GameManager.planets (in-memory, per planet seed); M2 makes that durable via save slots.
- Save schema v3 (slots in user://saves/slot_N.json) already carries planets/ship_upgrades/campaign fields so later milestones do not migrate.
- M8 was done before M7 because it is scaffold-only; M7 is the last open milestone.

## Milestone 7 plan (next session)

1. `scripts/ship/ship_parts.gd` (class_name ShipParts): part defs - HULL_CORE (required, 1 max),
   HULL_SECTION (+15 hull), ENGINE (+12% speed, required >= 1), WEAPON (+1 damage), CARGO_POD (+15 cap).
   Each has a resource cost and a color/glyph for the editor grid.
2. Shipyard UI: new scene `scenes/ui/shipyard.tscn` opened from a "Shipyard" button in the HUD ship
   menu. 7x7 grid of cell buttons; palette on the right; click cell to place/remove selected part;
   live stat totals; Build button pays the summed cost.
3. Validation before Build: exactly one HULL_CORE, at least one ENGINE (spec minimum); optionally
   4-connectivity to the core.
4. Persistence: GameManager.ship_designs (Array of {name, cells: [{x, y, part}]}) + active_design
   index, added to save collect/apply (schema already versioned).
5. Integration: flagship stats derive from the active design when one exists (extend
   ShipUpgrades.speed_multiplier/hull_bonus/weapon_bonus to add design bonuses; upgrades remain as
   the baseline system, per the milestone spec "replace or extend").

## Session-2 recap (2026-07-04)

Milestones 1-6 and 8 are implemented and pushed, one commit each. None of it has been run yet -
the Godot binary is unavailable in the build environment. First action next session: open the
editor, fix anything it reports, commit .uid artifacts, then playtest: new game from the main
menu, gather, build a Habitat (B), survive the first wave, visit XETH-PRIME (story planet with
golden ring), buy an escort, pick a fight with a patrol.

## Notes for the next session

- Godot binary is not on PATH; code is written blind against Godot 4.7 APIs. When the user
  opens the editor, fix any parse errors it reports before continuing.
- First editor open will generate `.uid` files and may rewrite `.tscn`/`project.godot`
  formatting; commit those changes as a "Godot import artifacts" commit.
- Controls: WASD/arrows = move, E = interact, Space/LMB = attack, R = respawn.
- Keep this file ASCII-only (a PowerShell edit once corrupted UTF-8 dashes).
