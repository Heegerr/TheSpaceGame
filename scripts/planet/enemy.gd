extends CharacterBody2D
## Hostile alien: wanders idly, chases the player inside its detect radius,
## and deals contact damage with a cooldown. Aggros when shot.

enum State { IDLE, CHASE }

const SPEED_CHASE := 88.0
const SPEED_WANDER := 30.0
const STEERING := 400.0
const DETECT_RADIUS := 150.0
const LOSE_RADIUS := 240.0
const ATTACK_RANGE := 24.0
const ATTACK_COOLDOWN := 0.9
const CONTACT_DAMAGE := 1
const MAX_HEALTH := 3
const SCRAP_DROP_CHANCE := 0.6

const BODY_COLORS: Array[Color] = [
	Color(0.69, 0.3, 0.86),
	Color(0.85, 0.31, 0.48),
	Color(0.31, 0.85, 0.66),
]

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body

var state := State.IDLE
var health := MAX_HEALTH

var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _attack_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_pick_wander()


func setup(biome: int) -> void:
	body_polygon.color = BODY_COLORS[clampi(biome, 0, BODY_COLORS.size() - 1)]


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	var player := get_tree().get_first_node_in_group("player_on_foot")
	var player_alive: bool = player != null and player.alive
	var distance := INF
	if player_alive:
		distance = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			if player_alive and distance < DETECT_RADIUS:
				state = State.CHASE
			else:
				_wander(delta)
		State.CHASE:
			if not player_alive or distance > LOSE_RADIUS:
				state = State.IDLE
				_pick_wander()
			else:
				var to_player: Vector2 = (player.global_position - global_position).normalized()
				velocity = velocity.move_toward(to_player * SPEED_CHASE, STEERING * delta)
				if distance < ATTACK_RANGE and _attack_timer == 0.0:
					_attack_timer = ATTACK_COOLDOWN
					player.take_damage(CONTACT_DAMAGE, global_position)
	move_and_slide()


func take_damage(amount: int, from_position: Vector2) -> void:
	health -= amount
	Sfx.play_hit(1.3)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -12), str(amount), Color(1.0, 0.85, 0.4))
	visual.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
	var away := (global_position - from_position).normalized()
	if away != Vector2.ZERO:
		velocity += away * 120.0
	if state == State.IDLE:
		state = State.CHASE
	if health <= 0:
		_die()


func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander()
	velocity = velocity.move_toward(_wander_dir * SPEED_WANDER, 300.0 * delta)


func _pick_wander() -> void:
	_wander_timer = _rng.randf_range(1.2, 3.0)
	if _rng.randf() < 0.35:
		_wander_dir = Vector2.ZERO
	else:
		_wander_dir = Vector2.from_angle(_rng.randf_range(0.0, TAU))


func _die() -> void:
	if _rng.randf() < SCRAP_DROP_CHANCE:
		Inventory.add("scrap", 1)
		FloatingText.spawn(get_parent(), global_position, "+1 Scrap", Color(0.77, 0.5, 0.24))
	queue_free()
