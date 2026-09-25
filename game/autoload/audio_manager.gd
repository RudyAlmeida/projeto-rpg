extends Node
## Autoload "AudioManager": background music that survives scene changes, and sound
## effects. Asking for the track that is already playing keeps it going (no restart between
## rooms). Battles push their theme and pop back to the map music afterwards.
## Sound effects: play_sfx(&"hit") plays assets/audio/sfx/hit.ogg (Kenney CC0 packs).

const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 8

var _music: AudioStreamPlayer
var _stack: Array[AudioStream] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache := {}
var _next_voice := 0
## 0..1, set from the options menu.
var sfx_volume := 1.0
## 0..1, set from the options menu.
var music_volume := 1.0:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		if _music:
			_music.volume_db = linear_to_db(maxf(music_volume, 0.0001))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = &"Master"
	add_child(_music)
	music_volume = music_volume
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_sfx_players.append(p)


## Plays a sound effect by id (file name in assets/audio/sfx). Unknown ids are ignored.
## `pitch` varies repeated sounds (hits) a little.
func play_sfx(id: StringName, pitch := 1.0, volume := 1.0) -> void:
	if sfx_volume <= 0.0:
		return
	var stream := sfx(id)
	if stream == null:
		return
	var player := _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(maxf(sfx_volume * volume, 0.0001))
	player.play()


func sfx(id: StringName) -> AudioStream:
	if not _sfx_cache.has(id):
		var path := SFX_DIR + String(id) + ".ogg"
		_sfx_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _sfx_cache[id]


func play_music(stream: AudioStream, loop := true) -> void:
	if stream == null:
		stop_music()
		return
	if current_music() == stream and _music.playing:
		return
	_set_loop(stream, loop)
	_music.stream = stream
	_music.play()


## Plays `stream` on top of the current track; pop_music() returns to the previous one.
func push_music(stream: AudioStream, loop := true) -> void:
	_stack.push_back(current_music())
	play_music(stream, loop)


func pop_music() -> void:
	var previous: AudioStream = _stack.pop_back() if not _stack.is_empty() else null
	if previous:
		play_music(previous)
	else:
		stop_music()


func stop_music() -> void:
	_music.stop()
	_music.stream = null


func current_music() -> AudioStream:
	return _music.stream


func is_music_playing() -> bool:
	return _music.playing


static func _set_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
