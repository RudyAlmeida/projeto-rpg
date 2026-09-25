extends Node
## Autoload "AudioManager": background music that survives scene changes.
## Asking for the track that is already playing keeps it going (no restart between rooms).
## Battles push their theme and pop back to the map music afterwards.

var _music: AudioStreamPlayer
var _stack: Array[AudioStream] = []
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
