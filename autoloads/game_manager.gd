extends Node
## Global game flow singleton, registered as the "GameManager" autoload.
##
## Owns the galaxy seed, the space<->surface scene flow, the per-planet colony
## registry, and slot-based save/load. Resource counts live in the Inventory
## autoload (loaded before this one).

signal planet_changed(planet_name: String)
signal game_saved
signal game_loaded

const SAVE_VERSION := 3
const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SPACE_SCENE := "res://scenes/space/space.tscn"
const SURFACE_SCENE := "res://scenes/planet/planet_surface.tscn"

const StructureScript := preload("res://scripts/colony/structure.gd")

## Active save slot (0-based). -1 = no slot (dev run straight into a scene);
## saving is skipped in that case.
var current_slot := -1

## Seed for the whole galaxy: planet positions and per-planet seeds derive from it.
var galaxy_seed: int = 20260704

## Display name of the planet the player is on. "" means flying in space.
var current_planet := ""

## Full data of the planet the player is on (null in space).
var current_planet_data: PlanetData = null

## Where the ship was left in space: {"position": Vector2, "rotation": float}.
var ship_state: Dictionary = {}

## Per-planet colony data keyed by str(planet_seed):
## {"visited": bool, "structures": [{"type": int, "x": int, "y": int}, ...]}
var planets: Dictionary[String, Dictionary] = {}

## Ship upgrade tiers by category ("engine", "hull", "weapon", "cargo").
var ship_upgrades: Dictionary[String, int] = {}

## Number of AI escort ships owned (spawned alongside the flagship in space).
var fleet_size := 0

## Grid-based ship designs from the Shipyard: Array of {"name": String, "cells": Array}.
## Only the flagship draws bonuses from the active design.
var ship_designs: Array = []

## Index into ship_designs applied to the flagship, or -1 for none.
var active_design_index := -1

## Campaign progress: wave escalation stage, boss completion, infinite mode.
var campaign: Dictionary = {"stage": 0, "completed": false, "infinite": false, "waves_survived": 0, "next_wave_in": 90.0}


# -- Scene flow ----------------------------------------------------------------

func land_on_planet(planet_data: PlanetData, ship: Node2D) -> void:
	current_planet_data = planet_data
	current_planet = planet_data.display_name
	ship_state = {"position": ship.global_position, "rotation": ship.rotation}
	planet_record(planet_data.planet_seed)["visited"] = true
	planet_changed.emit(current_planet)
	save_current()
	var scene := SURFACE_SCENE if planet_data.surface_scene == "" else planet_data.surface_scene
	get_tree().change_scene_to_file.call_deferred(scene)


func return_to_space() -> void:
	current_planet_data = null
	current_planet = ""
	planet_changed.emit(current_planet)
	save_current()
	get_tree().change_scene_to_file.call_deferred(SPACE_SCENE)


func quit_to_menu() -> void:
	save_current()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)


# -- Colony registry -------------------------------------------------------------

func planet_record(p_seed: int) -> Dictionary:
	var key := str(p_seed)
	if not planets.has(key):
		planets[key] = {"visited": false, "structures": []}
	return planets[key]


func structures_on(p_seed: int) -> Array:
	return planet_record(p_seed).get("structures", [])


func add_structure(p_seed: int, structure_type: int, cell: Vector2i) -> void:
	structures_on(p_seed).append({"type": structure_type, "x": cell.x, "y": cell.y})
	recompute_capacity()
	if structure_type == StructureScript.Type.HABITAT and colonized_planet_count() == 1:
		SteamBridge.unlock("first_colony")


func count_structures(structure_type: int) -> int:
	var total := 0
	for key in planets:
		for entry in planets[key].get("structures", []):
			if int(entry.get("type", -1)) == structure_type:
				total += 1
	return total


## A planet counts as colonized once it has a Habitat.
func colonized_planet_count() -> int:
	var total := 0
	for key in planets:
		for entry in planets[key].get("structures", []):
			if int(entry.get("type", -1)) == StructureScript.Type.HABITAT:
				total += 1
				break
	return total


func colonist_capacity() -> int:
	return count_structures(StructureScript.Type.HABITAT) * 2


## Wave-failure penalty: a raided colony loses one random structure.
func remove_random_structure(p_seed: int) -> bool:
	var list := structures_on(p_seed)
	if list.is_empty():
		return false
	list.remove_at(randi_range(0, list.size() - 1))
	recompute_capacity()
	return true


## Storage Silos (+25 each) and cargo upgrades (+25/tier) raise the resource cap.
func recompute_capacity() -> void:
	var bonus := count_structures(StructureScript.Type.SILO) * 25
	bonus += int(ship_upgrades.get("cargo", 0)) * 25
	bonus += int(ShipParts.design_bonus().get("cargo", 0))
	Inventory.set_cap_bonus(bonus)


# -- Save slots -------------------------------------------------------------------

func new_game(slot: int) -> void:
	current_slot = slot
	galaxy_seed = randi() % 1000000000
	current_planet = ""
	current_planet_data = null
	ship_state = {}
	planets = {}
	ship_upgrades = {}
	fleet_size = 0
	ship_designs = []
	active_design_index = -1
	campaign = {"stage": 0, "completed": false, "infinite": false, "waves_survived": 0, "next_wave_in": 90.0}
	Inventory.apply_save_data({})
	Inventory.set_cap_bonus(0)
	save_current()
	get_tree().change_scene_to_file.call_deferred(SPACE_SCENE)


func load_slot(slot: int) -> bool:
	var data := _read_slot(slot)
	if data.is_empty():
		return false
	current_slot = slot
	_apply_save_data(data)
	current_planet = ""
	current_planet_data = null
	game_loaded.emit()
	get_tree().change_scene_to_file.call_deferred(SPACE_SCENE)
	return true


## Loads the most recently saved slot. Returns false if there are no saves.
func continue_game() -> bool:
	var best := -1
	var best_time := -1
	for slot in SLOT_COUNT:
		var meta := slot_meta(slot)
		if meta.get("exists", false) and int(meta.get("unix", 0)) > best_time:
			best_time = int(meta.get("unix", 0))
			best = slot
	if best < 0:
		return false
	return load_slot(best)


func has_any_save() -> bool:
	for slot in SLOT_COUNT:
		if slot_meta(slot).get("exists", false):
			return true
	return false


func slot_meta(slot: int) -> Dictionary:
	var data := _read_slot(slot)
	if data.is_empty():
		return {"exists": false}
	var meta: Variant = data.get("meta", {})
	if not (meta is Dictionary):
		meta = {}
	return {
		"exists": true,
		"colonized": int(meta.get("colonized", 0)),
		"timestamp": str(meta.get("timestamp", "?")),
		"unix": int(meta.get("unix", 0)),
	}


func save_current() -> void:
	if current_slot < 0:
		return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# If we are flying, refresh the ship state before writing.
	var ship := get_tree().get_first_node_in_group("player_ship")
	if ship != null and current_planet == "":
		ship_state = {"position": ship.global_position, "rotation": ship.rotation}
	var file := FileAccess.open(_slot_path(current_slot), FileAccess.WRITE)
	if file == null:
		push_error("GameManager: cannot write save slot %d: %s" % [current_slot, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(_collect_save_data(), "\t"))
	game_saved.emit()


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func _read_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(_slot_path(slot)):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		push_error("GameManager: save slot %d is corrupt, ignoring it" % slot)
		return {}
	return data


func _collect_save_data() -> Dictionary:
	var ship_data := {}
	if not ship_state.is_empty():
		var pos: Vector2 = ship_state.get("position", Vector2.ZERO)
		ship_data = {"x": pos.x, "y": pos.y, "rotation": float(ship_state.get("rotation", 0.0))}
	return {
		"version": SAVE_VERSION,
		"galaxy_seed": galaxy_seed,
		"inventory": Inventory.get_save_data(),
		"planets": planets.duplicate(true),
		"ship_upgrades": ship_upgrades.duplicate(),
		"fleet_size": fleet_size,
		"ship_designs": ship_designs.duplicate(true),
		"active_design_index": active_design_index,
		"campaign": campaign.duplicate(),
		"ship": ship_data,
		"meta": {
			"timestamp": Time.get_datetime_string_from_system(false, true),
			"unix": int(Time.get_unix_time_from_system()),
			"colonized": colonized_planet_count(),
		},
	}


func _apply_save_data(data: Dictionary) -> void:
	galaxy_seed = int(data.get("galaxy_seed", galaxy_seed))

	var saved_inventory: Variant = data.get("inventory", {})
	if saved_inventory is Dictionary:
		Inventory.apply_save_data(saved_inventory)

	planets = {}
	var saved_planets: Variant = data.get("planets", {})
	if saved_planets is Dictionary:
		for key in saved_planets:
			if saved_planets[key] is Dictionary:
				planets[str(key)] = saved_planets[key]

	ship_upgrades = {}
	var saved_upgrades: Variant = data.get("ship_upgrades", {})
	if saved_upgrades is Dictionary:
		for key in saved_upgrades:
			ship_upgrades[str(key)] = int(saved_upgrades[key])

	fleet_size = int(data.get("fleet_size", 0))

	ship_designs = []
	var saved_designs: Variant = data.get("ship_designs", [])
	if saved_designs is Array:
		for design in saved_designs:
			if design is Dictionary:
				ship_designs.append(design)
	active_design_index = int(data.get("active_design_index", -1))

	var saved_campaign: Variant = data.get("campaign", {})
	if saved_campaign is Dictionary:
		for key in campaign:
			if saved_campaign.has(key):
				campaign[key] = saved_campaign[key]

	ship_state = {}
	var saved_ship: Variant = data.get("ship", {})
	if saved_ship is Dictionary and saved_ship.has("x"):
		ship_state = {
			"position": Vector2(float(saved_ship.get("x", 0.0)), float(saved_ship.get("y", 0.0))),
			"rotation": float(saved_ship.get("rotation", 0.0)),
		}

	recompute_capacity()
