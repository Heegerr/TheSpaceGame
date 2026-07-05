class_name Star
extends Node2D
## Visual anchor for a star system: drawn at the system's center with its
## orbiting planets placed around it by PlanetField. Not landable or
## interactable itself. Star type visuals (color/size/effects) land in
## Milestone 10; today every star uses the same yellow-star look.

var display_name := ""
var star_radius := 46.0
var star_color := Color(1.0, 0.92, 0.55)
var glow_color := Color(1.0, 0.92, 0.55, 0.18)


func setup(system_data: StarSystemData) -> void:
	display_name = system_data.display_name
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, star_radius * 2.2, glow_color)
	draw_circle(Vector2.ZERO, star_radius * 1.5, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 1.6))
	draw_circle(Vector2.ZERO, star_radius, star_color)
	if display_name != "":
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-120, -star_radius - 14.0), display_name,
				HORIZONTAL_ALIGNMENT_CENTER, 240, 9, Color(1, 1, 1, 0.55))
