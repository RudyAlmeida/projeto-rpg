extends GutTest
## Prologue story beats played for real on their maps, with auto dialogue and auto battles:
## Eco wakes up and the Triturador falls, the Voss fight, Gerd's farewell.

const DIR := "res://scenes/maps/prologue/"
const ATTACK := preload("res://data/skills/attack.tres")
const KAEL := preload("res://data/characters/kael.tres")
const GERD := preload("res://data/characters/gerd.tres")
const ECO := preload("res://data/characters/eco.tres")

var _saved_state: Dictionary
var _auto := false


func before_each() -> void:
	_saved_state = GameState.to_dict()
	Settings.text_speed = &"instant"
	Settings.apply()
	Engine.time_scale = 8.0


func after_each() -> void:
	# Let a pending scene change (fade) finish before cleaning up its map.
	for i in 600:
		if not SceneManager.is_transitioning:
			break
		await get_tree().process_frame
	_auto = false
	Engine.time_scale = 1.0
	await wait_process_frames(2)
	var box := DialogueManager.box()
	for i in 30:
		if not box.is_open():
			break
		box.confirm()
	GameState.from_dict(_saved_state)
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().unload_current_scene()
	for node in get_tree().root.get_children():
		if node is FieldMap or node is MainMenu:
			node.queue_free()


func _party(members: Array) -> void:
	GameState.party.clear()
	for entry: Array in members:
		GameState.party.append(PartyMember.new(entry[0], entry[1]))
	GameState.money = 100


## Clicks through every conversation (first choice) until `_auto` is cleared.
func _auto_dialogue() -> void:
	_auto = true
	var box := DialogueManager.box()
	while _auto:
		await get_tree().process_frame
		if box.is_open():
			if box.is_choosing():
				box.choose(0)
			else:
				box.confirm()


func _load(map_name: String) -> FieldMap:
	var map: FieldMap = load(DIR + map_name + ".tscn").instantiate()
	map.battle_music = false
	map.battle_auto_timing = DamageFormula.Timing.PERFECT
	map.battle_started.connect(func(battle: BattleScene) -> void:
		battle.command_requested.connect(func(unit: BattleUnit) -> void:
			var foes := battle.battle.opponents_of(unit)
			foes.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.hp < b.hp)
			battle.submit_command(ATTACK, foes[0])))
	add_child_autofree(map)
	return map


func _wait_flag(flag: StringName, seconds: float) -> bool:
	var frames := int(seconds * 60)
	for i in frames:
		if GameState.get_flag(flag):
			return true
		await get_tree().process_frame
	return false


func test_eco_wakes_and_the_triturador_falls() -> void:
	_party([[KAEL, 12], [GERD, 1]])
	for f in [&"prologue_started", &"gerd_joined", &"junkyard_entered"]:
		GameState.set_flag(f)
	_auto_dialogue()
	var map := _load("camara")
	var watched := [false]
	map.battle_started.connect(func(b: BattleScene) -> void:
		watched[0] = true
		assert_eq(b.battle.enemies.size(), 3, "the Triturador fights in three parts"))
	assert_true(await _wait_flag(&"boss_beaten", 90.0), "boss beaten")
	assert_true(watched[0])
	assert_true(GameState.party.any(func(m: PartyMember) -> bool: return m.data.id == &"eco"), "Eco joined")
	assert_eq(GameState.count(&"bronze_valve"), 1)
	assert_eq(GameState.count(&"gear_blade"), 1)
	assert_true(GameState.is_objective_done(&"q_prologue", &"fetch_valve") or GameState.quest_state(&"q_prologue") == "")


func test_voss_fight_ends_the_scene_and_gerd_leaves() -> void:
	_party([[KAEL, 4], [GERD, 1], [ECO, 4]])
	for f in [&"prologue_started", &"gerd_joined", &"eco_awake", &"boss_beaten", &"dinner_done", &"slept",
			&"empire_arrived", &"gerd_out"]:
		GameState.set_flag(f)
	_auto_dialogue()
	var map := _load("vila_caldeira")
	await wait_process_frames(3)
	assert_true(map.get_node("Voss").visible)
	var voss_scene: Cutscene = load("res://data/cutscenes/p8_voss.tres")
	voss_scene.play(map)
	assert_true(await _wait_flag(&"voss_fought", 120.0), "the scripted fight ends by itself")
	assert_false(GameState.party.any(func(m: PartyMember) -> bool: return m.data.id == &"gerd"), "Gerd left the party")
	assert_true(GameState.party.all(func(m: PartyMember) -> bool: return m.hp == m.max_hp()), "restored after the fight")
	await wait_process_frames(2)
	assert_false(map.get_node("Voss").visible)
	assert_true(map.get_node("SoldierSouth").visible, "soldiers still block the south street")
	assert_true(map.player.can_move())


func test_farewell_leads_out_through_the_back_door() -> void:
	_party([[KAEL, 4], [ECO, 4]])
	for f in [&"prologue_started", &"gerd_joined", &"eco_awake", &"boss_beaten", &"dinner_done", &"slept",
			&"empire_arrived", &"gerd_out", &"voss_fought"]:
		GameState.set_flag(f)
	_auto_dialogue()
	_load("oficina")
	assert_true(await _wait_flag(&"escaped", 60.0), "farewell played")
