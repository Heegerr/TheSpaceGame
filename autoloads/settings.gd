extends Node
## Autoload "Settings": master audio volume and keyboard rebinds. Persists to
## user://settings.cfg (separate from save slots - these apply regardless of
## which save is loaded, or none at all from the main menu).

signal keybind_changed(action: String)

const SETTINGS_PATH := "user://settings.cfg"

## Actions the Options menu lets the player rebind, in display order.
const REBINDABLE_ACTIONS: Dictionary[String, String] = {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"interact": "Interact",
	"attack": "Attack",
	"respawn": "Respawn",
	"build_menu": "Build Menu",
	"switch_ship": "Switch Ship",
	"toggle_map": "Toggle Map",
	"pause": "Pause",
}

var master_volume := 1.0

var _default_keycodes: Dictionary[String, int] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in REBINDABLE_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				_default_keycodes[action] = (event as InputEventKey).physical_keycode
				break
	_load()
	_apply_volume()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)) if master_volume > 0.0 else -80.0)
	AudioServer.set_bus_mute(bus, master_volume <= 0.0)


## Replaces only the keyboard event(s) for `action` (mouse/gamepad events on
## the same action, like attack's LMB binding, are left alone).
func rebind_key(action: String, physical_keycode: int) -> void:
	_apply_keybind(action, physical_keycode)
	_save()


func _apply_keybind(action: String, physical_keycode: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var new_event := InputEventKey.new()
	new_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action, new_event)
	keybind_changed.emit(action)


func reset_keybind(action: String) -> void:
	if _default_keycodes.has(action):
		rebind_key(action, _default_keycodes[action])


func current_keycode(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return KEY_NONE


func key_display_name(action: String) -> String:
	var keycode := current_keycode(action)
	return OS.get_keycode_string(keycode) if keycode != KEY_NONE else "-"


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	for action in REBINDABLE_ACTIONS:
		config.set_value("keybinds", action, current_keycode(action))
	config.save(SETTINGS_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
	for action in REBINDABLE_ACTIONS:
		var keycode: int = int(config.get_value("keybinds", action, current_keycode(action)))
		if keycode != KEY_NONE:
			_apply_keybind(action, keycode)
