extends Node
## Autoload "Inventory": resource counts the player carries. Persists across
## scene changes because it lives on an autoload, and is serialized into the
## save file by GameManager. Each resource is capped; Storage Silos and cargo
## upgrades raise the cap via set_cap_bonus().

signal changed(resource_id: String, new_amount: int)

const RESOURCE_TYPES: Array[String] = [
	"ore", "plant", "scrap", "alloy",
	"obsidian", "biomass", "crystal", "silicate", "acid", "resin", "cryo_ore",
]
const BASE_CAP := 50

var _counts: Dictionary[String, int] = {}
var _cap_bonus := 0


func _ready() -> void:
	for resource_id in RESOURCE_TYPES:
		if not _counts.has(resource_id):
			_counts[resource_id] = 0


func cap() -> int:
	return BASE_CAP + _cap_bonus


func set_cap_bonus(bonus: int) -> void:
	if _cap_bonus == bonus:
		return
	_cap_bonus = bonus
	for resource_id in _counts:
		changed.emit(resource_id, _counts[resource_id])


func count(resource_id: String) -> int:
	return int(_counts.get(resource_id, 0))


## Returns the amount actually added (may be less than requested if the cap
## was hit - see resource_node.gd, which surfaces that as "capped" feedback).
func add(resource_id: String, amount: int) -> int:
	var before := count(resource_id)
	_counts[resource_id] = clampi(before + amount, 0, cap())
	changed.emit(resource_id, _counts[resource_id])
	return _counts[resource_id] - before


func is_full(resource_id: String) -> bool:
	return count(resource_id) >= cap()


func try_spend(resource_id: String, amount: int) -> bool:
	if count(resource_id) < amount:
		return false
	add(resource_id, -amount)
	return true


func get_save_data() -> Dictionary:
	return _counts.duplicate()


func apply_save_data(data: Dictionary) -> void:
	_counts.clear()
	for resource_id in RESOURCE_TYPES:
		_counts[resource_id] = 0
	for resource_id in data:
		_counts[str(resource_id)] = int(data[resource_id])
	for resource_id in _counts:
		changed.emit(resource_id, _counts[resource_id])
