extends Area2D
## Player blaster bolt: flies straight, damages the first body it hits
## (enemy or terrain), then frees itself.

const SPEED := 340.0
const LIFETIME := 0.9

var direction := Vector2.RIGHT
var damage := 1

var _age := 0.0


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()
