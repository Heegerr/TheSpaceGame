class_name FloatingText
extends Label
## Short-lived world-space floating text (pickup amounts, damage numbers).


static func spawn(parent: Node, world_position: Vector2, text_value: String, color: Color = Color.WHITE) -> void:
	var label := FloatingText.new()
	label.text = text_value
	label.modulate = color
	label.z_index = 50
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.position = world_position + Vector2(-40, -6)
	label.size = Vector2(80, 12)
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 22.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)
