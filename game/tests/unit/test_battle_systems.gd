extends GutTest
## Block B battle systems: statuses, items, multi-target, Aether bar and specials, perfect
## bonuses, AI rules, swaps, Dual Techs, fleeing, regional Aether factor.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const BRANN := preload("res://data/characters/brann.tres")
const ECO := preload("res://data/characters/eco.tres")
const SLIME := preload("res://data/enemies/oil_slime.tres")
const SENTINEL := preload("res://data/enemies/brass_sentinel.tres")
const ATTACK := preload("res://data/skills/attack.tres")
const FIRE := preload("res://data/skills/fire.tres")
const SLEEP := preload("res://data/skills/lyra_sleep.tres")
const RESONANCE := preload("res://data/skills/kael_resonance.tres")
const OIL_JET := preload("res://data/skills/slime_oil_jet.tres")
const CANNON := preload("res://data/skills/sentinel_cannon.tres")
const REPAIR := preload("res://data/skills/sentinel_repair.tres")
const ECO_PROTECT := preload("res://data/skills/eco_protect.tres")
const POTION := preload("res://data/items/potion.tres")
const FEATHER := preload("res://data/items/phoenix_feather.tres")
const ANTIDOTE := preload("res://data/items/antidote.tres")
const SPARK := preload("res://data/techs/spark.tres")
const EARTH_ROAR := preload("res://data/techs/earth_roar.tres")
const S := StatusEffects.Id

var battle: Battle


func _new_battle(heroes: Array[CombatantData], foes: Array[CombatantData], seed := 3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var balance := CombatBalance.new()
	balance.crit_base_percent = -100.0
	balance.hit_base_percent = 1000.0
	battle = Battle.new(rng, balance)
	var members: Array[PartyMember] = []
	for d in heroes:
		members.append(PartyMember.new(d))
	battle.start_with_party(members, foes)


func _hero(name: String) -> BattleUnit:
	for u in battle.party + battle.reserves:
		if u.display_name() == name:
			return u
	return null


func _take_turn(unit: BattleUnit) -> void:
	for i in 200:
		if battle.next_turn() == unit:
			return
		battle.queue.commit_action()
	fail_test("unit never got a turn")


# ---------- statuses ----------

func test_poison_ticks_at_turn_start() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	battle.add_status(kael, S.POISON)
	_take_turn(kael)
	var t := battle.begin_turn(kael)
	assert_eq(t.damage, 7, "6% of 120")
	assert_eq(kael.hp, 113)
	assert_false(t.skip)


func test_sleep_skips_turns_and_breaks_on_hit() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var slime := battle.enemies[0]
	battle.add_status(slime, S.SLEEP)
	_take_turn(slime)
	assert_true(battle.begin_turn(slime).skip, "asleep: turn skipped")
	var kael := _hero("Kael")
	_take_turn(kael)
	var r := battle.resolve(kael, ATTACK, slime)
	assert_true(S.SLEEP in r.statuses_removed, "physical hit wakes it up")
	assert_false(slime.has_status(S.SLEEP))


func test_paralysis_skips_exactly_one_turn() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	battle.add_status(kael, S.PARALYSIS)
	_take_turn(kael)
	assert_true(battle.begin_turn(kael).skip)
	_take_turn(kael)
	assert_false(battle.begin_turn(kael).skip)


func test_haste_and_slow_change_turn_speed() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	battle.add_status(kael, S.SLOW)
	_take_turn(kael)
	battle.queue.commit_action()
	assert_eq(battle.queue.counter_of(kael), battle.queue.delay_for(25, 3) * 2)
	battle.add_status(kael, S.HASTE)
	assert_false(kael.has_status(S.SLOW), "Haste cancels Slow")


func test_silence_blocks_magic() -> void:
	_new_battle([LYRA] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var lyra := _hero("Lyra")
	assert_true(lyra.can_use(FIRE))
	battle.add_status(lyra, S.SILENCE)
	assert_false(lyra.can_use(FIRE))
	assert_true(lyra.can_use(ATTACK))


func test_protect_reduces_physical_damage() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	var slime := battle.enemies[0]
	_take_turn(slime)
	var normal := battle.resolve(slime, battle.enemies[0].data.skills[0], kael).amount
	battle.add_status(kael, S.PROTECT)
	_take_turn(slime)
	var shielded := battle.resolve(slime, battle.enemies[0].data.skills[0], kael).amount
	assert_almost_eq(float(shielded), normal * 0.67, 1.5)


func test_immunity_blocks_status() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	assert_false(battle.add_status(battle.enemies[0], S.SLEEP), "sentinels cannot sleep")


func test_resonance_dismantles_only_machines() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL, SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	_take_turn(kael)
	var on_machine := battle.resolve(kael, RESONANCE, battle.enemies[0])
	assert_true(S.DISMANTLED in on_machine.statuses_added)
	_take_turn(kael)
	var on_slime := battle.resolve(kael, RESONANCE, battle.enemies[1])
	assert_true(on_slime.no_effect)


func test_dismantled_halves_defense() -> void:
	_new_battle([BRANN] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var brann := _hero("Brann")
	var sentinel := battle.enemies[0]
	_take_turn(brann)
	var before := battle.resolve(brann, ATTACK, sentinel).amount
	sentinel.hp = sentinel.max_hp()
	battle.add_status(sentinel, S.DISMANTLED)
	_take_turn(brann)
	var after := battle.resolve(brann, ATTACK, sentinel).amount
	assert_gt(after, before)


func test_spirit_resists_negative_statuses_sometimes() -> void:
	_new_battle([LYRA] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var lyra := _hero("Lyra")
	var landed := 0
	for i in 40:
		battle.enemies[0].statuses.clear()
		_take_turn(lyra)
		lyra.mp = 40
		if S.SLEEP in battle.resolve(lyra, SLEEP, battle.enemies[0]).statuses_added:
			landed += 1
	assert_between(landed, 15, 39, "~73% after Spirit 5 resistance")


# ---------- items / multi-target ----------

func test_potion_heals_and_consumes() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	battle.inventory = {&"potion": 2}
	var kael := _hero("Kael")
	kael.hp = 30
	_take_turn(kael)
	var r := battle.use_item(kael, POTION, [kael] as Array[BattleUnit])
	assert_eq(r[0].amount, 60)
	assert_eq(battle.inventory[&"potion"], 1)


func test_phoenix_feather_revives_into_queue() -> void:
	_new_battle([KAEL, LYRA] as Array[CombatantData], [SLIME] as Array[CombatantData])
	battle.inventory = {&"phoenix_feather": 1}
	var lyra := _hero("Lyra")
	lyra.hp = 0
	battle.queue.remove(lyra)
	var kael := _hero("Kael")
	_take_turn(kael)
	var r := battle.use_item(kael, FEATHER, [lyra] as Array[BattleUnit])
	assert_true(r[0].revived)
	assert_eq(lyra.hp, roundi(lyra.max_hp() * 0.3))
	assert_true(battle.queue.has(lyra), "revived hero takes turns again")
	assert_false(battle.inventory.has(&"phoenix_feather"), "last one used up")


func test_antidote_cures_poison() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	battle.inventory = {&"antidote": 1}
	var kael := _hero("Kael")
	battle.add_status(kael, S.POISON)
	_take_turn(kael)
	var r := battle.use_item(kael, ANTIDOTE, [kael] as Array[BattleUnit])
	assert_true(S.POISON in r[0].statuses_removed)


func test_multi_target_hits_every_enemy() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var sentinel := battle.enemies[0]
	_take_turn(sentinel)
	var results := battle.resolve_action(sentinel, CANNON, battle.targets_for(sentinel, CANNON.target))
	assert_eq(results.size(), 1)
	_new_battle([KAEL, LYRA, BRANN] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	sentinel = battle.enemies[0]
	_take_turn(sentinel)
	results = battle.resolve_action(sentinel, CANNON, battle.targets_for(sentinel, CANNON.target))
	assert_eq(results.size(), 3, "cannon hits all three heroes")


# ---------- Aether bar / specials / perfect bonuses ----------

func test_aether_fills_from_damage_and_timing() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	_take_turn(kael)
	battle.resolve(kael, ATTACK, battle.enemies[0], DamageFormula.Timing.PERFECT)
	assert_eq(kael.aether, 6, "+6 per Perfect")
	var slime := battle.enemies[0]
	_take_turn(slime)
	var hit := battle.resolve(slime, battle.enemies[0].data.skills[0], kael).amount
	assert_eq(kael.aether, 6 + roundi(60.0 * hit / 120.0))


func test_special_needs_full_bar_and_empties_it() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var kael := _hero("Kael")
	assert_false(kael.can_use(KAEL.special))
	kael.aether = 100
	assert_true(kael.can_use(KAEL.special))
	_take_turn(kael)
	battle.resolve(kael, KAEL.special, battle.enemies[0])
	assert_eq(kael.aether, 0)


func test_kael_perfect_adds_extra_hit() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var kael := _hero("Kael")
	_take_turn(kael)
	var r := battle.resolve(kael, ATTACK, battle.enemies[0], DamageFormula.Timing.PERFECT)
	assert_almost_eq(float(r.extra_amount), r.amount * 0.5, 1.5)


func test_lyra_perfect_refunds_mp() -> void:
	_new_battle([LYRA] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var lyra := _hero("Lyra")
	_take_turn(lyra)
	battle.resolve(lyra, FIRE, battle.enemies[0], DamageFormula.Timing.PERFECT)
	assert_eq(lyra.mp, 40 - 4 + 1, "25% of 4 MP back")


func test_brann_overload_overheats_him() -> void:
	_new_battle([BRANN] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var brann := _hero("Brann")
	_take_turn(brann)
	var r := battle.resolve(brann, ATTACK, battle.enemies[0], DamageFormula.Timing.OVERLOAD)
	assert_true(r.overheated_self)
	assert_true(brann.has_status(S.OVERHEAT))


func test_eco_perfect_block_protects_party() -> void:
	_new_battle([ECO, KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var slime := battle.enemies[0]
	_take_turn(slime)
	battle.resolve(slime, battle.enemies[0].data.skills[0], _hero("Eco"), DamageFormula.Timing.PERFECT)
	assert_true(_hero("Kael").has_status(S.PROTECT))


# ---------- AI ----------

func test_sentinel_repairs_when_low() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var sentinel := battle.enemies[0]
	sentinel.hp = 20
	assert_eq(battle.choose_enemy_action(sentinel)[0], REPAIR)


func test_sentinel_fires_cannon_every_third_turn() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var sentinel := battle.enemies[0]
	sentinel.turns_taken = 3
	assert_eq(battle.choose_enemy_action(sentinel)[0], CANNON)


func test_sentinel_targets_highest_threat() -> void:
	_new_battle([KAEL, BRANN] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var sentinel := battle.enemies[0]
	sentinel.turns_taken = 1
	_hero("Brann").threat = 50
	assert_eq(battle.choose_enemy_action(sentinel)[1], _hero("Brann"))


func test_slime_oil_jet_prefers_heroes_without_slow() -> void:
	_new_battle([KAEL, LYRA] as Array[CombatantData], [SLIME] as Array[CombatantData])
	battle.add_status(_hero("Kael"), S.SLOW)
	for i in 30:
		var choice := battle.choose_enemy_action(battle.enemies[0])
		if choice[0] == OIL_JET:
			assert_eq(choice[1], _hero("Lyra"))


# ---------- swap / techs / flee ----------

func test_fourth_member_starts_in_reserve_and_can_swap() -> void:
	_new_battle([KAEL, LYRA, BRANN, ECO] as Array[CombatantData], [SLIME] as Array[CombatantData])
	assert_eq(battle.party.size(), 3)
	assert_eq(battle.reserves.size(), 1)
	var kael := _hero("Kael")
	_take_turn(kael)
	var eco := _hero("Eco")
	battle.swap(kael, eco)
	assert_true(eco in battle.party)
	assert_true(kael in battle.reserves)
	assert_true(battle.queue.has(eco))
	assert_false(battle.queue.has(kael))


func test_dual_tech_available_and_spends_partner_turn() -> void:
	_new_battle([KAEL, LYRA] as Array[CombatantData], [SLIME] as Array[CombatantData])
	var kael := _hero("Kael")
	var techs := DataRegistry.all_techs()
	var available := battle.available_techs(kael, techs)
	assert_true(SPARK in available)
	assert_false(EARTH_ROAR in available, "needs Brann and Eco")
	_take_turn(kael)
	var lyra := _hero("Lyra")
	var lyra_mp := lyra.mp
	var results := battle.resolve_tech(SPARK, kael, [battle.enemies[0]] as Array[BattleUnit],
		[DamageFormula.Timing.PERFECT, DamageFormula.Timing.PERFECT] as Array[int])
	assert_gt(results[0].amount, 0)
	assert_eq(lyra.mp, lyra_mp - SPARK.mp_cost)
	assert_eq(battle.queue.counter_of(lyra), battle.queue.delay_for(22, SPARK.skill.weight))


func test_flee_chance_and_bosses() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	assert_between(battle.flee_chance(), 10.0, 95.0)
	var boss := SENTINEL.duplicate() as CombatantData
	boss.is_boss = true
	_new_battle([KAEL] as Array[CombatantData], [boss] as Array[CombatantData])
	assert_eq(battle.flee_chance(), 0.0)


func test_successful_flee_ends_battle() -> void:
	_new_battle([KAEL] as Array[CombatantData], [SLIME] as Array[CombatantData])
	battle.rng.seed = 1
	var kael := _hero("Kael")
	var escaped := false
	for i in 10:
		_take_turn(kael)
		if battle.try_flee():
			escaped = true
			break
	assert_true(escaped)
	assert_eq(battle.outcome(), Battle.Outcome.FLED)


func test_regional_aether_factor_scales_magic() -> void:
	_new_battle([LYRA] as Array[CombatantData], [SENTINEL] as Array[CombatantData])
	var lyra := _hero("Lyra")
	_take_turn(lyra)
	var normal := battle.resolve(lyra, FIRE, battle.enemies[0]).amount
	battle.enemies[0].hp = 110
	battle.aether_factor = 0.7
	_take_turn(lyra)
	var drained := battle.resolve(lyra, FIRE, battle.enemies[0]).amount
	assert_almost_eq(float(drained), normal * 0.7, 2.0)


func test_reserves_get_75_percent_xp() -> void:
	_new_battle([KAEL, LYRA, BRANN, ECO] as Array[CombatantData], [SLIME, SLIME] as Array[CombatantData])
	for e in battle.enemies:
		e.hp = 0
	var results := battle.finish_victory()
	var eco_result: Dictionary = results.filter(func(r: Dictionary) -> bool: return r["member"].data == ECO)[0]
	assert_eq(eco_result["xp"], 18)
