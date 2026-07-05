class_name TechTree
extends RefCounted
## Research Building tech tree (Milestone 14). General upgrades are always
## purchasable; special upgrades additionally require a Research Building to
## currently sit on a planet in a specific star system type. Unlocks persist
## in GameManager.research.unlocked and never re-lock, even if that building
## is later lost.

const GENERAL: Dictionary[String, Dictionary] = {
	"faster_miners": {
		"name": "Efficient Miners",
		"desc": "Miners produce 35% faster",
		"cost": {"ore": 20, "scrap": 10, "research": 3},
	},
	"stronger_towers": {
		"name": "Tower Armaments",
		"desc": "+2 Defense Tower damage",
		"cost": {"scrap": 16, "alloy": 4, "research": 3},
	},
	"more_cargo": {
		"name": "Bulk Storage",
		"desc": "+25 resource cap",
		"cost": {"ore": 16, "alloy": 3, "research": 3},
	},
	"faster_engines": {
		"name": "Tuned Engines",
		"desc": "+15% fleet-wide ship speed",
		"cost": {"ore": 14, "alloy": 4, "research": 3},
	},
}

## requires_star_type gates the upgrade behind having a Research Building on
## a planet of that StarSystemTypes.Type when unlocking (not just owning it).
const SPECIAL: Dictionary[String, Dictionary] = {
	"nebula_shielding": {
		"name": "Nebula Shielding",
		"desc": "+20 flagship max hull (Nebula systems only)",
		"cost": {"crystal": 10, "alloy": 6, "research": 6},
		"requires_star_type": StarSystemTypes.Type.NEBULA,
	},
	"cryo_hardening": {
		"name": "Cryo Hardening",
		"desc": "+15 flagship max shield (Red Dwarf systems only)",
		"cost": {"cryo_ore": 10, "alloy": 6, "research": 6},
		"requires_star_type": StarSystemTypes.Type.RED_DWARF,
	},
}


static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in GENERAL:
		ids.append(id)
	for id in SPECIAL:
		ids.append(id)
	return ids


static func def_of(id: String) -> Dictionary:
	return GENERAL.get(id, SPECIAL.get(id, {}))


static func is_special(id: String) -> bool:
	return SPECIAL.has(id)


static func is_unlocked(id: String) -> bool:
	return bool(GameManager.research.get("unlocked", {}).get(id, false))


## current_star_type is the system type of the planet the player is standing
## on (-1 if unknown), used only to gate special upgrades at unlock time.
static func can_unlock(id: String, current_star_type: int) -> bool:
	if is_unlocked(id):
		return false
	var def := def_of(id)
	if def.is_empty():
		return false
	if is_special(id) and int(def["requires_star_type"]) != current_star_type:
		return false
	return _can_afford(def["cost"])


static func unlock(id: String, current_star_type: int) -> bool:
	if not can_unlock(id, current_star_type):
		return false
	var cost: Dictionary = def_of(id)["cost"]
	for key in cost:
		if key == "research":
			continue
		Inventory.add(str(key), -int(cost[key]))
	GameManager.research["points"] = float(GameManager.research.get("points", 0.0)) - float(cost.get("research", 0))
	var unlocked: Dictionary = GameManager.research.get("unlocked", {})
	unlocked[id] = true
	GameManager.research["unlocked"] = unlocked
	GameManager.recompute_capacity()
	return true


static func _can_afford(cost: Dictionary) -> bool:
	for key in cost:
		if key == "research":
			if float(GameManager.research.get("points", 0.0)) < float(cost[key]):
				return false
		elif Inventory.count(str(key)) < int(cost[key]):
			return false
	return true


static func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in cost:
		var label := "RP" if key == "research" else str(key)
		parts.append("%d %s" % [int(cost[key]), label])
	return ", ".join(parts)


# -- Gameplay effects --------------------------------------------------------------

static func miner_interval_multiplier() -> float:
	return 0.65 if is_unlocked("faster_miners") else 1.0


static func tower_damage_bonus() -> int:
	return 2 if is_unlocked("stronger_towers") else 0


static func cargo_bonus() -> int:
	return 25 if is_unlocked("more_cargo") else 0


static func engine_speed_bonus() -> float:
	return 0.15 if is_unlocked("faster_engines") else 0.0


static func flagship_hull_bonus() -> float:
	return 20.0 if is_unlocked("nebula_shielding") else 0.0


static func flagship_shield_bonus() -> float:
	return 15.0 if is_unlocked("cryo_hardening") else 0.0
