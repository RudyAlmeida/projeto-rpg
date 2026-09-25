class_name CutsceneTrigger
extends Area2D
## Plays `cutscene` the first time the player walks in (skipped once its flag is set).
## `autostart`: plays as soon as the map is ready instead (scene openings).
## Gated by `show_if_flag` / `hide_if_flag` (FlagGate).

@export var cutscene: Cutscene
@export var autostart := false
@export var show_if_flag: StringName
@export var hide_if_flag: StringName

var _running := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if autostart:
		_autostart.call_deferred()


func _autostart() -> void:
	await get_tree().process_frame  # let the map place the player first
	await _try_play()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		await _try_play()


func _try_play() -> void:
	if _running or cutscene == null or not FlagGate.passes(show_if_flag, hide_if_flag):
		return
	if cutscene.once_flag != &"" and GameState.get_flag(cutscene.once_flag):
		return
	_running = true
	await cutscene.play(get_parent())
	_running = false
