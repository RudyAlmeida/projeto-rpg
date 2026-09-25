class_name SkillData
extends Resource
## A battle command: attack, magic, defend, heal or support (GDD_Combate, sections 3–7).

enum Kind { ATTACK, MAGIC, DEFEND, HEAL, SUPPORT }
enum Target { ENEMY, ALLY, SELF, ALL_ENEMIES, ALL_ALLIES, ALLY_KO }
enum Element { NONE, FIRE, ICE, THUNDER, WATER, EARTH, WIND, LIGHT, DARK }

@export var id: StringName
@export var display_name := ""
@export var kind := Kind.ATTACK
@export var target := Target.ENEMY
## CTB weight: 2 fast, 3 normal, 4 heavy (TurnQueue.WEIGHT_*).
@export var weight := TurnQueue.WEIGHT_NORMAL
@export var mp_cost := 0
@export var power := 0
@export var multiplier := 1.0
@export var element := Element.NONE
@export_multiline var description := ""

@export_group("Status")
## StatusEffects.Id -> chance in percent (before the target's Spirit resistance).
@export var inflicts: Dictionary = {}
## Duration for inflicted statuses (0 = each status' default).
@export var status_turns := 0
## StatusEffects.Id values removed from the target.
@export var cures: Array[int] = []
## Only affects mechanical targets (e.g. Kael's Resonance).
@export var mechanical_only := false

@export_group("Revive")
## Revives KO'd allies with this share of max HP (Target.ALLY_KO).
@export_range(0.0, 1.0) var revive_percent := 0.0


func is_offensive() -> bool:
	return kind == Kind.ATTACK or kind == Kind.MAGIC


func is_multi_target() -> bool:
	return target == Target.ALL_ENEMIES or target == Target.ALL_ALLIES


func targets_enemies() -> bool:
	return target == Target.ENEMY or target == Target.ALL_ENEMIES
