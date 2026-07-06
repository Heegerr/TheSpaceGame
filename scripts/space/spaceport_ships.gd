class_name SpaceportShips
extends RefCounted
## Spaceport-trainable ship kinds (Milestone 17): a fast Interceptor, a heavy
## Gunship, and a Support Ship that repairs nearby fleet ships instead of
## fighting. Stat multipliers apply on top of player_ship.gd's base stats via
## PlayerShip.apply_spaceport_kind(); role "support" flips off attacking.

const DEFS: Dictionary[String, Dictionary] = {
	"interceptor": {
		"name": "Interceptor",
		"desc": "Fast, fragile striker",
		"cost": {"ore": 14, "alloy": 2},
		"build_time": 18.0,
		"speed_mult": 1.3, "hull_mult": 0.7, "damage_mult": 1.1,
		"role": "combat",
	},
	"gunship": {
		"name": "Gunship",
		"desc": "Slow, heavily armed and armored",
		"cost": {"ore": 22, "scrap": 10, "alloy": 4},
		"build_time": 26.0,
		"speed_mult": 0.75, "hull_mult": 1.6, "damage_mult": 1.6,
		"role": "combat",
	},
	"support": {
		"name": "Support Ship",
		"desc": "Repairs nearby fleet ships instead of fighting",
		"cost": {"ore": 16, "alloy": 5},
		"build_time": 22.0,
		"speed_mult": 0.9, "hull_mult": 1.0, "damage_mult": 0.0,
		"role": "support",
	},
}


static func cost_of(id: String) -> Dictionary:
	return DEFS[id]["cost"]


static func can_afford(id: String) -> bool:
	# TODO: REMOVE BEFORE RELEASE - debug god mode builds ships for free.
	if GameManager.debug_god_mode:
		return true
	var cost := cost_of(id)
	for resource_id in cost:
		if Inventory.count(resource_id) < int(cost[resource_id]):
			return false
	return true


static func pay_cost(id: String) -> bool:
	# TODO: REMOVE BEFORE RELEASE - debug god mode builds ships for free.
	if GameManager.debug_god_mode:
		return true
	if not can_afford(id):
		return false
	var cost := cost_of(id)
	for resource_id in cost:
		Inventory.add(resource_id, -int(cost[resource_id]))
	return true
