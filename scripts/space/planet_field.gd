extends Node2D
## Scatters seeded planets around the origin of the space scene.
## The same galaxy seed always produces the same planet layout.

const PLANET_SCENE := preload("res://scenes/space/planet.tscn")
const PLANET_COUNT := 14
const FIELD_RADIUS := 3800.0
const MIN_DISTANCE := 620.0
const SPAWN_CLEAR_RADIUS := 420.0

var planets: Array[SpacePlanet] = []


func _ready() -> void:
	generate(GameManager.galaxy_seed)


func generate(galaxy_seed: int) -> void:
	for planet in planets:
		planet.queue_free()
	planets.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = galaxy_seed
	var positions: Array[Vector2] = []
	var attempts := 0
	while positions.size() < PLANET_COUNT and attempts < 800:
		attempts += 1
		var pos := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * FIELD_RADIUS
		if pos.length() < SPAWN_CLEAR_RADIUS:
			continue
		var too_close := false
		for existing in positions:
			if existing.distance_to(pos) < MIN_DISTANCE:
				too_close = true
				break
		if not too_close:
			positions.append(pos)
	for i in positions.size():
		var planet: SpacePlanet = PLANET_SCENE.instantiate()
		planet.position = positions[i]
		add_child(planet)
		var planet_data := PlanetData.make(hash("%d:%d" % [galaxy_seed, i]))
		var story := StoryRegistry.story_for_index(i)
		if not story.is_empty():
			planet_data.display_name = str(story["name"])
			planet_data.biome = int(story["biome"])
			planet_data.radius = float(story["radius"])
			planet_data.story_id = str(story["id"])
			planet_data.surface_scene = str(story["scene"])
			planet_data.atmosphere_color = Color(1.0, 0.85, 0.4, 0.4)
		planet.setup(planet_data)
		planets.append(planet)
