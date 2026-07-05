extends Node2D
## Spawns hostile patrols near planets and manages engagement: entering a
## patrol's engage radius flips the space scene into combat mode, clearing an
## engaged patrol awards salvage, fleeing far enough disengages. Patrol
## strength scales with campaign stage and colonized planets.

const ENEMY_SCENE := preload("res://scenes/space/enemy_ship.tscn")
const ENGAGE_DISTANCE := 520.0
const DISENGAGE_DISTANCE := 950.0

var patrols: Array[Dictionary] = []
var is_any_engaged := false

@onready var _space: Node2D = get_parent()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameManager.galaxy_seed + 777
	var threat := int(GameManager.campaign.get("stage", 0)) + GameManager.colonized_planet_count() / 2
	var planet_field: Node2D = _space.get_node("PlanetField")
	if planet_field.planets.is_empty():
		return
	var patrol_count := clampi(3 + threat, 3, 8)
	for i in patrol_count:
		var planet: SpacePlanet = planet_field.planets[rng.randi_range(0, planet_field.planets.size() - 1)]
		var anchor: Vector2 = planet.position + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(380.0, 650.0)
		var ship_count := rng.randi_range(2, 3 + mini(threat, 3))
		var patrol := {"ships": [], "engaged": false}
		for j in ship_count:
			var enemy := ENEMY_SCENE.instantiate()
			enemy.position = anchor + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(20.0, 90.0)
			add_child(enemy)
			enemy.add_to_group("hostile_ship")
			enemy.setup(_pick_kind(rng, threat), anchor)
			enemy.died.connect(_on_enemy_died.bind(patrol))
			patrol["ships"].append(enemy)
		patrols.append(patrol)


func reset_aggro() -> void:
	for patrol in patrols:
		patrol["engaged"] = false
		for ship in patrol["ships"]:
			if is_instance_valid(ship):
				ship.aggro = false


func _physics_process(_delta: float) -> void:
	var any_engaged := false
	for patrol in patrols:
		if patrol["ships"].is_empty():
			continue
		var nearest := _nearest_fleet_distance(patrol)
		if not patrol["engaged"] and nearest < ENGAGE_DISTANCE:
			patrol["engaged"] = true
			for ship in patrol["ships"]:
				if is_instance_valid(ship):
					ship.aggro = true
			_hud_banner("COMBAT MODE", Color(1, 0.4, 0.35))
		elif patrol["engaged"] and nearest > DISENGAGE_DISTANCE:
			patrol["engaged"] = false
			for ship in patrol["ships"]:
				if is_instance_valid(ship):
					ship.aggro = false
		any_engaged = any_engaged or bool(patrol["engaged"])
	is_any_engaged = any_engaged


func _pick_kind(rng: RandomNumberGenerator, threat: int) -> int:
	var roll := rng.randf()
	var dart_weight := maxf(0.3, 0.55 - threat * 0.04)
	if roll < dart_weight:
		return 0
	if roll < 0.8:
		return 1
	return 2


func _nearest_fleet_distance(patrol: Dictionary) -> float:
	var best := INF
	for ship in patrol["ships"]:
		if not is_instance_valid(ship):
			continue
		for member in get_tree().get_nodes_in_group("player_fleet"):
			if member is Node2D:
				best = minf(best, ship.global_position.distance_to((member as Node2D).global_position))
	return best


func _on_enemy_died(ship: Node, patrol: Dictionary) -> void:
	patrol["ships"].erase(ship)
	if patrol["engaged"] and patrol["ships"].is_empty():
		patrol["engaged"] = false
		_award_loot()


func _award_loot() -> void:
	var ore := randi_range(4, 8)
	var scrap := randi_range(3, 6)
	var alloy := randi_range(0, 2)
	Inventory.add("ore", ore)
	Inventory.add("scrap", scrap)
	if alloy > 0:
		Inventory.add("alloy", alloy)
	_hud_banner("VICTORY  +%d Ore  +%d Scrap  +%d Alloy" % [ore, scrap, alloy], Color(1, 0.85, 0.4))
	Sfx.play_pickup()


func _hud_banner(text: String, color: Color) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_banner(text, color)
