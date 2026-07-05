class_name PlanetData
extends RefCounted
## Everything derivable from a planet's seed: name, biome, space appearance,
## and the surface tile palette. Shared by the space view and surface generation.
## Milestone 11 expands biome count from 3 to 10; each biome also gets an
## ambient CanvasModulate tint applied on the surface (see PlanetSurface).

enum Biome { GRASS, DESERT, ICE, VOLCANIC, SWAMP, CRYSTAL, BARREN, TOXIC, FOREST, TUNDRA }

const BIOME_COUNT := 10
const NAME_SYLLABLES: Array[String] = [
	"ke", "pler", "zor", "ath", "ion", "vex", "tau", "rin",
	"os", "mir", "dra", "ul", "tho", "nak", "ei", "sol",
]

## [base_color, accent_color, atmosphere_color] for the space view.
const SPACE_PALETTE: Dictionary[int, Array] = {
	Biome.GRASS: [Color(0.28, 0.62, 0.32), Color(0.17, 0.37, 0.54), Color(0.5, 0.83, 1.0, 0.28)],
	Biome.DESERT: [Color(0.85, 0.63, 0.4), Color(0.72, 0.46, 0.24), Color(1.0, 0.85, 0.63, 0.25)],
	Biome.ICE: [Color(0.75, 0.9, 0.94), Color(0.5, 0.72, 0.85), Color(0.87, 0.97, 1.0, 0.3)],
	Biome.VOLCANIC: [Color(0.42, 0.12, 0.08), Color(0.9, 0.4, 0.1), Color(1.0, 0.5, 0.2, 0.3)],
	Biome.SWAMP: [Color(0.3, 0.45, 0.3), Color(0.2, 0.32, 0.2), Color(0.5, 0.7, 0.5, 0.25)],
	Biome.CRYSTAL: [Color(0.5, 0.35, 0.7), Color(0.7, 0.55, 0.9), Color(0.75, 0.55, 1.0, 0.3)],
	Biome.BARREN: [Color(0.55, 0.5, 0.44), Color(0.4, 0.36, 0.3), Color(0.7, 0.65, 0.58, 0.2)],
	Biome.TOXIC: [Color(0.55, 0.65, 0.2), Color(0.35, 0.45, 0.12), Color(0.7, 0.85, 0.3, 0.3)],
	Biome.FOREST: [Color(0.2, 0.45, 0.22), Color(0.12, 0.3, 0.15), Color(0.5, 0.8, 0.5, 0.25)],
	Biome.TUNDRA: [Color(0.68, 0.74, 0.78), Color(0.5, 0.58, 0.64), Color(0.8, 0.88, 0.95, 0.25)],
}

## Surface tile palette per biome: [low ground, main ground, alt ground, obstacle].
const TILE_PALETTE: Dictionary[int, Array] = {
	Biome.GRASS: [Color(0.17, 0.37, 0.54), Color(0.28, 0.62, 0.32), Color(0.4, 0.74, 0.42), Color(0.42, 0.44, 0.48)],
	Biome.DESERT: [Color(0.64, 0.44, 0.25), Color(0.85, 0.63, 0.4), Color(0.91, 0.74, 0.51), Color(0.54, 0.3, 0.19)],
	Biome.ICE: [Color(0.25, 0.44, 0.62), Color(0.75, 0.91, 0.95), Color(0.87, 0.96, 0.98), Color(0.5, 0.72, 0.85)],
	Biome.VOLCANIC: [Color(0.15, 0.05, 0.05), Color(0.32, 0.12, 0.1), Color(0.85, 0.35, 0.08), Color(0.12, 0.08, 0.08)],
	Biome.SWAMP: [Color(0.15, 0.25, 0.18), Color(0.28, 0.42, 0.28), Color(0.38, 0.5, 0.3), Color(0.2, 0.28, 0.2)],
	Biome.CRYSTAL: [Color(0.25, 0.15, 0.4), Color(0.45, 0.3, 0.65), Color(0.6, 0.5, 0.85), Color(0.35, 0.25, 0.5)],
	Biome.BARREN: [Color(0.35, 0.32, 0.28), Color(0.5, 0.46, 0.4), Color(0.58, 0.54, 0.48), Color(0.3, 0.28, 0.24)],
	Biome.TOXIC: [Color(0.25, 0.32, 0.1), Color(0.45, 0.55, 0.15), Color(0.6, 0.7, 0.2), Color(0.3, 0.35, 0.12)],
	Biome.FOREST: [Color(0.1, 0.28, 0.14), Color(0.18, 0.42, 0.2), Color(0.28, 0.52, 0.26), Color(0.14, 0.24, 0.16)],
	Biome.TUNDRA: [Color(0.45, 0.5, 0.55), Color(0.62, 0.68, 0.72), Color(0.72, 0.78, 0.8), Color(0.4, 0.44, 0.48)],
}

## Ambient CanvasModulate tint applied to the whole surface scene per biome.
const AMBIENT_TINT: Dictionary[int, Color] = {
	Biome.GRASS: Color(1.0, 1.0, 1.0),
	Biome.DESERT: Color(1.06, 0.98, 0.85),
	Biome.ICE: Color(0.9, 0.97, 1.06),
	Biome.VOLCANIC: Color(1.1, 0.85, 0.75),
	Biome.SWAMP: Color(0.9, 1.0, 0.9),
	Biome.CRYSTAL: Color(0.95, 0.9, 1.1),
	Biome.BARREN: Color(1.0, 0.97, 0.9),
	Biome.TOXIC: Color(0.95, 1.06, 0.8),
	Biome.FOREST: Color(0.88, 1.0, 0.9),
	Biome.TUNDRA: Color(0.92, 0.96, 1.06),
}

var planet_seed: int
var display_name: String
var biome: int
var radius: float
var base_color: Color
var accent_color: Color
var atmosphere_color: Color

## StarSystemTypes.Type of the system this planet orbits, or -1 if generated
## outside PlanetField (e.g. running planet_surface.tscn directly from the
## editor). Set by PlanetField right after PlanetData.make(). Milestone 14
## uses it to gate system-locked Research Building tech tree upgrades.
var star_type := -1

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
	var palette: Array = SPACE_PALETTE[data.biome]
	var base: Color = palette[0]
	data.base_color = Color(clampf(base.r + jitter, 0.0, 1.0), clampf(base.g + jitter, 0.0, 1.0), clampf(base.b + jitter, 0.0, 1.0))
	data.accent_color = palette[1]
	data.atmosphere_color = palette[2]
	return data


static func _pick_biome(rng: RandomNumberGenerator, biome_weights: Dictionary) -> int:
	if biome_weights.is_empty():
		return rng.randi_range(0, BIOME_COUNT - 1)
	var total := 0.0
	for biome_index in range(BIOME_COUNT):
		total += float(biome_weights.get(biome_index, 1.0))
	var roll := rng.randf_range(0.0, total)
	var accum := 0.0
	for biome_index in range(BIOME_COUNT):
		accum += float(biome_weights.get(biome_index, 1.0))
		if roll <= accum:
			return biome_index
	return BIOME_COUNT - 1


## Surface palette for a biome: [low ground, main ground, alt ground, obstacle].
static func tile_colors_for(p_biome: int) -> Array[Color]:
	var colors: Array[Color] = []
	colors.assign(TILE_PALETTE[p_biome])
	return colors


func tile_colors() -> Array[Color]:
	return PlanetData.tile_colors_for(biome)


static func ambient_tint_for(p_biome: int) -> Color:
	return AMBIENT_TINT[p_biome]
