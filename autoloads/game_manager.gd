extends Node
## Global game state singleton, registered as the "GameManager" autoload.
##
## Access it from any script:
##   GameManager.set_current_planet("kepler_prime")
##   GameManager.add_resource("ore", 5)
##   GameManager.save_game()

signal planet_changed(planet_id: String)
signal resource_changed(resource_id: String, new_amount: int)
signal game_saved
signal game_loaded

const SAVE_PATH := "user://save_game.json"
const SAVE_VERSION := 1

## Id of the planet the player is currently on or orbiting. "" means deep space.
var current_planet: String = ""

## Player resources keyed by id. Add new resource types here as the game grows.
var resources: Dictionary[String, int] = {
	"fuel": 100,
	"ore": 0,
	"credits": 0,
}


func set_current_planet(planet_id: String) -> void:
	if planet_id == current_planet:
		return
	current_planet = planet_id
	planet_changed.emit(current_planet)


func get_resource(resource_id: String) -> int:
	return int(resources.get(resource_id, 0))


func add_resource(resource_id: String, amount: int) -> void:
	resources[resource_id] = get_resource(resource_id) + amount
	resource_changed.emit(resource_id, resources[resource_id])


## Deducts the cost and returns true, or returns false if the player can't afford it.
func try_spend_resource(resource_id: String, amount: int) -> bool:
	if get_resource(resource_id) < amount:
		return false
	add_resource(resource_id, -amount)
	return true


# Save / load ------------------------------------------------------------------
# Placeholder implementation: a single JSON file in user://. Replace with save
# slots, versioned migration, etc. later without touching any callers.

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameManager: cannot write save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(_collect_save_data(), "\t"))
	game_saved.emit()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameManager: cannot read save file: %s" % error_string(FileAccess.get_open_error()))
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		push_error("GameManager: save file is corrupt, ignoring it")
		return false
	_apply_save_data(data)
	game_loaded.emit()
	return true


## Everything that should persist belongs in this dictionary.
func _collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_planet": current_planet,
		"resources": resources.duplicate(),
	}


func _apply_save_data(data: Dictionary) -> void:
	current_planet = str(data.get("current_planet", ""))
	resources.clear()
	var saved_resources: Variant = data.get("resources", {})
	if saved_resources is Dictionary:
		for resource_id in saved_resources:
			resources[str(resource_id)] = int(saved_resources[resource_id])
	planet_changed.emit(current_planet)
	for resource_id in resources:
		resource_changed.emit(resource_id, resources[resource_id])
