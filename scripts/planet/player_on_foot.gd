extends CharacterBody2D
## On-foot player: 8-directional movement, interaction with nearby
## interactables, a mouse-aimed blaster, and health with hit feedback.

signal health_changed(current: int, max_health: int)
signal died

const MAX_SPEED := 130.0
const ACCELERATION := 900.0
const FRICTION := 1100.0
const MAX_HEALTH := 5
const SHOOT_COOLDOWN := 0.3
const INVULN_TIME := 1.0
const KNOCKBACK := 170.0

const PROJECTILE_SCENE := preload("res://scenes/planet/projectile.tscn")

@onready var interact_range: Area2D = $InteractRange
@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

var health := MAX_HEALTH
var alive := true

## Cleared by the build controller while build mode is active, so placement
## clicks don't fire the blaster.
var shooting_enabled := true

var _interact_target: Area2D
var _shoot_timer := 0.0
var _invuln_timer := 0.0
var _step_timer := 0.0


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_shoot_timer = maxf(0.0, _shoot_timer - delta)
	_update_invulnerability(delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	_update_footsteps(delta)
	_update_interact_target()
	if shooting_enabled and Input.is_action_pressed("attack") and _shoot_timer == 0.0:
		_shoot()


func _update_footsteps(delta: float) -> void:
	if velocity.length() > 40.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.28
			Sfx.play_footstep()
	else:
		_step_timer = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if alive and event.is_action_pressed("interact") and _interact_target != null:
		_interact_target.interact()


func take_damage(amount: int, from_position: Vector2) -> void:
	# TODO: REMOVE BEFORE RELEASE - debug god mode ignores all damage.
	if GameManager.debug_god_mode:
		return
	if not alive or _invuln_timer > 0.0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	_invuln_timer = INVULN_TIME
	var away := (global_position - from_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.DOWN
	velocity += away * KNOCKBACK
	Sfx.play_hit(0.8)
	visual.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.25)
	if health == 0:
		_die()


func respawn(at: Vector2) -> void:
	global_position = at
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)
	alive = true
	visible = true
	visual.visible = true
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", false)
	_invuln_timer = INVULN_TIME
	(get_node("Camera2D") as Camera2D).reset_smoothing()


func _shoot() -> void:
	_shoot_timer = SHOOT_COOLDOWN
	Sfx.play_laser()
	var dir := (get_global_mouse_position() - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.direction = dir
	projectile.position = position + dir * 10.0
	get_parent().add_child(projectile)


func _die() -> void:
	alive = false
	visible = false
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.hide_hint()
	died.emit()


func _update_invulnerability(delta: float) -> void:
	if _invuln_timer <= 0.0:
		return
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	visual.visible = int(_invuln_timer * 12.0) % 2 == 0
	if _invuln_timer == 0.0:
		visual.visible = true


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
