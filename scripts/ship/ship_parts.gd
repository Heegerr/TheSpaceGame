class_name ShipParts
extends RefCounted
## Grid-based ship part definitions for the Shipyard (Milestone 7). A design
## is a set of {x, y, part} cells on a GRID_SIZE x GRID_SIZE grid; exactly one
## HULL_CORE and at least one ENGINE are required, and every part must be
## 4-connected to the core so the layout reads as one physical ship.
## Bonuses from the active design (GameManager.ship_designs) stack additively
## on top of ShipUpgrades tiers, applied only to the flagship.

enum Part { HULL_CORE, HULL_SECTION, ENGINE, WEAPON, CARGO_POD }

const GRID_SIZE := 7

const DEFS: Dictionary[int, Dictionary] = {
	Part.HULL_CORE: {
		"name": "Hull Core", "glyph": "C", "color": Color(0.85, 0.87, 0.92),
		"cost": {}, "hull": 10, "speed": 0.0, "damage": 0, "cargo": 0,
	},
	Part.HULL_SECTION: {
		"name": "Hull Section", "glyph": "H", "color": Color(0.55, 0.58, 0.66),
		"cost": {"ore": 6, "scrap": 2}, "hull": 15, "speed": 0.0, "damage": 0, "cargo": 0,
	},
	Part.ENGINE: {
		"name": "Engine", "glyph": "E", "color": Color(1.0, 0.65, 0.3),
		"cost": {"ore": 8, "alloy": 1}, "hull": 0, "speed": 0.12, "damage": 0, "cargo": 0,
	},
	Part.WEAPON: {
		"name": "Weapon", "glyph": "W", "color": Color(0.9, 0.35, 0.35),
		"cost": {"scrap": 6, "alloy": 1}, "hull": 0, "speed": 0.0, "damage": 1, "cargo": 0,
	},
	Part.CARGO_POD: {
		"name": "Cargo Pod", "glyph": "P", "color": Color(0.5, 0.75, 0.55),
		"cost": {"plant": 4, "ore": 4}, "hull": 0, "speed": 0.0, "damage": 0, "cargo": 15,
	},
}

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func cost_of(part: int) -> Dictionary:
	return DEFS[part]["cost"]


static func cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "free"
	var parts: PackedStringArray = []
	for resource_id in cost:
		parts.append("%d %s" % [int(cost[resource_id]), resource_id])
	return ", ".join(parts)


static func can_afford_cost(cost: Dictionary) -> bool:
	for resource_id in cost:
		if Inventory.count(resource_id) < int(cost[resource_id]):
			return false
	return true


static func total_cost(cells: Dictionary) -> Dictionary:
	var total: Dictionary = {}
	for pos in cells:
		var part: int = cells[pos]
		if not DEFS.has(part):
			continue
		var cost: Dictionary = DEFS[part]["cost"]
		for resource_id in cost:
			total[resource_id] = int(total.get(resource_id, 0)) + int(cost[resource_id])
	return total


static func totals_of(cells: Dictionary) -> Dictionary:
	var hull := 0
	var speed := 0.0
	var damage := 0
	var cargo := 0
	for pos in cells:
		var part: int = cells[pos]
		if not DEFS.has(part):
			continue
		var def: Dictionary = DEFS[part]
		hull += int(def["hull"])
		speed += float(def["speed"])
		damage += int(def["damage"])
		cargo += int(def["cargo"])
	return {"hull": hull, "speed": speed, "damage": damage, "cargo": cargo}


## Exactly one HULL_CORE, at least one ENGINE, and every cell 4-connected to the core.
static func validate(cells: Dictionary) -> Dictionary:
	var core_pos := Vector2i(-999, -999)
	var core_count := 0
	var engine_count := 0
	for pos in cells:
		var part: int = cells[pos]
		if part == Part.HULL_CORE:
			core_count += 1
			core_pos = pos
		elif part == Part.ENGINE:
			engine_count += 1
	if core_count != 1:
		return {"valid": false, "error": "Needs exactly one Hull Core"}
	if engine_count < 1:
		return {"valid": false, "error": "Needs at least one Engine"}
	var visited := {core_pos: true}
	var queue: Array[Vector2i] = [core_pos]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		for offset in NEIGHBORS:
			var neighbor := current + offset
			if cells.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	if visited.size() != cells.size():
		return {"valid": false, "error": "All parts must connect to the Hull Core"}
	return {"valid": true, "error": ""}


static func cells_to_array(cells: Dictionary) -> Array:
	var out: Array = []
	for pos in cells:
		out.append({"x": pos.x, "y": pos.y, "part": cells[pos]})
	return out


## Raw {x, y, part} cell entries of the active saved design, or [] if none.
static func active_design_cells() -> Array:
	if GameManager.active_design_index < 0 or GameManager.active_design_index >= GameManager.ship_designs.size():
		return []
	var design: Dictionary = GameManager.ship_designs[GameManager.active_design_index]
	return design.get("cells", [])


## Additive {hull, speed, damage, cargo} bonus from the active design.
static func design_bonus() -> Dictionary:
	var cells: Dictionary = {}
	for entry in active_design_cells():
		cells[Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))] = int(entry.get("part", -1))
	return totals_of(cells)
