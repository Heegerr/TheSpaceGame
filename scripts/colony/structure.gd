extends StaticBody2D
## A placed colony structure on a planet surface. One scene handles all types;
## DEFS is the single source of truth for names, costs, and descriptions.
## Production (Miner/Refinery) only ticks while the player is on the planet —
## offline/background production is a future feature.

enum Type { HABITAT, MINER, REFINERY, SILO }

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
}

const MINER_INTERVAL := 10.0
const REFINERY_INTERVAL := 12.0

var type := Type.HABITAT

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
			production_timer.start(MINER_INTERVAL)
		Type.REFINERY:
			production_timer.timeout.connect(_on_production)
			production_timer.start(REFINERY_INTERVAL)


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
