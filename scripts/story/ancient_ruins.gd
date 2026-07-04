extends StoryPlanet
## Story planet XETH-PRIME: a ruined desert vault with a lonely custodian.

const MAP := [
	"########################",
	"#......,,,.....~~~.....#",
	"#..P...,,......~~~.....#",
	"#......................#",
	"#....,,....#############",
	"#..........#..........##",
	"#..........#..........##",
	"#..........#..........##",
	"#..........#..........##",
	"#..........####..#######",
	"#......................#",
	"#,,,...................#",
	"#......~~~.............#",
	"#......~~~~............#",
	"#......................#",
	"########################",
]


func _map() -> PackedStringArray:
	return PackedStringArray(MAP)


func _biome() -> int:
	return PlanetData.Biome.DESERT


func _grant_reward() -> void:
	Inventory.add("alloy", 12)
	hud.show_banner("The vault opens: +12 Alloy recovered", Color(0.5, 1.0, 0.6))
