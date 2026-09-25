class_name CombatBalance
extends Resource
## Tunable combat numbers (GDD_Combate, section 11). Defaults match the approved GDD v1.0.
## Save a copy as data/balance/combat.tres to tune without touching code.

@export_group("Turn queue (CTB)")
@export var tick_constant := 3000.0
@export var tick_speed_offset := 20.0
@export var initial_counter_weight := 3
@export var initial_counter_jitter := 0.1

@export_group("Timing")
@export var attack_perfect_mult := 1.3
@export var attack_good_mult := 1.1
@export var defense_perfect_mult := 0.5
@export var defense_good_mult := 0.75

@export_group("Damage")
@export var variance_min := 0.95
@export var variance_max := 1.05
@export var crit_base_percent := 3.0
@export var crit_luck_divisor := 8.0
@export var crit_mult := 1.5
@export var hit_base_percent := 95.0
@export var magic_stat_mult := 2.0
@export var heal_stat_mult := 1.5
@export var max_damage := 9999

@export_group("Elements")
@export var weak_mult := 1.5
@export var resist_mult := 0.5
