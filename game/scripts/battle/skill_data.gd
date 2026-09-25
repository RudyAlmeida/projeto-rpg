class_name SkillData
extends Resource
## A battle command: basic attack, magic, defend or heal (GDD_Combate, sections 3–5).

enum Kind { ATTACK, MAGIC, DEFEND, HEAL }
enum Target { ENEMY, ALLY, SELF }
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


func is_offensive() -> bool:
	return kind == Kind.ATTACK or kind == Kind.MAGIC
