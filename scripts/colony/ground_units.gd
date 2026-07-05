class_name GroundUnits
extends RefCounted
## Trainable Barracks unit definitions (Milestone 16): a balanced Soldier, a
## slow tanky Heavy, and a ranged Ranger. Stats drive ally_unit.gd directly.

const DEFS: Dictionary[String, Dictionary] = {
	"soldier": {
		"name": "Soldier",
		"desc": "Balanced melee fighter",
		"cost": {"ore": 10, "scrap": 4},
		"train_time": 12.0,
		"health": 8, "speed": 70.0, "damage": 2,
		"range": 20.0, "aggro_range": 160.0, "cooldown": 0.8,
		"ranged": false, "color": Color(0.4, 0.7, 0.9),
	},
	"heavy": {
		"name": "Heavy",
		"desc": "Slow, tanky brawler",
		"cost": {"ore": 18, "scrap": 10, "alloy": 2},
		"train_time": 20.0,
		"health": 18, "speed": 45.0, "damage": 4,
		"range": 22.0, "aggro_range": 150.0, "cooldown": 1.1,
		"ranged": false, "color": Color(0.55, 0.45, 0.35),
	},
	"ranger": {
		"name": "Ranger",
		"desc": "Fires from a distance",
		"cost": {"ore": 12, "scrap": 8},
		"train_time": 16.0,
		"health": 6, "speed": 65.0, "damage": 1,
		"range": 130.0, "aggro_range": 200.0, "cooldown": 1.0,
		"ranged": true, "color": Color(0.5, 0.85, 0.55),
	},
}


static func cost_of(id: String) -> Dictionary:
	return DEFS[id]["cost"]


static func can_afford(id: String) -> bool:
	var cost := cost_of(id)
	for resource_id in cost:
		if Inventory.count(resource_id) < int(cost[resource_id]):
			return false
	return true


static func pay_cost(id: String) -> bool:
	if not can_afford(id):
		return false
	var cost := cost_of(id)
	for resource_id in cost:
		Inventory.add(resource_id, -int(cost[resource_id]))
	return true
