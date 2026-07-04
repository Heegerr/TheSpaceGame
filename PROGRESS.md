# Build Progress

Phased build of the space exploration game. Each phase is committed and pushed to
https://github.com/Heegerr/TheSpaceGame when complete.

To resume in a new session: read this file, `CLAUDE.md`, and `git log --oneline`,
then continue with the first unchecked phase.

- [x] Phase 0 — git init, remote wired, initial push
- [x] Phase 1 — Player ship & space movement (ship, starfield parallax, smooth camera, input map)
- [ ] Phase 2 — Planet generation & landing (planets in space, FastNoiseLite tile surface, on-foot player)
- [ ] Phase 3 — Resource gathering (Inventory autoload, gatherable nodes, HUD)
- [ ] Phase 4 — Basic combat (alien enemy AI, player projectile, health, game over/respawn)
- [ ] Phase 5 — Return to ship & loop closure (surface -> space, persistent inventory, new seeds)
- [ ] Phase 6 — Placeholder audio (AudioStreamGenerator SFX: laser, footsteps, pickup, hit, engine)

## Notes for the next session

- Godot binary is not on PATH; code is written blind against Godot 4.7 APIs — when the user
  opens the editor, fix any parse errors it reports before continuing.
- First editor open will generate `.uid` files and may rewrite `.tscn`/`project.godot`
  formatting; commit those changes as a "Godot import artifacts" commit.
- Controls: WASD/arrows = move, E = interact, Space/LMB = attack, R = respawn.
