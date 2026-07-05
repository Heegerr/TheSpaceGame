extends Node2D
## Build mode for planet surfaces. Toggle with the build_menu action (B):
## shows a tile-snapped ghost, 1-4 pick a structure, click places it if the
## tile is valid and the cost can be paid. Records placements in GameManager
## so they persist per planet.

const Structure := preload("res://scripts/colony/structure.gd")
const PAD_KEEPOUT := 48.0

var active := false
var selected_type := 0

var _surface: Node2D
var _terrain: TileMapLayer


func setup(surface: Node2D, terrain: TileMapLayer) -> void:
	_surface = surface
	_terrain = terrain
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		set_active(not active)
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			var index: int = key_event.keycode - KEY_1
			if index >= 0 and index < Structure.DEFS.size():
				selected_type = index
				_notify_hud()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# Milestone 15 grew the structure roster past 9 types, so the number
		# keys alone can no longer reach every entry; wheel cycles through all.
		var step := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		selected_type = (selected_type + step + Structure.DEFS.size()) % Structure.DEFS.size()
		_notify_hud()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		_try_place(_mouse_cell())
		get_viewport().set_input_as_handled()


func set_active(value: bool) -> void:
	active = value
	set_process(active)
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player_on_foot")
	if player != null:
		player.shooting_enabled = not active
	_notify_hud()


func _notify_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.set_build_menu(active, selected_type)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var cell := _mouse_cell()
	var origin := _terrain.map_to_local(cell) - Vector2(16, 16)
	var ok := _can_place(cell) and Structure.can_afford(selected_type)
	var color := Color(0.4, 1.0, 0.5, 0.3) if ok else Color(1.0, 0.35, 0.3, 0.3)
	draw_rect(Rect2(origin, Vector2(32, 32)), color)
	draw_rect(Rect2(origin, Vector2(32, 32)), Color(color.r, color.g, color.b, 0.9), false, 1.0)


func _mouse_cell() -> Vector2i:
	return _terrain.local_to_map(_terrain.to_local(get_global_mouse_position()))


func _can_place(cell: Vector2i) -> bool:
	if not _surface.is_placeable(cell):
		return false
	if _surface.structure_cells.has(cell):
		return false
	if _terrain.map_to_local(cell).distance_to(_surface.pad_position) < PAD_KEEPOUT:
		return false
	# Milestone 17: Spaceport requires the planet to already be colonized.
	if selected_type == Structure.Type.SPACEPORT and not GameManager.planet_has_habitat(_surface.data.planet_seed):
		return false
	return true


func _try_place(cell: Vector2i) -> void:
	if not _can_place(cell):
		return
	if not Structure.pay_cost(selected_type):
		FloatingText.spawn(_surface, _terrain.map_to_local(cell) + Vector2(0, -10), "Not enough resources", Color(1, 0.5, 0.4))
		return
	_surface.place_structure(selected_type, cell, true)
	Sfx.play_pickup()
