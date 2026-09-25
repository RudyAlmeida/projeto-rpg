class_name Warp
extends Area2D
## Door / exit: when the player steps in, SceneManager moves them to `target_scene`,
## arriving at the spawn point named `target_spawn` in that scene.

@export_file("*.tscn") var target_scene := ""
@export var target_spawn := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not SceneManager.is_transitioning and target_scene != "":
		SceneManager.change_scene(target_scene, target_spawn)
