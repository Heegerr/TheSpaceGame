class_name GateInteract
extends Area2D
## Interact hotspot for a Gate structure (Milestone 13): lets the player toggle
## it open/closed. The gate itself (the parent StaticBody2D) still blocks
## enemies whenever it is closed; opening it only lifts that block, it does
## not distinguish who walks through.

var gate: Node


func get_prompt() -> String:
	return "Press E to close the gate" if gate.gate_open else "Press E to open the gate"


func can_interact() -> bool:
	return true


func interact() -> void:
	gate.toggle_gate()
