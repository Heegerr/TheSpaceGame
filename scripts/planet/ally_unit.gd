extends CharacterBody2D
## A trained Barracks unit (Milestone 16). Guards near its spawn point by
## default; "Follow Me" from the Barracks panel switches it to trailing the
## player instead. Either way it automatically engages the nearest enemy in
## its aggro range - melee units close the distance, the Ranger stops at
## range and fires the existing ground projectile.

enum Mode { GUARD, FOLLOW }

const STEERING := 400.0
const PROJECTILE_SCENE := preload("res://scenes/planet/projectile.tscn")

var mode := Mode.GUARD
var home_position := Vector2.ZERO
var health := 1
var max_health := 1

var _stats: Dictionary = {}
var _attack_timer := 0.0

@onready var body_polygon: Polygon2D = $Body


func setup(unit_id: String, spawn_position: Vector2) -> void:
	_stats = GroundUnits.DEFS[unit_id]
	max_health = int(_stats["health"])
	health = max_health
	home_position = spawn_position
	global_position = spawn_position
	body_polygon.color = _stats["color"]


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	var speed: float = _stats["speed"]
	var attack_range: float = _stats["range"]
	var target := _nearest_enemy()
	if target != null:
		var distance := global_position.distance_to(target.global_position)
		if distance > attack_range * 0.85:
			velocity = velocity.move_toward((target.global_position - global_position).normalized() * speed, STEERING * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, STEERING * delta)
			if _attack_timer <= 0.0:
				_attack_timer = float(_stats["cooldown"])
				_attack(target)
	else:
		var anchor := _guard_anchor()
		var to_anchor := anchor - global_position
		if to_anchor.length() > 12.0:
			velocity = velocity.move_toward(to_anchor.normalized() * speed, STEERING * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, STEERING * delta)
	move_and_slide()


func _guard_anchor() -> Vector2:
	if mode == Mode.FOLLOW:
		var player := get_tree().get_first_node_in_group("player_on_foot")
		if player != null:
			return player.global_position + Vector2(0, 26)
	return home_position


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_distance: float = _stats["aggro_range"]
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy_node
	return best


func _attack(target: Node2D) -> void:
	if bool(_stats.get("ranged", false)):
		var direction := (target.global_position - global_position).normalized()
		var bolt := PROJECTILE_SCENE.instantiate()
		bolt.direction = direction
		bolt.damage = int(_stats["damage"])
		bolt.position = global_position + direction * 10.0
		get_parent().add_child(bolt)
	elif target.has_method("take_damage"):
		target.take_damage(int(_stats["damage"]), global_position)


func take_damage(amount: int, _from_position: Vector2) -> void:
	health -= amount
	body_polygon.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(body_polygon, "modulate", Color.WHITE, 0.2)
	if health <= 0:
		queue_free()
