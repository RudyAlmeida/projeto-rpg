class_name PartyMember
extends RefCounted
## A hero's persistent progress: level, XP and current HP/MP. Stats are derived from the
## CombatantData base values plus per-level growth.

var data: CombatantData
var level := 1
## XP gathered towards the next level (resets on level up).
var xp := 0
var hp: int
var mp: int


func _init(p_data: CombatantData, p_level := 1) -> void:
	data = p_data
	level = p_level
	hp = max_hp()
	mp = max_mp()


static func xp_to_next(p_level: int, balance: CombatBalance = null) -> int:
	var b := balance if balance else DamageFormula.balance
	return roundi(b.xp_base * pow(p_level, b.xp_exponent))


func stat(name: StringName) -> int:
	var base: int = data.get(name)
	return base + floori(float(data.growth.get(name, 0.0)) * (level - 1))


func max_hp() -> int:
	return stat(&"max_hp")


func max_mp() -> int:
	return stat(&"max_mp")


func is_alive() -> bool:
	return hp > 0


## Adds XP and levels up as many times as it covers. Max HP/MP gains are added to the
## current values too. Returns how many levels were gained.
func gain_xp(amount: int, balance: CombatBalance = null) -> int:
	var b := balance if balance else DamageFormula.balance
	var gained := 0
	xp += amount
	while level < b.max_level and xp >= xp_to_next(level, b):
		xp -= xp_to_next(level, b)
		var old_hp := max_hp()
		var old_mp := max_mp()
		level += 1
		gained += 1
		if hp > 0:
			hp += max_hp() - old_hp
		mp += max_mp() - old_mp
	return gained


func restore() -> void:
	hp = max_hp()
	mp = max_mp()


func to_dict() -> Dictionary:
	return {"data": data.resource_path, "level": level, "xp": xp, "hp": hp, "mp": mp}


static func from_dict(d: Dictionary) -> PartyMember:
	var member := PartyMember.new(load(d["data"]), int(d["level"]))
	member.xp = int(d["xp"])
	member.hp = clampi(int(d["hp"]), 0, member.max_hp())
	member.mp = clampi(int(d["mp"]), 0, member.max_mp())
	return member
