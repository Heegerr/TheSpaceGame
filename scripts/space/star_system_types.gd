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
		# Even spread across the base biomes (PlanetData.Biome).
		"biome_weights": {0: 1.0, 1: 1.0, 2: 1.0},
	},
	Type.RED_DWARF: {
		"name": "Red Dwarf",
		"color": Color(0.95, 0.4, 0.32),
		"radius_mult": 0.65,
		"nebula": false,
		"binary": false,
		"pulse": false,
		# Cold and dim: skews barren/icy.
		"biome_weights": {0: 0.3, 1: 0.7, 2: 2.0},
	},
	Type.BLUE_GIANT: {
		"name": "Blue Giant",
		"color": Color(0.55, 0.72, 1.0),
		"radius_mult": 1.6,
		"nebula": false,
		"binary": false,
		"pulse": false,
		# Fierce heat: skews hot/rocky.
		"biome_weights": {0: 0.4, 1: 2.0, 2: 0.2},
	},
	Type.BINARY: {
		"name": "Binary System",
		"color": Color(1.0, 0.78, 0.4),
		"radius_mult": 0.85,
		"nebula": false,
		"binary": true,
		"pulse": false,
		"biome_weights": {0: 1.0, 1: 1.5, 2: 0.8},
	},
	Type.NEUTRON_STAR: {
		"name": "Neutron Star",
		"color": Color(0.75, 0.88, 1.0),
		"radius_mult": 0.4,
		"nebula": false,
		"binary": false,
		"pulse": true,
		# Sterile and irradiated: mostly barren, some ice.
		"biome_weights": {0: 0.1, 1: 1.6, 2: 1.2},
	},
	Type.NEBULA: {
		"name": "Nebula System",
		"color": Color(0.78, 0.55, 0.95),
		"radius_mult": 1.1,
		"nebula": true,
		"binary": false,
		"pulse": false,
		# Exotic conditions: favors ice (stand-in for crystal/exotic until Milestone 11).
		"biome_weights": {0: 0.6, 1: 0.6, 2: 1.8},
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
