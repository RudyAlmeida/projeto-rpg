class_name Cutscene
extends Resource
## A scripted scene: steps run in order while the player is locked.
## `once_flag` is set at the end; triggers skip cutscenes whose flag is already set.
## A CHANGE_SCENE or END_CHAPTER step ends the cutscene (the map goes away).

signal finished

@export var id: StringName
@export var once_flag: StringName
@export var steps: Array[CutsceneStep] = []

## Title screen, where END_CHAPTER returns after the save prompt.
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"


## Runs the cutscene on `map` (a FieldMap).
func play(map: Node) -> void:
	var player: Player = map.get_node_or_null("Player")
	if player:
		player.locked = true
	var leaves_map := false
	for step in steps:
		if step.type == CutsceneStep.Type.CHANGE_SCENE or step.type == CutsceneStep.Type.END_CHAPTER:
			leaves_map = true
			if once_flag != &"":
				GameState.set_flag(once_flag)
		await _run_step(map, step)
		if leaves_map:
			break
	if not leaves_map:
		if once_flag != &"":
			GameState.set_flag(once_flag)
		if player and is_instance_valid(player):
			player.locked = false
	finished.emit()


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
		CutsceneStep.Type.FINISH_QUEST:
			GameState.finish_quest(step.id)
		CutsceneStep.Type.COMPLETE_OBJECTIVE:
			var parts := String(step.id).split(":")
			GameState.complete_objective(StringName(parts[0]), StringName(parts[1]))
		CutsceneStep.Type.GIVE_ITEM:
			GameState.add_item(step.id, step.amount)
		CutsceneStep.Type.REMOVE_ITEM:
			GameState.remove_item(step.id, step.amount)
		CutsceneStep.Type.GIVE_MONEY:
			GameState.add_money(step.amount)
		CutsceneStep.Type.PLAY_MUSIC:
			AudioManager.play_music(step.music)
		CutsceneStep.Type.STOP_MUSIC:
			AudioManager.stop_music()
		CutsceneStep.Type.JOIN_PARTY:
			join_party(step.id, step.amount)
		CutsceneStep.Type.LEAVE_PARTY:
			leave_party(step.id)
		CutsceneStep.Type.RESTORE_PARTY:
			for member in GameState.party:
				member.restore()
		CutsceneStep.Type.BATTLE:
			if map.has_method(&"fight"):
				await map.fight(step.enemies, FieldMap.Encounter.NORMAL, step.music, step.end_after_turns)
		CutsceneStep.Type.CHANGE_SCENE:
			SceneManager.change_scene(step.text, String(step.id))
		CutsceneStep.Type.SHAKE:
			await shake(map, step.seconds, step.strength)
		CutsceneStep.Type.FLASH:
			await flash(map, step.color, step.seconds)
		CutsceneStep.Type.SHOW:
			if node is CanvasItem:
				(node as CanvasItem).show()
		CutsceneStep.Type.HIDE:
			if node is CanvasItem:
				(node as CanvasItem).hide()
		CutsceneStep.Type.TELEPORT:
			if node is Node2D:
				(node as Node2D).position = step.position
				if node.has_method(&"face"):
					node.face(step.facing)
		CutsceneStep.Type.END_CHAPTER:
			await ChapterCard.show_card(map.get_tree(), step.text)
			await MainMenu.open_save(map.get_tree()).closed
			SceneManager.change_scene(TITLE_SCENE)


## Adds a hero (no-op if already there). `level` 0 = the party's average level.
static func join_party(character_id: StringName, level := 0) -> void:
	if GameState.party.any(func(m: PartyMember) -> bool: return m.data.id == character_id):
		return
	var data := DataRegistry.character(character_id)
	if data == null:
		push_error("join_party: unknown character %s" % character_id)
		return
	if level <= 0:
		var total := 0
		for m in GameState.party:
			total += m.level
		level = maxi(1, roundi(float(total) / maxi(1, GameState.party.size())))
	GameState.party.append(PartyMember.new(data, level))


static func leave_party(character_id: StringName) -> void:
	for i in GameState.party.size():
		if GameState.party[i].data.id == character_id:
			GameState.party.remove_at(i)
			return


## Shakes the player's camera (explosions, the airship, the Triturador falling).
static func shake(map: Node, seconds: float, strength: float) -> void:
	var camera: Camera2D = map.get_viewport().get_camera_2d()
	if camera == null:
		return
	var tree := map.get_tree()
	var elapsed := 0.0
	while elapsed < seconds:
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()
		await tree.create_timer(0.04).timeout
		elapsed += 0.04
	camera.offset = Vector2.ZERO


## Full-screen flash that fades out (explosions, Eco waking up).
static func flash(map: Node, color: Color, seconds: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	map.add_child(layer)
	var tween := map.create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, seconds)
	await tween.finished
	layer.queue_free()
