extends Node2D
## Builds a three-depth parallax starfield from runtime-generated textures,
## so no image assets are needed.

const TILE := 512
const LAYER_SPECS := [
	{"scroll": 0.12, "count": 240, "brightness": 0.45, "big_chance": 0.0},
	{"scroll": 0.3, "count": 120, "brightness": 0.75, "big_chance": 0.1},
	{"scroll": 0.55, "count": 55, "brightness": 1.0, "big_chance": 0.3},
]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for spec: Dictionary in LAYER_SPECS:
		var layer := Parallax2D.new()
		layer.scroll_scale = Vector2.ONE * float(spec.scroll)
		layer.repeat_size = Vector2(TILE, TILE)
		layer.repeat_times = 3
		add_child(layer)
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = _make_star_texture(rng, int(spec.count), float(spec.brightness), float(spec.big_chance))
		layer.add_child(sprite)


func _make_star_texture(rng: RandomNumberGenerator, count: int, brightness: float, big_chance: float) -> ImageTexture:
	var img := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	for i in count:
		var x := rng.randi_range(0, TILE - 2)
		var y := rng.randi_range(0, TILE - 2)
		var tint := Color(1, 1, 1)
		var roll := rng.randf()
		if roll < 0.15:
			tint = Color(0.72, 0.82, 1.0)
		elif roll < 0.25:
			tint = Color(1.0, 0.86, 0.7)
		var a := brightness * rng.randf_range(0.5, 1.0)
		var color := Color(tint.r, tint.g, tint.b, a)
		img.set_pixel(x, y, color)
		if rng.randf() < big_chance:
			img.set_pixel(x + 1, y, color)
			img.set_pixel(x, y + 1, color)
			img.set_pixel(x + 1, y + 1, color)
	return ImageTexture.create_from_image(img)
