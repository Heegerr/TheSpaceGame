extends Node2D
## Space scene controller: restores ship state after returning from a planet
## and handles approaching/landing on the nearest planet.

const LAND_DISTANCE := 70.0

@onready var ship: CharacterBody2D = $PlayerShip
@onready var planet_field: Node2D = $PlanetField

var _nearby_planet: SpacePlanet


func _ready() -> void:
	if not GameManager.ship_state.is_empty():
		ship.position = GameManager.ship_state.get("position", Vector2.ZERO)
		ship.rotation = GameManager.ship_state.get("rotation", 0.0)
		(ship.get_node("Camera2D") as Camera2D).reset_smoothing()


func _process(_delta: float) -> void:
	var best: SpacePlanet = null
	var best_distance := INF
	for planet: SpacePlanet in planet_field.planets:
		var distance := ship.position.distance_to(planet.position) - planet.data.radius
		if distance < LAND_DISTANCE and distance < best_distance:
			best_distance = distance
			best = planet
	if best != _nearby_planet:
		if _nearby_planet != null:
			_nearby_planet.highlighted = false
		_nearby_planet = best
		if _nearby_planet != null:
			_nearby_planet.highlighted = true


func _unhandled_input(event: InputEvent) -> void:
	if _nearby_planet == null:
		return
	if event.is_action_pressed("interact"):
		_land()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := get_global_mouse_position()
		if mouse.distance_to(_nearby_planet.global_position) <= _nearby_planet.data.radius + 10.0:
			_land()


func _land() -> void:
	GameManager.land_on_planet(_nearby_planet.data, ship)
