extends Node
## Autoload "Music": procedurally generated ambient background pad music,
## continuous across every scene (main menu and gameplay both) since it lives
## on an autoload - same "no art/audio assets yet, generate at runtime"
## approach as Sfx, but streamed forever instead of one-shot clips. Three
## sine voices glide between slow triads (Am-F-C-G) so chord changes never
## click or cut; a slow amplitude LFO gives it a gentle "breathing" feel.
## Volume follows Settings.music_volume live, and stacks with master_volume
## since the player is routed through the "Master" bus like everything else.

const MIX_RATE := 22050.0
const VOICES := 3
const CHORD_DURATION := 7.0
const GLIDE_TIME := 2.5
const VOICE_GAIN := 0.06
const CHORDS: Array[Array] = [
	[220.00, 261.63, 329.63],  # A3 C4 E4 - A minor
	[174.61, 220.00, 261.63],  # F3 A3 C4 - F major
	[130.81, 164.81, 196.00],  # C3 E3 G3 - C major
	[196.00, 246.94, 293.66],  # G3 B3 D4 - G major
]

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: Array[float] = [0.0, 0.0, 0.0]
var _current_freq: Array[float] = []
var _from_freq: Array[float] = []
var _target_freq: Array[float] = []
var _chord_index := 0
var _chord_timer := CHORD_DURATION
var _glide_timer := 0.0
var _lfo_phase := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_current_freq = CHORDS[0].duplicate()
	_from_freq = CHORDS[0].duplicate()
	_target_freq = CHORDS[0].duplicate()

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.5
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.bus = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func _process(delta: float) -> void:
	_advance_chord(delta)
	if _playback == null:
		return
	_lfo_phase = fmod(_lfo_phase + delta * 0.15, 1.0)
	var breathing := 0.75 + 0.25 * sin(_lfo_phase * TAU)
	var volume: float = Settings.music_volume
	while _playback.get_frames_available() > 0:
		var sample := 0.0
		for i in VOICES:
			_phase[i] = fmod(_phase[i] + _current_freq[i] / MIX_RATE, 1.0)
			sample += sin(_phase[i] * TAU) * VOICE_GAIN
		sample *= breathing * volume
		_playback.push_frame(Vector2(sample, sample))


func _advance_chord(delta: float) -> void:
	_chord_timer -= delta
	if _chord_timer <= 0.0:
		_chord_timer = CHORD_DURATION
		_chord_index = (_chord_index + 1) % CHORDS.size()
		_from_freq = _current_freq.duplicate()
		_target_freq = CHORDS[_chord_index].duplicate()
		_glide_timer = GLIDE_TIME
	if _glide_timer > 0.0:
		_glide_timer = maxf(0.0, _glide_timer - delta)
		var t := 1.0 - _glide_timer / GLIDE_TIME
		for i in VOICES:
			_current_freq[i] = lerpf(_from_freq[i], _target_freq[i], t)
