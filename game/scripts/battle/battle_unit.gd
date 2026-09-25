class_name BattleUnit
extends RefCounted
## Runtime state of one combatant in a battle (pure logic, no nodes).

var data: CombatantData
var is_player: bool
var hp: int
var mp: int
var defending := false


func _init(p_data: CombatantData, p_is_player: bool) -> void:
	data = p_data
	is_player = p_is_player
	hp = data.max_hp
	mp = data.max_mp


func is_alive() -> bool:
	return hp > 0


func display_name() -> String:
	return data.display_name


## Returns the HP actually lost.
func take_damage(amount: int) -> int:
	var lost := mini(amount, hp)
	hp -= lost
	return lost


## Returns the HP actually recovered. KO'd units cannot be healed this way.
func heal(amount: int) -> int:
	if not is_alive():
		return 0
	var gained := mini(amount, data.max_hp - hp)
	hp += gained
	return gained


func can_use(skill: SkillData) -> bool:
	return mp >= skill.mp_cost
