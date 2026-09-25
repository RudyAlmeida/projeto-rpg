class_name AsciiMap
extends TileMapLayer
## Prototype map built from a text layout (Phase 1). Real maps will be painted in the
## editor with Codex tilesets; this keeps early maps readable and diff-friendly.
##
## Legend: "." grass, "," path/floor, "#" wall (solid), "~" water (solid),
## "P" player spawn on grass, "p" player spawn on path/floor.

const TILE_SIZE := 16
const TILESET_TEXTURE := preload("res://assets/tilesets/til_placeholder.png")

## Atlas column of each symbol in til_placeholder.png, and whether it blocks movement.
const LEGEND := {
	".": {"atlas": 0, "solid": false},
	",": {"atlas": 1, "solid": false},
	"#": {"atlas": 2, "solid": true},
	"~": {"atlas": 3, "solid": true},
	"P": {"atlas": 0, "solid": false},
	"p": {"atlas": 1, "solid": false},
}
const SPAWN_SYMBOLS := ["P", "p"]
const ATLAS_COLUMNS := 4

@export_multiline var layout := ""

## Centre of the "P" cell in local coordinates (Vector2.ZERO if the layout has none).
var spawn_position := Vector2.ZERO


func _ready() -> void:
	tile_set = build_tile_set()
	build(layout)


static func build_tile_set() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	set.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = TILESET_TEXTURE
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	set.add_source(source, 0)
	var half := TILE_SIZE / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for column in ATLAS_COLUMNS:
		var coords := Vector2i(column, 0)
		source.create_tile(coords)
		if _is_solid_column(column):
			var data := source.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, square)
	return set


func build(text: String) -> void:
	clear()
	var rows := text.strip_edges().split("\n")
	for y in rows.size():
		var row := rows[y].strip_edges(false, true)
		for x in row.length():
			var symbol := row[x]
			if not LEGEND.has(symbol):
				continue
			set_cell(Vector2i(x, y), 0, Vector2i(LEGEND[symbol]["atlas"], 0))
			if symbol in SPAWN_SYMBOLS:
				spawn_position = map_to_local(Vector2i(x, y))


## Map bounds in pixels, for camera limits.
func pixel_rect() -> Rect2i:
	var used := get_used_rect()
	return Rect2i(used.position * TILE_SIZE, used.size * TILE_SIZE)


func is_solid_at(cell: Vector2i) -> bool:
	var coords := get_cell_atlas_coords(cell)
	return coords.x >= 0 and _is_solid_column(coords.x)


static func _is_solid_column(column: int) -> bool:
	for entry: Dictionary in LEGEND.values():
		if entry["atlas"] == column:
			return entry["solid"]
	return false
