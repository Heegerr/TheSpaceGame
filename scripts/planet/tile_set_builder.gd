class_name TileSetBuilder
extends RefCounted
## Builds the placeholder 32 px surface TileSet at runtime so no image assets
## are needed. Atlas layout: column = variant, row = biome.
## Variants: 0 low ground, 1 main ground, 2 alt ground, 3 obstacle (collides).

const TILE_SIZE := 32
const VARIANTS := 4
const VARIANT_LOW := 0
const VARIANT_GROUND := 1
const VARIANT_ALT := 2
const VARIANT_OBSTACLE := 3


static func build() -> TileSet:
	var img := Image.create_empty(TILE_SIZE * VARIANTS, TILE_SIZE * PlanetData.BIOME_COUNT, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for biome in PlanetData.BIOME_COUNT:
		var colors := PlanetData.tile_colors_for(biome)
		for variant in VARIANTS:
			_paint_tile(img, rng, variant * TILE_SIZE, biome * TILE_SIZE, colors, variant)

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_source(source, 0)

	for biome in PlanetData.BIOME_COUNT:
		for variant in VARIANTS:
			var coords := Vector2i(variant, biome)
			source.create_tile(coords)
			if variant == VARIANT_OBSTACLE:
				var tile_data := source.get_tile_data(coords, 0)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
				]))
	return tile_set


static func _paint_tile(img: Image, rng: RandomNumberGenerator, ox: int, oy: int, colors: Array[Color], variant: int) -> void:
	# Obstacle tiles sit on the main ground color with a rock blob on top.
	var base: Color = colors[variant] if variant < VARIANT_OBSTACLE else colors[VARIANT_GROUND]
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var f := rng.randf_range(-0.05, 0.05)
			var c := Color(clampf(base.r + f, 0.0, 1.0), clampf(base.g + f, 0.0, 1.0), clampf(base.b + f, 0.0, 1.0))
			if rng.randf() < 0.03:
				c = c.darkened(0.18)
			img.set_pixel(ox + x, oy + y, c)
	if variant == VARIANT_OBSTACLE:
		var rock: Color = colors[VARIANT_OBSTACLE]
		var center := Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		for y in TILE_SIZE:
			for x in TILE_SIZE:
				var dist := Vector2(x + 0.5, y + 0.5).distance_to(center) + rng.randf_range(-1.6, 1.6)
				if dist < 13.0:
					var c := rock
					if dist > 10.5:
						c = rock.darkened(0.3)
					elif y < TILE_SIZE / 2 and rng.randf() < 0.25:
						c = rock.lightened(0.12)
					img.set_pixel(ox + x, oy + y, c)
