class_name StoryRegistry
extends RefCounted
## Hand-authored story planets injected into the procedural galaxy. Each entry
## claims a planet slot index in the PlanetField: the slot's position stays
## procedural (semi-fixed coordinates per galaxy seed), but the planet's
## identity and its surface scene are hand-made. Story planets get a golden
## atmosphere ring so they stand out in space.

const STORY_PLANETS: Array[Dictionary] = [
	{
		"index": 2,
		"id": "ancient_ruins",
		"name": "XETH-PRIME",
		"biome": PlanetData.Biome.DESERT,
		"radius": 60.0,
		"scene": "res://scenes/story/ancient_ruins.tscn",
	},
	{
		"index": 5,
		"id": "derelict_station",
		"name": "OUTPOST-9",
		"biome": PlanetData.Biome.ICE,
		"radius": 44.0,
		"scene": "res://scenes/story/derelict_station.tscn",
	},
]


static func story_for_index(index: int) -> Dictionary:
	for entry in STORY_PLANETS:
		if int(entry["index"]) == index:
			return entry
	return {}
