class_name Warp
extends Area2D
## Door / exit: when the player steps in, SceneManager moves them to `target_scene`,
## arriving at the spawn point named `target_spawn` in that scene.

@export_file("*.tscn") var target_scene := ""
@export var target_spawn := ""
## Locked until this flag is set; `locked_lines` play when the player tries it.
@export var require_flag: StringName
@export var locked_lines: Array[DialogueLine] = []
## Where the player is pushed back to (local offset) after a locked message.
@export var push_back := Vector2(0, 12)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or SceneManager.is_transitioning or target_scene == "":
		return
	if require_flag != &"" and not GameState.get_flag(require_flag):
		var player := body as Player
		player.locked = true
		if not locked_lines.is_empty():
			await DialogueManager.play(locked_lines)
		player.position += push_back
		player.locked = false
		return
	SceneManager.change_scene(target_scene, target_spawn)
