extends Node
## Autoload "Sfx": procedurally generated placeholder sounds played through
## AudioStreamGenerator. One-shots are pre-synthesized PCM clips pushed into a
## generator buffer on play; the ship engine hum is streamed continuously.
## These are placeholders until real assets land in audio/sfx and audio/music.

const MIX_RATE := 22050.0

var _players: Dictionary[String, AudioStreamPlayer] = {}
var _clips: Dictionary[String, PackedVector2Array] = {}

var _engine_player: AudioStreamPlayer
var _engine_playback: AudioStreamGeneratorPlayback
var _engine_phase := 0.0
var _engine_thrust := 0.0
var _engine_level := 0.0


func _ready() -> void:
	_clips["laser"] = _synth_laser()
	_clips["footstep"] = _synth_footstep()
	_clips["pickup"] = _synth_pickup()
	_clips["hit"] = _synth_hit()
	for id in _clips:
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = MIX_RATE
		stream.buffer_length = _clips[id].size() / MIX_RATE + 0.2
		var player := AudioStreamPlayer.new()
		player.stream = stream
		add_child(player)
		_players[id] = player

	var engine_stream := AudioStreamGenerator.new()
	engine_stream.mix_rate = MIX_RATE
	engine_stream.buffer_length = 0.15
	_engine_player = AudioStreamPlayer.new()
	_engine_player.stream = engine_stream
	_engine_player.volume_db = -8.0
	add_child(_engine_player)
	_engine_player.play()
	_engine_playback = _engine_player.get_stream_playback()


func _process(delta: float) -> void:
	if _engine_playback == null:
		return
	# Smooth the thrust level so the hum doesn't click on sudden changes.
	_engine_level = move_toward(_engine_level, _engine_thrust, 3.0 * delta)
	var freq := 46.0 + 50.0 * _engine_level
	while _engine_playback.get_frames_available() > 0:
		_engine_phase = fmod(_engine_phase + freq / MIX_RATE, 1.0)
		var s := sin(_engine_phase * TAU) * 0.16
		s += (randf() * 2.0 - 1.0) * 0.05
		s *= _engine_level
		_engine_playback.push_frame(Vector2(s, s))


## 0 = silent, 1 = full burn. The space scene's ship drives this every frame.
func set_engine_thrust(value: float) -> void:
	_engine_thrust = clampf(value, 0.0, 1.0)


func play_laser() -> void:
	_play("laser", randf_range(0.95, 1.05))


func play_footstep() -> void:
	_play("footstep", randf_range(0.9, 1.1))


func play_pickup() -> void:
	_play("pickup", 1.0)


func play_hit(pitch: float = 1.0) -> void:
	_play("hit", pitch)


func _play(id: String, pitch: float) -> void:
	var player := _players[id]
	player.pitch_scale = pitch
	player.stop()
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		playback.push_buffer(_clips[id])


# -- Synthesis -------------------------------------------------------------------

func _synth_laser() -> PackedVector2Array:
	var duration := 0.16
	var n := int(duration * MIX_RATE)
	var frames := PackedVector2Array()
	frames.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq := lerpf(950.0, 230.0, pow(t, 0.6))
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var square := 1.0 if phase < 0.5 else -1.0
		var s := square * 0.2 * pow(1.0 - t, 1.4)
		frames[i] = Vector2(s, s)
	return frames


func _synth_footstep() -> PackedVector2Array:
	var duration := 0.07
	var n := int(duration * MIX_RATE)
	var frames := PackedVector2Array()
	frames.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / n
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.6 + noise * 0.4
		var s := prev * 0.28 * pow(1.0 - t, 2.2)
		frames[i] = Vector2(s, s)
	return frames


func _synth_pickup() -> PackedVector2Array:
	var duration := 0.16
	var n := int(duration * MIX_RATE)
	var frames := PackedVector2Array()
	frames.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq := 660.0 if t < 0.5 else 990.0
		var local := fmod(t, 0.5) / 0.5
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var s := sin(phase * TAU) * 0.17 * (1.0 - local)
		frames[i] = Vector2(s, s)
	return frames


func _synth_hit() -> PackedVector2Array:
	var duration := 0.12
	var n := int(duration * MIX_RATE)
	var frames := PackedVector2Array()
	frames.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase = fmod(phase + 110.0 / MIX_RATE, 1.0)
		var square := 1.0 if phase < 0.5 else -1.0
		var s := square * 0.3 * pow(1.0 - t, 1.5)
		s += (randf() * 2.0 - 1.0) * 0.35 * pow(1.0 - t, 2.0)
		frames[i] = Vector2(s * 0.8, s * 0.8)
	return frames
