class_name GemInstance
extends RefCounted
## One owned gem (GDD 8.2). Gems are unique: each keeps its own AP and level, whether it
## sits in the bag or in an equipment socket.

var item: ItemData
var ap := 0


func _init(p_item: ItemData, p_ap := 0) -> void:
	item = p_item
	ap = p_ap


## Level 1 + one per AP threshold reached (thresholds accumulate: 20, then +60 ...).
func level() -> int:
	var needed := 0
	var lvl := 1
	for step in item.gem_ap_per_level:
		needed += step
		if ap >= needed:
			lvl += 1
	return lvl


func max_level() -> int:
	return item.gem_ap_per_level.size() + 1


func is_mastered() -> bool:
	return level() >= max_level()


## AP still needed for the next level (0 when mastered).
func ap_to_next() -> int:
	var needed := 0
	for step in item.gem_ap_per_level:
		needed += step
		if ap < needed:
			return needed - ap
	return 0


## Skills this gem grants at its current level.
func skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	for i in mini(level(), item.gem_skills.size()):
		out.append(item.gem_skills[i])
	return out


func stat_bonus(name: StringName) -> int:
	return int(item.gem_stat_bonuses.get(name, 0)) * level()


## Returns true if the gem levelled up.
func gain_ap(amount: int) -> bool:
	var before := level()
	ap += amount
	return level() > before


func to_dict() -> Dictionary:
	return {"id": item.id, "ap": ap}


static func from_dict(d: Dictionary) -> GemInstance:
	var gem_item := DataRegistry.item(StringName(d["id"]))
	return GemInstance.new(gem_item, int(d.get("ap", 0))) if gem_item else null
