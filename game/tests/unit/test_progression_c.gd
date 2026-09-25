extends GutTest
## Block C: inventory, equipment, gem sockets and levels, skill trees, and saving all of it.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const ECO := preload("res://data/characters/eco.tres")
const BRASS_BLADE := preload("res://data/items/brass_blade.tres")
const GEAR_BLADE := preload("res://data/items/gear_blade.tres")
const OAK_STAFF := preload("res://data/items/oak_staff.tres")
const AVIATOR := preload("res://data/items/aviator_coat.tres")
const GEAR_AMULET := preload("res://data/items/gear_amulet.tres")
const GEM_FIRE := preload("res://data/items/gem_fire.tres")
const GEM_STRENGTH := preload("res://data/items/gem_strength.tres")
const GEM_TIMING := preload("res://data/items/gem_timing.tres")
const FIRE := preload("res://data/skills/fire.tres")
const FIRE2 := preload("res://data/skills/fire2.tres")
const PISTON := preload("res://data/skills/kael_piston.tres")

var _saved_state: Dictionary


func before_each() -> void:
	_saved_state = GameState.to_dict()
	GameState.new_game([KAEL, LYRA, ECO] as Array[CombatantData], 1000)


func after_each() -> void:
	GameState.from_dict(_saved_state)


func _kael() -> PartyMember:
	return GameState.party[0]


# ---------- equipment ----------

func test_new_game_starts_with_gear() -> void:
	var kael := _kael()
	assert_eq(kael.equipment[ItemData.Kind.WEAPON], GEAR_BLADE)
	assert_eq(kael.weapon_attack(), 10)
	assert_eq(kael.stat(&"defense"), 8 + 3, "base DEF + leather coat")
	assert_eq(kael.socket_count(), 3, "blade 2 + coat 1")


func test_equipping_changes_stats_and_returns_old_gear() -> void:
	GameState.add_item(&"brass_blade")
	assert_true(GameState.equip(_kael(), BRASS_BLADE))
	assert_eq(_kael().weapon_attack(), 17)
	assert_eq(GameState.count(&"gear_blade"), 1, "old weapon back in the bag")
	assert_eq(GameState.count(&"brass_blade"), 0)


func test_equip_restrictions() -> void:
	GameState.add_item(&"oak_staff")
	assert_false(GameState.equip(_kael(), OAK_STAFF), "only Lyra uses staves")
	assert_true(GameState.equip(GameState.party[1], OAK_STAFF))
	assert_eq(GameState.party[1].stat(&"magic"), 15 + 6)


func test_accessory_bonus() -> void:
	GameState.add_item(&"gear_amulet")
	GameState.equip(_kael(), GEAR_AMULET)
	assert_eq(_kael().stat(&"speed"), 25 + 3)


func test_losing_sockets_returns_gems_to_bag() -> void:
	var gem := GemInstance.new(GEM_FIRE)
	GameState.gem_bag.append(gem)
	GameState.socket_gem(_kael(), 2, gem)  # the coat's socket
	assert_false(gem in GameState.gem_bag)
	GameState.unequip(_kael(), ItemData.Kind.ARMOR)
	assert_true(gem in GameState.gem_bag, "coat removed: its gem comes back")
	assert_eq(_kael().socket_count(), 2)
	assert_eq(GameState.count(&"leather_coat"), 1)


# ---------- gems ----------

func test_gem_levels_with_ap() -> void:
	var gem := GemInstance.new(GEM_FIRE)
	assert_eq(gem.level(), 1)
	assert_eq(gem.skills(), [FIRE] as Array[SkillData])
	assert_true(gem.gain_ap(20))
	assert_eq(gem.level(), 2)
	assert_eq(gem.skills(), [FIRE, FIRE2] as Array[SkillData])
	gem.gain_ap(60)
	assert_eq(gem.level(), 3)
	assert_true(gem.is_mastered())
	assert_eq(gem.ap_to_next(), 0)


func test_socketed_gem_grants_skills_and_stats() -> void:
	var kael := _kael()
	GameState.gem_bag.append(GemInstance.new(GEM_FIRE))
	GameState.socket_gem(kael, 0, GameState.gem_bag[0])
	assert_true(FIRE in kael.all_skills(), "Kael can cast Fire with the gem")
	assert_eq(kael.all_skills()[-1].kind, SkillData.Kind.DEFEND, "Defend stays last in the menu")
	assert_eq(kael.stat(&"magic"), 6 + 1)
	var strength := GemInstance.new(GEM_STRENGTH, 20)
	kael.set_gem(1, strength)
	assert_eq(kael.stat(&"strength"), 12 + 6, "+3 × level 2")


func test_battle_ap_levels_socketed_gems_only() -> void:
	var kael := _kael()
	var socketed := GemInstance.new(GEM_FIRE)
	var bagged := GemInstance.new(GEM_FIRE)
	kael.set_gem(0, socketed)
	GameState.gem_bag.append(bagged)
	var up := GameState.add_ap(25)
	assert_eq(up, [socketed] as Array[GemInstance])
	assert_eq(bagged.ap, 0)


func test_timing_gem_widens_window() -> void:
	var kael := _kael()
	assert_eq(kael.timing_window_mult(), 1.0)
	kael.set_gem(0, GemInstance.new(GEM_TIMING))
	assert_almost_eq(kael.timing_window_mult(), 1.25, 0.001)
	kael.set_gem(0, GemInstance.new(GEM_TIMING, 80))
	assert_almost_eq(kael.timing_window_mult(), 1.75, 0.001, "level 3")


func test_battle_unit_uses_gem_skills() -> void:
	var kael := _kael()
	kael.set_gem(0, GemInstance.new(GEM_FIRE))
	var unit := BattleUnit.new(kael.data, true, kael)
	assert_true(FIRE in unit.skill_list())


# ---------- skill tree ----------

func test_level_up_gives_skill_points() -> void:
	var kael := _kael()
	kael.gain_xp(24)
	assert_eq(kael.skill_points, 2)


func test_tree_requirements_and_costs() -> void:
	var kael := _kael()
	kael.skill_points = 10
	assert_false(kael.learn(&"k_piston"), "needs Vigor first")
	assert_true(kael.learn(&"k_vigor"))
	assert_eq(kael.max_hp(), 120 + 15)
	assert_true(kael.learn(&"k_piston"))
	assert_true(PISTON in kael.all_skills())
	assert_eq(kael.skill_points, 10 - 1 - 2)
	assert_false(kael.learn(&"k_piston"), "already learned")


func test_cannot_learn_without_points() -> void:
	var kael := _kael()
	kael.skill_points = 0
	assert_false(kael.learn(&"k_vigor"))


func test_every_hero_has_a_tree() -> void:
	for id in [&"kael", &"lyra", &"brann", &"eco"]:
		var tree := DataRegistry.tree_for(id)
		assert_not_null(tree, "%s has a tree" % id)
		assert_eq(tree.nodes.size(), 6)


# ---------- save ----------

func test_progression_survives_save_round_trip() -> void:
	var kael := _kael()
	GameState.add_item(&"brass_blade")
	GameState.equip(kael, BRASS_BLADE)
	kael.set_gem(0, GemInstance.new(GEM_FIRE, 25))
	GameState.gem_bag.append(GemInstance.new(GEM_STRENGTH, 5))
	kael.skill_points = 3
	kael.learn(&"k_vigor")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.new_game([LYRA] as Array[CombatantData])
	GameState.from_dict(snapshot)
	kael = _kael()
	assert_eq(kael.equipment[ItemData.Kind.WEAPON], BRASS_BLADE)
	assert_eq(kael.sockets[0].item, GEM_FIRE)
	assert_eq(kael.sockets[0].ap, 25)
	assert_eq(kael.learned, [&"k_vigor"] as Array[StringName])
	assert_eq(kael.skill_points, 2)
	assert_eq(GameState.gem_bag.size(), 1)
	assert_eq(GameState.gem_bag[0].ap, 5)
	assert_eq(GameState.count(&"gear_blade"), 1)
