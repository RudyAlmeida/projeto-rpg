extends CanvasLayer
## Autoload "SceneManager": scene changes with a fade to black, and the spawn point the
## next map should place the player on.

signal transition_started
signal transition_finished

const FADE_TIME := 0.25

var is_transitioning := false

var _pending_spawn := ""
var _fade: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.101961, 0.0784314, 0.137255)  # palette outline colour, not pure black
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


## Fades out, switches to `scene_path`, remembers `spawn_id` for the new map, fades in.
func change_scene(scene_path: String, spawn_id := "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	transition_started.emit()
	await _fade_to(1.0)
	_pending_spawn = spawn_id
	var err := get_tree().change_scene_to_file(scene_path)
	assert(err == OK, "change_scene_to_file(%s) failed: %s" % [scene_path, error_string(err)])
	await get_tree().scene_changed
	await _fade_to(0.0)
	is_transitioning = false
	transition_finished.emit()


## Returns the spawn id requested by the last transition and clears it (maps call this once).
func take_pending_spawn() -> String:
	var id := _pending_spawn
	_pending_spawn = ""
	return id


func fade_alpha() -> float:
	return _fade.modulate.a


## Fade to black without changing scene (inns, cutscenes).
func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
