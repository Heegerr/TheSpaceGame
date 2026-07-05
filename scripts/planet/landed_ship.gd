extends Area2D
## The player's ship parked on the landing pad. Boarding it enters the ship
## interior (Milestone 18), which has its own Upgrade Terminal for the ship
## menu (upgrades, fleet, launch) and an exit hatch back to the surface.
## Gathered resources persist because they live on the Inventory autoload.


func get_prompt() -> String:
	return "Press E to board your ship"


func interact() -> void:
	GameManager.enter_ship_interior()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 26.0, Color(0.13, 0.15, 0.19))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.35, 0.4, 0.5), 1.5)
