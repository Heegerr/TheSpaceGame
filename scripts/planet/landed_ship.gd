extends Area2D
## The player's ship parked on the landing pad of a planet surface.
## (Interacting with it to return to space arrives in Phase 5.)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 26.0, Color(0.13, 0.15, 0.19))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.35, 0.4, 0.5), 1.5)
