extends CharacterBody2D
## A ship in the player's fleet. Player-controlled (input thrust, mouse-aimed
## weapons, feeds the engine hum) or an AI escort that holds formation and
## engages hostiles. Stats scale with ShipUpgrades tiers; combat mode slows
## all fleet ships for more deliberate maneuvering.

signal destroyed(ship: Node)

const BASE_MAX_SPEED := 260.0
const BASE_ACCELERATION := 420.0
const DRAG := 220.0
const TURN_SPEED := 9.0
const FOLLOW_ARRIVE_RADIUS := 90.0
const ENGAGE_RADIUS := 420.0
const HOLD_DISTANCE := 130.0
const COMBAT_SPEED_SCALE := 0.55

const BASE_HULL := 75.0
const BASE_SHIELD := 40.0
const SHIELD_REGEN := 8.0
const SHIELD_REGEN_DELAY := 3.0
const MAX_ENERGY := 100.0
const ENERGY_REGEN := 22.0
const SHOT_ENERGY := 12.0
const SHOT_COOLDOWN := 0.35
const BASE_DAMAGE := 2.0
const ESCORT_FIRE_RANGE := 340.0

const BOLT_SCENE := preload("res://scenes/space/ship_bolt.tscn")

var is_player_controlled := true
var follow_target: Node2D
var follow_offset := Vector2.ZERO
var combat_slowdown := false

var max_hull := BASE_HULL
var hull := BASE_HULL
var shield := BASE_SHIELD
var energy := MAX_ENERGY

var _shot_timer := 0.0
var _shield_delay := 0.0

@onready var flame: Polygon2D = $Flame


func _ready() -> void:
	reset_combat_state()


func reset_combat_state() -> void:
	max_hull = BASE_HULL + ShipUpgrades.hull_bonus()
	hull = max_hull
	shield = BASE_SHIELD
	energy = MAX_ENERGY


func _physics_process(delta: float) -> void:
	_shot_timer = maxf(0.0, _shot_timer - delta)
	energy = minf(MAX_ENERGY, energy + ENERGY_REGEN * delta)
	if _shield_delay > 0.0:
		_shield_delay = maxf(0.0, _shield_delay - delta)
	else:
		shield = minf(BASE_SHIELD, shield + SHIELD_REGEN * delta)

	var speed_scale := COMBAT_SPEED_SCALE if combat_slowdown else 1.0
	var max_speed := BASE_MAX_SPEED * ShipUpgrades.speed_multiplier() * speed_scale
	var acceleration := BASE_ACCELERATION * ShipUpgrades.speed_multiplier() * speed_scale
	var thrust := Vector2.ZERO
	if is_player_controlled:
		thrust = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		Sfx.set_engine_thrust(thrust.length())
		if Input.is_action_pressed("attack"):
			_try_fire((get_global_mouse_position() - global_position).normalized())
	else:
		thrust = _escort_thrust()
		var hostile := _nearest_hostile(ESCORT_FIRE_RANGE)
		if hostile != null:
			_try_fire((hostile.global_position - global_position).normalized())

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


func take_ship_damage(amount: float, _from_position: Vector2) -> void:
	_shield_delay = SHIELD_REGEN_DELAY
	var remaining := amount
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		hull -= remaining
	var prior := modulate
	modulate = prior * Color(1.0, 0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(self, "modulate", prior, 0.2)
	Sfx.play_hit(0.7 if is_player_controlled else 0.9)
	if hull <= 0.0:
		destroyed.emit(self)


func _try_fire(direction: Vector2) -> void:
	if _shot_timer > 0.0 or energy < SHOT_ENERGY or direction == Vector2.ZERO:
		return
	_shot_timer = SHOT_COOLDOWN
	energy -= SHOT_ENERGY
	var bolt := BOLT_SCENE.instantiate()
	bolt.direction = direction
	bolt.damage = BASE_DAMAGE + ShipUpgrades.weapon_bonus()
	bolt.set_faction(true)
	bolt.position = position + direction * 16.0
	get_parent().add_child(bolt)
	if is_player_controlled:
		Sfx.play_laser()


func _escort_thrust() -> Vector2:
	var hostile := _nearest_hostile(ENGAGE_RADIUS)
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


func _nearest_hostile(radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := radius
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
