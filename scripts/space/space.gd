extends Node2D
## Space scene controller: owns the ship roster (flagship + escorts), the
## follow camera, ship switching (Tab), planet landing, and combat mode state
## (driven by the EncounterManager).

const LAND_DISTANCE := 70.0
const SHIP_SCENE := preload("res://scenes/space/player_ship.tscn")
const ESCORT_OFFSETS: Array[Vector2] = [Vector2(-70, 55), Vector2(-70, -55), Vector2(-120, 0)]
const ESCORT_TINT := Color(0.78, 0.9, 1.0)

@onready var planet_field: Node2D = $PlanetField
@onready var camera: Camera2D = $Camera2D
@onready var encounters: Node2D = $EncounterManager
@onready var waves: Node2D = $WaveManager
@onready var hud: CanvasLayer = $HUD

var ships: Array[CharacterBody2D] = []
var active_index := 0
var combat_active := false
var _nearby_planet: SpacePlanet


func _ready() -> void:
	var flagship: CharacterBody2D = $PlayerShip
	_register_ship(flagship)
	if not GameManager.ship_state.is_empty():
		flagship.position = GameManager.ship_state.get("position", Vector2.ZERO)
		flagship.rotation = GameManager.ship_state.get("rotation", 0.0)
	for i in GameManager.fleet_size:
		var escort: CharacterBody2D = SHIP_SCENE.instantiate()
		escort.position = flagship.position + ESCORT_OFFSETS[i % ESCORT_OFFSETS.size()]
		add_child(escort)
		escort.is_player_controlled = false
		escort.is_flagship = false
		_register_ship(escort)
	_set_active(0, true)


func active_ship() -> CharacterBody2D:
	return ships[active_index]


func set_combat(active: bool) -> void:
	if combat_active == active:
		return
	combat_active = active
	for ship in ships:
		if is_instance_valid(ship):
			ship.combat_slowdown = active


func _process(_delta: float) -> void:
	set_combat(encounters.is_any_engaged or waves.is_engaged)
	camera.global_position = active_ship().global_position
	var best: SpacePlanet = null
	var best_distance := INF
	for planet: SpacePlanet in planet_field.planets:
		var distance := active_ship().position.distance_to(planet.position) - planet.data.radius
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
	if event.is_action_pressed("switch_ship") and ships.size() > 1:
		Sfx.set_engine_thrust(0.0)
		_set_active((active_index + 1) % ships.size(), false)
		get_viewport().set_input_as_handled()
		return
	if _nearby_planet == null:
		return
	if event.is_action_pressed("interact"):
		_land()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := get_global_mouse_position()
		if mouse.distance_to(_nearby_planet.global_position) <= _nearby_planet.data.radius + 10.0:
			_land()


func _register_ship(ship: CharacterBody2D) -> void:
	ships.append(ship)
	ship.add_to_group("player_fleet")
	ship.combat_slowdown = combat_active
	ship.destroyed.connect(_on_ship_destroyed)


func _set_active(index: int, snap: bool) -> void:
	active_index = index
	var escort_slot := 0
	for i in ships.size():
		var ship := ships[i]
		ship.is_player_controlled = i == index
		if i == index:
			ship.follow_target = null
			if not ship.is_in_group("player_ship"):
				ship.add_to_group("player_ship")
			ship.modulate = Color.WHITE
		else:
			ship.follow_target = ships[index]
			ship.follow_offset = ESCORT_OFFSETS[escort_slot % ESCORT_OFFSETS.size()]
			escort_slot += 1
			if ship.is_in_group("player_ship"):
				ship.remove_from_group("player_ship")
			ship.modulate = ESCORT_TINT
	hud.bind_ship(active_ship())
	if snap:
		camera.global_position = active_ship().global_position
		camera.reset_smoothing()


func _on_ship_destroyed(ship: CharacterBody2D) -> void:
	if ship == ships[0]:
		# The flagship never dies for good: emergency warp back to the spawn point.
		hud.show_banner("SHIP DESTROYED - emergency warp home", Color(1, 0.4, 0.35))
		ship.position = Vector2.ZERO
		ship.velocity = Vector2.ZERO
		ship.reset_combat_state()
		encounters.reset_aggro()
		set_combat(false)
		if ship == active_ship():
			camera.global_position = ship.global_position
			camera.reset_smoothing()
		return
	hud.show_banner("Escort lost", Color(1, 0.6, 0.4))
	GameManager.fleet_size = maxi(0, GameManager.fleet_size - 1)
	var active := active_ship()
	ships.erase(ship)
	ship.queue_free()
	if ship == active:
		_set_active(0, true)
	else:
		# The erase shifted indices; re-resolve where the active ship now sits.
		_set_active(maxi(ships.find(active), 0), false)


func _land() -> void:
	GameManager.land_on_planet(_nearby_planet.data, active_ship())
