extends GutTest
## Checks DamageFormula against the worked examples of GDD_Combate v1.0 (section 5.7).


func test_kael_attack_example() -> void:
	# Kael: FOR 12 + weapon 10 = ATQ 22 vs Oil Slime DEF 5 -> ~21.
	var base := DamageFormula.physical_base(22, 1.0, 5)
	assert_eq(DamageFormula.finalize(base), 21)


func test_kael_perfect_timing_example() -> void:
	var base := DamageFormula.physical_base(22, 1.0, 5)
	assert_eq(DamageFormula.finalize(base, 1.0, false, 1.0, DamageFormula.attack_timing_mult(DamageFormula.Timing.PERFECT)), 27)


func test_lyra_fire_weakness_example() -> void:
	# Lyra: MAG 15, Fire power 20 vs ESP 5, target weak to Fire -> ~71.
	var base := DamageFormula.magical_base(15, 20, 1.0, 5)
	assert_eq(DamageFormula.finalize(base, 1.0, false, DamageFormula.element_mult(DamageFormula.Affinity.WEAK)), 71)


func test_defense_timing_reduces_damage() -> void:
	assert_eq(DamageFormula.finalize(100.0, 1.0, false, 1.0, DamageFormula.defense_timing_mult(DamageFormula.Timing.PERFECT)), 50)
	assert_eq(DamageFormula.finalize(100.0, 1.0, false, 1.0, DamageFormula.defense_timing_mult(DamageFormula.Timing.GOOD)), 75)
	assert_eq(DamageFormula.finalize(100.0, 1.0, false, 1.0, DamageFormula.defense_timing_mult(DamageFormula.Timing.MISS)), 100)


func test_missing_timing_has_no_penalty() -> void:
	assert_eq(DamageFormula.attack_timing_mult(DamageFormula.Timing.MISS), 1.0)


func test_crit_multiplies_by_one_and_a_half() -> void:
	assert_eq(DamageFormula.finalize(100.0, 1.0, true), 150)


func test_damage_is_capped_and_never_negative() -> void:
	assert_eq(DamageFormula.finalize(50000.0), 9999)
	assert_eq(DamageFormula.finalize(10.0, 1.0, false, DamageFormula.element_mult(DamageFormula.Affinity.IMMUNE)), 0)


func test_higher_defense_means_less_damage() -> void:
	assert_gt(DamageFormula.physical_base(100, 1.0, 10), DamageFormula.physical_base(100, 1.0, 100))


func test_heal_formula() -> void:
	# Selene: MAG 14 × 1.5 + power 25 = 46.
	assert_eq(DamageFormula.finalize(DamageFormula.heal_base(14, 25)), 46)


func test_hit_chance_is_clamped() -> void:
	assert_eq(DamageFormula.hit_chance(0, 0), 95.0)
	assert_eq(DamageFormula.hit_chance(100, 0), 100.0)
	assert_eq(DamageFormula.hit_chance(0, 500), 5.0)


func test_crit_chance_grows_with_luck() -> void:
	assert_eq(DamageFormula.crit_chance(0), 3.0)
	assert_eq(DamageFormula.crit_chance(40), 8.0)


func test_variance_stays_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 200:
		var v := DamageFormula.roll_variance(rng)
		assert_between(v, 0.95, 1.05)
