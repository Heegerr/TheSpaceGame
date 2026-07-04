extends CharacterBody2D
## On-foot player controller: 8-directional movement plus interaction with
## nearby interactables (resource nodes, the landed ship).

const MAX_SPEED := 130.0
const ACCELERATION := 900.0
const FRICTION := 1100.0

@onready var interact_range: Area2D = $InteractRange

var _interact_target: Area2D


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	_update_interact_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _interact_target != null:
		_interact_target.interact()


func _update_interact_target() -> void:
	var best: Area2D = null
	var best_distance := INF
	for area in interact_range.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		if area.has_method("can_interact") and not area.can_interact():
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	if best == _interact_target:
		return
	_interact_target = best
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if _interact_target != null:
		hud.show_hint(_interact_target.get_prompt())
	else:
		hud.hide_hint()
