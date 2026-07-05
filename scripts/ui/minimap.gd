extends Control
## Icon-based minimap (Milestone 12), active in both space and ground modes.
## Lives in the top-right corner; "toggle_map" (M) expands it to a
## full-screen map. Draws simple dots/icons scaled from world positions
## rather than the actual scene, so cost stays flat regardless of world size.

const CORNER_SIZE := Vector2(120.0, 120.0)
const CORNER_MARGIN := 8.0
## Sits below the health bar / ship status bars, which already occupy the
## top-right corner up to about y=42.
const CORNER_TOP := 46.0
## The base viewport is 640x360 (see CLAUDE.md pixel-art contract); keep the
## expanded map comfortably inside it.
const FULL_SIZE := Vector2(440.0, 300.0)
const SPACE_RADIUS_SMALL := 1400.0
const SPACE_RADIUS_FULL := 4200.0
const GROUND_RADIUS_SMALL := 480.0
const GROUND_RADIUS_FULL := 1400.0
const REFRESH_INTERVAL := 0.15

var expanded := false
var _refresh_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_corner()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		expanded = not expanded
		if expanded:
			_layout_full()
		else:
			_layout_corner()
		get_viewport().set_input_as_handled()
		queue_redraw()


func _layout_corner() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -CORNER_MARGIN - CORNER_SIZE.x
	offset_top = CORNER_TOP
	offset_right = -CORNER_MARGIN
	offset_bottom = CORNER_TOP + CORNER_SIZE.y


func _layout_full() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -FULL_SIZE.x / 2.0
	offset_right = FULL_SIZE.x / 2.0
	offset_top = -FULL_SIZE.y / 2.0
	offset_bottom = FULL_SIZE.y / 2.0


func _draw() -> void:
	var panel_size: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, panel_size), Color(0.05, 0.06, 0.09, 0.78))
	draw_rect(Rect2(Vector2.ZERO, panel_size), Color(1, 1, 1, 0.25), false, 1.0)

	var ground_player: Node2D = get_tree().get_first_node_in_group("player_on_foot")
	if ground_player != null and is_instance_valid(ground_player):
		_draw_ground(ground_player, panel_size)
	else:
		var ship: Node2D = get_tree().get_first_node_in_group("player_ship")
		if ship != null and is_instance_valid(ship):
			_draw_space(ship, panel_size)

	if not expanded:
		draw_string(ThemeDB.fallback_font, Vector2(4, panel_size.y - 3), "M: map",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.5))


func _draw_space(ship: Node2D, panel_size: Vector2) -> void:
	var radius := SPACE_RADIUS_FULL if expanded else SPACE_RADIUS_SMALL
	var center := panel_size / 2.0
	var scale_f := (minf(panel_size.x, panel_size.y) / 2.0 - 6.0) / radius

	var planet_field := get_tree().current_scene.get_node_or_null("PlanetField") as PlanetField
	if planet_field != null:
		for child in planet_field.get_children():
			if child is Star:
				_dot((child as Star).position, ship.position, center, scale_f, radius, Color(1.0, 0.9, 0.5, 0.75), 3.0)
		for planet in planet_field.planets:
			if not is_instance_valid(planet):
				continue
			var colonized: bool = not GameManager.structures_on(planet.data.planet_seed).is_empty()
			var color := Color(0.6, 0.65, 0.75)
			if colonized:
				color = Color(0.5, 0.9, 0.55)
			if planet.data.story_id != "":
				color = Color(1.0, 0.85, 0.35)
			_dot(planet.position, ship.position, center, scale_f, radius, color, 2.2)

	for hostile in get_tree().get_nodes_in_group("hostile_ships"):
		if hostile is Node2D and is_instance_valid(hostile):
			_dot((hostile as Node2D).position, ship.position, center, scale_f, radius, Color(1.0, 0.3, 0.3), 2.0)

	for fleet_ship in get_tree().get_nodes_in_group("player_fleet"):
		if not (fleet_ship is Node2D) or not is_instance_valid(fleet_ship):
			continue
		var fleet_node := fleet_ship as Node2D
		var is_active := fleet_node == ship
		_dot(fleet_node.position, ship.position, center, scale_f, radius,
				Color(1, 1, 1) if is_active else Color(0.7, 0.85, 1.0), 3.0 if is_active else 2.0)


func _draw_ground(player: Node2D, panel_size: Vector2) -> void:
	var radius := GROUND_RADIUS_FULL if expanded else GROUND_RADIUS_SMALL
	var center := panel_size / 2.0
	var scale_f := (minf(panel_size.x, panel_size.y) / 2.0 - 6.0) / radius

	for structure in get_tree().get_nodes_in_group("structures"):
		if structure is Node2D and is_instance_valid(structure):
			_dot((structure as Node2D).position, player.position, center, scale_f, radius, Color(0.55, 0.75, 1.0), 2.6)
	for resource in get_tree().get_nodes_in_group("resources"):
		if resource is CanvasItem and is_instance_valid(resource) and (resource as CanvasItem).visible:
			_dot((resource as Node2D).position, player.position, center, scale_f, radius, Color(0.6, 0.9, 0.5), 1.6)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and is_instance_valid(enemy):
			_dot((enemy as Node2D).position, player.position, center, scale_f, radius, Color(1.0, 0.3, 0.3), 2.2)
	draw_circle(center, 3.0, Color(1, 1, 1))


func _dot(world_pos: Vector2, origin: Vector2, center: Vector2, scale_f: float, radius: float, color: Color, r: float) -> void:
	var delta := world_pos - origin
	if delta.length() > radius:
		return
	draw_circle(center + delta * scale_f, r, color)
