extends GutTest
## Dialogue box behaviour and talking to an NPC on the real test map.

var level: Node2D
var player: Player
var npc: NPC


func before_each() -> void:
	level = load("res://scenes/maps/test_map.tscn").instantiate()
	add_child_autofree(level)
	level.get_node("Music").stop()
	player = level.get_node("Player")
	# A test NPC right below the player (player spawns facing down).
	npc = load("res://scenes/characters/npc.tscn").instantiate()
	npc.dialogue = [DialogueLine.make("Gerd", "Primeira fala."), DialogueLine.make("Kael", "Segunda fala.")] as Array[DialogueLine]
	npc.position = player.position + Vector2(0, 16)
	level.add_child(npc)
	await wait_physics_frames(2)


func after_each() -> void:
	# Close any conversation left open so the autoload is clean for the next test.
	# Bounded, so a regression in the box can never hang the test run again.
	var box := DialogueManager.box()
	for i in 20:
		if not box.is_open():
			break
		box.confirm()
	assert_false(box.is_open(), "dialogue box failed to close")
	Input.action_release(&"move_left")


func test_interacting_with_npc_opens_dialogue() -> void:
	assert_true(player.try_interact())
	assert_true(DialogueManager.is_active)
	assert_true(DialogueManager.box().is_open())


func test_nothing_in_front_means_no_dialogue() -> void:
	npc.position += Vector2(200, 0)
	await wait_physics_frames(2)
	assert_false(player.try_interact())
	assert_false(DialogueManager.is_active)


func test_text_types_out_then_confirm_reveals_all() -> void:
	player.try_interact()
	var box := DialogueManager.box()
	assert_true(box.is_typing(), "starts typing")
	box.confirm()
	assert_false(box.is_typing(), "confirm reveals the full line")
	assert_eq(box.get_node("Panel/Name").text, "Gerd")


func test_confirm_advances_and_closes_after_last_line() -> void:
	player.try_interact()
	var box := DialogueManager.box()
	watch_signals(DialogueManager)
	box.confirm()  # reveal line 1
	box.confirm()  # go to line 2
	assert_eq(box.get_node("Panel/Name").text, "Kael")
	box.confirm()  # reveal line 2
	box.confirm()  # close
	await wait_process_frames(1)
	assert_false(box.is_open())
	assert_false(DialogueManager.is_active)
	assert_signal_emitted(DialogueManager, "dialogue_finished")


func test_player_cannot_move_during_dialogue() -> void:
	player.try_interact()
	var start := player.position
	Input.action_press(&"move_left")
	await wait_physics_frames(20)
	assert_eq(player.position, start)


func test_npc_turns_to_face_player() -> void:
	player.try_interact()
	var sprite: Sprite2D = npc.get_node("Sprite")
	# Player is above the NPC, so the NPC must face up (column 2).
	assert_eq(sprite.region_rect.position.x, 2.0 * Player.FRAME_SIZE)
