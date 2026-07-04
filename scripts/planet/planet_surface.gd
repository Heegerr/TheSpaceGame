extends Node2D
## Procedural planet surface: FastNoiseLite-driven 32 px tile terrain generated
## from the planet's seed, with a cleared landing pad, scattered gatherable
## resources, and the on-foot player.

const MAP_SIZE := 80
const VARIANT_LOW := TileSetBuilder.VARIANT_LOW
const VARIANT_GROUND := TileSetBuilder.VARIANT_GROUND
const VARIANT_ALT := TileSetBuilder.VARIANT_ALT
const VARIANT_OBSTACLE := TileSetBuilder.VARIANT_OBSTACLE

const RESOURCE_SCENE := preload("res://scenes/planet/resource_node.tscn")
const RESOURCE_CAP := 80
const RESOURCE_CHANCE := 0.014
const PAD_CLEAR_DISTANCE := 96.0

const BIOME_RESOURCE_WEIGHTS: Dictionary[int, Dictionary] = {
	PlanetData.Biome.GRASS: {"plant": 0.5, "ore": 0.3, "scrap": 0.2},
	PlanetData.Biome.DESERT: {"scrap": 0.45, "ore": 0.4, "plant": 0.15},
	PlanetData.Biome.ICE: {"ore": 0.5, "scrap": 0.3, "plant": 0.2},
}

@onready var terrain: TileMapLayer = $Terrain
@onready var player: CharacterBody2D = $Player
@onready var landed_ship: Node2D = $LandedShip
@onready var hud: CanvasLayer = $HUD

var data: PlanetData
var pad_position: Vector2
var _variants: Array[PackedInt32Array] = []


func _ready() -> void:
	data = GameManager.current_planet_data
	if data == null:
		# Scene was run directly (F6) — make a random planet for testing.
		data = PlanetData.make(randi())
	terrain.tile_set = TileSetBuilder.build()
	_generate_terrain()
	_place_pad_and_player()
	_scatter_resources()


func _generate_terrain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = data.planet_seed
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	_variants.clear()
	for y in MAP_SIZE:
		var row := PackedInt32Array()
		row.resize(MAP_SIZE)
		for x in MAP_SIZE:
			var v := noise.get_noise_2d(x, y)
			var variant := VARIANT_OBSTACLE
			if v < -0.28:
				variant = VARIANT_LOW
			elif v < 0.12:
				variant = VARIANT_GROUND
			elif v < 0.5:
				variant = VARIANT_ALT
			if x < 2 or y < 2 or x >= MAP_SIZE - 2 or y >= MAP_SIZE - 2:
				variant = VARIANT_OBSTACLE
			row[x] = variant
		_variants.append(row)

	var spawn := _find_spawn_cell()
	for y in range(spawn.y - 3, spawn.y + 4):
		for x in range(spawn.x - 3, spawn.x + 4):
			_variants[y][x] = VARIANT_GROUND

	for y in MAP_SIZE:
		for x in MAP_SIZE:
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(_variants[y][x], data.biome))
	pad_position = terrain.map_to_local(spawn)


func _find_spawn_cell() -> Vector2i:
	var center := Vector2i(MAP_SIZE / 2, MAP_SIZE / 2)
	for ring in 25:
		for y in range(center.y - ring, center.y + ring + 1):
			for x in range(center.x - ring, center.x + ring + 1):
				if _area_clear(Vector2i(x, y)):
					return Vector2i(x, y)
	return center


func _area_clear(cell: Vector2i) -> bool:
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x - 2, cell.x + 3):
			if x < 3 or y < 3 or x >= MAP_SIZE - 3 or y >= MAP_SIZE - 3:
				return false
			var variant := _variants[y][x]
			if variant == VARIANT_OBSTACLE or variant == VARIANT_LOW:
				return false
	return true


## True for cells where things (resources, enemies) may be placed.
func is_placeable(cell: Vector2i) -> bool:
	if cell.x < 3 or cell.y < 3 or cell.x >= MAP_SIZE - 3 or cell.y >= MAP_SIZE - 3:
		return false
	var variant := _variants[cell.y][cell.x]
	return variant == VARIANT_GROUND or variant == VARIANT_ALT


func _place_pad_and_player() -> void:
	landed_ship.position = pad_position
	player.position = pad_position + Vector2(0, 44)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_SIZE * 32
	camera.limit_bottom = MAP_SIZE * 32
	camera.reset_smoothing()


func _scatter_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.planet_seed + 1
	var weights: Dictionary = BIOME_RESOURCE_WEIGHTS[data.biome]
	var placed := 0
	for y in MAP_SIZE:
		for x in MAP_SIZE:
			if placed >= RESOURCE_CAP:
				return
			var cell := Vector2i(x, y)
			if not is_placeable(cell):
				continue
			if rng.randf() > RESOURCE_CHANCE:
				continue
			var world := terrain.map_to_local(cell)
			if world.distance_to(pad_position) < PAD_CLEAR_DISTANCE:
				continue
			var node := RESOURCE_SCENE.instantiate()
			node.position = world + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0))
			add_child(node)
			node.setup(_pick_weighted(rng, weights))
			placed += 1


func _pick_weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var roll := rng.randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return "ore"
