extends Node
## Autoload "GameState": everything that must survive scene changes and go into a save —
## party progress, money, inventory, gems, story flags and play time.

signal money_changed(amount: int)
signal inventory_changed
signal quest_changed(id: StringName)

var party: Array[PartyMember] = []
var money := 0
## Item id (StringName) -> count. Gems are not here: they are unique (gem_bag).
var inventory: Dictionary = {}
## Gems not socketed in anyone's equipment.
var gem_bag: Array[GemInstance] = []
## Story / world flags, e.g. {"met_gerd": true, "affinity_lyra": 3}.
var flags: Dictionary = {}
## Quest id -> {"state": "active"|"ready"|"done", "done": [objective ids]}.
var quests: Dictionary = {}
var play_time := 0.0


func _process(delta: float) -> void:
	if is_started():
		play_time += delta


func is_started() -> bool:
	return not party.is_empty()


func new_game(heroes: Array[CombatantData], starting_money := 0) -> void:
	party.clear()
	for data in heroes:
		party.append(PartyMember.new(data))
	money = starting_money
	inventory.clear()
	gem_bag.clear()
	flags.clear()
	quests.clear()
	play_time = 0.0


# ---------- affinity (H-06) ----------

## Hidden affinity with a character (the Kael–Lyra–Isolde triangle decides the epilogue).
func affinity(character: StringName) -> int:
	return int(flags.get(StringName("affinity_" + character), 0))


func add_affinity(character: StringName, amount: int) -> void:
	flags[StringName("affinity_" + character)] = affinity(character) + amount


# ---------- quests ----------

func quest_state(id: StringName) -> String:
	return str(quests.get(id, {}).get("state", ""))


func start_quest(id: StringName) -> void:
	if quests.has(id):
		return
	quests[id] = {"state": "active", "done": []}
	_sync_quest(id)
	# Objectives achieved before the quest was given (e.g. the enemy was already beaten).
	var quest := DataRegistry.quest(id)
	if quest:
		for objective in quest.objective_ids:
			if get_flag(_early_flag(id, objective)):
				complete_objective(id, objective)


## Marks an objective done; when all are done the quest becomes "ready" to hand in.
## Before the quest starts it is remembered and applied when the quest begins.
func complete_objective(id: StringName, objective: StringName) -> void:
	if not quests.has(id):
		set_flag(_early_flag(id, objective))
		return
	if quest_state(id) != "active":
		return
	var done: Array = quests[id]["done"]
	if not objective in done:
		done.append(objective)
	var quest := DataRegistry.quest(id)
	if quest and quest.objective_ids.all(func(o: StringName) -> bool: return o in done):
		quests[id]["state"] = "ready"
	_sync_quest(id)


func is_objective_done(id: StringName, objective: StringName) -> bool:
	return objective in quests.get(id, {}).get("done", [])


## Hands in a quest and pays its rewards.
func finish_quest(id: StringName) -> void:
	if quest_state(id) == "done" or not quests.has(id):
		return
	quests[id]["state"] = "done"
	var quest := DataRegistry.quest(id)
	if quest:
		add_money(quest.reward_money)
		for item_id: StringName in quest.reward_items:
			add_item(item_id, int(quest.reward_items[item_id]))
		for member in party:
			member.gain_xp(quest.reward_xp)
	_sync_quest(id)


static func _early_flag(id: StringName, objective: StringName) -> StringName:
	return StringName("objective_%s_%s" % [id, objective])


func _sync_quest(id: StringName) -> void:
	flags[StringName("quest_" + id)] = quest_state(id)
	quest_changed.emit(id)


# ---------- money / items ----------

func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


func count(id: StringName) -> int:
	return int(inventory.get(id, 0))


## Adds items; gems become new GemInstances in the bag.
func add_item(id: StringName, amount := 1) -> void:
	var item := DataRegistry.item(id)
	if item and item.kind == ItemData.Kind.GEM:
		for i in amount:
			gem_bag.append(GemInstance.new(item))
	else:
		inventory[id] = count(id) + amount
	inventory_changed.emit()


func remove_item(id: StringName, amount := 1) -> bool:
	if count(id) < amount:
		return false
	inventory[id] = count(id) - amount
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	return true


## Inventory items of `kind`, sorted by name.
func items_of_kind(kind: ItemData.Kind) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for id: StringName in inventory:
		var item := DataRegistry.item(id)
		if item and item.kind == kind and count(id) > 0:
			out.append(item)
	out.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.display_name < b.display_name)
	return out


## Equip from the inventory: the previous piece and displaced gems go back.
func equip(member: PartyMember, item: ItemData) -> bool:
	if not member.can_equip(item) or not remove_item(item.id):
		return false
	var result := member.equip(item)
	_take_back(result)
	return true


func unequip(member: PartyMember, kind: ItemData.Kind) -> void:
	_take_back(member.unequip(kind))


func _take_back(result: Dictionary) -> void:
	if result["previous"]:
		add_item((result["previous"] as ItemData).id)
	for gem: GemInstance in result["gems"]:
		gem_bag.append(gem)


## Moves a gem from the bag into a socket (swapping out whatever was there).
func socket_gem(member: PartyMember, index: int, gem: GemInstance) -> void:
	gem_bag.erase(gem)
	var old := member.set_gem(index, gem)
	if old:
		gem_bag.append(old)
	inventory_changed.emit()


func unsocket_gem(member: PartyMember, index: int) -> void:
	var old := member.set_gem(index, null)
	if old:
		gem_bag.append(old)
	inventory_changed.emit()


## Battle Pontos de Éter go to every party member's equipped gems (GDD 8.2).
## Returns the gems that levelled up.
func add_ap(amount: int) -> Array[GemInstance]:
	var up: Array[GemInstance] = []
	for member in party:
		up.append_array(member.gain_ap(amount))
	return up


# ---------- flags ----------

func set_flag(name: StringName, value: Variant = true) -> void:
	flags[name] = value


func get_flag(name: StringName, default: Variant = false) -> Variant:
	return flags.get(name, default)


# ---------- save ----------

func to_dict() -> Dictionary:
	return {
		"party": party.map(func(m: PartyMember) -> Dictionary: return m.to_dict()),
		"money": money,
		"inventory": inventory.duplicate(),
		"gem_bag": gem_bag.map(func(g: GemInstance) -> Dictionary: return g.to_dict()),
		"flags": flags.duplicate(true),
		"quests": quests.duplicate(true),
		"play_time": play_time,
	}


func from_dict(d: Dictionary) -> void:
	party.clear()
	for entry: Dictionary in d.get("party", []):
		party.append(PartyMember.from_dict(entry))
	money = int(d.get("money", 0))
	inventory.clear()
	for key: String in d.get("inventory", {}):
		inventory[StringName(key)] = int(d["inventory"][key])
	gem_bag.clear()
	for entry: Dictionary in d.get("gem_bag", []):
		var gem := GemInstance.from_dict(entry)
		if gem:
			gem_bag.append(gem)
	flags.clear()
	for key: String in d.get("flags", {}):
		flags[StringName(key)] = d["flags"][key]
	quests.clear()
	for key: String in d.get("quests", {}):
		var q: Dictionary = d["quests"][key]
		var done: Array[StringName] = []
		for o: String in q.get("done", []):
			done.append(StringName(o))
		quests[StringName(key)] = {"state": str(q.get("state", "active")), "done": done}
	play_time = float(d.get("play_time", 0.0))
