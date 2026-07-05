class_name StarSystemData
extends RefCounted
## One star system: a star at a fixed galaxy position with 2-6 orbiting
## planets. Everything here derives from (galaxy_seed, system_index), so a
## revisit always reconstructs the same system (star type added in Milestone 10).

const NAME_SYLLABLES: Array[String] = [
	"Xar", "Velk", "Kori", "Dune", "Esh", "Ptor", "Wyn", "Actarus", "Ilun", "Bree",
]

var system_index: int
var system_seed: int
var position: Vector2
var display_name: String
## Seeds of the planets orbiting this star, in orbit order (innermost first).
var planet_seeds: Array[int] = []


static func make(galaxy_seed: int, index: int, system_position: Vector2, seeds: Array[int]) -> StarSystemData:
	var data := StarSystemData.new()
	data.system_index = index
	data.system_seed = hash("galaxy-system:%d:%d" % [galaxy_seed, index])
	data.position = system_position
	data.planet_seeds = seeds
	var rng := RandomNumberGenerator.new()
	rng.seed = data.system_seed
	data.display_name = "%s System" % NAME_SYLLABLES[rng.randi_range(0, NAME_SYLLABLES.size() - 1)]
	return data
