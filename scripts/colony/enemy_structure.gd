extends StaticBody2D
## An enemy colony structure on a distant planet surface, seeded procedurally
## by planet_surface.gd - never player-built and never saved: like enemy
## walkers, colonies regenerate deterministically on every landing. Sits on
## physics layer 1 ("world") so it blocks movement exactly like player
## structures, and joins group "enemies" (via the scene) so player Towers,
## ally units, and the minimap already treat it as hostile with no extra
## plumbing. Turrets mirror the player's Defense Tower: they auto-fire the
## shared ground projectile at the player or their units in range, using a
## hostile collision mask so the bolts can never hit fellow aliens.

signal destroyed(structure: Node)

enum Kind { MINER, TURRET, WALL }

const DEFS: Dictionary[int, Dictionary] = {
	Kind.MINER: {
		"name": "Enemy Miner",
		"health": 8,
		"loot": {"ore": 4, "scrap": 2},
	},
	Kind.TURRET: {
		"name": "Enemy Turret",
		"health": 12,
		"loot": {"scrap": 3},
	},
	Kind.WALL: {
		"name": "Enemy Wall",
		"health": 14,
		"loot": {},
	},
}

const TURRET_INTERVAL := 1.3
## Slightly past the player Tower's 170 so trading shots is not a free win.
const TURRET_RANGE := 190.0
const PROJECTILE_SCENE := preload("res://scenes/planet/projectile.tscn")
## world (1) + player (2) layers: hostile bolts hit the player and their ally
## units (both on the "player" layer) and die on terrain, but never hit the
## aliens or other enemy structures en route.
const HOSTILE_BOLT_MASK := 3
const HOSTILE_BOLT_COLOR := Color(1.0, 0.45, 0.4)

var kind := Kind.WALL
## The planet's 0..1 distance-based danger: scales this structure's health,
## the turret's damage, and the loot it drops when destroyed.
var danger := 0.0
var max_health := 1
var health := 1

var _fire_timer := 0.0


func setup(p_kind: int, p_danger: float) -> void:
	kind = p_kind as Kind
	danger = clampf(p_danger, 0.0, 1.0)
	max_health = roundi(float(DEFS[kind]["health"]) * (1.0 + danger))
	health = max_health
	# Stagger opening shots so clustered turrets do not volley in sync.
	_fire_timer = randf_range(0.4, TURRET_INTERVAL)
	set_physics_process(kind == Kind.TURRET)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_fire_timer = TURRET_INTERVAL
	_fire_at_nearest_target()


## structure.gd's Tower targeting, aimed the other way: the nearest of the
## on-foot player and their trained units inside TURRET_RANGE.
func _fire_at_nearest_target() -> void:
	var nearest: Node2D = null
	var nearest_distance := TURRET_RANGE
	var candidates: Array[Node] = []
	var player := get_tree().get_first_node_in_group("player_on_foot")
	if player != null and player.alive:
		candidates.append(player)
	candidates.append_array(get_tree().get_nodes_in_group("player_units"))
	for candidate in candidates:
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var node := candidate as Node2D
		var distance := global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = node
	if nearest == null:
		return
	var direction := (nearest.global_position - global_position).normalized()
	var bolt := PROJECTILE_SCENE.instantiate()
	bolt.direction = direction
	bolt.damage = 1 + roundi(danger * 2.0)
	bolt.collision_mask = HOSTILE_BOLT_MASK
	bolt.modulate = HOSTILE_BOLT_COLOR
	bolt.position = global_position + direction * 14.0
	get_parent().add_child(bolt)


func take_damage(amount: int, _from_position: Vector2) -> void:
	health -= amount
	Sfx.play_hit(1.1)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -14), str(amount), Color(1.0, 0.85, 0.4))
	modulate = Color(1, 0.35, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	if health <= 0:
		_die()


## Raiding reward: loot scales with the same danger that made the fight hard.
func _die() -> void:
	var loot: Dictionary = DEFS[kind]["loot"]
	for resource_id in loot:
		var amount := roundi(float(loot[resource_id]) * (1.0 + danger))
		var added := Inventory.add(str(resource_id), amount)
		if added > 0:
			FloatingText.spawn(get_parent(), global_position, "+%d %s" % [added, str(resource_id)], Color(0.77, 0.5, 0.24))
	destroyed.emit(self)
	queue_free()


func _draw() -> void:
	match kind:
		Kind.MINER:
			draw_rect(Rect2(-10, -4, 20, 15), Color(0.3, 0.26, 0.3))
			draw_rect(Rect2(-4, -12, 8, 8), Color(0.38, 0.32, 0.36))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 11), Vector2(5, 11), Vector2(0, 15)]), Color(0.9, 0.25, 0.2))
			draw_rect(Rect2(-8, -2, 5, 4), Color(0.95, 0.35, 0.3))
		Kind.TURRET:
			draw_rect(Rect2(-9, -2, 18, 16), Color(0.28, 0.24, 0.28))
			draw_rect(Rect2(-4, -14, 8, 13), Color(0.36, 0.3, 0.34))
			draw_circle(Vector2(0, -14), 5.0, Color(1.0, 0.25, 0.2))
			draw_arc(Vector2(0, -14), TURRET_RANGE, 0.0, TAU, 48, Color(1.0, 0.25, 0.2, 0.1), 1.0)
		Kind.WALL:
			draw_rect(Rect2(-16, -10, 32, 20), Color(0.3, 0.25, 0.28))
			draw_line(Vector2(-16, -3), Vector2(16, -3), Color(0.2, 0.16, 0.18), 1.5)
			draw_line(Vector2(-16, 4), Vector2(16, 4), Color(0.2, 0.16, 0.18), 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(-6, -16), Vector2(-2, -10)]), Color(0.85, 0.3, 0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(2, -10), Vector2(6, -16), Vector2(10, -10)]), Color(0.85, 0.3, 0.25))
