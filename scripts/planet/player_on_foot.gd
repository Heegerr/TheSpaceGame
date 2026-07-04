extends CharacterBody2D
## On-foot player controller for planet surfaces: 8-directional movement.

const MAX_SPEED := 130.0
const ACCELERATION := 900.0
const FRICTION := 1100.0


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
