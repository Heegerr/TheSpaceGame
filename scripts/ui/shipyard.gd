extends CanvasLayer
## Grid-based ship builder overlay (Milestone 7). Place HULL_CORE/HULL_SECTION/
## ENGINE/WEAPON/CARGO_POD parts on a GRID_SIZE x GRID_SIZE grid; Build pays
## the summed cost and replaces GameManager.ship_designs[0], which the
## flagship reads bonuses from via ShipParts.design_bonus().

const ERASE := -1

@onready var grid: GridContainer = $Panel/Box/Main/GridPanel/Grid
@onready var palette: VBoxContainer = $Panel/Box/Main/Palette
@onready var stats_label: Label = $Panel/Box/StatsLabel
@onready var cost_label: Label = $Panel/Box/CostLabel
@onready var build_button: Button = $Panel/Box/Buttons/BuildButton

var _cells: Dictionary[Vector2i, int] = {}
var _cell_buttons: Dictionary[Vector2i, Button] = {}
var _palette_buttons: Dictionary[int, Button] = {}
var _selected_part: int = ShipParts.Part.HULL_CORE


func _ready() -> void:
	visible = false
	_build_grid()
	_build_palette()
	build_button.pressed.connect(_on_build)
	$Panel/Box/Buttons/ClearButton.pressed.connect(_on_clear)
	$Panel/Box/Buttons/CloseButton.pressed.connect(close)


func open() -> void:
	_load_active_design()
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _build_grid() -> void:
	grid.columns = ShipParts.GRID_SIZE
	for y in ShipParts.GRID_SIZE:
		for x in ShipParts.GRID_SIZE:
			var pos := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(26, 26)
			button.add_theme_font_size_override("font_size", 10)
			button.pressed.connect(_on_cell_pressed.bind(pos))
			grid.add_child(button)
			_cell_buttons[pos] = button


func _build_palette() -> void:
	for part in ShipParts.DEFS:
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_on_palette_pressed.bind(part))
		palette.add_child(button)
		_palette_buttons[part] = button
	var erase := Button.new()
	erase.add_theme_font_size_override("font_size", 8)
	erase.pressed.connect(_on_palette_pressed.bind(ERASE))
	palette.add_child(erase)
	_palette_buttons[ERASE] = erase


func _on_palette_pressed(part: int) -> void:
	_selected_part = part
	_refresh_palette()


func _on_cell_pressed(pos: Vector2i) -> void:
	# Placement is intentionally unvalidated: any part can be placed in any
	# order, so a Hull Core goes down first with no prerequisites. Design
	# requirements (core + engine + connectivity) are only checked when
	# finalizing via the Build button - see ShipParts.validate().
	if _selected_part == ERASE:
		_cells.erase(pos)
	else:
		if _selected_part == ShipParts.Part.HULL_CORE:
			for key in _cells.keys():
				if _cells[key] == ShipParts.Part.HULL_CORE:
					_cells.erase(key)
					break
		_cells[pos] = _selected_part
	_refresh()


func _on_clear() -> void:
	_cells.clear()
	_refresh()


func _on_build() -> void:
	var check := ShipParts.validate(_cells)
	if not bool(check["valid"]):
		stats_label.text = str(check["error"])
		stats_label.add_theme_color_override("font_color", Color(1, 0.45, 0.4))
		return
	var cost := ShipParts.total_cost(_cells)
	if not ShipParts.can_afford_cost(cost):
		stats_label.text = "Not enough resources"
		stats_label.add_theme_color_override("font_color", Color(1, 0.45, 0.4))
		return
	for resource_id in cost:
		Inventory.add(resource_id, -int(cost[resource_id]))
	var design := {"name": "Flagship", "cells": ShipParts.cells_to_array(_cells)}
	if GameManager.ship_designs.is_empty():
		GameManager.ship_designs.append(design)
	else:
		GameManager.ship_designs[0] = design
	GameManager.active_design_index = 0
	GameManager.recompute_capacity()
	GameManager.save_current()
	var flagship := get_tree().get_first_node_in_group("player_ship")
	if flagship != null:
		flagship.reset_combat_state()
	_refresh()
	stats_label.text = "Design built."
	stats_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))


func _load_active_design() -> void:
	_cells.clear()
	for entry in ShipParts.active_design_cells():
		var pos := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		_cells[pos] = int(entry.get("part", -1))


func _refresh() -> void:
	for pos in _cell_buttons:
		var button: Button = _cell_buttons[pos]
		var part: int = _cells.get(pos, ERASE)
		if part == ERASE or not ShipParts.DEFS.has(part):
			button.text = ""
			button.modulate = Color(0.4, 0.4, 0.45)
		else:
			var def: Dictionary = ShipParts.DEFS[part]
			button.text = str(def["glyph"])
			button.modulate = def["color"]
	_refresh_palette()
	var totals := ShipParts.totals_of(_cells)
	stats_label.text = "Hull +%d   Speed +%d%%   Damage +%d   Cargo +%d" % [
			int(totals["hull"]), roundi(float(totals["speed"]) * 100.0), int(totals["damage"]), int(totals["cargo"])]
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	# Live finalize-readiness: Build stays disabled with a neutral "what's
	# next" hint until the design is complete, so the whole-design checks
	# (e.g. "at least one Engine") can never read as placement requirements.
	var check := ShipParts.validate(_cells)
	build_button.disabled = not bool(check["valid"])
	var status := "ready to build" if bool(check["valid"]) else str(check["error"])
	cost_label.text = "Cost: %s  -  %s" % [ShipParts.cost_text(ShipParts.total_cost(_cells)), status]


func _refresh_palette() -> void:
	for part in _palette_buttons:
		var button: Button = _palette_buttons[part]
		var selected := part == _selected_part
		if part == ERASE:
			button.text = "Erase" + (" *" if selected else "")
		else:
			var def: Dictionary = ShipParts.DEFS[part]
			button.text = "%s%s - %s" % [str(def["name"]), (" *" if selected else ""), ShipParts.cost_text(def["cost"])]
