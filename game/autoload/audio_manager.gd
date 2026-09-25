extends Node
## Autoload "AudioManager": background music that survives scene changes.
## Asking for the track that is already playing keeps it going (no restart between rooms).

var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = &"Master"
	add_child(_music)


func play_music(stream: AudioStream) -> void:
	if stream == null:
		stop_music()
		return
	if current_music() == stream and _music.playing:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()
	_music.stream = null


func current_music() -> AudioStream:
	return _music.stream


func is_music_playing() -> bool:
	return _music.playing
