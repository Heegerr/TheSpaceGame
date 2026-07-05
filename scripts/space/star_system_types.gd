class_name StarSystemTypes
extends RefCounted
## Star system type definitions (Milestone 10). Each type gives the Star node
## a distinct look (color/size/effects) and skews which planet biomes appear
## in that system via biome_weights (consumed by PlanetData.make).

enum Type { YELLOW_STAR, RED_DWARF, BLUE_GIANT, BINARY, NEUTRON_STAR, NEBULA }

const COUNT := 6

const DEFS: Dictionary[int, Dictionary] = {
	Type.YELLOW_STAR: {
		"name": "Yellow Star",
		"color": Color(1.0, 0.92, 0.55),
		"radius_mult": 1.0,
		"nebula": false,
		"binary": false,
		"pulse": false,
		# Balanced spread; slightly favors the "common" biomes.
		# Biome order: GRASS DESERT ICE VOLCANIC SWAMP CRYSTAL BARREN TOXIC FOREST TUNDRA
		"biome_weights": {0: 1.2, 1: 1.2, 2: 1.0, 3: 0.4, 4: 0.8, 5: 0.4, 6: 1.0, 7: 0.4, 8: 1.2, 9: 1.0},
	},
	Type.RED_DWARF: {
		"name": "Red Dwarf",
		"color": Color(0.95, 0.4, 0.32),
		"radius_mult": 0.65,
		"nebula": false,
		"binary": false,
		"pulse": false,
		# Cold and dim: skews ice/tundra/barren.
		"biome_weights": {0: 0.4, 1: 0.5, 2: 1.8, 3: 0.1, 4: 0.3, 5: 0.3, 6: 1.6, 7: 0.2, 8: 0.4, 9: 2.0},
	},
	Type.BLUE_GIANT: {
		"name": "Blue Giant",
		"color": Color(0.55, 0.72, 1.0),
		"radius_mult": 1.6,
		"nebula": false,
		"binary": false,
		"pulse": false,
		# Fierce heat: skews volcanic/desert/toxic.
		"biome_weights": {0: 0.3, 1: 1.6, 2: 0.2, 3: 2.2, 4: 0.3, 5: 0.5, 6: 1.0, 7: 1.2, 8: 0.2, 9: 0.1},
	},
	Type.BINARY: {
		"name": "Binary System",
		"color": Color(1.0, 0.78, 0.4),
		"radius_mult": 0.85,
		"nebula": false,
		"binary": true,
		"pulse": false,
		# Two suns: warm and varied.
		"biome_weights": {0: 0.8, 1: 1.4, 2: 0.6, 3: 1.6, 4: 0.6, 5: 0.6, 6: 1.0, 7: 0.8, 8: 0.6, 9: 0.4},
	},
	Type.NEUTRON_STAR: {
		"name": "Neutron Star",
		"color": Color(0.75, 0.88, 1.0),
		"radius_mult": 0.4,
		"nebula": false,
		"binary": false,
		"pulse": true,
		# Sterile and irradiated: mostly barren/toxic, some crystal.
		"biome_weights": {0: 0.1, 1: 0.6, 2: 0.8, 3: 0.4, 4: 0.2, 5: 1.4, 6: 2.0, 7: 1.2, 8: 0.1, 9: 0.6},
	},
	Type.NEBULA: {
		"name": "Nebula System",
		"color": Color(0.78, 0.55, 0.95),
		"radius_mult": 1.1,
		"nebula": true,
		"binary": false,
		"pulse": false,
		# Exotic/anomalous conditions: crystal, toxic, swamp.
		"biome_weights": {0: 0.3, 1: 0.4, 2: 0.6, 3: 0.6, 4: 1.2, 5: 2.2, 6: 0.4, 7: 1.6, 8: 0.3, 9: 0.5},
	},
}

const NEBULA_TINTS: Array[Color] = [
	Color(0.6, 0.35, 0.8, 0.06), Color(0.35, 0.6, 0.8, 0.06), Color(0.8, 0.4, 0.55, 0.06),
]


static func display_name(star_type: int) -> String:
	return str(DEFS[star_type]["name"])


static func biome_weights(star_type: int) -> Dictionary:
	return DEFS[star_type]["biome_weights"]


## Deterministic star type for a system, derived from its seed so it is
## always the same on revisit without needing its own save field.
static func type_for_seed(system_seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = system_seed
	return rng.randi_range(0, COUNT - 1)
