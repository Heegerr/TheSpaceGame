class_name SpaceportInteract
extends Area2D
## Interact hotspot for a Spaceport (Milestone 17): opens the HUD's ship
## training panel, mirroring BarracksInteract for ground units.

var spaceport: Node


func get_prompt() -> String:
	return "Press E for the spaceport"


func can_interact() -> bool:
	return true


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_spaceport_menu(spaceport)
