extends GutTest
## Prologue combat rules: the Triturador's guarded core, the Stuck status (blocked by
## Protect), the Scrap Crow's theft and escape, Voss's scripted fight and guest heroes.

const KAEL := preload("res://data/characters/kael.tres")
const ECO := preload("res://data/characters/eco.tres")
const GERD := preload("res://data/characters/gerd.tres")
const CLAW_UP := preload("res://data/enemies/crusher_claw_up.tres")
const CLAW_DOWN := preload("res://data/enemies/crusher_claw_down.tres")
const CORE := preload("res://data/enemies/crusher_core.tres")
const CROW := preload("res://data/enemies/scrap_crow.tres")
const VOSS := preload("res://data/enemies/voss.tres")
const SOLDIER := preload("res://data/enemies/imperial_soldier.tres")
const ATTACK := preload("res://data/skills/attack.tres")
const COMPACT := preload("res://data/skills/core_compact.tres")
const SNATCH := preload("res://data/skills/crow_snatch.tres")

var battle: Battle


func _battle(heroes: Array, foes: Array) -> Battle:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var balance := CombatBalance.new()
	balance.crit_base_percent = -100.0
	balance.hit_base_percent = 1000.0
	var b := Battle.new(rng, balance)
	var h: Array[CombatantData] = []
	h.assign(heroes)
	var f: Array[CombatantData] = []
	f.assign(foes)
	b.start(h, f)
	return b


## Makes `unit` the current actor, as if its turn had come up (resolve commits its action).
func _take_turn(b: Battle, unit: BattleUnit) -> void:
	for i in 80:
		if b.next_turn() == unit:
			return
		b.queue.commit_action()
	fail_test("unit never got a turn")


func _enemy(b: Battle, id: StringName) -> BattleUnit:
	for u in b.enemies:
		if u.data.id == id:
			return u
	return null


func test_core_takes_quarter_damage_while_a_claw_stands() -> void:
	battle = _battle([KAEL], [CLAW_UP, CORE, CLAW_DOWN])
	var kael := battle.party[0]
	var core := _enemy(battle, &"crusher_core")
	assert_true(battle.is_guarded(core))
	_take_turn(battle, kael)
	var guarded := battle.resolve(kael, ATTACK, core, DamageFormula.Timing.GOOD).amount
	_enemy(battle, &"crusher_claw_up").hp = 0
	assert_true(battle.is_guarded(core), "one claw still guards")
	_enemy(battle, &"crusher_claw_down").hp = 0
	assert_false(battle.is_guarded(core))
	_take_turn(battle, kael)
	var open := battle.resolve(kael, ATTACK, core, DamageFormula.Timing.GOOD).amount
	assert_almost_eq(float(guarded), open * 0.25, open * 0.1, "guarded hit ≈ 25%%: %d vs %d" % [guarded, open])


func test_compact_sticks_unless_protected() -> void:
	battle = _battle([KAEL, ECO], [CORE])
	var core := battle.enemies[0]
	var kael := battle.party[0]
	var eco := battle.party[1]
	_take_turn(battle, core)
	battle.resolve(core, COMPACT, kael, DamageFormula.Timing.MISS)
	assert_true(kael.has_status(StatusEffects.Id.STUCK))
	_take_turn(battle, kael)
	var start := battle.begin_turn(kael)
	assert_true(start.skip, "Stuck heroes lose their turn")
	battle.add_status(eco, StatusEffects.Id.PROTECT)
	_take_turn(battle, core)
	var r := battle.resolve(core, COMPACT, eco, DamageFormula.Timing.MISS)
	assert_false(eco.has_status(StatusEffects.Id.STUCK), "Eco's Protection prevents it")
	assert_has(r.resisted, StatusEffects.Id.STUCK)


func test_crow_steals_flees_and_returns_loot_when_beaten() -> void:
	battle = _battle([KAEL], [CROW])
	battle.inventory = {&"potion": 2}
	var crow := battle.enemies[0]
	_take_turn(battle, crow)
	var r := battle.resolve(crow, SNATCH, battle.party[0], DamageFormula.Timing.MISS)
	assert_eq(r.stolen_item, &"potion")
	assert_eq(battle.inventory.get(&"potion", 0), 1)
	crow.turns_taken = CROW.escape_after_turns + 1
	var start := battle.begin_turn(crow)
	assert_true(start.escaped)
	assert_false(crow.is_alive())
	assert_eq(battle.outcome(), Battle.Outcome.VICTORY)
	assert_eq(battle.total_xp(), 0, "no reward for a thief that got away")
	# A thief knocked out drops what it took.
	battle = _battle([KAEL], [CROW])
	battle.inventory = {&"potion": 1}
	crow = battle.enemies[0]
	_take_turn(battle, crow)
	battle.resolve(crow, SNATCH, battle.party[0], DamageFormula.Timing.MISS)
	assert_eq(battle.inventory.get(&"potion", 0), 0)
	crow.hp = 1
	_take_turn(battle, battle.party[0])
	battle.resolve(battle.party[0], ATTACK, crow, DamageFormula.Timing.GOOD)
	assert_eq(battle.inventory.get(&"potion", 0), 1)


func test_voss_fight_ends_after_four_turns_without_defeat() -> void:
	battle = _battle([KAEL, ECO], [SOLDIER, VOSS, SOLDIER])
	battle.end_after_turns = {&"voss": 4}
	var voss := _enemy(battle, &"voss")
	voss.turns_taken = 3
	assert_eq(battle.outcome(), Battle.Outcome.ONGOING)
	voss.turns_taken = 4
	assert_eq(battle.outcome(), Battle.Outcome.SCRIPTED)
	voss.turns_taken = 0
	for hero in battle.party:
		hero.hp = 0
	assert_eq(battle.outcome(), Battle.Outcome.SCRIPTED, "losing the story fight is not a game over")


func test_guest_keeps_level_and_cannot_be_swapped() -> void:
	assert_true(GERD.guest)
	var gerd := PartyMember.new(GERD, 1)
	var kael := PartyMember.new(KAEL, 1)
	battle = Battle.new()
	battle.start_with_party([kael, gerd] as Array[PartyMember], [SOLDIER] as Array[CombatantData])
	battle.enemies[0].hp = 0
	battle.finish_victory(500)
	assert_eq(gerd.level, 1, "guests don't level")
	assert_gt(kael.level, 1)
