extends Node
## Autoload "SteamBridge": thin, optional wrapper around the GodotSteam
## extension. The game must run identically without Steam — every call no-ops
## when the extension or the Steam client is missing (graceful degradation
## for testing before the store page exists). Setup: docs/steam.md.

const APP_ID := 480  # Valve's public test AppID (Spacewar). Replace with the real one.

const ACHIEVEMENTS: Dictionary[String, String] = {
	"first_colony": "ACH_FIRST_COLONY",
	"first_wave": "ACH_FIRST_WAVE",
	"campaign_complete": "ACH_CAMPAIGN_COMPLETE",
	"infinite_10": "ACH_INFINITE_10_WAVES",
}

var available := false
var _steam: Object = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Engine.has_singleton("Steam"):
		print("SteamBridge: GodotSteam not installed - running in offline mode")
		return
	_steam = Engine.get_singleton("Steam")
	# The init API differs slightly across GodotSteam versions; probe defensively.
	if _steam.has_method("steamInitEx"):
		var result: Variant = _steam.steamInitEx(APP_ID, true)
		available = result is Dictionary and int((result as Dictionary).get("status", 1)) == 0
	elif _steam.has_method("steamInit"):
		var result: Variant = _steam.steamInit()
		if result is bool:
			available = result
		elif result is Dictionary:
			available = int((result as Dictionary).get("status", 0)) == 1
	if available:
		print("SteamBridge: Steam initialized (app %d)" % APP_ID)
	else:
		print("SteamBridge: Steam not running or init failed - offline mode")


func _process(_delta: float) -> void:
	if available and _steam.has_method("run_callbacks"):
		_steam.run_callbacks()


## Unlock by internal id (key of ACHIEVEMENTS). Safe to call repeatedly.
func unlock(achievement_id: String) -> void:
	if not available:
		return
	var api_name: String = ACHIEVEMENTS.get(achievement_id, "")
	if api_name == "" or not _steam.has_method("setAchievement"):
		return
	_steam.setAchievement(api_name)
	if _steam.has_method("storeStats"):
		_steam.storeStats()
