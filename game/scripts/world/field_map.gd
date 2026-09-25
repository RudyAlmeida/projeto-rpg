class_name FieldMap
extends Node2D
## Base script for explorable maps. Expects children "Map" (AsciiMap) and "Player", and an
## optional "Spawns" node with SpawnPoint children. Places the player on the spawn requested
## by SceneManager (or the layout's "P"), clamps the camera and starts the map's music.

signal battle_started(battle: BattleScene)
signal battle_finished(outcome: Battle.Outcome)

@export var music: AudioStream
## Heroes that fight when a FieldEnemy is touched (prototype: fixed party, full HP each battle).
@export var party: Array[CombatantData] = []

## Tests / accessibility: forwarded to BattleScene.auto_timing.
var battle_auto_timing := -1

var _battle: BattleScene

@onready var map: AsciiMap = $Map
@onready var player: Player = $Player


func _ready() -> void:
	_place_player(SceneManager.take_pending_spawn())
	player.set_camera_limits(camera_rect(map.pixel_rect(), get_viewport_rect().size))
	AudioManager.play_music(music)
	for enemy: FieldEnemy in find_children("*", "FieldEnemy", true, false):
		enemy.touched_player.connect(start_battle)


func in_battle() -> bool:
	return _battle != null


## Battle on the spot (D-04): the field enemy and the player sprite step aside, the battle
## places everyone around the camera centre. Defeat retries the same battle.
func start_battle(enemy: FieldEnemy) -> void:
	if in_battle() or party.is_empty():
		return
	player.locked = true
	player.hide()
	enemy.freeze()
	var outcome := Battle.Outcome.DEFEAT
	while outcome == Battle.Outcome.DEFEAT:
		_battle = BattleScene.new()
		_battle.auto_timing = battle_auto_timing
		add_child(_battle)
		_battle.start(party, enemy.enemies, player.camera_center())
		battle_started.emit(_battle)
		outcome = await _battle.battle_ended
		_battle.queue_free()
		_battle = null
	enemy.queue_free()
	player.show()
	player.locked = false
	battle_finished.emit(outcome)


func spawn_point(id: String) -> SpawnPoint:
	if id == "" or not has_node("Spawns/" + id):
		return null
	return get_node("Spawns/" + id) as SpawnPoint


## Camera limits: the map bounds, grown (and centred) when the map is smaller than the
## screen, so small interiors sit in the middle instead of the top-left corner.
static func camera_rect(map_rect: Rect2i, screen: Vector2) -> Rect2i:
	var rect := map_rect
	var extra_x := maxi(0, int(screen.x) - rect.size.x)
	var extra_y := maxi(0, int(screen.y) - rect.size.y)
	rect.position -= Vector2i(extra_x / 2, extra_y / 2)
	rect.size += Vector2i(extra_x, extra_y)
	return rect


func _place_player(spawn_id: String) -> void:
	var spawn := spawn_point(spawn_id)
	if spawn:
		player.position = spawn.position
		player.facing = spawn.facing
	else:
		player.position = map.spawn_position
