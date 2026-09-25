class_name DamageFormula
extends RefCounted
## Pure combat formulas (GDD_Combate, section 5). No scene or node access, so they can be
## unit-tested and reused by the battle, the UI previews and the balancing tools.

enum Timing { MISS, GOOD, PERFECT }
enum Affinity { NORMAL, WEAK, RESIST, IMMUNE, ABSORB }

static var balance := CombatBalance.new()


## Physical base: ATQ × mult × 100 / (100 + DEF).
static func physical_base(attack: int, multiplier: float, target_defense: int) -> float:
	return attack * multiplier * 100.0 / (100.0 + target_defense)


## Magical base: (MAG × 2 + power) × mult × 100 / (100 + ESP).
static func magical_base(magic: int, power: int, multiplier: float, target_spirit: int) -> float:
	return (magic * balance.magic_stat_mult + power) * multiplier * 100.0 / (100.0 + target_spirit)


## Heal base: MAG × 1.5 + power (not reduced by the target).
static func heal_base(magic: int, power: int) -> float:
	return magic * balance.heal_stat_mult + power


## Applies every multiplier to a base value and returns the final integer amount,
## clamped to [0, max_damage]. `variance` is the rolled factor (1.0 = no variance).
static func finalize(base: float, variance := 1.0, is_crit := false, element_mult := 1.0,
		timing_mult := 1.0, other_mult := 1.0) -> int:
	var value := base * variance * element_mult * timing_mult * other_mult
	if is_crit:
		value *= balance.crit_mult
	return clampi(roundi(value), 0, balance.max_damage)


static func attack_timing_mult(result: Timing) -> float:
	match result:
		Timing.PERFECT:
			return balance.attack_perfect_mult
		Timing.GOOD:
			return balance.attack_good_mult
	return 1.0


static func defense_timing_mult(result: Timing) -> float:
	match result:
		Timing.PERFECT:
			return balance.defense_perfect_mult
		Timing.GOOD:
			return balance.defense_good_mult
	return 1.0


## Element multiplier. ABSORB returns -1: the caller turns the damage into healing.
static func element_mult(affinity: Affinity) -> float:
	match affinity:
		Affinity.WEAK:
			return balance.weak_mult
		Affinity.RESIST:
			return balance.resist_mult
		Affinity.IMMUNE:
			return 0.0
		Affinity.ABSORB:
			return -1.0
	return 1.0


## Physical hit chance in percent: 95 + (PRE − EVA) / 2, clamped to [5, 100].
static func hit_chance(precision: int, evasion: int) -> float:
	return clampf(balance.hit_base_percent + (precision - evasion) / 2.0, 5.0, 100.0)


## Critical chance in percent: 3 + SOR / 8.
static func crit_chance(luck: int) -> float:
	return balance.crit_base_percent + luck / balance.crit_luck_divisor


static func roll_variance(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(balance.variance_min, balance.variance_max)
