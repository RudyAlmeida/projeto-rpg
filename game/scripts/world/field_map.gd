class_name FieldMap
extends Node2D
## Base script for explorable maps. Expects children "Map" (AsciiMap) and "Player", and an
## optional "Spawns" node with SpawnPoint children. Places the player on the spawn requested
## by SceneManager (or the layout's "P"), clamps the camera and starts the map's music.

signal battle_started(battle: BattleScene)
signal battle_finished(outcome: Battle.Outcome)

@export var music: AudioStream
## Starting party when a game begins on this map (dev start); normally GameState's party.
@export var party: Array[CombatantData] = []
## Items (id -> count) and money for a game that starts on this map (dev start).
@export var starting_items: Dictionary = {}
@export var starting_money := 0
## Regional Aether factor for magic (GDD 5.6): 0.7 drained, 1.0 normal, 1.2 pristine.
@export_range(0.5, 1.5, 0.05) var aether_factor := 1.0

## Tests / accessibility: forwarded to BattleScene.auto_timing.
var battle_auto_timing := -1
## Tests: disable battle music (it would replace the map track).
var battle_music := true

var _battle: BattleScene

@onready var map: AsciiMap = $Map
@onready var player: Player = $Player


func _ready() -> void:
	# Running a map directly (editor F6 / dev start): begin a game with this map's party.
	if not GameState.is_started() and not party.is_empty():
		GameState.new_game(party, starting_money)
		for id: StringName in starting_items:
			GameState.inventory[id] = int(starting_items[id])
	_place_player(SceneManager.take_pending_spawn())
	player.set_camera_limits(camera_rect(map.pixel_rect(), get_viewport_rect().size))
	AudioManager.play_music(music)
	for enemy: FieldEnemy in find_children("*", "FieldEnemy", true, false):
		enemy.touched_player.connect(start_battle)


func in_battle() -> bool:
	return _battle != null


## Battle on the spot (D-04): the field enemy and the player sprite step aside, the battle
## places everyone around the camera centre. Touching an enemy from behind gives the party
## the first move; being touched from behind is an ambush. Defeat retries the same battle.
func start_battle(enemy: FieldEnemy) -> void:
	if in_battle() or not GameState.is_started():
		return
	var approach := encounter_type(player.global_position, Player.facing_vector(player.facing),
		enemy.global_position, enemy.facing_vector())
	player.locked = true
	player.hide()
	enemy.freeze()
	var outcome := Battle.Outcome.DEFEAT
	while outcome == Battle.Outcome.DEFEAT:
		_battle = BattleScene.new()
		_battle.auto_timing = battle_auto_timing
		_battle.inventory = GameState.inventory
		_battle.techs = DataRegistry.all_techs()
		_battle.aether_factor = aether_factor
		_battle.play_music = battle_music
		_battle.timing_window_scale = GameState.settings.get(&"timing_window", 1.0)
		add_child(_battle)
		_battle.start_with_party(GameState.party, enemy.enemies, player.camera_center(),
			approach == Encounter.INITIATIVE, null, approach == Encounter.AMBUSH)
		battle_started.emit(_battle)
		outcome = await _battle.battle_ended
		if outcome == Battle.Outcome.VICTORY:
			GameState.add_money(_battle.battle.total_money())  # AP and drops are handled by the battle
		_battle.queue_free()
		_battle = null
		approach = Encounter.NORMAL  # a retry starts even
	if outcome == Battle.Outcome.FLED:
		enemy.resume()
	else:
		enemy.queue_free()
	player.show()
	player.locked = false
	battle_finished.emit(outcome)


enum Encounter { NORMAL, INITIATIVE, AMBUSH }


## GDD 2.1: reaching the enemy from behind = initiative; the enemy reaching the player's
## back = ambush.
static func encounter_type(player_pos: Vector2, player_facing: Vector2, enemy_pos: Vector2,
		enemy_facing: Vector2) -> Encounter:
	var to_enemy := (enemy_pos - player_pos).normalized()
	if to_enemy.dot(player_facing) > 0.5 and to_enemy.dot(enemy_facing) > 0.5:
		return Encounter.INITIATIVE  # player walks into the enemy's back
	if to_enemy.dot(player_facing) < -0.5 and (-to_enemy).dot(enemy_facing) > 0.5:
		return Encounter.AMBUSH      # enemy walks into the player's back
	return Encounter.NORMAL


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
	var saved_position := SaveManager.take_pending_position()
	var spawn := spawn_point(spawn_id)
	if saved_position != Vector2.INF:
		player.position = saved_position
		player.facing = SaveManager.pending_facing
	elif spawn:
		player.position = spawn.position
		player.facing = spawn.facing
	else:
		player.position = map.spawn_position
