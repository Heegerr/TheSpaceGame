extends Node2D
## Scatters seeded star systems around the origin of the space scene, each
## with 2-6 orbiting planets (Milestone 9). System centers are spaced far
## apart (a long haul between systems); planets orbit close to their star
## (a quick hop within a system). The same galaxy seed always produces the
## same layout. `planets` stays a flat list so encounter/wave code that picks
## "a random planet" or "the nearest planet" is unaffected by the grouping.

const PLANET_SCENE := preload("res://scenes/space/planet.tscn")
const STAR_SCENE := preload("res://scenes/space/star.tscn")

const SYSTEM_COUNT := 8
const MIN_PLANETS_PER_SYSTEM := 2
const MAX_PLANETS_PER_SYSTEM := 6
const FIELD_RADIUS := 3800.0
const SYSTEM_MIN_DISTANCE := 1300.0
const SPAWN_CLEAR_RADIUS := 900.0
const ORBIT_BASE_RADIUS := 150.0
const ORBIT_STEP := 95.0
const ORBIT_JITTER := 20.0

var planets: Array[SpacePlanet] = []
var systems: Array[StarSystemData] = []


func _ready() -> void:
	generate(GameManager.galaxy_seed)


func generate(galaxy_seed: int) -> void:
	for planet in planets:
		planet.queue_free()
	planets.clear()
	for child in get_children():
		if child is Star:
			child.queue_free()
	systems.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = galaxy_seed
	var centers: Array[Vector2] = []
	var attempts := 0
	while centers.size() < SYSTEM_COUNT and attempts < 800:
		attempts += 1
		var pos := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * FIELD_RADIUS
		if pos.length() < SPAWN_CLEAR_RADIUS:
			continue
		var too_close := false
		for existing in centers:
			if existing.distance_to(pos) < SYSTEM_MIN_DISTANCE:
				too_close = true
				break
		if not too_close:
			centers.append(pos)

	var flat_index := 0
	for system_index in centers.size():
		var system_center := centers[system_index]
		var planet_count := rng.randi_range(MIN_PLANETS_PER_SYSTEM, MAX_PLANETS_PER_SYSTEM)
		var seeds: Array[int] = []
		for i in planet_count:
			seeds.append(hash("galaxy:%d" % flat_index))
			flat_index += 1
		var system_data := StarSystemData.make(galaxy_seed, system_index, system_center, seeds)
		systems.append(system_data)

		var star: Star = STAR_SCENE.instantiate()
		star.position = system_center
		add_child(star)
		star.setup(system_data)

		var orbit_rng := RandomNumberGenerator.new()
		orbit_rng.seed = system_data.system_seed
		var base_angle := orbit_rng.randf_range(0.0, TAU)
		for i in seeds.size():
			var flat_i := flat_index - seeds.size() + i
			var angle := base_angle + i * (TAU / 3.2) + orbit_rng.randf_range(-0.3, 0.3)
			var orbit_radius := ORBIT_BASE_RADIUS + i * ORBIT_STEP + orbit_rng.randf_range(-ORBIT_JITTER, ORBIT_JITTER)
			var planet_pos := system_center + Vector2.from_angle(angle) * orbit_radius

			var planet: SpacePlanet = PLANET_SCENE.instantiate()
			planet.position = planet_pos
			add_child(planet)
			var planet_data := PlanetData.make(seeds[i], StarSystemTypes.biome_weights(system_data.star_type))
			var story := StoryRegistry.story_for_index(flat_i)
			if not story.is_empty():
				planet_data.display_name = str(story["name"])
				planet_data.biome = int(story["biome"])
				planet_data.radius = float(story["radius"])
				planet_data.story_id = str(story["id"])
				planet_data.surface_scene = str(story["scene"])
				planet_data.atmosphere_color = Color(1.0, 0.85, 0.4, 0.4)
			planet.setup(planet_data)
			planets.append(planet)


## The system a given planet seed belongs to, or null if not found.
func system_of(p_seed: int) -> StarSystemData:
	for system_data in systems:
		if p_seed in system_data.planet_seeds:
			return system_data
	return null
