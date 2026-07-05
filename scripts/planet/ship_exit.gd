extends Area2D
## Exit hatch inside the ship interior (Milestone 18): returns to the planet
## surface near the landed ship (the surface regenerates fresh, same as any
## other land/return - consistent with the existing space<->surface flow).


func get_prompt() -> String:
	return "Press E to exit the ship"


func can_interact() -> bool:
	return true


func interact() -> void:
	GameManager.exit_ship_interior()


func _draw() -> void:
	draw_rect(Rect2(-12, -16, 24, 32), Color(0.24, 0.26, 0.32))
	draw_rect(Rect2(-9, -13, 18, 26), Color(0.5, 0.85, 0.55, 0.5))
	draw_arc(Vector2(-9, 0), 4.0, 0.0, TAU, 10, Color(0.7, 0.95, 0.75), 1.5)
