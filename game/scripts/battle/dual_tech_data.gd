class_name DualTechData
extends Resource
## Combined technique (Dual / Triple Tech, GDD 7). Uses `skill` for its effect and damage;
## every participant pays `mp_cost` and spends its turn.

@export var id: StringName
@export var display_name := ""
## CombatantData ids of every participant, in timing order.
@export var participants: Array[StringName] = []
@export var skill: SkillData
@export var mp_cost := 4
## Damage/heal bonus per participant timing: × (1 + perfect × 0.15 + good × 0.05).
@export var perfect_bonus := 0.15
@export var good_bonus := 0.05
@export_multiline var description := ""
