class_name Star
extends Node2D
## Visual anchor for a star system: drawn at the system's center with its
## orbiting planets placed around it by PlanetField. Not landable or
## interactable itself. Look (color/size/nebula/binary/pulse) comes from the
## system's StarSystemTypes.Type (Milestone 10).

var display_name := ""
var star_radius := 46.0
var star_color := Color(1.0, 0.92, 0.55)
## StarSystemTypes.Type; plain int to match star_type everywhere else.
var star_type: int = StarSystemTypes.Type.YELLOW_STAR
var _nebula_tint := Color(0, 0, 0, 0)
var _pulse_time := 0.0


func setup(system_data: StarSystemData) -> void:
	display_name = system_data.display_name
	star_type = system_data.star_type
	var def: Dictionary = StarSystemTypes.DEFS[star_type]
	star_color = def["color"]
	star_radius = 46.0 * float(def["radius_mult"])
	if bool(def["nebula"]):
		var tints := StarSystemTypes.NEBULA_TINTS
		_nebula_tint = tints[system_data.system_index % tints.size()]
	set_process(bool(def["pulse"]))
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var def: Dictionary = StarSystemTypes.DEFS[star_type]
	if _nebula_tint.a > 0.0:
		for i in 3:
			draw_circle(Vector2(cos(i * 2.1) * 60.0, sin(i * 2.1) * 60.0), 260.0 - i * 30.0, _nebula_tint)
	var pulse := 1.0 + (0.15 * sin(_pulse_time * 4.0) if bool(def["pulse"]) else 0.0)
	var glow := Color(star_color.r, star_color.g, star_color.b, 0.18)
	_draw_star_body(Vector2.ZERO, star_radius * pulse, star_color, glow)
	if bool(def["binary"]):
		var companion_offset := Vector2(star_radius * 2.4, 0.0)
		_draw_star_body(companion_offset, star_radius * 0.6, star_color.lightened(0.2), glow)
		_draw_star_body(-companion_offset, star_radius * 0.6, star_color.lightened(0.2), glow)
	if display_name != "":
		var font := ThemeDB.fallback_font
		var label := "%s - %s" % [display_name, StarSystemTypes.display_name(star_type)]
		draw_string(font, Vector2(-140, -star_radius * 2.4 - 14.0), label,
				HORIZONTAL_ALIGNMENT_CENTER, 280, 9, Color(1, 1, 1, 0.55))


func _draw_star_body(center: Vector2, radius: float, color: Color, glow: Color) -> void:
	draw_circle(center, radius * 2.2, glow)
	draw_circle(center, radius * 1.5, Color(glow.r, glow.g, glow.b, glow.a * 1.6))
	draw_circle(center, radius, color)
