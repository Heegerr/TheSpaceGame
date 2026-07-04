extends StoryPlanet
## Story planet OUTPOST-9: a frozen crash site hiding a salvageable escort.

const MAP := [
	"######################",
	"#~~~~................#",
	"#~~~....##########...#",
	"#~~.....#........#...#",
	"#..P....#........#...#",
	"#.......#........#...#",
	"#.......##..######...#",
	"#....................#",
	"#,,,,................#",
	"#........,,,,........#",
	"#...............,,,..#",
	"#~~..................#",
	"#~~~~................#",
	"######################",
]


func _map() -> PackedStringArray:
	return PackedStringArray(MAP)


func _biome() -> int:
	return PlanetData.Biome.ICE


func _grant_reward() -> void:
	if GameManager.fleet_size < ShipUpgrades.MAX_FLEET:
		GameManager.fleet_size += 1
		hud.show_banner("Salvaged escort ship joins your fleet!", Color(0.5, 1.0, 0.6))
	else:
		Inventory.add("alloy", 8)
		hud.show_banner("Fleet already full - stripped hull for +8 Alloy", Color(0.5, 1.0, 0.6))
