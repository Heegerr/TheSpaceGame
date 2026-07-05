class_name PlanetData
extends RefCounted
## Everything derivable from a planet's seed: name, biome, space appearance,
## and the surface tile palette. Shared by the space view and surface generation.

enum Biome { GRASS, DESERT, ICE }

const BIOME_COUNT := 3
const NAME_SYLLABLES: Array[String] = [
	"ke", "pler", "zor", "ath", "ion", "vex", "tau", "rin",
	"os", "mir", "dra", "ul", "tho", "nak", "ei", "sol",
]

var planet_seed: int
var display_name: String
var biome: int
var radius: float
var base_color: Color
var accent_color: Color
var atmosphere_color: Color

## Set for hand-authored story planets (see StoryRegistry): landing loads
## surface_scene instead of the procedural surface.
var story_id := ""
var surface_scene := ""


## biome_weights (Milestone 10) optionally skews biome choice per star system
## type, e.g. {Biome.ICE: 2.0} makes ice planets twice as likely; an empty
## dictionary means an even spread across all biomes.
static func make(p_seed: int, biome_weights: Dictionary = {}) -> PlanetData:
	var data := PlanetData.new()
	data.planet_seed = p_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	data.biome = _pick_biome(rng, biome_weights)
	data.radius = rng.randf_range(34.0, 72.0)
	var syllables := ""
	for i in rng.randi_range(2, 3):
		syllables += NAME_SYLLABLES[rng.randi_range(0, NAME_SYLLABLES.size() - 1)]
	data.display_name = "%s-%02d" % [syllables.capitalize(), rng.randi_range(1, 99)]
	var jitter := rng.randf_range(-0.05, 0.05)
	match data.biome:
		Biome.GRASS:
			data.base_color = Color(0.28 + jitter, 0.62, 0.32)
			data.accent_color = Color(0.17, 0.37, 0.54)
			data.atmosphere_color = Color(0.5, 0.83, 1.0, 0.28)
		Biome.DESERT:
			data.base_color = Color(0.85, 0.63 + jitter, 0.4)
			data.accent_color = Color(0.72, 0.46, 0.24)
			data.atmosphere_color = Color(1.0, 0.85, 0.63, 0.25)
		Biome.ICE:
			data.base_color = Color(0.75 + jitter, 0.9, 0.94)
			data.accent_color = Color(0.5, 0.72, 0.85)
			data.atmosphere_color = Color(0.87, 0.97, 1.0, 0.3)
	return data


static func _pick_biome(rng: RandomNumberGenerator, biome_weights: Dictionary) -> int:
	if biome_weights.is_empty():
		return rng.randi_range(0, BIOME_COUNT - 1)
	var total := 0.0
	for biome in range(BIOME_COUNT):
		total += float(biome_weights.get(biome, 1.0))
	var roll := rng.randf_range(0.0, total)
	var accum := 0.0
	for biome in range(BIOME_COUNT):
		accum += float(biome_weights.get(biome, 1.0))
		if roll <= accum:
			return biome
	return BIOME_COUNT - 1


## Surface palette for a biome: [low ground, main ground, alt ground, obstacle].
static func tile_colors_for(p_biome: int) -> Array[Color]:
	match p_biome:
		Biome.DESERT:
			return [Color(0.64, 0.44, 0.25), Color(0.85, 0.63, 0.4), Color(0.91, 0.74, 0.51), Color(0.54, 0.3, 0.19)]
		Biome.ICE:
			return [Color(0.25, 0.44, 0.62), Color(0.75, 0.91, 0.95), Color(0.87, 0.96, 0.98), Color(0.5, 0.72, 0.85)]
		_:
			return [Color(0.17, 0.37, 0.54), Color(0.28, 0.62, 0.32), Color(0.4, 0.74, 0.42), Color(0.42, 0.44, 0.48)]


func tile_colors() -> Array[Color]:
	return PlanetData.tile_colors_for(biome)
