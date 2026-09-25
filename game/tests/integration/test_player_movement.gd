extends GutTest
## Loads the real test map and drives the player with simulated input.

var level: Node2D
var player: Player


func before_each() -> void:
	level = load("res://scenes/maps/test_map.tscn").instantiate()
	add_child_autofree(level)
	player = level.get_node("Player")
	level.get_node("Music").stop()
	await wait_physics_frames(2)


func after_each() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down", &"run"]:
		Input.action_release(action)


func test_player_starts_on_spawn() -> void:
	assert_eq(player.position, level.get_node("Map").spawn_position)


func test_walking_right_moves_and_faces_right() -> void:
	var start := player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(30)
	assert_gt(player.position.x, start.x + 20)
	assert_eq(player.facing, Player.Facing.RIGHT)


func test_running_is_faster_than_walking() -> void:
	var start := player.position
	Input.action_press(&"move_down")
	await wait_physics_frames(20)
	var walked := player.position.y - start.y
	Input.action_press(&"run")
	var run_start := player.position
	await wait_physics_frames(20)
	assert_gt(player.position.y - run_start.y, walked * 1.4)


func test_walls_stop_the_player() -> void:
	# Walk up for a long time: the outer wall (row 0) must stop the player inside the map.
	Input.action_press(&"move_up")
	await wait_physics_frames(400)
	var map: AsciiMap = level.get_node("Map")
	var cell := map.local_to_map(player.position)
	assert_false(map.is_solid_at(cell), "player ended inside a solid tile at %s" % cell)
	assert_gt(player.position.y, 16.0, "player crossed the top wall")


func test_facing_for_direction() -> void:
	assert_eq(Player.facing_for(Vector2.UP), Player.Facing.UP)
	assert_eq(Player.facing_for(Vector2.DOWN), Player.Facing.DOWN)
	assert_eq(Player.facing_for(Vector2(-1, 0.3)), Player.Facing.LEFT)
	assert_eq(Player.facing_for(Vector2(0.7, 0.7)), Player.Facing.RIGHT)
