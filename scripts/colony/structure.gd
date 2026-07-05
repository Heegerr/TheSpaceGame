extends StaticBody2D
## A placed colony structure on a planet surface. One scene handles all types;
## DEFS is the single source of truth for names, costs, and descriptions.
## Production (Miner/Refinery) only ticks while the player is on the planet —
## offline/background production is a future feature. Milestone 13 adds
## defense structures: Tower (auto-fires the existing projectile at nearby
## enemies), Wall (a solid blocker - like every structure here it already sits
## on the "world" physics layer, so enemy CharacterBody2D collision already
## respects it with no pathfinding changes needed), and Gate (a togglable
## wall the player can open/close via a child interact hotspot).

enum Type { HABITAT, MINER, REFINERY, SILO, TOWER, WALL, GATE, RESEARCH, STORAGE_1, STORAGE_2, STORAGE_3 }

const DEFS: Dictionary[int, Dictionary] = {
	Type.HABITAT: {
		"name": "Habitat",
		"desc": "+2 colonist capacity",
		"cost": {"plant": 6, "ore": 4},
	},
	Type.MINER: {
		"name": "Miner",
		"desc": "+1 Ore / 10s",
		"cost": {"ore": 8, "scrap": 2},
	},
	Type.REFINERY: {
		"name": "Refinery",
		"desc": "3 Ore -> 1 Alloy / 12s",
		"cost": {"scrap": 6, "ore": 4},
	},
	Type.SILO: {
		"name": "Storage Silo",
		"desc": "+25 resource cap",
		"cost": {"ore": 4, "scrap": 4},
	},
	Type.TOWER: {
		"name": "Defense Tower",
		"desc": "Auto-fires at nearby enemies",
		"cost": {"ore": 10, "scrap": 6},
	},
	Type.WALL: {
		"name": "Wall",
		"desc": "Blocks enemy movement",
		"cost": {"ore": 3, "scrap": 1},
	},
	Type.GATE: {
		"name": "Gate",
		"desc": "Togglable wall - E to open/close",
		"cost": {"ore": 5, "scrap": 2},
	},
	Type.RESEARCH: {
		"name": "Research Building",
		"desc": "Generates research points - E for tech tree",
		"cost": {"ore": 12, "alloy": 3, "scrap": 6},
	},
	Type.STORAGE_1: {
		"name": "Storage I",
		"desc": "+40 resource cap",
		"cost": {"ore": 8, "scrap": 6},
	},
	Type.STORAGE_2: {
		"name": "Storage II",
		"desc": "+70 resource cap",
		"cost": {"ore": 16, "scrap": 10, "alloy": 3},
	},
	Type.STORAGE_3: {
		"name": "Storage III",
		"desc": "+110 resource cap",
		"cost": {"ore": 26, "scrap": 16, "alloy": 8},
	},
}

const MINER_INTERVAL := 10.0
const REFINERY_INTERVAL := 12.0
const TOWER_INTERVAL := 1.1
const TOWER_RANGE := 170.0
const TOWER_DAMAGE := 2
const RESEARCH_INTERVAL := 8.0
const RESEARCH_YIELD := 1.0

const PROJECTILE_SCENE := preload("res://scenes/planet/projectile.tscn")

var type := Type.HABITAT
## Gate only: true = collision lifted (player and enemies can both pass).
var gate_open := false

@onready var production_timer: Timer = $ProductionTimer


static func display_name(structure_type: int) -> String:
	return str(DEFS[structure_type]["name"])


static func cost_of(structure_type: int) -> Dictionary:
	return DEFS[structure_type]["cost"]


static func can_afford(structure_type: int) -> bool:
	var cost := cost_of(structure_type)
	for resource_id in cost:
		if Inventory.count(resource_id) < int(cost[resource_id]):
			return false
	return true


static func pay_cost(structure_type: int) -> bool:
	if not can_afford(structure_type):
		return false
	var cost := cost_of(structure_type)
	for resource_id in cost:
		Inventory.add(resource_id, -int(cost[resource_id]))
	return true


func setup(structure_type: int) -> void:
	type = structure_type
	queue_redraw()
	match type:
		Type.MINER:
			production_timer.timeout.connect(_on_production)
			production_timer.start(MINER_INTERVAL * TechTree.miner_interval_multiplier())
		Type.REFINERY:
			production_timer.timeout.connect(_on_production)
			production_timer.start(REFINERY_INTERVAL)
		Type.TOWER:
			production_timer.timeout.connect(_on_production)
			production_timer.start(TOWER_INTERVAL)
		Type.RESEARCH:
			production_timer.timeout.connect(_on_production)
			production_timer.start(RESEARCH_INTERVAL)
			_add_interact_area(ResearchInteract.new())
		Type.GATE:
			var gate_area := GateInteract.new()
			gate_area.gate = self
			_add_interact_area(gate_area)


func _add_interact_area(area: Area2D) -> void:
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)


func toggle_gate() -> void:
	gate_open = not gate_open
	collision_layer = 0 if gate_open else 1
	queue_redraw()


func _on_production() -> void:
	match type:
		Type.MINER:
			if Inventory.count("ore") < Inventory.cap():
				Inventory.add("ore", 1)
				FloatingText.spawn(get_parent(), global_position + Vector2(0, -18), "+1 Ore", Color(0.44, 0.89, 0.91))
		Type.REFINERY:
			if Inventory.count("alloy") < Inventory.cap() and Inventory.try_spend("ore", 3):
				Inventory.add("alloy", 1)
				FloatingText.spawn(get_parent(), global_position + Vector2(0, -18), "+1 Alloy", Color(0.85, 0.55, 0.95))
		Type.TOWER:
			_fire_at_nearest_enemy()
		Type.RESEARCH:
			GameManager.research["points"] = float(GameManager.research.get("points", 0.0)) + RESEARCH_YIELD
			FloatingText.spawn(get_parent(), global_position + Vector2(0, -18), "+1 RP", Color(0.6, 0.85, 1.0))


func _fire_at_nearest_enemy() -> void:
	var nearest: Node2D = null
	var nearest_distance := TOWER_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest == null:
		return
	var direction := (nearest.global_position - global_position).normalized()
	var bolt := PROJECTILE_SCENE.instantiate()
	bolt.direction = direction
	bolt.damage = TOWER_DAMAGE + TechTree.tower_damage_bonus()
	bolt.position = global_position + direction * 14.0
	get_parent().add_child(bolt)


func _draw() -> void:
	match type:
		Type.HABITAT:
			var dome := PackedVector2Array()
			for i in 9:
				var angle := PI + i * PI / 8.0
				dome.append(Vector2(2, 3) + Vector2(cos(angle), sin(angle)) * 11.0 - Vector2(2, 0))
			draw_rect(Rect2(-12, 3, 24, 8), Color(0.55, 0.58, 0.66))
			draw_colored_polygon(dome, Color(0.72, 0.76, 0.85))
			draw_rect(Rect2(-3, -2, 6, 5), Color(1.0, 0.85, 0.45))
		Type.MINER:
			draw_rect(Rect2(-10, -4, 20, 15), Color(0.5, 0.52, 0.58))
			draw_rect(Rect2(-4, -12, 8, 8), Color(0.62, 0.64, 0.7))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 11), Vector2(5, 11), Vector2(0, 15)]), Color(0.95, 0.6, 0.2))
			draw_rect(Rect2(-8, -2, 5, 4), Color(0.44, 0.89, 0.91))
		Type.REFINERY:
			draw_rect(Rect2(-12, -4, 15, 15), Color(0.56, 0.5, 0.6))
			draw_rect(Rect2(3, 1, 9, 10), Color(0.48, 0.42, 0.52))
			draw_rect(Rect2(5, -12, 4, 13), Color(0.4, 0.36, 0.44))
			draw_rect(Rect2(-9, 2, 6, 9), Color(0.85, 0.55, 0.95))
		Type.SILO:
			draw_rect(Rect2(-8, -12, 16, 24), Color(0.75, 0.72, 0.62))
			draw_circle(Vector2(0, -12), 8.0, Color(0.85, 0.82, 0.72))
			draw_line(Vector2(-8, -4), Vector2(8, -4), Color(0.6, 0.57, 0.48), 1.5)
			draw_line(Vector2(-8, 4), Vector2(8, 4), Color(0.6, 0.57, 0.48), 1.5)
		Type.TOWER:
			draw_rect(Rect2(-9, -2, 18, 16), Color(0.42, 0.44, 0.5))
			draw_rect(Rect2(-4, -14, 8, 13), Color(0.55, 0.58, 0.65))
			draw_circle(Vector2(0, -14), 5.0, Color(0.88, 0.32, 0.3))
			draw_arc(Vector2(0, -14), TOWER_RANGE, 0.0, TAU, 48, Color(0.88, 0.32, 0.3, 0.12), 1.0)
		Type.WALL:
			draw_rect(Rect2(-16, -10, 32, 20), Color(0.46, 0.44, 0.4))
			draw_line(Vector2(-16, -3), Vector2(16, -3), Color(0.34, 0.32, 0.29), 1.5)
			draw_line(Vector2(-16, 4), Vector2(16, 4), Color(0.34, 0.32, 0.29), 1.5)
		Type.GATE:
			var gate_color := Color(0.5, 0.62, 0.4) if gate_open else Color(0.55, 0.45, 0.32)
			draw_rect(Rect2(-16, -12, 6, 24), Color(0.4, 0.38, 0.34))
			draw_rect(Rect2(10, -12, 6, 24), Color(0.4, 0.38, 0.34))
			if not gate_open:
				draw_rect(Rect2(-10, -8, 20, 16), gate_color)
			else:
				draw_rect(Rect2(-10, -8, 20, 16), gate_color, false, 1.5)
		Type.RESEARCH:
			draw_rect(Rect2(-11, -2, 22, 14), Color(0.4, 0.44, 0.55))
			draw_circle(Vector2(0, -8), 9.0, Color(0.5, 0.6, 0.78))
			draw_arc(Vector2(0, -8), 9.0, PI, TAU, 16, Color(0.6, 0.85, 1.0), 1.5)
			draw_line(Vector2(0, -17), Vector2(0, -24), Color(0.6, 0.85, 1.0), 1.5)
			draw_circle(Vector2(0, -24), 2.0, Color(0.7, 0.95, 1.0))
		Type.STORAGE_1, Type.STORAGE_2, Type.STORAGE_3:
			_draw_storage(type - Type.STORAGE_1 + 1)


func _draw_storage(tier: int) -> void:
	var half_width := 9.0 + tier * 2.0
	var height := 18.0 + tier * 4.0
	var crate := Color(0.62, 0.5, 0.34)
	draw_rect(Rect2(-half_width, -height, half_width * 2.0, height), crate)
	draw_rect(Rect2(-half_width, -height, half_width * 2.0, height), crate.darkened(0.3), false, 1.5)
	for band in tier:
		var y := -height + 4.0 + band * (height - 8.0) / maxf(1.0, float(tier))
		draw_line(Vector2(-half_width, y), Vector2(half_width, y), crate.darkened(0.4), 1.0)
