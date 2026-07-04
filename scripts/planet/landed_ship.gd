extends Area2D
## The player's ship parked on the landing pad. Boarding it opens the ship
## menu (upgrades, fleet, launch). Gathered resources persist because they
## live on the Inventory autoload.


func get_prompt() -> String:
	return "Press E to board your ship"


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_ship_menu()
	else:
		GameManager.return_to_space()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 26.0, Color(0.13, 0.15, 0.19))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.35, 0.4, 0.5), 1.5)
