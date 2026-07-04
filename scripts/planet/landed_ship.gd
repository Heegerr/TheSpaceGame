extends Area2D
## The player's ship parked on the landing pad. Interacting with it flies back
## to space — gathered resources persist because they live on the Inventory
## autoload, and the space scene restores the ship where it was left.


func get_prompt() -> String:
	return "Press E to return to your ship"


func interact() -> void:
	GameManager.return_to_space()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 26.0, Color(0.13, 0.15, 0.19))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.35, 0.4, 0.5), 1.5)
