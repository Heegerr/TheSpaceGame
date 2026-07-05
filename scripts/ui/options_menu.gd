extends CanvasLayer
## Options menu overlay (Milestone: audio + keybinds). Instanced on demand
## from the main menu and the in-game pause menu; Settings autoload persists
## changes immediately, so there's no separate "Apply" step.

@onready var volume_slider: HSlider = $Panel/Box/VolumeRow/VolumeSlider
@onready var volume_label: Label = $Panel/Box/VolumeRow/VolumeLabel
@onready var music_slider: HSlider = $Panel/Box/MusicRow/MusicSlider
@onready var music_label: Label = $Panel/Box/MusicRow/MusicLabel
@onready var keybind_list: VBoxContainer = $Panel/Box/Scroll/KeybindList
@onready var rebind_hint: Label = $Panel/Box/RebindHint

var _rebind_rows: Dictionary[String, Dictionary] = {}
var _rebinding_action := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = Settings.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = Settings.music_volume
	music_slider.value_changed.connect(_on_music_changed)
	_build_keybind_rows()
	$Panel/Box/Buttons/ResetButton.pressed.connect(_on_reset_pressed)
	$Panel/Box/Buttons/CloseButton.pressed.connect(close)
	rebind_hint.text = ""


func open() -> void:
	_cancel_rebind()
	volume_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	_update_volume_label()
	_update_music_label()
	_refresh_keybind_rows()
	visible = true


func close() -> void:
	_cancel_rebind()
	visible = false


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_update_volume_label()


func _update_volume_label() -> void:
	volume_label.text = "%d%%" % int(round(Settings.master_volume * 100.0))


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)
	_update_music_label()


func _update_music_label() -> void:
	music_label.text = "%d%%" % int(round(Settings.music_volume * 100.0))


func _build_keybind_rows() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = str(Settings.REBINDABLE_ACTIONS[action])
		var key_label := Label.new()
		key_label.add_theme_font_size_override("font_size", 9)
		key_label.custom_minimum_size = Vector2(64, 0)
		var rebind_button := Button.new()
		rebind_button.text = "Rebind"
		rebind_button.add_theme_font_size_override("font_size", 8)
		rebind_button.pressed.connect(_on_rebind_pressed.bind(action))
		row.add_child(name_label)
		row.add_child(key_label)
		row.add_child(rebind_button)
		keybind_list.add_child(row)
		_rebind_rows[action] = {"key_label": key_label, "button": rebind_button}


func _refresh_keybind_rows() -> void:
	for action in _rebind_rows:
		_rebind_rows[action]["key_label"].text = Settings.key_display_name(action)


func _on_rebind_pressed(action: String) -> void:
	_cancel_rebind()
	_rebinding_action = action
	_rebind_rows[action]["button"].text = "Press a key..."
	rebind_hint.text = "Press any key to bind to \"%s\" (Esc to cancel)" % str(Settings.REBINDABLE_ACTIONS[action])


func _cancel_rebind() -> void:
	if _rebinding_action != "" and _rebind_rows.has(_rebinding_action):
		_rebind_rows[_rebinding_action]["button"].text = "Rebind"
	_rebinding_action = ""
	rebind_hint.text = ""


func _unhandled_key_input(event: InputEvent) -> void:
	if _rebinding_action == "" or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	var action := _rebinding_action
	var keycode := key_event.physical_keycode
	_cancel_rebind()
	if keycode == KEY_ESCAPE:
		return
	Settings.rebind_key(action, keycode)
	_refresh_keybind_rows()


func _on_reset_pressed() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		Settings.reset_keybind(action)
	_refresh_keybind_rows()
