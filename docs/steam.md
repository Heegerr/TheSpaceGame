# Steam Integration (GodotSteam)

The game integrates Steam through the `SteamBridge` autoload
(`autoloads/steam_bridge.gd`). Everything degrades gracefully: without the
GodotSteam extension or a running Steam client, the game runs identically and
logs `SteamBridge: ... offline mode` at startup. That line is the smoke test.

## Installing GodotSteam (not vendored in this repo)

1. Download the GodotSteam **GDExtension** release matching this Godot version
   (4.7) from https://godotsteam.com / GitHub releases.
2. Unzip into `addons/godotsteam/` so the `.gdextension` file and platform
   binaries sit there. No autoload registration is needed for the extension
   itself - it registers the `Steam` singleton natively.
3. Put a `steam_appid.txt` containing the AppID next to the Godot editor
   binary (for editor runs) and next to the exported exe (for testing).
   `SteamBridge.APP_ID` is 480 (Valve's public Spacewar test app) until the
   real AppID exists - replace it in `steam_bridge.gd` then.
4. Launch with Steam running: startup log should read
   `SteamBridge: Steam initialized (app ...)`.

## Achievements

Create these API names in Steamworks (App Admin > Stats & Achievements):

| API name               | Unlocked when                                    |
| ---------------------- | ------------------------------------------------ |
| ACH_FIRST_COLONY       | First Habitat built (first colonized planet)     |
| ACH_FIRST_WAVE         | First alien wave repelled                        |
| ACH_CAMPAIGN_COMPLETE  | Boss wave survived, campaign complete            |
| ACH_INFINITE_10_WAVES  | 10+ waves survived in infinite mode              |

Unlock hooks live in `GameManager.add_structure()` and
`wave_manager.gd/_wave_cleared()`; call `SteamBridge.unlock("<internal id>")`
with the keys defined in `SteamBridge.ACHIEVEMENTS` to add more.

## Cloud saves

Save slots are plain JSON under `user://saves/` (on Windows:
`%APPDATA%/Godot/app_userdata/The Space Game/saves`). The simplest sync is
Steam **Auto-Cloud** (Steamworks > App Admin > Cloud):

- Root: `WinAppDataRoaming`, path: `Godot/app_userdata/The Space Game/saves`,
  pattern: `*.json` (add matching roots for Linux/macOS when those builds exist).

No code changes are needed for Auto-Cloud. If per-file control is wanted
later, swap `FileAccess` writes in `GameManager` for `Steam.fileWrite()` -
keep the local-file path as the fallback when `SteamBridge.available` is false.

## Graceful degradation checklist

- Extension missing: `Engine.has_singleton("Steam")` is false -> offline mode.
- Steam client not running: init fails -> offline mode, game unaffected.
- Achievements/cloud calls all no-op when `SteamBridge.available` is false.
