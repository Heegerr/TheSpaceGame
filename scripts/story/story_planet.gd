class_name StoryPlanet
extends Node2D
## Base for hand-authored story planet surfaces. Terrain comes from an ASCII
## map (override _map and _biome): '#' obstacle, '.' ground, ',' alt ground,
## '~' low ground, 'P' landing pad cell. Dialogue triggers placed in the scene
## emit dialogue_finished; the first completion grants _grant_reward() once
## (tracked per planet in the save file as "story_done").

var data: PlanetData
var pad_position := Vector2(64, 64)

@onready var terrain: TileMapLayer = $Terrain
@onready var player: CharacterBody2D = $Player
@onready var landed_ship: Area2D = $LandedShip
@onready var hud: CanvasLayer = $HUD


func _map() -> PackedStringArray:
	return PackedStringArray()


func _biome() -> int:
	return PlanetData.Biome.GRASS


func _grant_reward() -> void:
	Inventory.add("alloy", 10)
	hud.show_banner("Story complete: +10 Alloy", Color(0.5, 1.0, 0.6))


func _ready() -> void:
	data = GameManager.current_planet_data
	if data == null:
		data = PlanetData.make(0)
	terrain.tile_set = TileSetBuilder.build()
	var map := _map()
	for y in map.size():
		var row := map[y]
		for x in row.length():
			var variant := TileSetBuilder.VARIANT_GROUND
			match row[x]:
				"#":
					variant = TileSetBuilder.VARIANT_OBSTACLE
				"~":
					variant = TileSetBuilder.VARIANT_LOW
				",":
					variant = TileSetBuilder.VARIANT_ALT
				"P":
					pad_position = terrain.map_to_local(Vector2i(x, y))
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(variant, _biome()))
	landed_ship.position = pad_position
	player.position = pad_position + Vector2(0, 40)
	var width := 20
	var height := 12
	if map.size() > 0:
		width = map[0].length()
		height = map.size()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = width * 32
	camera.limit_bottom = height * 32
	camera.reset_smoothing()
	hud.bind_player(player)
	for child in get_children():
		if child.has_signal("dialogue_finished"):
			child.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	var record := GameManager.planet_record(data.planet_seed)
	if bool(record.get("story_done", false)):
		hud.show_banner("Nothing more to find here.", Color(0.8, 0.85, 0.95))
		return
	record["story_done"] = true
	_grant_reward()
	GameManager.save_current()
