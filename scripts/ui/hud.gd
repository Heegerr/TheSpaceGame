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
@onready var ship_menu: PanelContainer = $ShipMenu
@onready var ship_menu_box: VBoxContainer = $ShipMenu/ShipMenuBox

var _count_labels: Dictionary[String, Label] = {}
var _build_rows: Array[Dictionary] = []
var _build_selected := 0
var _build_active := false
var _ship_rows: Array[Dictionary] = []
var _fleet_label: Label
var _fleet_button: Button
var _ship_menu_built := false
var _space_ship: Node
var _ship_bars: VBoxContainer
var _hull_bar: ProgressBar
var _shield_bar: ProgressBar
var _energy_bar: ProgressBar
var _banner: Label
var _banner_tween: Tween


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
	_create_ship_bars()
	_create_banner()
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


# -- Space ship binding (hull/shield/energy bars, polled while visible) --------------

func bind_ship(ship: Node) -> void:
	_space_ship = ship
	_ship_bars.visible = true


func _process(_delta: float) -> void:
	if _ship_bars.visible and _space_ship != null and is_instance_valid(_space_ship):
		_hull_bar.max_value = _space_ship.max_hull
		_hull_bar.value = _space_ship.hull
		_shield_bar.max_value = _space_ship.BASE_SHIELD
		_shield_bar.value = _space_ship.shield
		_energy_bar.max_value = _space_ship.MAX_ENERGY
		_energy_bar.value = _space_ship.energy


func show_banner(text: String, color: Color = Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = _banner.create_tween()
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


func _create_ship_bars() -> void:
	_ship_bars = VBoxContainer.new()
	_ship_bars.anchor_left = 1.0
	_ship_bars.anchor_right = 1.0
	_ship_bars.offset_left = -104.0
	_ship_bars.offset_right = -8.0
	_ship_bars.offset_top = 8.0
	_ship_bars.add_theme_constant_override("separation", 2)
	_ship_bars.visible = false
	add_child(_ship_bars)
	_hull_bar = _make_bar(Color(0.88, 0.32, 0.3))
	_shield_bar = _make_bar(Color(0.35, 0.65, 1.0))
	_energy_bar = _make_bar(Color(1.0, 0.85, 0.35))


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(96, 7)
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.1, 0.11, 0.15, 0.85)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	_ship_bars.add_child(bar)
	return bar


func _create_banner() -> void:
	_banner = Label.new()
	_banner.anchor_right = 1.0
	_banner.offset_top = 64.0
	_banner.offset_bottom = 90.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 14)
	_banner.modulate.a = 0.0
	add_child(_banner)


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
	if ship_menu.visible:
		_refresh_ship_menu()


# -- Ship menu (upgrades + fleet), opened by boarding the landed ship ---------------

func show_ship_menu() -> void:
	if not _ship_menu_built:
		_build_ship_menu()
	_refresh_ship_menu()
	ship_menu.visible = true


func hide_ship_menu() -> void:
	ship_menu.visible = false


func _build_ship_menu() -> void:
	_ship_menu_built = true
	ship_menu_box.add_theme_constant_override("separation", 5)
	var title := Label.new()
	title.text = "SHIP SYSTEMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	ship_menu_box.add_child(title)
	for category in ShipUpgrades.DEFS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_label := Label.new()
		cost_label.add_theme_font_size_override("font_size", 8)
		var buy := Button.new()
		buy.text = "Upgrade"
		buy.add_theme_font_size_override("font_size", 8)
		buy.pressed.connect(_on_buy_upgrade.bind(category))
		row.add_child(name_label)
		row.add_child(cost_label)
		row.add_child(buy)
		ship_menu_box.add_child(row)
		_ship_rows.append({"category": category, "name": name_label, "cost": cost_label, "buy": buy})
	var fleet_row := HBoxContainer.new()
	fleet_row.add_theme_constant_override("separation", 8)
	_fleet_label = Label.new()
	_fleet_label.add_theme_font_size_override("font_size", 8)
	_fleet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fleet_button = Button.new()
	_fleet_button.text = "Buy Escort (%s)" % _cost_text(ShipUpgrades.ESCORT_COST)
	_fleet_button.add_theme_font_size_override("font_size", 8)
	_fleet_button.pressed.connect(_on_buy_escort)
	fleet_row.add_child(_fleet_label)
	fleet_row.add_child(_fleet_button)
	ship_menu_box.add_child(fleet_row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	var launch := Button.new()
	launch.text = "Launch"
	launch.add_theme_font_size_override("font_size", 10)
	launch.pressed.connect(_on_launch)
	var close := Button.new()
	close.text = "Close"
	close.add_theme_font_size_override("font_size", 10)
	close.pressed.connect(hide_ship_menu)
	buttons.add_child(launch)
	buttons.add_child(close)
	ship_menu_box.add_child(buttons)


func _refresh_ship_menu() -> void:
	if not _ship_menu_built:
		return
	for row in _ship_rows:
		var category: String = row["category"]
		var def: Dictionary = ShipUpgrades.DEFS[category]
		var current := ShipUpgrades.tier(category)
		row["name"].text = "%s  T%d/%d  -  %s" % [def["name"], current, ShipUpgrades.MAX_TIER, def["desc"]]
		var cost := ShipUpgrades.next_cost(category)
		if cost.is_empty():
			row["cost"].text = "MAX"
			row["buy"].disabled = true
		else:
			row["cost"].text = _cost_text(cost)
			row["buy"].disabled = not ShipUpgrades.can_afford_cost(cost)
			row["cost"].add_theme_color_override("font_color",
					Color(0.6, 1, 0.6) if ShipUpgrades.can_afford_cost(cost) else Color(1, 0.45, 0.4))
	_fleet_label.text = "Escorts: %d/%d  -  Colonist capacity: %d" % [
			GameManager.fleet_size, ShipUpgrades.MAX_FLEET, GameManager.colonist_capacity()]
	_fleet_button.disabled = GameManager.fleet_size >= ShipUpgrades.MAX_FLEET \
			or not ShipUpgrades.can_afford_cost(ShipUpgrades.ESCORT_COST)


func _on_buy_upgrade(category: String) -> void:
	ShipUpgrades.buy(category)
	_refresh_ship_menu()


func _on_buy_escort() -> void:
	ShipUpgrades.buy_escort()
	_refresh_ship_menu()


func _on_launch() -> void:
	hide_ship_menu()
	GameManager.return_to_space()


func _on_planet_changed(planet_name: String) -> void:
	planet_label.text = planet_name


func _on_health_changed(current: int, _max_health: int) -> void:
	health_bar.value = current
