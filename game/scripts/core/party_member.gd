class_name PartyMember
extends RefCounted
## A hero's persistent progress: level, XP, HP/MP/Aether, equipment with gem sockets and
## the skill tree. Stats = base + level growth + equipment + gems + tree bonuses.

const SLOT_KINDS: Array[ItemData.Kind] = [ItemData.Kind.WEAPON, ItemData.Kind.ARMOR, ItemData.Kind.ACCESSORY]
## GDD 8.1: Pontos de Habilidade gained per level.
const SKILL_POINTS_PER_LEVEL := 2

var data: CombatantData
var level := 1
## XP gathered towards the next level (resets on level up).
var xp := 0
var hp: int
var mp: int
## Aether bar (0..100), kept between battles (GDD 7).
var aether := 0
## ItemData.Kind -> ItemData (WEAPON, ARMOR, ACCESSORY).
var equipment := {}
## One entry per gem socket of the equipped gear; null = empty socket.
var sockets: Array[GemInstance] = []
var skill_points := 0
var learned: Array[StringName] = []


func _init(p_data: CombatantData, p_level := 1) -> void:
	data = p_data
	level = p_level
	for item in data.starting_equipment:
		equipment[item.kind] = item
	_resize_sockets()
	hp = max_hp()
	mp = max_mp()


static func xp_to_next(p_level: int, balance: CombatBalance = null) -> int:
	var b := balance if balance else DamageFormula.balance
	return roundi(b.xp_base * pow(p_level, b.xp_exponent))


# ---------- stats ----------

func base_stat(name: StringName) -> int:
	var base: int = data.get(name)
	return base + floori(float(data.growth.get(name, 0.0)) * (level - 1))


func stat(name: StringName) -> int:
	var value := base_stat(name)
	for item: ItemData in equipment.values():
		value += int(item.stat_bonuses.get(name, 0))
	for gem in sockets:
		if gem:
			value += gem.stat_bonus(name)
	for node in learned_nodes():
		value += int(node.stat_bonuses.get(name, 0))
	return maxi(value, 0)


func max_hp() -> int:
	return stat(&"max_hp")


func max_mp() -> int:
	return stat(&"max_mp")


func is_alive() -> bool:
	return hp > 0


## Weapon power for physical damage: the equipped weapon, or the character's bare default.
func weapon_attack() -> int:
	var weapon: ItemData = equipment.get(ItemData.Kind.WEAPON)
	return weapon.attack if weapon else data.weapon_power


# ---------- skills ----------

## Battle commands: character skills, then skill-tree skills, then gem skills (no repeats).
func all_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	for skill in data.skills:
		if not skill in out:
			out.append(skill)
	for node in learned_nodes():
		if node.skill and not node.skill in out:
			out.insert(out.size() - 1 if not out.is_empty() and out[-1].kind == SkillData.Kind.DEFEND else out.size(), node.skill)
	for gem in sockets:
		if gem:
			for skill in gem.skills():
				if not skill in out:
					out.insert(out.size() - 1 if not out.is_empty() and out[-1].kind == SkillData.Kind.DEFEND else out.size(), skill)
	return out


## Timing window multiplier from equipped gems (e.g. the Watchmaker's Eye).
func timing_window_mult() -> float:
	var mult := 1.0
	for gem in sockets:
		if gem and gem.item.gem_effects.has(&"timing_window"):
			mult = maxf(mult, 1.0 + (float(gem.item.gem_effects[&"timing_window"]) - 1.0) * gem.level())
	return mult


# ---------- progression ----------

## Adds XP and levels up as many times as it covers. Max HP/MP gains are added to the
## current values too; every level grants Pontos de Habilidade. Returns levels gained.
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
		skill_points += SKILL_POINTS_PER_LEVEL
		if hp > 0:
			hp += max_hp() - old_hp
		mp += max_mp() - old_mp
	return gained


## Pontos de Éter to every socketed gem. Returns the gems that levelled up.
func gain_ap(amount: int) -> Array[GemInstance]:
	var up: Array[GemInstance] = []
	for gem in sockets:
		if gem and gem.gain_ap(amount):
			up.append(gem)
	return up


func restore() -> void:
	hp = max_hp()
	mp = max_mp()


# ---------- equipment ----------

func can_equip(item: ItemData) -> bool:
	return item.is_equipment() and item.can_equip(data.id)


## Equips `item` in its slot. Returns {"previous": ItemData or null, "gems": [GemInstance]}
## — gems that no longer fit go back to the caller (the bag).
func equip(item: ItemData) -> Dictionary:
	assert(can_equip(item), "%s cannot equip %s" % [data.display_name, item.id])
	var previous: ItemData = equipment.get(item.kind)
	equipment[item.kind] = item
	return {"previous": previous, "gems": _resize_sockets()}


func unequip(kind: ItemData.Kind) -> Dictionary:
	var previous: ItemData = equipment.get(kind)
	equipment.erase(kind)
	return {"previous": previous, "gems": _resize_sockets()}


func socket_count() -> int:
	var total := 0
	for item: ItemData in equipment.values():
		total += item.gem_slots
	return total


## Puts `gem` in socket `index`; returns the gem that was there (or null).
func set_gem(index: int, gem: GemInstance) -> GemInstance:
	var old := sockets[index]
	sockets[index] = gem
	return old


func _resize_sockets() -> Array[GemInstance]:
	var removed: Array[GemInstance] = []
	var count := socket_count()
	while sockets.size() > count:
		var gem: GemInstance = sockets.pop_back()
		if gem:
			removed.append(gem)
	while sockets.size() < count:
		sockets.append(null)
	# Losing gear can lower the maximums.
	hp = mini(hp, max_hp())
	mp = mini(mp, max_mp())
	return removed


# ---------- skill tree ----------

func tree() -> SkillTreeData:
	return DataRegistry.tree_for(data.id)


func learned_nodes() -> Array[SkillTreeNode]:
	var out: Array[SkillTreeNode] = []
	var t := tree()
	if t:
		for id in learned:
			var n := t.node(id)
			if n:
				out.append(n)
	return out


func can_learn(node: SkillTreeNode) -> bool:
	if node.id in learned or skill_points < node.cost:
		return false
	return node.requires.all(func(req: StringName) -> bool: return req in learned)


func learn(node_id: StringName) -> bool:
	var t := tree()
	var node := t.node(node_id) if t else null
	if node == null or not can_learn(node):
		return false
	skill_points -= node.cost
	learned.append(node_id)
	return true


# ---------- save ----------

func to_dict() -> Dictionary:
	var equip := {}
	for kind: int in equipment:
		equip[str(kind)] = (equipment[kind] as ItemData).id
	return {
		"data": data.resource_path, "level": level, "xp": xp, "hp": hp, "mp": mp, "aether": aether,
		"equipment": equip,
		"sockets": sockets.map(func(g: GemInstance) -> Variant: return g.to_dict() if g else null),
		"skill_points": skill_points,
		"learned": learned.map(func(id: StringName) -> String: return str(id)),
	}


static func from_dict(d: Dictionary) -> PartyMember:
	var member := PartyMember.new(load(d["data"]), int(d["level"]))
	member.xp = int(d["xp"])
	if d.has("equipment"):
		member.equipment.clear()
		for key: String in d["equipment"]:
			var item := DataRegistry.item(StringName(d["equipment"][key]))
			if item:
				member.equipment[item.kind] = item
		member._resize_sockets()
	var saved_sockets: Array = d.get("sockets", [])
	for i in mini(saved_sockets.size(), member.sockets.size()):
		if saved_sockets[i] is Dictionary:
			member.sockets[i] = GemInstance.from_dict(saved_sockets[i])
	member.skill_points = int(d.get("skill_points", 0))
	for id: String in d.get("learned", []):
		member.learned.append(StringName(id))
	member.hp = clampi(int(d["hp"]), 0, member.max_hp())
	member.mp = clampi(int(d["mp"]), 0, member.max_mp())
	member.aether = clampi(int(d.get("aether", 0)), 0, 100)
	return member
