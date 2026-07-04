extends CharacterBody2D
## Hostile ship. Three kinds with distinct movement and attack patterns:
## DART (fast/weak, strafing runs), BRUISER (slow/tanky, presses in),
## LANCER (artillery, holds range and lobs heavy bolts).

signal died(ship: Node)

enum Kind { DART, BRUISER, LANCER }

const STATS: Dictionary[int, Dictionary] = {
	Kind.DART: {"hull": 12.0, "shield": 0.0, "speed": 300.0, "damage": 1.0, "cooldown": 0.5, "fire_range": 230.0, "preferred": 150.0, "bolt_speed": 420.0},
	Kind.BRUISER: {"hull": 60.0, "shield": 20.0, "speed": 120.0, "damage": 3.0, "cooldown": 1.4, "fire_range": 270.0, "preferred": 180.0, "bolt_speed": 300.0},
	Kind.LANCER: {"hull": 20.0, "shield": 0.0, "speed": 170.0, "damage": 4.0, "cooldown": 2.2, "fire_range": 580.0, "preferred": 470.0, "bolt_speed": 260.0},
}
const COLORS: Dictionary[int, Color] = {
	Kind.DART: Color(1.0, 0.45, 0.35),
	Kind.BRUISER: Color(0.9, 0.55, 0.2),
	Kind.LANCER: Color(0.75, 0.4, 1.0),
}

const BOLT_SCENE := preload("res://scenes/space/ship_bolt.tscn")
const TURN_SPEED := 7.0
const DRIFT_SPEED := 40.0
const STEERING := 380.0

var kind := Kind.DART
var hull := 12.0
var shield := 0.0
var aggro := false
var anchor := Vector2.ZERO

var _cooldown := 0.0
var _strafe_sign := 1.0
var _wobble := 0.0

@onready var body_polygon: Polygon2D = $Body


func setup(p_kind: int, p_anchor: Vector2) -> void:
	kind = p_kind
	anchor = p_anchor
	var stats := STATS[kind]
	hull = float(stats["hull"])
	shield = float(stats["shield"])
	body_polygon.color = COLORS[kind]
	match kind:
		Kind.DART:
			body_polygon.polygon = PackedVector2Array([Vector2(10, 0), Vector2(-8, 6), Vector2(-4, 0), Vector2(-8, -6)])
		Kind.BRUISER:
			body_polygon.polygon = PackedVector2Array([Vector2(12, 0), Vector2(4, 10), Vector2(-10, 8), Vector2(-10, -8), Vector2(4, -10)])
		Kind.LANCER:
			body_polygon.polygon = PackedVector2Array([Vector2(16, 0), Vector2(-6, 4), Vector2(-12, 0), Vector2(-6, -4)])
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_wobble += delta
	var stats := STATS[kind]
	var target := _nearest_player_ship()
	if not aggro or target == null:
		var to_anchor := anchor - global_position
		velocity = velocity.move_toward(to_anchor.limit_length(DRIFT_SPEED), 200.0 * delta)
	else:
		var to_target := target.global_position - global_position
		var distance := to_target.length()
		var dir := to_target / maxf(distance, 0.001)
		var preferred := float(stats["preferred"])
		var desired := dir
		match kind:
			Kind.DART:
				desired = (dir + dir.orthogonal() * _strafe_sign * sin(_wobble * 2.6) * 0.8).normalized()
				if distance < preferred * 0.6:
					desired = -dir
			Kind.BRUISER:
				desired = dir
			Kind.LANCER:
				if distance > preferred + 80.0:
					desired = dir
				elif distance < preferred - 80.0:
					desired = -dir
				else:
					desired = dir.orthogonal() * _strafe_sign * 0.5
		velocity = velocity.move_toward(desired * float(stats["speed"]), STEERING * delta)
		if distance < float(stats["fire_range"]) and _cooldown == 0.0:
			_cooldown = float(stats["cooldown"])
			_fire(dir)
	if velocity.length_squared() > 25.0:
		rotation = lerp_angle(rotation, velocity.angle(), 1.0 - exp(-TURN_SPEED * delta))
	move_and_slide()


func take_ship_damage(amount: float, _from_position: Vector2) -> void:
	aggro = true
	var remaining := amount
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		hull -= remaining
	var prior := modulate
	modulate = prior * Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", prior, 0.18)
	Sfx.play_hit(1.4)
	if hull <= 0.0:
		died.emit(self)
		queue_free()


func _fire(dir: Vector2) -> void:
	var stats := STATS[kind]
	var spread := 0.12 if kind == Kind.DART else 0.03
	var bolt := BOLT_SCENE.instantiate()
	bolt.direction = dir.rotated(randf_range(-spread, spread))
	bolt.damage = float(stats["damage"])
	bolt.speed = float(stats["bolt_speed"])
	bolt.set_faction(false)
	bolt.position = position + bolt.direction * 16.0
	get_parent().add_child(bolt)


func _nearest_player_ship() -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("player_fleet"):
		if node is Node2D and is_instance_valid(node):
			var distance := global_position.distance_squared_to((node as Node2D).global_position)
			if distance < best_distance:
				best_distance = distance
				best = node
	return best
