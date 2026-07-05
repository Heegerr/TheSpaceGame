class_name ResearchInteract
extends Area2D
## Interact hotspot for a Research Building (Milestone 14): opens the tech
## tree UI. The building's own planet_seed/star_type is looked up from
## GameManager.current_planet_data since only the planet the player is
## standing on can ever be interacted with.


func get_prompt() -> String:
	return "Press E to open the tech tree"


func can_interact() -> bool:
	return true


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_tech_tree()
