extends Node2D
## Phase 1 prototype map: places the player on the layout's spawn point, clamps the camera
## to the map and plays the town theme.

const MUSIC := preload("res://assets/audio/music/bgm_vila_caldeira_test_a.mp3")

@onready var _map: AsciiMap = $Map
@onready var _player: Player = $Player
@onready var _music: AudioStreamPlayer = $Music


func _ready() -> void:
	_player.position = _map.spawn_position
	_player.set_camera_limits(_map.pixel_rect())
	var stream := MUSIC.duplicate() as AudioStreamMP3
	stream.loop = true
	_music.stream = stream
	_music.play()
