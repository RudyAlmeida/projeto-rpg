class_name Cutscene
extends Resource
## A scripted scene: steps run in order while the player is locked.
## `once_flag` is set at the end; triggers skip cutscenes whose flag is already set.

@export var id: StringName
@export var once_flag: StringName
@export var steps: Array[CutsceneStep] = []


## Runs the cutscene on `map` (a FieldMap).
func play(map: Node) -> void:
	var player: Player = map.get_node_or_null("Player")
	if player:
		player.locked = true
	for step in steps:
		await _run_step(map, step)
	if once_flag != &"":
		GameState.set_flag(once_flag)
	if player:
		player.locked = false


func _run_step(map: Node, step: CutsceneStep) -> void:
	var node: Node = map.get_node_or_null(step.actor) if not step.actor.is_empty() else null
	match step.type:
		CutsceneStep.Type.SAY:
			await DialogueManager.play(step.lines)
		CutsceneStep.Type.MOVE:
			if node and node.has_method(&"walk_to"):
				await node.walk_to(step.position, step.speed)
		CutsceneStep.Type.FACE:
			if node and node.has_method(&"face"):
				node.face(step.facing)
		CutsceneStep.Type.WAIT:
			await map.get_tree().create_timer(step.seconds).timeout
		CutsceneStep.Type.FADE_OUT:
			await SceneManager.fade_out()
		CutsceneStep.Type.FADE_IN:
			await SceneManager.fade_in()
		CutsceneStep.Type.SET_FLAG:
			GameState.set_flag(step.id)
		CutsceneStep.Type.START_QUEST:
			GameState.start_quest(step.id)
		CutsceneStep.Type.GIVE_ITEM:
			GameState.add_item(step.id, step.amount)
		CutsceneStep.Type.PLAY_MUSIC:
			AudioManager.play_music(step.music)
