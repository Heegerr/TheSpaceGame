extends Node
## Autoload "Inventory": resource counts the player carries. Persists across
## scene changes because it lives on an autoload, and is serialized into the
## save file by GameManager.

signal changed(resource_id: String, new_amount: int)

const RESOURCE_TYPES: Array[String] = ["ore", "plant", "scrap"]

var _counts: Dictionary[String, int] = {}


func _ready() -> void:
	for resource_id in RESOURCE_TYPES:
		if not _counts.has(resource_id):
			_counts[resource_id] = 0


func count(resource_id: String) -> int:
	return int(_counts.get(resource_id, 0))


func add(resource_id: String, amount: int) -> void:
	_counts[resource_id] = count(resource_id) + amount
	changed.emit(resource_id, _counts[resource_id])


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
