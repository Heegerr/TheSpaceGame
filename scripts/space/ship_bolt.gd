extends Area2D
## Ship weapon bolt. Faction decides what it can hit: player-fired bolts hit
## hostile ships (layer 6), hostile bolts hit the player fleet (layer 2).

const LIFETIME := 1.6

var direction := Vector2.RIGHT
var speed := 480.0
var damage := 2.0

var _age := 0.0


func set_faction(player_fired: bool) -> void:
	collision_mask = 32 if player_fired else 2
	modulate = Color(0.6, 1.0, 0.95) if player_fired else Color(1.0, 0.5, 0.4)


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_ship_damage"):
		body.take_ship_damage(damage, global_position)
	queue_free()
