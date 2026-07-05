extends Node2D
## Simple walkable cockpit/bridge interior for the player's landed ship
## (Milestone 18). Fixed-size room (not procedural - there's only one ship),
## with an Upgrade Terminal and an exit hatch. Reuses player_on_foot.tscn
## wholesale since walking/interacting is all that's needed here; there is no
## combat inside the ship, so its health/attack systems just sit unused.

const ROOM_HALF_WIDTH := 110.0
const ROOM_HALF_HEIGHT := 70.0

@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	camera.limit_left = int(-ROOM_HALF_WIDTH)
	camera.limit_right = int(ROOM_HALF_WIDTH)
	camera.limit_top = int(-ROOM_HALF_HEIGHT)
	camera.limit_bottom = int(ROOM_HALF_HEIGHT)
	camera.reset_smoothing()
	queue_redraw()


func _draw() -> void:
	var size := Vector2(ROOM_HALF_WIDTH * 2.0, ROOM_HALF_HEIGHT * 2.0)
	draw_rect(Rect2(-ROOM_HALF_WIDTH, -ROOM_HALF_HEIGHT, size.x, size.y), Color(0.16, 0.17, 0.22))
	for x in range(-int(ROOM_HALF_WIDTH) + 16, int(ROOM_HALF_WIDTH), 32):
		draw_line(Vector2(x, -ROOM_HALF_HEIGHT), Vector2(x, ROOM_HALF_HEIGHT), Color(0.2, 0.21, 0.27), 1.0)
	draw_rect(Rect2(-ROOM_HALF_WIDTH, -ROOM_HALF_HEIGHT, size.x, size.y), Color(0.32, 0.35, 0.42), false, 3.0)
