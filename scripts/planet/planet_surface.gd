extends Node2D
## Procedural planet surface: FastNoiseLite-driven 32 px tile terrain generated
## from the planet's seed, with a cleared landing pad, scattered gatherable
## resources, and the on-foot player. Difficulty scales with the planet's
## distance-based danger (PlanetData.danger): more and tougher aliens, and
## past PlanetData.COLONY_DANGER_THRESHOLD, seeded enemy colonies.

## Tile dimensions of the square surface. 140 (was 80) roughly triples the
## explorable area; generation stays a single one-time pass (~19.6k set_cell
## calls) and TileMapLayer only renders visible tiles, so both load time and
## runtime cost remain comfortable.
const MAP_SIZE := 140
const VARIANT_LOW := TileSetBuilder.VARIANT_LOW
const VARIANT_GROUND := TileSetBuilder.VARIANT_GROUND
const VARIANT_ALT := TileSetBuilder.VARIANT_ALT
const VARIANT_OBSTACLE := TileSetBuilder.VARIANT_OBSTACLE

const RESOURCE_SCENE := preload("res://scenes/planet/resource_node.tscn")
## High enough that the row-by-row scatter loop practically never hits it on a
## 140x140 map (~190 expected placements), so resources stay evenly spread
## instead of clustering toward the top rows when the cap cuts the loop short.
const RESOURCE_CAP := 200
const RESOURCE_CHANCE := 0.014
const PAD_CLEAR_DISTANCE := 96.0

const ENEMY_SCENE := preload("res://scenes/planet/enemy.tscn")
const ENEMY_MIN := 10
const ENEMY_MAX := 16
const ENEMY_MIN_PAD_DISTANCE := 320.0
## Extra aliens at danger 1.0, scaling linearly from 0 at the galaxy origin.
const ENEMY_DANGER_BONUS := 18

const STRUCTURE_SCENE := preload("res://scenes/colony/structure.tscn")

const ENEMY_STRUCTURE_SCENE := preload("res://scenes/colony/enemy_structure.tscn")
const EnemyStructure := preload("res://scripts/colony/enemy_structure.gd")
const COLONY_MIN_PAD_DISTANCE := 620.0
const COLONY_SPACING := 900.0

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
	_spawn_enemy_colonies()
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
	var to_spawn := rng.randi_range(ENEMY_MIN, ENEMY_MAX) + roundi(data.danger * ENEMY_DANGER_BONUS)
	var attempts := 0
	var spawned := 0
	while spawned < to_spawn and attempts < 900:
		attempts += 1
		var cell := Vector2i(rng.randi_range(3, MAP_SIZE - 4), rng.randi_range(3, MAP_SIZE - 4))
		if not is_placeable(cell) or structure_cells.has(cell):
			continue
		var world := terrain.map_to_local(cell)
		if world.distance_to(pad_position) < ENEMY_MIN_PAD_DISTANCE:
			continue
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = world
		add_child(enemy)
		enemy.setup(data.biome, _pick_enemy_tier(rng))
		spawned += 1


## Tier odds scale with danger: planets near the origin field only normal
## aliens; the outer rim is mostly veterans with a heavy elite presence.
func _pick_enemy_tier(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < data.danger * 0.45:
		return 2
	if roll < data.danger * 1.1:
		return 1
	return 0


## Distance-based enemy colonies: planets past PlanetData.COLONY_DANGER_THRESHOLD
## get seeded hostile outposts - miners worth raiding for loot, turrets that
## fire on the player and their units, and broken wall rings - with more
## clusters and tougher structures the further the planet sits from the galaxy
## origin. Like the alien walkers they are visit-local: destroyed structures
## regenerate (deterministically, seed+3) on the next landing.
func _spawn_enemy_colonies() -> void:
	if data.danger < PlanetData.COLONY_DANGER_THRESHOLD:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = data.planet_seed + 3
	var centers: Array[Vector2i] = []
	var cluster_count := 1 + int(data.danger * 2.2)
	for i in cluster_count:
		var center := _find_colony_center(rng, centers)
		if center.x < 0:
			continue
		centers.append(center)
		_build_colony_cluster(rng, center)


## A colony center needs clear ground away from the landing pad and from other
## colonies. Returns (-1, -1) when no spot survives the attempt budget.
func _find_colony_center(rng: RandomNumberGenerator, taken: Array[Vector2i]) -> Vector2i:
	for attempt in 240:
		var cell := Vector2i(rng.randi_range(8, MAP_SIZE - 9), rng.randi_range(8, MAP_SIZE - 9))
		if not is_placeable(cell) or structure_cells.has(cell):
			continue
		var world := terrain.map_to_local(cell)
		if world.distance_to(pad_position) < COLONY_MIN_PAD_DISTANCE:
			continue
		var crowded := false
		for other in taken:
			if terrain.map_to_local(other).distance_to(world) < COLONY_SPACING:
				crowded = true
				break
		if not crowded:
			return cell
	return Vector2i(-1, -1)


## Turrets at the heart, miners around them, and a partial wall ring whose
## gaps fall wherever terrain blocks placement or the roll misses - so every
## colony has a way in. Counts scale with danger.
func _build_colony_cluster(rng: RandomNumberGenerator, center: Vector2i) -> void:
	_place_enemy_structure(EnemyStructure.Kind.TURRET, center)
	_scatter_colony_kind(rng, EnemyStructure.Kind.TURRET, roundi(data.danger * 2.0), center, 2)
	_scatter_colony_kind(rng, EnemyStructure.Kind.MINER, 2 + int(data.danger * 3.0), center, 3)
	var wall_chance := 0.5 + data.danger * 0.4
	for cell in _ring_cells(center, 4):
		if rng.randf() > wall_chance:
			continue
		if is_placeable(cell) and not structure_cells.has(cell):
			_place_enemy_structure(EnemyStructure.Kind.WALL, cell)


func _scatter_colony_kind(rng: RandomNumberGenerator, kind: int, count: int, center: Vector2i, radius: int) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 60:
		attempts += 1
		var cell := center + Vector2i(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))
		if not is_placeable(cell) or structure_cells.has(cell):
			continue
		_place_enemy_structure(kind, cell)
		placed += 1


## Cells at exactly Chebyshev distance `radius` from `center`.
func _ring_cells(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if maxi(absi(x - center.x), absi(y - center.y)) == radius:
				cells.append(Vector2i(x, y))
	return cells


func _place_enemy_structure(kind: int, cell: Vector2i) -> void:
	var structure := ENEMY_STRUCTURE_SCENE.instantiate()
	structure.position = terrain.map_to_local(cell)
	add_child(structure)
	structure.setup(kind, data.danger)
	structure.destroyed.connect(_on_enemy_structure_destroyed.bind(cell))
	# Occupies the cell like a player structure (blocks build mode, resource
	# scatter, and alien spawns) but is never recorded in GameManager -
	# colonies are procedural, not part of the player's save.
	structure_cells[cell] = structure


func _on_enemy_structure_destroyed(_structure: Node, cell: Vector2i) -> void:
	structure_cells.erase(cell)


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
