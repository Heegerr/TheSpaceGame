extends CanvasLayer
## In-game HUD: resource counts, planet name, health bar, hint text, build
## menu, pause menu, and the game-over overlay. Lives in group "hud" so
## gameplay code can find it. Runs while the tree is paused (pause menu).

const Structure := preload("res://scripts/colony/structure.gd")

const RESOURCE_COLORS: Dictionary[String, Color] = {
	"ore": Color(0.44, 0.89, 0.91),
	"plant": Color(0.34, 0.76, 0.37),
	"scrap": Color(0.77, 0.5, 0.24),
	"alloy": Color(0.85, 0.55, 0.95),
}
const RESOURCE_LABELS: Dictionary[String, String] = {
	"ore": "Ore",
	"plant": "Plants",
	"scrap": "Scrap",
	"alloy": "Alloy",
}

@onready var resources_box: VBoxContainer = $Resources
@onready var planet_label: Label = $PlanetLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var hint_label: Label = $HintLabel
@onready var game_over_screen: Control = $GameOver
@onready var build_menu: PanelContainer = $BuildMenu
@onready var build_entries: HBoxContainer = $BuildMenu/BuildEntries
@onready var pause_menu: Control = $PauseMenu
@onready var pause_status: Label = $PauseMenu/Center/VBox/StatusLabel

var _count_labels: Dictionary[String, Label] = {}
var _build_rows: Array[Dictionary] = []
var _build_selected := 0
var _build_active := false


func _ready() -> void:
	for resource_id in Inventory.RESOURCE_TYPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(8, 8)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.color = RESOURCE_COLORS.get(resource_id, Color.WHITE)
		row.add_child(swatch)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 8)
		row.add_child(label)
		resources_box.add_child(row)
		_count_labels[resource_id] = label
		_update_count(resource_id, Inventory.count(resource_id))
	_create_build_menu()
	Inventory.changed.connect(_update_count)
	GameManager.planet_changed.connect(_on_planet_changed)
	_on_planet_changed(GameManager.current_planet)
	health_bar.visible = false
	hint_label.text = ""
	game_over_screen.visible = false
	build_menu.visible = false
	pause_menu.visible = false
	$PauseMenu/Center/VBox/ResumeButton.pressed.connect(toggle_pause)
	$PauseMenu/Center/VBox/SaveButton.pressed.connect(_on_save_pressed)
	$PauseMenu/Center/VBox/MenuButton.pressed.connect(GameManager.quit_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not game_over_screen.visible:
		toggle_pause()
		get_viewport().set_input_as_handled()


# -- Pause menu -------------------------------------------------------------------

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused
	pause_status.text = ""


func _on_save_pressed() -> void:
	if GameManager.current_slot < 0:
		pause_status.text = "No save slot (started from the editor)"
		return
	GameManager.save_current()
	pause_status.text = "Saved."


# -- Player binding -----------------------------------------------------------------

func bind_player(player: Node) -> void:
	health_bar.visible = true
	health_bar.max_value = player.MAX_HEALTH
	health_bar.value = player.health
	player.health_changed.connect(_on_health_changed)


func show_hint(text: String) -> void:
	hint_label.text = text


func hide_hint() -> void:
	hint_label.text = ""


func show_game_over() -> void:
	game_over_screen.visible = true


func hide_game_over() -> void:
	game_over_screen.visible = false


# -- Build menu ---------------------------------------------------------------------

func set_build_menu(active: bool, selected: int) -> void:
	_build_active = active
	_build_selected = selected
	build_menu.visible = active
	if active:
		_refresh_build_menu()
		show_hint("Click to place - 1-4 to select - B to exit build mode")
	else:
		hide_hint()


func _create_build_menu() -> void:
	build_entries.add_theme_constant_override("separation", 14)
	for structure_type in Structure.DEFS:
		var def: Dictionary = Structure.DEFS[structure_type]
		var box := VBoxContainer.new()
		var title := Label.new()
		title.add_theme_font_size_override("font_size", 8)
		title.text = "[%d] %s" % [structure_type + 1, def["name"]]
		var cost := Label.new()
		cost.add_theme_font_size_override("font_size", 8)
		cost.text = _cost_text(def["cost"])
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 8)
		desc.modulate = Color(0.75, 0.78, 0.85)
		desc.text = str(def["desc"])
		box.add_child(title)
		box.add_child(cost)
		box.add_child(desc)
		build_entries.add_child(box)
		_build_rows.append({"type": structure_type, "title": title, "cost": cost})


func _cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for resource_id in cost:
		parts.append("%d %s" % [int(cost[resource_id]), RESOURCE_LABELS.get(resource_id, resource_id)])
	return ", ".join(parts)


func _refresh_build_menu() -> void:
	if not _build_active:
		return
	for row in _build_rows:
		var selected: bool = row["type"] == _build_selected
		row["title"].add_theme_color_override("font_color", Color(1, 0.9, 0.4) if selected else Color.WHITE)
		row["cost"].add_theme_color_override("font_color",
				Color(0.6, 1, 0.6) if Structure.can_afford(row["type"]) else Color(1, 0.45, 0.4))


# -- Internal -------------------------------------------------------------------------

func _update_count(resource_id: String, amount: int) -> void:
	if _count_labels.has(resource_id):
		_count_labels[resource_id].text = "%s: %d/%d" % [RESOURCE_LABELS.get(resource_id, resource_id), amount, Inventory.cap()]
	if _build_active:
		_refresh_build_menu()


func _on_planet_changed(planet_name: String) -> void:
	planet_label.text = planet_name


func _on_health_changed(current: int, _max_health: int) -> void:
	health_bar.value = current
