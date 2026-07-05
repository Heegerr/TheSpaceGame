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
- [x] Milestone 7 - Grid-based ship builder from parts (stats additive, validation, designs stored in save)
- [x] Milestone 8 - GodotSteam integration scaffold (SteamBridge autoload with offline fallback, achievement hooks, docs/steam.md; the binary GDExtension itself must be downloaded per docs, it is not vendored)

Notes:
- M1 stores structures in GameManager.planets (in-memory, per planet seed); M2 makes that durable via save slots.
- Save schema v3 (slots in user://saves/slot_N.json) already carries planets/ship_upgrades/campaign fields so later milestones do not migrate.
- M7: `scripts/ship/ship_parts.gd` (ShipParts) defines HULL_CORE/HULL_SECTION/ENGINE/WEAPON/CARGO_POD;
  `scenes/ui/shipyard.tscn` + `scripts/ui/shipyard.gd` is a 7x7 grid builder opened via a "Shipyard"
  button in the HUD ship menu; validation requires exactly one core, >=1 engine, and 4-connectivity;
  Build pays the summed cost and writes GameManager.ship_designs[0] (schema v3, no migration needed).
  Bonuses apply only to the flagship (`player_ship.gd` `is_flagship`, false for escorts) additively on
  top of ShipUpgrades tiers.

## Second build wave (Milestones 9-18)

Requested 2026-07-05: a third build wave extending the second wave's colony/combat systems -
multi-planet star systems with typed system modifiers (M9-10), expanded biome variety tied to
system type (M11), a minimap (M12), defense structures (M13), research/tech tree (M14), a
dedicated storage building (M15), ground unit training via Barracks (M16), space unit training
via Spaceport (M17), and an enterable ship interior (M18). Being implemented one milestone at a
time, each its own commit, per session pacing agreed with the user. See git log for progress;
this file's milestone list will grow as each lands.

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
