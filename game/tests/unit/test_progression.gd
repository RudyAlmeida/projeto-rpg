extends GutTest
## PartyMember levels/XP, GameState and SaveManager round trips, battle XP sharing.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const BRANN := preload("res://data/characters/brann.tres")
const SLIME := preload("res://data/enemies/oil_slime.tres")
const ATTACK := preload("res://data/skills/attack.tres")
const TEST_SLOT := 99

var _saved_state: Dictionary


func before_each() -> void:
	_saved_state = GameState.to_dict()


func after_each() -> void:
	GameState.from_dict(_saved_state)
	SaveManager.delete_save(TEST_SLOT)


func test_xp_curve() -> void:
	assert_eq(PartyMember.xp_to_next(1), 20)
	assert_eq(PartyMember.xp_to_next(2), 61)
	assert_gt(PartyMember.xp_to_next(10), PartyMember.xp_to_next(9))


func test_level_one_stats_match_data() -> void:
	var kael := PartyMember.new(KAEL)
	assert_eq(kael.max_hp(), 120)
	assert_eq(kael.stat(&"strength"), 12)
	assert_eq(kael.hp, 120)


func test_growth_raises_stats_per_level() -> void:
	var kael := PartyMember.new(KAEL, 5)
	assert_eq(kael.max_hp(), 120 + 48, "12 HP per level × 4")
	assert_eq(kael.stat(&"strength"), 12 + 6, "1.5 × 4")
	assert_eq(kael.stat(&"magic"), 6 + 2, "0.6 × 4 = 2.4, floored")


func test_gain_xp_levels_up_and_raises_hp() -> void:
	var kael := PartyMember.new(KAEL)
	kael.hp = 100
	assert_eq(kael.gain_xp(24), 1)
	assert_eq(kael.level, 2)
	assert_eq(kael.xp, 4, "leftover XP carries over")
	assert_eq(kael.hp, 112, "max HP gain is added to current HP")


func test_gain_xp_can_skip_several_levels() -> void:
	var lyra := PartyMember.new(LYRA)
	assert_eq(lyra.gain_xp(20 + 61 + 116), 3)
	assert_eq(lyra.level, 4)


func test_member_dict_round_trip() -> void:
	var brann := PartyMember.new(BRANN, 3)
	brann.xp = 17
	brann.hp = 50
	var copy := PartyMember.from_dict(brann.to_dict())
	assert_eq(copy.data, BRANN)
	assert_eq([copy.level, copy.xp, copy.hp, copy.mp], [3, 17, 50, brann.mp])


func test_game_state_round_trip() -> void:
	GameState.new_game([KAEL, LYRA] as Array[CombatantData], 30)
	GameState.party[0].gain_xp(30)
	GameState.inventory[&"potion"] = 3
	GameState.set_flag(&"met_gerd")
	var snapshot := GameState.to_dict()
	GameState.new_game([BRANN] as Array[CombatantData])
	GameState.from_dict(JSON.parse_string(JSON.stringify(snapshot)))  # as it comes from disk
	assert_eq(GameState.party.size(), 2)
	assert_eq(GameState.party[0].level, 2)
	assert_eq(GameState.money, 30)
	assert_eq(GameState.inventory[&"potion"], 3)
	assert_true(GameState.get_flag(&"met_gerd"))


func test_save_file_round_trip() -> void:
	GameState.new_game([KAEL] as Array[CombatantData], 55)
	assert_eq(SaveManager.write_save(TEST_SLOT, "res://scenes/maps/test_map.tscn", Vector2(100, 200), Player.Facing.LEFT), OK)
	assert_true(SaveManager.has_save(TEST_SLOT))
	var data := SaveManager.read_save(TEST_SLOT)
	assert_eq(data["scene"], "res://scenes/maps/test_map.tscn")
	assert_eq(int(data["version"]), SaveManager.VERSION, "JSON numbers come back as floats")
	assert_eq(int(data["state"]["money"]), 55)


func test_corrupt_save_is_rejected() -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file := FileAccess.open(SaveManager.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_eq(SaveManager.read_save(TEST_SLOT), {})
	assert_eq(SaveManager.load_game(TEST_SLOT), ERR_FILE_CORRUPT)


func test_victory_shares_xp_and_writes_hp_back() -> void:
	var members: Array[PartyMember] = [PartyMember.new(KAEL), PartyMember.new(LYRA)]
	var battle := Battle.new()
	battle.start_with_party(members, [SLIME, SLIME] as Array[CombatantData])
	battle.party[0].hp = 90
	battle.party[1].hp = 0  # KO'd at the end
	for e in battle.enemies:
		e.hp = 0
	var results := battle.finish_victory()
	assert_eq(results[0]["xp"], 24)
	assert_eq(results[1]["xp"], 12, "KO'd heroes get 50%")
	assert_eq(members[0].level, 2)
	assert_eq(members[0].hp, 90 + 12, "HP written back, plus the level-up gain")
	assert_eq(members[1].hp, 1, "KO'd heroes come back with 1 HP")


func test_battle_uses_level_scaled_stats() -> void:
	var strong := PartyMember.new(KAEL, 10)
	var battle := Battle.new()
	battle.start_with_party([strong] as Array[PartyMember], [SLIME] as Array[CombatantData])
	assert_eq(battle.party[0].stat(&"strength"), strong.stat(&"strength"))
	assert_eq(battle.party[0].max_hp(), strong.max_hp())


func test_knocked_out_members_sit_out() -> void:
	var members: Array[PartyMember] = [PartyMember.new(KAEL), PartyMember.new(LYRA)]
	members[1].hp = 0
	var battle := Battle.new()
	battle.start_with_party(members, [SLIME] as Array[CombatantData])
	assert_eq(battle.party.size(), 1)
