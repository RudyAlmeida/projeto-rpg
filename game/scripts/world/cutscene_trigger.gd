class_name CutsceneTrigger
extends Area2D
## Plays `cutscene` the first time the player walks in (skipped once its flag is set).

@export var cutscene: Cutscene

var _running := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _running or not body is Player or cutscene == null:
		return
	if cutscene.once_flag != &"" and GameState.get_flag(cutscene.once_flag):
		return
	_running = true
	await cutscene.play(get_parent())
	_running = false
