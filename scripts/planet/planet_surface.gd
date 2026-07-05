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

const ENEMY_SCENE := preload("res://scenes/planet/enemy.tscn")
const ENEMY_MIN := 6
const ENEMY_MAX := 10
const ENEMY_MIN_PAD_DISTANCE := 320.0

const STRUCTURE_SCENE := preload("res://scenes/colony/structure.tscn")

## Milestone 11: each new biome's weight table centers on its own exclusive
## resource (obsidian/biomass/crystal/silicate/acid/resin/cryo_ore), so that
## resource never appears anywhere else.
const BIOME_RESOURCE_WEIGHTS: Dictionary[int, Dictionary] = {
	PlanetData.Biome.GRASS: {"plant": 0.5, "ore": 0.3, "scrap": 0.2},
	PlanetData.Biome.DESERT: {"scrap": 0.45, "ore": 0.4, "plant": 0.15},
	PlanetData.Biome.ICE: {"ore": 0.5, "scrap": 0.3, "plant": 0.2},
	PlanetData.Biome.VOLCANIC: {"obsidian": 0.6, "ore": 0.25, "scrap": 0.15},
	PlanetData.Biome.SWAMP: {"biomass": 0.6, "plant": 0.25, "ore": 0.15},
	PlanetData.Biome.CRYSTAL: {"crystal": 0.65, "ore": 0.2, "scrap": 0.15},
	PlanetData.Biome.BARREN: {"silicate": 0.55, "ore": 0.3, "scrap": 0.15},
	PlanetData.Biome.TOXIC: {"acid": 0.6, "scrap": 0.25, "ore": 0.15},
	PlanetData.Biome.FOREST: {"resin": 0.5, "plant": 0.35, "ore": 0.15},
	PlanetData.Biome.TUNDRA: {"cryo_ore": 0.55, "ore": 0.25, "plant": 0.2},
}

@onready var terrain: TileMapLayer = $Terrain
@onready var player: CharacterBody2D = $Player
@onready var landed_ship: Node2D = $LandedShip
@onready var hud: CanvasLayer = $HUD
@onready var ambient_tint: CanvasModulate = $AmbientTint

var data: PlanetData
var pad_position: Vector2
var structure_cells: Dictionary[Vector2i, Node] = {}
var _variants: Array[PackedInt32Array] = []


func _ready() -> void:
	data = GameManager.current_planet_data
	if data == null:
		# Scene was run directly (F6) — make a random planet for testing.
		data = PlanetData.make(randi())
	terrain.tile_set = TileSetBuilder.build()
	ambient_tint.color = PlanetData.ambient_tint_for(data.biome)
	_generate_terrain()
	_place_pad_and_player()
	_load_structures()
	_scatter_resources()
	_spawn_enemies()
	hud.bind_player(player)
	player.died.connect(_on_player_died)
	$BuildController.setup(self, terrain)


func _load_structures() -> void:
	for entry in GameManager.structures_on(data.planet_seed):
		var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		place_structure(int(entry.get("type", 0)), cell, false)


func place_structure(structure_type: int, cell: Vector2i, record: bool) -> void:
	var structure := STRUCTURE_SCENE.instantiate()
	structure.position = terrain.map_to_local(cell)
	add_child(structure)
	structure.setup(structure_type)
	structure_cells[cell] = structure
	if record:
		GameManager.add_structure(data.planet_seed, structure_type, cell)


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
			if not is_placeable(cell) or structure_cells.has(cell):
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


func _spawn_enemies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.planet_seed + 2
	var to_spawn := rng.randi_range(ENEMY_MIN, ENEMY_MAX)
	var attempts := 0
	var spawned := 0
	while spawned < to_spawn and attempts < 400:
		attempts += 1
		var cell := Vector2i(rng.randi_range(3, MAP_SIZE - 4), rng.randi_range(3, MAP_SIZE - 4))
		if not is_placeable(cell):
			continue
		var world := terrain.map_to_local(cell)
		if world.distance_to(pad_position) < ENEMY_MIN_PAD_DISTANCE:
			continue
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = world
		add_child(enemy)
		enemy.setup(data.biome)
		spawned += 1


func _on_player_died() -> void:
	hud.show_game_over()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("respawn") and not player.alive:
		player.respawn(pad_position + Vector2(0, 44))
		hud.hide_game_over()


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
