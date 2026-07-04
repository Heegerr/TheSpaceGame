extends Area2D
## A gatherable resource on the planet surface. The player's InteractRange
## finds it via the "interactable" physics layer; interact() adds to the
## Inventory, then the node hides and respawns after a delay.

const DISPLAY_NAMES: Dictionary[String, String] = {
	"ore": "Ore",
	"plant": "Plants",
	"scrap": "Scrap",
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
