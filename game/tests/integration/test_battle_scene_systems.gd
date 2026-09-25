extends GutTest
## Block B through the BattleScene: item menu, swap menu, Dual Tech, fleeing, hold timing
## and field encounter detection. Time runs 8x faster; timing presses are automatic.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const BRANN := preload("res://data/characters/brann.tres")
const ECO := preload("res://data/characters/eco.tres")
const SLIME := preload("res://data/enemies/oil_slime.tres")
const SPARK := preload("res://data/techs/spark.tres")

var scene: BattleScene


func before_each() -> void:
	Engine.time_scale = 8.0
	scene = BattleScene.new()
	scene.auto_timing = DamageFormula.Timing.GOOD
	add_child_autofree(scene)


func after_each() -> void:
	Engine.time_scale = 1.0


func _start(heroes: Array[CombatantData], inventory := {}) -> void:
	scene.inventory = inventory
	scene.techs = DataRegistry.all_techs()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	scene.start(heroes, [SLIME, SLIME] as Array[CombatantData], Vector2(320, 180), true, rng)
	await wait_for_signal(scene.command_requested, 10.0)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	scene._unhandled_input(event)


func _root_index(id: String) -> int:
	for i in scene._list_entries.size():
		if scene._list_entries[i].get("id") == id:
			return i
	return -1


func _go_to(id: String) -> void:
	for i in _root_index(id):
		_press(&"move_down")


func test_root_menu_lists_commands() -> void:
	await _start([KAEL, LYRA, BRANN, ECO] as Array[CombatantData], {&"potion": 1})
	var ids: Array = scene._list_entries.map(func(e: Dictionary) -> String: return e["id"])
	assert_eq(ids, ["attack", "skills", "items", "defend", "swap", "flee"])


func test_item_menu_uses_a_potion() -> void:
	await _start([KAEL, LYRA] as Array[CombatantData], {&"potion": 2})
	scene.battle.party[0].hp = 50
	scene.battle.party[1].hp = 50
	_go_to("items")
	_press(&"confirm")   # open Itens
	assert_eq(scene._mode, BattleScene.Mode.ITEMS)
	_press(&"confirm")   # Poção
	assert_eq(scene._mode, BattleScene.Mode.TARGET)
	_press(&"confirm")   # first ally
	await wait_seconds(2.0)
	assert_eq(scene.inventory[&"potion"], 1)


func test_swap_menu_brings_in_reserve_who_acts_now() -> void:
	await _start([KAEL, LYRA, BRANN, ECO] as Array[CombatantData])
	var first := scene._actor
	_go_to("swap")
	_press(&"confirm")   # Trocar
	assert_eq(scene._mode, BattleScene.Mode.SWAP)
	_press(&"confirm")   # Eco
	await wait_for_signal(scene.command_requested, 5.0)
	assert_eq(scene._actor.display_name(), "Eco", "the reserve acts this turn")
	assert_true(scene._actor in scene.battle.party)
	assert_true(first in scene.battle.reserves)
	assert_eq(scene._list_entries[_root_index("swap")].get("enabled"), false, "one swap per turn")


func test_dual_tech_spends_both_heroes_mp() -> void:
	await _start([KAEL, LYRA] as Array[CombatantData])
	var kael := scene.battle.party[0]
	var lyra := scene.battle.party[1]
	var actor := scene._actor
	var lyra_mp := lyra.mp
	var kael_mp := kael.mp
	scene.submit_action({"type": "tech", "tech": SPARK, "targets": [scene.battle.enemies[0]]})
	await wait_seconds(3.0)
	assert_eq(lyra.mp, lyra_mp - SPARK.mp_cost)
	assert_eq(kael.mp, kael_mp - SPARK.mp_cost)
	assert_true(actor == kael or actor == lyra)


func test_flee_ends_battle() -> void:
	watch_signals(scene)
	await _start([KAEL, LYRA] as Array[CombatantData])
	scene.command_requested.connect(func(_u: BattleUnit) -> void: scene.submit_action({"type": "flee"}))
	scene.submit_action({"type": "flee"})
	await wait_for_signal(scene.battle_ended, 20.0)
	assert_signal_emitted_with_parameters(scene, "battle_ended", [Battle.Outcome.FLED])


func test_special_appears_when_aether_is_full() -> void:
	await _start([KAEL, LYRA] as Array[CombatantData])
	assert_eq(_root_index("special"), -1)
	scene._actor.aether = 100
	scene._open_root()
	assert_eq(_root_index("special"), 1)


func test_hold_gauge_zones() -> void:
	assert_eq(TimingPrompt.evaluate_hold(0.3), DamageFormula.Timing.MISS)
	assert_eq(TimingPrompt.evaluate_hold(0.7), DamageFormula.Timing.GOOD)
	assert_eq(TimingPrompt.evaluate_hold(0.9), DamageFormula.Timing.PERFECT)
	assert_eq(TimingPrompt.evaluate_hold(1.2), DamageFormula.Timing.OVERLOAD, "held too long")
	assert_eq(TimingPrompt.evaluate_hold(0.75, 2.0), DamageFormula.Timing.PERFECT, "easy mode widens the zone")


func test_encounter_types() -> void:
	# Player at left walking right; enemy to the right.
	var pos := Vector2.ZERO
	var enemy := Vector2(20, 0)
	assert_eq(FieldMap.encounter_type(pos, Vector2.RIGHT, enemy, Vector2.RIGHT), FieldMap.Encounter.INITIATIVE, "enemy faces away")
	assert_eq(FieldMap.encounter_type(pos, Vector2.RIGHT, enemy, Vector2.LEFT), FieldMap.Encounter.NORMAL, "face to face")
	assert_eq(FieldMap.encounter_type(pos, Vector2.LEFT, enemy, Vector2.LEFT), FieldMap.Encounter.AMBUSH, "enemy hits the player's back")
