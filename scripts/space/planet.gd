class_name SpacePlanet
extends Node2D
## A planet in the space scene. Purely visual — approach/landing interaction
## is coordinated by space.gd so only the nearest planet reacts.

var data: PlanetData
var highlighted := false:
	set(value):
		if highlighted != value:
			highlighted = value
			queue_redraw()


func setup(planet_data: PlanetData) -> void:
	data = planet_data
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = data.planet_seed
	draw_circle(Vector2.ZERO, data.radius + 7.0, data.atmosphere_color)
	draw_circle(Vector2.ZERO, data.radius, data.base_color)
	for i in rng.randi_range(5, 9):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(0.0, data.radius * 0.6)
		var blotch_radius := rng.randf_range(data.radius * 0.12, data.radius * 0.3)
		draw_circle(Vector2.from_angle(angle) * dist, blotch_radius, data.accent_color)
	if highlighted:
		draw_arc(Vector2.ZERO, data.radius + 12.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 1.5)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-100, -data.radius - 16.0), data.display_name,
				HORIZONTAL_ALIGNMENT_CENTER, 200, 10, Color(1, 1, 1, 0.95))
		draw_string(font, Vector2(-100, data.radius + 26.0), "Press E to land",
				HORIZONTAL_ALIGNMENT_CENTER, 200, 8, Color(1, 1, 1, 0.7))
