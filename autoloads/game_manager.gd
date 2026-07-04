extends Node
## Global game flow singleton, registered as the "GameManager" autoload.
##
## Owns the galaxy seed, the space<->surface scene flow, and save/load.

signal planet_changed(planet_name: String)
signal resource_changed(resource_id: String, new_amount: int)
signal game_saved
signal game_loaded

const SAVE_PATH := "user://save_game.json"
const SAVE_VERSION := 1
const SPACE_SCENE := "res://scenes/space/space.tscn"
const SURFACE_SCENE := "res://scenes/planet/planet_surface.tscn"

## Seed for the whole galaxy: planet positions and per-planet seeds derive from it.
var galaxy_seed: int = 20260704

## Display name of the planet the player is on. "" means flying in space.
var current_planet: String = ""

## Full data of the planet the player is on (null in space).
var current_planet_data: PlanetData = null

## Where the ship was left in space, so returning from a planet restores it.
var ship_state: Dictionary = {}

## Player resources keyed by id. (Replaced by the Inventory autoload in Phase 3.)
var resources: Dictionary[String, int] = {
	"fuel": 100,
	"ore": 0,
	"credits": 0,
}


# -- Scene flow ----------------------------------------------------------------

func land_on_planet(planet_data: PlanetData, ship: Node2D) -> void:
	current_planet_data = planet_data
	current_planet = planet_data.display_name
	ship_state = {"position": ship.global_position, "rotation": ship.rotation}
	planet_changed.emit(current_planet)
	get_tree().change_scene_to_file.call_deferred(SURFACE_SCENE)


func return_to_space() -> void:
	current_planet_data = null
	current_planet = ""
	planet_changed.emit(current_planet)
	get_tree().change_scene_to_file.call_deferred(SPACE_SCENE)


# -- Resources (placeholder until the Inventory autoload lands) ------------------

func get_resource(resource_id: String) -> int:
	return int(resources.get(resource_id, 0))


func add_resource(resource_id: String, amount: int) -> void:
	resources[resource_id] = get_resource(resource_id) + amount
	resource_changed.emit(resource_id, resources[resource_id])


func try_spend_resource(resource_id: String, amount: int) -> bool:
	if get_resource(resource_id) < amount:
		return false
	add_resource(resource_id, -amount)
	return true


# -- Save / load -----------------------------------------------------------------

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


func _collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"galaxy_seed": galaxy_seed,
		"resources": resources.duplicate(),
	}


func _apply_save_data(data: Dictionary) -> void:
	galaxy_seed = int(data.get("galaxy_seed", galaxy_seed))
	var saved_resources: Variant = data.get("resources", {})
	if saved_resources is Dictionary:
		resources.clear()
		for resource_id in saved_resources:
			resources[str(resource_id)] = int(saved_resources[resource_id])
	for resource_id in resources:
		resource_changed.emit(resource_id, resources[resource_id])
