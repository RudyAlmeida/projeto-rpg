extends GutTest
## Battle rules with the real data files. Crits are disabled and heroes always hit so the
## numbers match the GDD examples (±5% variance).

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const BRANN := preload("res://data/characters/brann.tres")
const SLIME := preload("res://data/enemies/oil_slime.tres")
const ATTACK := preload("res://data/skills/attack.tres")
const DEFEND := preload("res://data/skills/defend.tres")
const FIRE := preload("res://data/skills/fire.tres")
const TACKLE := preload("res://data/skills/slime_tackle.tres")

var battle: Battle


func before_each() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var balance := CombatBalance.new()
	balance.crit_base_percent = -100.0  # no crits
	balance.hit_base_percent = 1000.0   # always hit
	battle = Battle.new(rng, balance)
	battle.start([KAEL, LYRA, BRANN] as Array[CombatantData], [SLIME, SLIME] as Array[CombatantData])


func _unit(name: String) -> BattleUnit:
	for u in battle.party + battle.enemies:
		if u.display_name() == name:
			return u
	return null


## Makes `unit` the current actor, as if its turn had come up.
func _take_turn(unit: BattleUnit) -> void:
	for i in 50:
		if battle.next_turn() == unit:
			return
		battle.queue.commit_action()
	fail_test("unit never got a turn")


func test_start_builds_units_and_queue() -> void:
	assert_eq(battle.party.size(), 3)
	assert_eq(battle.enemies.size(), 2)
	assert_eq(battle.queue.size(), 5)
	assert_eq(battle.outcome(), Battle.Outcome.ONGOING)


func test_kael_attack_matches_gdd() -> void:
	var kael := _unit("Kael")
	_take_turn(kael)
	var r := battle.resolve(kael, ATTACK, battle.enemies[0])
	assert_between(r.amount, 20, 22, "GDD: ~21")


func test_perfect_timing_hits_harder() -> void:
	var kael := _unit("Kael")
	_take_turn(kael)
	var r := battle.resolve(kael, ATTACK, battle.enemies[0], DamageFormula.Timing.PERFECT)
	assert_between(r.amount, 26, 29, "GDD: ~27")


func test_lyra_fire_one_shots_weak_slime() -> void:
	var lyra := _unit("Lyra")
	_take_turn(lyra)
	var target := battle.enemies[0]
	var r := battle.resolve(lyra, FIRE, target)
	assert_eq(r.amount, 60, "overkill is capped at remaining HP (~71 raw)")
	assert_true(r.knocked_out)
	assert_false(battle.queue.has(target), "KO'd units leave the turn queue")
	assert_eq(lyra.mp, LYRA.max_mp - FIRE.mp_cost)


func test_defend_halves_damage_until_next_turn() -> void:
	var kael := _unit("Kael")
	var slime := battle.enemies[0]
	_take_turn(slime)
	var normal := battle.resolve(slime, TACKLE, kael).amount
	kael.hp = kael.data.max_hp
	_take_turn(kael)
	battle.resolve(kael, DEFEND, kael)
	assert_true(kael.defending)
	battle.queue.delay(kael, 500)  # Kael is faster: keep his next turn after the slime's attack
	_take_turn(slime)
	var defended := battle.resolve(slime, TACKLE, kael).amount
	assert_almost_eq(float(defended), normal * 0.5, 1.5)
	_take_turn(kael)  # _take_turn only commits other units' turns, so Kael's comes up
	assert_false(kael.defending, "stance ends when the unit's turn comes back")


func test_perfect_defense_timing_halves_enemy_damage() -> void:
	var kael := _unit("Kael")
	var slime := battle.enemies[0]
	_take_turn(slime)
	var normal := battle.resolve(slime, TACKLE, kael).amount
	_take_turn(slime)
	var blocked := battle.resolve(slime, TACKLE, kael, DamageFormula.Timing.PERFECT).amount
	assert_almost_eq(float(blocked), normal * 0.5, 1.5)


func test_weak_element_multiplies_and_resist_reduces() -> void:
	assert_eq(SLIME.affinity_for(SkillData.Element.FIRE), DamageFormula.Affinity.WEAK)
	assert_eq(SLIME.affinity_for(SkillData.Element.WATER), DamageFormula.Affinity.RESIST)
	assert_eq(SLIME.affinity_for(SkillData.Element.ICE), DamageFormula.Affinity.NORMAL)


func test_enemy_ai_attacks_a_living_hero() -> void:
	var slime := battle.enemies[0]
	_unit("Kael").hp = 0
	for i in 20:
		var choice := battle.choose_enemy_action(slime)
		assert_true(choice[0] in SLIME.skills, "uses one of its own skills (Tackle or Oil Jet)")
		assert_true((choice[1] as BattleUnit).is_player)
		assert_true((choice[1] as BattleUnit).is_alive(), "never targets a KO'd hero")


func test_victory_and_defeat() -> void:
	for e in battle.enemies:
		e.hp = 0
	assert_eq(battle.outcome(), Battle.Outcome.VICTORY)
	for e in battle.enemies:
		e.hp = 1
	for p in battle.party:
		p.hp = 0
	assert_eq(battle.outcome(), Battle.Outcome.DEFEAT)


func test_rewards_sum_all_enemies() -> void:
	assert_eq(battle.total_xp(), 24)
	assert_eq(battle.total_money(), 16)


func test_auto_battle_reaches_victory() -> void:
	# Heroes attack the first living enemy, enemies use their AI: the party must win.
	for turn in 200:
		if battle.outcome() != Battle.Outcome.ONGOING:
			break
		var unit := battle.next_turn()
		if unit.is_player:
			battle.resolve(unit, ATTACK, battle.alive(battle.enemies)[0])
		else:
			var choice := battle.choose_enemy_action(unit)
			battle.resolve(unit, choice[0], choice[1])
	assert_eq(battle.outcome(), Battle.Outcome.VICTORY)
	assert_eq(battle.alive(battle.party).size(), 3, "a fresh party should not lose anyone to two slimes")
