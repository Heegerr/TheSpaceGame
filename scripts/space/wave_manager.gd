extends Node2D
## Escalating alien waves that threaten colonized planets while the player is
## in space. A countdown runs whenever at least one planet is colonized; when
## it hits zero an assault fleet spawns at a colonized planet. Destroy it
## within the time limit or the colony loses a random structure. Surviving
## the boss wave (stage >= BOSS_STAGE) completes the campaign and unlocks
## infinite mode: waves keep coming, scaling with stage, with no more gating.

const ENEMY_SCENE := preload("res://scenes/space/enemy_ship.tscn")
const StructureScript := preload("res://scripts/colony/structure.gd")

const BOSS_STAGE := 5
const WAVE_INTERVAL := 90.0
const WAVE_TIME_LIMIT := 120.0
const ENGAGE_DISTANCE := 520.0

var wave_ships: Array[Node] = []
var wave_timer := 0.0
var target_planet: SpacePlanet
var is_boss_wave := false
var is_engaged := false

@onready var _space: Node2D = get_parent()
@onready var _planet_field: Node2D = _space.get_node("PlanetField")


func _physics_process(delta: float) -> void:
	if wave_ships.is_empty():
		_tick_countdown(delta)
	else:
		_tick_wave(delta)


func _tick_countdown(delta: float) -> void:
	is_engaged = false
	if GameManager.colonized_planet_count() == 0:
		_hud().set_threat(-1.0, 0)
		return
	GameManager.campaign["next_wave_in"] = float(GameManager.campaign.get("next_wave_in", WAVE_INTERVAL)) - delta
	var remaining := float(GameManager.campaign["next_wave_in"])
	_hud().set_threat(remaining, int(GameManager.campaign.get("stage", 0)))
	if remaining <= 0.0:
		_launch_wave()


func _tick_wave(delta: float) -> void:
	wave_timer -= delta
	_hud().set_threat_active(wave_timer, wave_ships.size(), is_boss_wave)
	is_engaged = false
	for ship in wave_ships:
		if not is_instance_valid(ship):
			continue
		for member in get_tree().get_nodes_in_group("player_fleet"):
			if member is Node2D and (ship as Node2D).global_position.distance_to((member as Node2D).global_position) < ENGAGE_DISTANCE:
				is_engaged = true
				break
		if is_engaged:
			break
	if wave_timer <= 0.0:
		_wave_failed()


func _launch_wave() -> void:
	target_planet = _pick_colonized_planet()
	if target_planet == null:
		GameManager.campaign["next_wave_in"] = WAVE_INTERVAL
		return
	var stage := int(GameManager.campaign.get("stage", 0))
	is_boss_wave = stage >= BOSS_STAGE and not bool(GameManager.campaign.get("completed", false))
	wave_timer = WAVE_TIME_LIMIT
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var count := 4 if is_boss_wave else clampi(3 + stage, 3, 10)
	for i in count:
		var kind: int
		if is_boss_wave:
			kind = 3 if i == 0 else 0
		else:
			var roll := rng.randf()
			if roll < maxf(0.3, 0.55 - stage * 0.05):
				kind = 0
			elif roll < 0.8:
				kind = 1
			else:
				kind = 2
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = target_planet.position + Vector2.from_angle(rng.randf_range(0.0, TAU)) * 900.0
		add_child(enemy)
		enemy.setup(kind, target_planet.position)
		enemy.aggro = true
		enemy.died.connect(_on_wave_ship_died)
		wave_ships.append(enemy)
	var template := "BOSS WAVE inbound at %s!" if is_boss_wave else "Alien wave inbound at %s!"
	_hud().show_banner(template % target_planet.data.display_name, Color(1, 0.4, 0.35))


func _on_wave_ship_died(ship: Node) -> void:
	wave_ships.erase(ship)
	if wave_ships.is_empty():
		_wave_cleared()


func _wave_cleared() -> void:
	var campaign := GameManager.campaign
	campaign["waves_survived"] = int(campaign.get("waves_survived", 0)) + 1
	campaign["stage"] = int(campaign.get("stage", 0)) + 1
	campaign["next_wave_in"] = WAVE_INTERVAL
	if is_boss_wave and not bool(campaign.get("completed", false)):
		campaign["completed"] = true
		campaign["infinite"] = true
		_hud().show_banner("CAMPAIGN COMPLETE - INFINITE MODE UNLOCKED", Color(0.5, 1.0, 0.6))
		SteamBridge.unlock("campaign_complete")
	else:
		_hud().show_banner("Wave repelled! Colony safe.", Color(0.5, 1.0, 0.6))
	if int(campaign.get("waves_survived", 0)) == 1:
		SteamBridge.unlock("first_wave")
	if bool(campaign.get("infinite", false)) and int(campaign.get("waves_survived", 0)) >= 10:
		SteamBridge.unlock("infinite_10")
	Inventory.add("alloy", 2 + int(campaign.get("stage", 0)) / 2)
	is_boss_wave = false
	target_planet = null
	GameManager.save_current()
	_hud().set_threat(float(campaign["next_wave_in"]), int(campaign["stage"]))


func _wave_failed() -> void:
	for ship in wave_ships:
		if is_instance_valid(ship):
			ship.queue_free()
	wave_ships.clear()
	if target_planet != null:
		GameManager.remove_random_structure(target_planet.data.planet_seed)
	_hud().show_banner("Colony raided - a structure was destroyed", Color(1, 0.5, 0.3))
	GameManager.campaign["next_wave_in"] = WAVE_INTERVAL
	is_boss_wave = false
	target_planet = null
	GameManager.save_current()


func _pick_colonized_planet() -> SpacePlanet:
	var candidates: Array[SpacePlanet] = []
	for planet: SpacePlanet in _planet_field.planets:
		var record: Dictionary = GameManager.planets.get(str(planet.data.planet_seed), {})
		for entry in record.get("structures", []):
			if int(entry.get("type", -1)) == StructureScript.Type.HABITAT:
				candidates.append(planet)
				break
	if candidates.is_empty():
		return null
	return candidates[randi_range(0, candidates.size() - 1)]


func _hud() -> CanvasLayer:
	return _space.get_node("HUD")
