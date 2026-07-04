extends CanvasLayer
## In-game HUD: resource counts, planet name, health bar, hint text, and the
## game-over overlay. Lives in group "hud" so gameplay code can find it.

const RESOURCE_COLORS: Dictionary[String, Color] = {
	"ore": Color(0.44, 0.89, 0.91),
	"plant": Color(0.34, 0.76, 0.37),
	"scrap": Color(0.77, 0.5, 0.24),
}
const RESOURCE_LABELS: Dictionary[String, String] = {
	"ore": "Ore",
	"plant": "Plants",
	"scrap": "Scrap",
}

@onready var resources_box: VBoxContainer = $Resources
@onready var planet_label: Label = $PlanetLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var hint_label: Label = $HintLabel
@onready var game_over_screen: Control = $GameOver

var _count_labels: Dictionary[String, Label] = {}


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
	Inventory.changed.connect(_update_count)
	GameManager.planet_changed.connect(_on_planet_changed)
	_on_planet_changed(GameManager.current_planet)
	health_bar.visible = false
	hint_label.text = ""
	game_over_screen.visible = false


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


func _update_count(resource_id: String, amount: int) -> void:
	if _count_labels.has(resource_id):
		_count_labels[resource_id].text = "%s: %d" % [RESOURCE_LABELS.get(resource_id, resource_id), amount]


func _on_planet_changed(planet_name: String) -> void:
	planet_label.text = planet_name


func _on_health_changed(current: int, _max_health: int) -> void:
	health_bar.value = current
