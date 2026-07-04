class_name ShipUpgrades
extends RefCounted
## Ship upgrade definitions and purchase logic. Tiers live in
## GameManager.ship_upgrades (saved per slot); costs come from the Inventory.

const MAX_TIER := 3
const MAX_FLEET := 3
const ESCORT_COST: Dictionary = {"ore": 30, "alloy": 4}

const DEFS: Dictionary[String, Dictionary] = {
	"engine": {
		"name": "Engine",
		"desc": "+20% thrust and speed per tier",
		"costs": [{"ore": 10}, {"ore": 15, "alloy": 2}, {"alloy": 5, "scrap": 10}],
	},
	"hull": {
		"name": "Hull",
		"desc": "+25 hull per tier (space combat)",
		"costs": [{"ore": 12}, {"scrap": 10, "ore": 10}, {"alloy": 6}],
	},
	"weapon": {
		"name": "Weapons",
		"desc": "+1 ship weapon damage per tier",
		"costs": [{"scrap": 8}, {"ore": 12, "scrap": 8}, {"alloy": 6, "scrap": 6}],
	},
	"cargo": {
		"name": "Cargo",
		"desc": "+25 resource cap per tier",
		"costs": [{"plant": 8, "ore": 6}, {"scrap": 12}, {"alloy": 4, "ore": 10}],
	},
}


static func tier(category: String) -> int:
	return int(GameManager.ship_upgrades.get(category, 0))


## Cost of the next tier, or {} when already maxed.
static func next_cost(category: String) -> Dictionary:
	var current := tier(category)
	if current >= MAX_TIER:
		return {}
	return DEFS[category]["costs"][current]


static func can_afford_cost(cost: Dictionary) -> bool:
	for resource_id in cost:
		if Inventory.count(resource_id) < int(cost[resource_id]):
			return false
	return true


static func buy(category: String) -> bool:
	var cost := next_cost(category)
	if cost.is_empty() or not can_afford_cost(cost):
		return false
	for resource_id in cost:
		Inventory.add(resource_id, -int(cost[resource_id]))
	GameManager.ship_upgrades[category] = tier(category) + 1
	GameManager.recompute_capacity()
	return true


static func buy_escort() -> bool:
	if GameManager.fleet_size >= MAX_FLEET or not can_afford_cost(ESCORT_COST):
		return false
	for resource_id in ESCORT_COST:
		Inventory.add(resource_id, -int(ESCORT_COST[resource_id]))
	GameManager.fleet_size += 1
	return true


static func speed_multiplier() -> float:
	return 1.0 + 0.2 * tier("engine")


static func hull_bonus() -> int:
	return 25 * tier("hull")


static func weapon_bonus() -> int:
	return tier("weapon")
