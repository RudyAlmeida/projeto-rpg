class_name TurnQueue
extends RefCounted
## CTB turn order (GDD_Combate, section 3). Each combatant has a counter; the lowest acts,
## that amount of "time" passes for everyone, and the actor's counter is refilled with
## the delay of the action it chose: base_tick(VEL) × action weight × speed modifier.

const WEIGHT_FAST := 2
const WEIGHT_NORMAL := 3
const WEIGHT_HEAVY := 4


class Entry:
	var actor: Object
	var speed: int
	var is_player: bool
	var counter: int
	var speed_mult := 1.0  # Haste = 0.5, Slow = 2.0

	func _init(p_actor: Object, p_speed: int, p_is_player: bool, p_counter: int) -> void:
		actor = p_actor
		speed = p_speed
		is_player = p_is_player
		counter = p_counter


var balance: CombatBalance
var _entries: Array[Entry] = []
var _current: Entry


func _init(p_balance: CombatBalance = null) -> void:
	balance = p_balance if p_balance else CombatBalance.new()


func base_tick(speed: int) -> int:
	return floori(balance.tick_constant / (speed + balance.tick_speed_offset))


func delay_for(speed: int, weight: int, speed_mult := 1.0) -> int:
	return roundi(base_tick(speed) * weight * speed_mult)


## Adds a combatant. With `initiative`, it starts at 0 and acts before everyone else.
func add(actor: Object, speed: int, is_player: bool, initiative := false,
		rng: RandomNumberGenerator = null) -> void:
	var counter := 0
	if not initiative:
		var jitter := 1.0
		if rng:
			jitter = rng.randf_range(1.0 - balance.initial_counter_jitter, 1.0 + balance.initial_counter_jitter)
		counter = roundi(base_tick(speed) * balance.initial_counter_weight * jitter)
	_entries.append(Entry.new(actor, speed, is_player, counter))


func remove(actor: Object) -> void:
	_entries = _entries.filter(func(e: Entry) -> bool: return e.actor != actor)
	if _current and _current.actor == actor:
		_current = null


func has(actor: Object) -> bool:
	return _find(actor) != null


func size() -> int:
	return _entries.size()


## Advances time to the next actor and returns it. Call commit_action() after it acts.
func next() -> Object:
	if _entries.is_empty():
		return null
	var entry := _pick(_entries)
	var elapsed := entry.counter
	for e in _entries:
		e.counter -= elapsed
	_current = entry
	return entry.actor


## Refills the current actor's counter with the delay of the chosen action.
func commit_action(weight := WEIGHT_NORMAL) -> void:
	assert(_current != null, "commit_action() without a current actor")
	_current.counter = delay_for(_current.speed, weight, _current.speed_mult)
	_current = null


## Upcoming turn order (`count` turns). If the current actor is about to use an action of
## `weight`, its first refill uses that weight — this is the "ghost" preview in the UI.
## Everyone else is assumed to take normal actions.
func preview(count: int, weight := WEIGHT_NORMAL) -> Array[Object]:
	var sim: Array[Entry] = []
	for e in _entries:
		var copy := Entry.new(e.actor, e.speed, e.is_player, e.counter)
		copy.speed_mult = e.speed_mult
		if e == _current:
			copy.counter = delay_for(e.speed, weight, e.speed_mult)
		sim.append(copy)
	var order: Array[Object] = []
	while order.size() < count and not sim.is_empty():
		var entry := _pick(sim)
		var elapsed := entry.counter
		for e in sim:
			e.counter -= elapsed
		order.append(entry.actor)
		entry.counter = delay_for(entry.speed, WEIGHT_NORMAL, entry.speed_mult)
	return order


func set_speed_mult(actor: Object, mult: float) -> void:
	var entry := _find(actor)
	if entry:
		entry.speed_mult = mult


## Pushes an actor back in the queue (delay attacks).
func delay(actor: Object, amount: int) -> void:
	var entry := _find(actor)
	if entry:
		entry.counter += amount


## Party swap (FFX style): the incoming actor takes over the outgoing actor's counter.
func swap(out_actor: Object, in_actor: Object, in_speed: int) -> void:
	var entry := _find(out_actor)
	assert(entry != null, "swap(): actor not in queue")
	entry.actor = in_actor
	entry.speed = in_speed
	entry.speed_mult = 1.0


func counter_of(actor: Object) -> int:
	var entry := _find(actor)
	return entry.counter if entry else -1


func _find(actor: Object) -> Entry:
	for e in _entries:
		if e.actor == actor:
			return e
	return null


## Lowest counter wins; ties go to higher speed, then to the player side.
static func _pick(entries: Array[Entry]) -> Entry:
	var best := entries[0]
	for e in entries:
		if e.counter < best.counter \
				or (e.counter == best.counter and e.speed > best.speed) \
				or (e.counter == best.counter and e.speed == best.speed and e.is_player and not best.is_player):
			best = e
	return best
