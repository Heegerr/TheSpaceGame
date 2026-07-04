extends CharacterBody2D
## Player ship: drifty thrust movement that rotates toward the travel direction.

const MAX_SPEED := 260.0
const ACCELERATION := 420.0
const DRAG := 220.0
const TURN_SPEED := 9.0

@onready var flame: Polygon2D = $Flame


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)

	# Rotate toward travel direction once there is meaningful movement.
	if velocity.length_squared() > 25.0:
		rotation = lerp_angle(rotation, velocity.angle(), 1.0 - exp(-TURN_SPEED * delta))

	flame.visible = input_dir != Vector2.ZERO
	if flame.visible:
		flame.scale.x = randf_range(0.8, 1.25)

	move_and_slide()
