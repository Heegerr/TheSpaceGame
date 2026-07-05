extends Area2D
## Upgrade terminal inside the ship interior (Milestone 18): opens the same
## ship menu (upgrades/fleet/Shipyard) used when boarding the ship in space,
## so upgrades can be managed without flying anywhere.


func get_prompt() -> String:
	return "Press E to manage your ship"


func can_interact() -> bool:
	return true


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_ship_menu()


func _draw() -> void:
	draw_rect(Rect2(-10, -14, 20, 22), Color(0.35, 0.38, 0.46))
	draw_rect(Rect2(-7, -11, 14, 14), Color(0.4, 0.75, 0.95, 0.85))
	draw_line(Vector2(-7, -4), Vector2(7, -4), Color(0.2, 0.5, 0.7), 1.0)
	draw_line(Vector2(-7, -8), Vector2(3, -8), Color(0.2, 0.5, 0.7), 1.0)
