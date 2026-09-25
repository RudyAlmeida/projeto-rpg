class_name BattleUnit
extends RefCounted
## Runtime state of one combatant in a battle (pure logic, no nodes). Heroes wrap a
## PartyMember (level-scaled stats, persistent HP/MP/Aether); enemies read CombatantData.

const AETHER_MAX := 100

var data: CombatantData
var member: PartyMember
var is_player: bool
var hp: int
var mp: int
var defending := false
## StatusEffects.Id -> remaining turns (-1 = until cured).
var statuses: Dictionary = {}
## Aether bar 0..100 (GDD 7); full unlocks the special move.
var aether := 0
## Damage dealt to the other side, for "highest threat" enemy targeting.
var threat := 0
var turns_taken := 0


func _init(p_data: CombatantData, p_is_player: bool, p_member: PartyMember = null) -> void:
	data = p_data
	is_player = p_is_player
	member = p_member
	hp = member.hp if member else data.max_hp
	mp = member.mp if member else data.max_mp
	aether = member.aether if member else 0


## Effective stat: level-scaled (and equipped) for party members, base value for enemies.
func stat(name: StringName) -> int:
	return member.stat(name) if member else int(data.get(name))


## Strength plus weapon power, for physical damage.
func attack_power() -> int:
	return stat(&"strength") + (member.weapon_attack() if member else data.weapon_power)


func max_hp() -> int:
	return stat(&"max_hp")


func max_mp() -> int:
	return stat(&"max_mp")


func is_alive() -> bool:
	return hp > 0


func display_name() -> String:
	return data.display_name


func has_status(id: StatusEffects.Id) -> bool:
	return statuses.has(id)


func is_blocked() -> bool:
	for id: int in statuses:
		if StatusEffects.blocks_action(id):
			return true
	return false


func aether_full() -> bool:
	return aether >= AETHER_MAX


func add_aether(amount: int) -> void:
	if is_alive():
		aether = clampi(aether + amount, 0, AETHER_MAX)


## Returns the HP actually lost.
func take_damage(amount: int) -> int:
	var lost := mini(amount, hp)
	hp -= lost
	return lost


## Returns the HP actually recovered. KO'd units cannot be healed this way.
func heal(amount: int) -> int:
	if not is_alive():
		return 0
	var gained := mini(amount, max_hp() - hp)
	hp += gained
	return gained


func restore_mp(amount: int) -> int:
	var gained := mini(amount, max_mp() - mp)
	mp += gained
	return gained


func can_use(skill: SkillData) -> bool:
	if mp < skill.mp_cost:
		return false
	if has_status(StatusEffects.Id.SILENCE) and (skill.kind == SkillData.Kind.MAGIC or skill.kind == SkillData.Kind.HEAL):
		return false
	if skill == data.special and not aether_full():
		return false
	return true
