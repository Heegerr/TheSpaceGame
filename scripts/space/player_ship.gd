extends CharacterBody2D
## A ship in space. Player-controlled (input thrust, feeds the engine hum) or
## an AI escort that holds formation on the active ship and moves to engage
## nearby hostiles (group "hostile_ships"; weapons arrive with space combat).
## Stats scale with ShipUpgrades tiers.

const BASE_MAX_SPEED := 260.0
const BASE_ACCELERATION := 420.0
const DRAG := 220.0
const TURN_SPEED := 9.0
const FOLLOW_ARRIVE_RADIUS := 90.0
const ENGAGE_RADIUS := 420.0
const HOLD_DISTANCE := 130.0

var is_player_controlled := true
var follow_target: Node2D
var follow_offset := Vector2.ZERO

@onready var flame: Polygon2D = $Flame


func _physics_process(delta: float) -> void:
	var max_speed := BASE_MAX_SPEED * ShipUpgrades.speed_multiplier()
	var acceleration := BASE_ACCELERATION * ShipUpgrades.speed_multiplier()
	var thrust := Vector2.ZERO
	if is_player_controlled:
		thrust = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		Sfx.set_engine_thrust(thrust.length())
	else:
		thrust = _escort_thrust()

	if thrust.length() > 0.05:
		velocity = velocity.move_toward(thrust.normalized() * max_speed * minf(thrust.length(), 1.0), acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)

	if velocity.length_squared() > 25.0:
		rotation = lerp_angle(rotation, velocity.angle(), 1.0 - exp(-TURN_SPEED * delta))

	flame.visible = thrust.length() > 0.05
	if flame.visible:
		flame.scale.x = randf_range(0.8, 1.25)

	move_and_slide()


func _escort_thrust() -> Vector2:
	var hostile := _nearest_hostile()
	if hostile != null:
		var to_hostile := hostile.global_position - global_position
		if to_hostile.length() > HOLD_DISTANCE:
			return to_hostile.normalized()
		return Vector2.ZERO
	if follow_target == null or not is_instance_valid(follow_target):
		return Vector2.ZERO
	var goal: Vector2 = follow_target.global_position + follow_offset.rotated(follow_target.rotation)
	var to_goal := goal - global_position
	if to_goal.length() > FOLLOW_ARRIVE_RADIUS:
		return to_goal.normalized()
	return to_goal / FOLLOW_ARRIVE_RADIUS * 0.35


func _nearest_hostile() -> Node2D:
	var best: Node2D = null
	var best_distance := ENGAGE_RADIUS
	for node in get_tree().get_nodes_in_group("hostile_ships"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var distance := global_position.distance_to((node as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	return best


func _exit_tree() -> void:
	if is_player_controlled:
		Sfx.set_engine_thrust(0.0)
