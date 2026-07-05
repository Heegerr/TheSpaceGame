class_name BarracksInteract
extends Area2D
## Interact hotspot for a Barracks (Milestone 16): opens the HUD's unit
## training panel, passing this specific building so Train presses queue on
## the right structure's timer.

var barracks: Node


func get_prompt() -> String:
	return "Press E for the barracks"


func can_interact() -> bool:
	return true


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_barracks_menu(barracks)
