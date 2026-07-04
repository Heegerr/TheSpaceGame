extends Area2D
## A talkable NPC or terminal on story planets. Uses the standard interactable
## contract (layer "interactable" + interact()/get_prompt()): each E press
## shows the next line via the HUD; after the last line it emits
## dialogue_finished so the story planet can grant its reward.

signal dialogue_finished

@export var speaker := "???"
@export var lines: PackedStringArray = PackedStringArray()

var _line_index := -1


func get_prompt() -> String:
	if _line_index < 0:
		return "Press E to talk to %s" % speaker
	return "Press E to continue"


func can_interact() -> bool:
	return lines.size() > 0


func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	_line_index += 1
	if _line_index >= lines.size():
		_line_index = -1
		if hud != null:
			hud.clear_dialogue()
		dialogue_finished.emit()
		return
	if hud != null:
		hud.show_dialogue("%s: %s" % [speaker, lines[_line_index]])


func _draw() -> void:
	draw_circle(Vector2(0, 0), 7.0, Color(0.4, 0.9, 0.8))
	draw_rect(Rect2(-3, -3, 2, 2), Color(0.05, 0.1, 0.12))
	draw_rect(Rect2(1, -3, 2, 2), Color(0.05, 0.1, 0.12))
	draw_line(Vector2(0, -7), Vector2(0, -12), Color(0.4, 0.9, 0.8), 1.5)
	draw_circle(Vector2(0, -13), 1.5, Color(1.0, 0.85, 0.4))
