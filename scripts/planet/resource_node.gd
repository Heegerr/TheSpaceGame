extends Area2D
## A gatherable resource on the planet surface. The player's InteractRange
## finds it via the "interactable" physics layer; interact() adds to the
## Inventory, then the node hides and respawns after a delay.

const DISPLAY_NAMES: Dictionary[String, String] = {
	"ore": "Ore",
	"plant": "Plants",
	"scrap": "Scrap",
	"obsidian": "Obsidian",
	"biomass": "Biomass",
	"crystal": "Crystal",
	"silicate": "Silicate",
	"acid": "Acid",
	"resin": "Resin",
	"cryo_ore": "Cryo Ore",
}

var resource_type := "ore"

@onready var respawn_timer: Timer = $RespawnTimer

var _depleted := false


func _ready() -> void:
	respawn_timer.timeout.connect(_respawn)


func setup(type: String) -> void:
	resource_type = type
	queue_redraw()


func get_prompt() -> String:
	return "Press E to gather %s" % DISPLAY_NAMES.get(resource_type, resource_type)


func can_interact() -> bool:
	return not _depleted


func interact() -> void:
	if _depleted:
		return
	var amount := randi_range(1, 3)
	Inventory.add(resource_type, amount)
	Sfx.play_pickup()
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -14),
			"+%d %s" % [amount, DISPLAY_NAMES.get(resource_type, resource_type)],
			Color(0.65, 0.95, 0.55))
	_depleted = true
	visible = false
	set_deferred("monitorable", false)
	respawn_timer.start(randf_range(20.0, 35.0))


func _respawn() -> void:
	_depleted = false
	visible = true
	set_deferred("monitorable", true)


func _draw() -> void:
	match resource_type:
		"ore":
			draw_colored_polygon(PackedVector2Array([Vector2(-9, 6), Vector2(-4, -7), Vector2(3, -9), Vector2(9, 4), Vector2(4, 8), Vector2(-3, 9)]), Color(0.47, 0.5, 0.57))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -2), Vector2(1, -7), Vector2(3, -1)]), Color(0.44, 0.89, 0.91))
			draw_colored_polygon(PackedVector2Array([Vector2(3, 2), Vector2(6, -3), Vector2(8, 3)]), Color(0.44, 0.89, 0.91))
		"plant":
			draw_line(Vector2(0, 8), Vector2(0, -4), Color(0.16, 0.42, 0.2), 2.0)
			draw_circle(Vector2(0, -6), 4.0, Color(0.34, 0.76, 0.37))
			draw_circle(Vector2(-4, -2), 3.0, Color(0.3, 0.68, 0.33))
			draw_circle(Vector2(4, -2), 3.0, Color(0.3, 0.68, 0.33))
			draw_circle(Vector2(2, -7), 1.5, Color(1.0, 0.82, 0.4))
		"scrap":
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 4), Vector2(-2, -8), Vector2(4, -5), Vector2(2, 2)]), Color(0.77, 0.5, 0.24))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 6), Vector2(6, -2), Vector2(9, 5)]), Color(0.54, 0.35, 0.17))
			draw_circle(Vector2(1, -2), 1.5, Color(0.91, 0.89, 0.85))
		"obsidian":
			draw_colored_polygon(PackedVector2Array([Vector2(-7, 8), Vector2(-3, -9), Vector2(3, -7), Vector2(8, 6), Vector2(0, 9)]), Color(0.12, 0.08, 0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -3), Vector2(1, -7), Vector2(2, -1)]), Color(0.9, 0.4, 0.1))
		"biomass":
			draw_circle(Vector2(-3, 3), 5.0, Color(0.28, 0.42, 0.28))
			draw_circle(Vector2(4, 1), 4.0, Color(0.38, 0.52, 0.3))
			draw_circle(Vector2(0, -5), 3.5, Color(0.45, 0.65, 0.3))
		"crystal":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -10), Vector2(6, -2), Vector2(4, 8), Vector2(-4, 8), Vector2(-6, -2)]), Color(0.5, 0.35, 0.7))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -10), Vector2(6, -2), Vector2(0, 0)]), Color(0.75, 0.6, 0.95))
		"silicate":
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 5), Vector2(-4, -6), Vector2(5, -8), Vector2(8, 3), Vector2(2, 8)]), Color(0.5, 0.46, 0.4))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -3), Vector2(3, -6), Vector2(4, 0)]), Color(0.65, 0.62, 0.56))
		"acid":
			draw_circle(Vector2.ZERO, 7.0, Color(0.35, 0.45, 0.12))
			draw_circle(Vector2.ZERO, 4.5, Color(0.65, 0.85, 0.2, 0.85))
			draw_circle(Vector2(-2, -2), 1.5, Color(0.85, 1.0, 0.5))
		"resin":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(5, 1), Vector2(2, 8), Vector2(-2, 8), Vector2(-5, 1)]), Color(0.75, 0.5, 0.15, 0.9))
			draw_circle(Vector2(-1, -3), 1.5, Color(0.95, 0.8, 0.5, 0.9))
		"cryo_ore":
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 4), Vector2(-3, -8), Vector2(4, -6), Vector2(8, 5), Vector2(0, 9)]), Color(0.4, 0.55, 0.65))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -3), Vector2(1, -6), Vector2(3, 0)]), Color(0.75, 0.92, 1.0))
