extends Node
## Autoload "GameState": everything that must survive scene changes and go into a save —
## party progress, money, inventory, story flags and play time.

signal money_changed(amount: int)

var party: Array[PartyMember] = []
var money := 0
## Item id (StringName) -> count.
var inventory: Dictionary = {}
## Story / world flags, e.g. {"met_gerd": true, "affinity_lyra": 3}.
var flags: Dictionary = {}
var play_time := 0.0
## Player preferences (options menu; stored in user://settings.cfg, not in saves).
var settings: Dictionary = {}


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
	flags.clear()
	play_time = 0.0


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


## Battle Pontos de Éter go to every party member's equipped gems (GDD 8.2).
func add_ap(amount: int) -> void:
	for member in party:
		member.gain_ap(amount)


func set_flag(name: StringName, value: Variant = true) -> void:
	flags[name] = value


func get_flag(name: StringName, default: Variant = false) -> Variant:
	return flags.get(name, default)


func to_dict() -> Dictionary:
	return {
		"party": party.map(func(m: PartyMember) -> Dictionary: return m.to_dict()),
		"money": money,
		"inventory": inventory.duplicate(),
		"flags": flags.duplicate(true),
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
	flags.clear()
	for key: String in d.get("flags", {}):
		flags[StringName(key)] = d["flags"][key]
	play_time = float(d.get("play_time", 0.0))
