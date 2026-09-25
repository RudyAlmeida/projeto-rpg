extends GutTest
## SceneManager fades, doors (Warp) and spawn points. Inside GUT there is no current scene,
## so change_scene() adds the map next to the runner; after_each unloads it again.


func after_each() -> void:
	if get_tree().current_scene:
		get_tree().unload_current_scene()
	AudioManager.stop_music()
	for action in [&"move_up", &"move_down"]:
		Input.action_release(action)


func _go(scene: String, spawn: String) -> void:
	SceneManager.change_scene(scene, spawn)
	await wait_for_signal(SceneManager.transition_finished, 3.0)


func test_change_scene_places_player_on_named_spawn() -> void:
	await _go("res://scenes/maps/test_house.tscn", "entrance")
	var house := get_tree().current_scene as FieldMap
	assert_eq(house.name, &"TestHouse")
	assert_eq(house.player.position, house.spawn_point("entrance").position)
	assert_eq(house.player.facing, Player.Facing.UP, "spawn sets facing")


func test_fade_is_clear_after_transition() -> void:
	await _go("res://scenes/maps/test_house.tscn", "entrance")
	assert_eq(SceneManager.fade_alpha(), 0.0)
	assert_false(SceneManager.is_transitioning)


func test_player_cannot_move_while_fading() -> void:
	SceneManager.change_scene("res://scenes/maps/test_house.tscn", "entrance")
	assert_true(SceneManager.is_transitioning)
	var player := Player.new()
	assert_false(player.can_move())
	player.free()
	await wait_for_signal(SceneManager.transition_finished, 3.0)


func test_unknown_spawn_falls_back_to_layout_p() -> void:
	await _go("res://scenes/maps/test_house.tscn", "nope")
	var house := get_tree().current_scene as FieldMap
	assert_eq(house.player.position, house.map.spawn_position)


func test_walking_through_door_goes_back_to_village() -> void:
	await _go("res://scenes/maps/test_house.tscn", "entrance")
	Input.action_press(&"move_down")
	await wait_for_signal(SceneManager.transition_started, 5.0)
	Input.action_release(&"move_down")  # the door fired; stop walking before arriving
	await wait_for_signal(SceneManager.transition_finished, 3.0)
	var village := get_tree().current_scene as FieldMap
	assert_eq(village.name, &"TestMap")
	assert_eq(village.player.position, village.spawn_point("from_house").position)


func test_same_music_keeps_playing_between_rooms() -> void:
	await _go("res://scenes/maps/test_map.tscn", "from_house")
	var track := AudioManager.current_music()
	assert_not_null(track)
	await _go("res://scenes/maps/test_house.tscn", "entrance")
	assert_eq(AudioManager.current_music(), track, "same stream object, not restarted")
	assert_true(AudioManager.is_music_playing())


func test_camera_rect_centres_small_maps() -> void:
	var rect := FieldMap.camera_rect(Rect2i(0, 0, 224, 128), Vector2(640, 360))
	assert_eq(rect, Rect2i(-208, -116, 640, 360))


func test_camera_rect_keeps_big_maps() -> void:
	var rect := FieldMap.camera_rect(Rect2i(0, 0, 768, 448), Vector2(640, 360))
	assert_eq(rect, Rect2i(0, 0, 768, 448))
