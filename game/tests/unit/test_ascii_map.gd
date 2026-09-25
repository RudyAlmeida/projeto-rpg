extends GutTest

const LAYOUT := "#####\n#.P~#\n#,,,#\n#####"

var map: AsciiMap


func before_each() -> void:
	map = AsciiMap.new()
	map.layout = LAYOUT
	add_child_autofree(map)


func test_builds_every_cell() -> void:
	assert_eq(map.get_used_rect(), Rect2i(0, 0, 5, 4))


func test_walls_and_water_are_solid() -> void:
	assert_true(map.is_solid_at(Vector2i(0, 0)), "wall")
	assert_true(map.is_solid_at(Vector2i(3, 1)), "water")
	assert_false(map.is_solid_at(Vector2i(1, 1)), "grass")
	assert_false(map.is_solid_at(Vector2i(2, 2)), "path")


func test_spawn_is_centre_of_p_cell() -> void:
	assert_eq(map.spawn_position, Vector2(2 * 16 + 8, 1 * 16 + 8))


func test_lowercase_p_spawns_on_floor() -> void:
	map.build("###\n#p#\n###")
	assert_eq(map.spawn_position, Vector2(24, 24))
	assert_eq(map.get_cell_atlas_coords(Vector2i(1, 1)), Vector2i(1, 0), "floor tile, not grass")


func test_pixel_rect_for_camera_limits() -> void:
	assert_eq(map.pixel_rect(), Rect2i(0, 0, 80, 64))


func test_every_row_of_test_map_has_same_width() -> void:
	var scene: PackedScene = load("res://scenes/maps/test_map.tscn")
	var state := scene.get_state()
	var layout := ""
	for i in state.get_node_property_count(1):
		if state.get_node_property_name(1, i) == &"layout":
			layout = state.get_node_property_value(1, i)
	var rows := layout.strip_edges().split("\n")
	assert_gt(rows.size(), 10)
	for row in rows:
		assert_eq(row.length(), rows[0].length(), "row: %s" % row)
