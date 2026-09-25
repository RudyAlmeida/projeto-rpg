extends Node
## Autoload "SaveManager": save slots as JSON in user://saves/. Each save stores the map,
## the player's position and facing, and GameState. `version` allows future migrations.

const SAVE_DIR := "user://saves"
const VERSION := 1

## Where the player stands when the next map loads after `load_game` (INF = unused).
var pending_position := Vector2.INF
var pending_facing := Player.Facing.DOWN


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Saves the current map (the tree's current scene must be a FieldMap).
func save_game(slot: int) -> Error:
	var map := get_tree().current_scene as FieldMap
	if map == null:
		return ERR_UNAVAILABLE
	return write_save(slot, map.scene_file_path, map.player.position, map.player.facing)


func write_save(slot: int, scene_path: String, position: Vector2, facing: Player.Facing) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"scene": scene_path,
		"position": [position.x, position.y],
		"facing": facing,
		"state": GameState.to_dict(),
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	return OK


## Reads a slot without applying it (for the load menu). Empty dictionary if missing/broken.
func read_save(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	# JSON instance: a broken file returns an error code instead of logging an engine error.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(slot_path(slot))) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or int(parsed.get("version", 0)) > VERSION:
		return {}
	return parsed


## Restores GameState and travels to the saved map and position.
func load_game(slot: int) -> Error:
	var data := read_save(slot)
	if data.is_empty():
		return ERR_FILE_CORRUPT if has_save(slot) else ERR_FILE_NOT_FOUND
	GameState.from_dict(data["state"])
	pending_position = Vector2(data["position"][0], data["position"][1])
	pending_facing = int(data.get("facing", 0)) as Player.Facing
	SceneManager.change_scene(data["scene"])
	return OK


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


## Consumed by FieldMap when it places the player.
func take_pending_position() -> Vector2:
	var pos := pending_position
	pending_position = Vector2.INF
	return pos
