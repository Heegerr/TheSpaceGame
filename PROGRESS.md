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
- [ ] Milestone 6 - Hand-crafted story planets injected into the procedural galaxy (2-3 scenes, dialogue triggers, rewards)
- [ ] Milestone 7 - Grid-based ship builder from parts (stats additive, validation, designs stored in save)
- [ ] Milestone 8 - GodotSteam integration (init with offline fallback, achievements, cloud saves, graceful degradation)

Notes:
- M1 stores structures in GameManager.planets (in-memory, per planet seed); M2 makes that durable via save slots.
- Save schema v3 (slots in user://saves/slot_N.json) already carries planets/ship_upgrades/campaign fields so later milestones do not migrate.

## Notes for the next session

- Godot binary is not on PATH; code is written blind against Godot 4.7 APIs. When the user
  opens the editor, fix any parse errors it reports before continuing.
- First editor open will generate `.uid` files and may rewrite `.tscn`/`project.godot`
  formatting; commit those changes as a "Godot import artifacts" commit.
- Controls: WASD/arrows = move, E = interact, Space/LMB = attack, R = respawn.
- Keep this file ASCII-only (a PowerShell edit once corrupted UTF-8 dashes).
