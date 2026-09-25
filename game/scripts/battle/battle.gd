class_name Battle
extends RefCounted
## Battle rules without any nodes: who acts next (TurnQueue), what an action does
## (DamageFormula + statuses), enemy AI, party swaps, Dual Techs and the outcome.
## BattleScene drives it and animates the results.

## SCRIPTED: a story fight ended (turn limit reached or the party fell) — no game over.
enum Outcome { ONGOING, VICTORY, DEFEAT, FLED, SCRIPTED }

const ACTIVE_MAX := 3
## GDD 7: Aether gained per hero press and when an ally falls.
const AETHER_PERFECT := 6
const AETHER_GOOD := 3
const AETHER_ALLY_DOWN := 10
const AETHER_DAMAGE_SHARE := 0.6
const EXTRA_HIT_SHARE := 0.5
const STEAM_PERFECT_MULT := 1.6
const MP_REFUND_SHARE := 0.25
const GUARD_ALL_TURNS := 2


## What happened to one target when an action resolved, for the UI to animate.
class ActionResult:
	var actor: BattleUnit
	var skill: SkillData
	var item: ItemData
	var target: BattleUnit
	var amount := 0          # damage dealt or HP healed
	var extra_amount := 0    # Kael's extra hit on a PERFECT
	var mp_amount := 0       # MP restored
	var hit := true
	var crit := false
	var knocked_out := false
	var absorbed := false    # element absorbed: the target was healed
	var revived := false
	var no_effect := false   # e.g. Resonance on a non-mechanical target
	var overheated_self := false
	var stolen_item: StringName
	var statuses_added: Array[int] = []
	var statuses_removed: Array[int] = []
	var resisted: Array[int] = []
	var timing := DamageFormula.Timing.MISS


## What happened at the start of a unit's turn (statuses ticking).
class TurnStart:
	var unit: BattleUnit
	var skip := false
	var reason := -1          # StatusEffects.Id that blocked the turn
	var damage := 0           # poison
	var heal := 0             # regen
	var knocked_out := false
	var escaped := false      # a thief ran off with its loot
	var expired: Array[int] = []


var party: Array[BattleUnit] = []
var reserves: Array[BattleUnit] = []
var enemies: Array[BattleUnit] = []
var queue: TurnQueue
var rng: RandomNumberGenerator
var balance: CombatBalance
## Regional Aether factor for magic and healing (GDD 5.6): 0.7 drained … 1.2 pristine.
var aether_factor := 1.0
## Item id -> count. Pass GameState.inventory to consume real items.
var inventory: Dictionary = {}
var fled := false
## Story fights: enemy id -> number of its turns after which the battle ends (SCRIPTED).
## Such fights also end as SCRIPTED instead of DEFEAT when the party falls.
var end_after_turns: Dictionary = {}


func _init(p_rng: RandomNumberGenerator = null, p_balance: CombatBalance = null) -> void:
	rng = p_rng if p_rng else RandomNumberGenerator.new()
	balance = p_balance if p_balance else DamageFormula.balance
	queue = TurnQueue.new(balance)


## Quick start with fresh level-1 heroes (tests, previews).
func start(heroes: Array[CombatantData], foes: Array[CombatantData], initiative := false) -> void:
	var members: Array[PartyMember] = []
	for data in heroes:
		members.append(PartyMember.new(data))
	start_with_party(members, foes, initiative)


## Starts with the persistent party: the first ACTIVE_MAX living members fight, the rest
## wait in reserve. `initiative`: heroes act first; `ambush`: enemies act first.
func start_with_party(members: Array[PartyMember], foes: Array[CombatantData], initiative := false,
		ambush := false) -> void:
	for member in members:
		if not member.is_alive():
			continue
		var unit := BattleUnit.new(member.data, true, member)
		if party.size() < ACTIVE_MAX:
			party.append(unit)
			queue.add(unit, unit.stat(&"speed"), true, initiative, rng)
		else:
			reserves.append(unit)
	for data in foes:
		var unit := BattleUnit.new(data, false)
		enemies.append(unit)
		queue.add(unit, unit.stat(&"speed"), false, ambush, rng)


# ---------- turn flow ----------

## Advances the CTB queue. The returned unit's defend stance ends as its turn begins.
func next_turn() -> BattleUnit:
	var unit := queue.next() as BattleUnit
	if unit:
		unit.defending = false
		unit.turns_taken += 1
	return unit


## Status effects at the start of `unit`'s turn: poison/regen ticks, petrification countdown,
## sleep/paralysis skips, durations running out. A skipped or KO'd turn is already committed.
func begin_turn(unit: BattleUnit) -> TurnStart:
	var t := TurnStart.new()
	t.unit = unit
	if not unit.is_player and unit.data.escape_after_turns > 0 and not unit.stolen.is_empty() 			and unit.turns_taken > unit.data.escape_after_turns:
		unit.escaped = true
		queue.remove(unit)
		t.escaped = true
		t.skip = true
		return t
	var max_hp := unit.max_hp()
	if unit.has_status(StatusEffects.Id.POISON):
		t.damage = unit.take_damage(maxi(1, roundi(max_hp * StatusEffects.POISON_PERCENT / 100.0)))
	if unit.has_status(StatusEffects.Id.REGEN):
		t.heal = unit.heal(maxi(1, roundi(max_hp * StatusEffects.REGEN_PERCENT / 100.0)))
	if unit.has_status(StatusEffects.Id.PETRIFY) and unit.statuses[StatusEffects.Id.PETRIFY] <= 1:
		unit.hp = 0
	for id: int in unit.statuses.keys():
		if StatusEffects.blocks_action(id) and not t.skip:
			t.skip = true
			t.reason = id
	# Durations tick after the checks, so a 1-turn Paralysis skips exactly one turn.
	for id: int in unit.statuses.keys():
		if unit.statuses[id] > 0:
			unit.statuses[id] -= 1
			if unit.statuses[id] == 0:
				remove_status(unit, id)
				t.expired.append(id)
	if not unit.is_alive():
		t.knocked_out = true
		t.skip = true
		_on_knock_out(unit)
	elif t.skip:
		queue.commit_action(TurnQueue.WEIGHT_NORMAL)
	return t


func alive(units: Array[BattleUnit]) -> Array[BattleUnit]:
	return units.filter(func(u: BattleUnit) -> bool: return u.is_alive())


func opponents_of(unit: BattleUnit) -> Array[BattleUnit]:
	return alive(enemies if unit.is_player else party)


func allies_of(unit: BattleUnit) -> Array[BattleUnit]:
	return alive(party if unit.is_player else enemies)


func knocked_out_allies_of(unit: BattleUnit) -> Array[BattleUnit]:
	return (party if unit.is_player else enemies).filter(func(u: BattleUnit) -> bool: return not u.is_alive())


## Valid targets for a skill or item target type, from `unit`'s point of view.
func targets_for(unit: BattleUnit, target: SkillData.Target) -> Array[BattleUnit]:
	match target:
		SkillData.Target.ENEMY, SkillData.Target.ALL_ENEMIES:
			return opponents_of(unit)
		SkillData.Target.ALLY, SkillData.Target.ALL_ALLIES:
			return allies_of(unit)
		SkillData.Target.ALLY_KO:
			return knocked_out_allies_of(unit)
	return [unit] as Array[BattleUnit]


func outcome() -> Outcome:
	if fled:
		return Outcome.FLED
	if alive(enemies).is_empty():
		return Outcome.VICTORY
	if alive(party).is_empty():
		return Outcome.SCRIPTED if not end_after_turns.is_empty() else Outcome.DEFEAT
	for unit in enemies:
		if end_after_turns.has(unit.data.id) and unit.turns_taken >= int(end_after_turns[unit.data.id]):
			return Outcome.SCRIPTED
	return Outcome.ONGOING


# ---------- statuses ----------

## Applies a status (respecting immunities). Returns false if it did not take.
func add_status(unit: BattleUnit, id: StatusEffects.Id, turns := 0) -> bool:
	if id in unit.data.status_immunities or not unit.is_alive():
		return false
	if id == StatusEffects.Id.HASTE:
		remove_status(unit, StatusEffects.Id.SLOW)
	elif id == StatusEffects.Id.SLOW:
		remove_status(unit, StatusEffects.Id.HASTE)
	unit.statuses[id] = turns if turns != 0 else StatusEffects.default_turns(id)
	_update_speed(unit)
	return true


func remove_status(unit: BattleUnit, id: int) -> void:
	unit.statuses.erase(id)
	_update_speed(unit)


func _update_speed(unit: BattleUnit) -> void:
	var mult := 1.0
	if unit.has_status(StatusEffects.Id.HASTE):
		mult = 0.5
	elif unit.has_status(StatusEffects.Id.SLOW):
		mult = 2.0
	queue.set_speed_mult(unit, mult)


# ---------- actions ----------

## Single-target convenience (tests, AI): resolves on `target`, or on every valid target
## for multi-target skills. Returns the first result.
func resolve(actor: BattleUnit, skill: SkillData, target: BattleUnit,
		timing := DamageFormula.Timing.MISS) -> ActionResult:
	var targets: Array[BattleUnit] = [target]
	if skill.is_multi_target():
		targets = targets_for(actor, skill.target)
	return resolve_action(actor, skill, targets, timing)[0]


## Resolves `skill` from `actor` on every unit in `targets` and refills the actor's turn.
## `timing` is the button-press result: the attacker's press for hero actions, the
## defender's press when an enemy hits a hero.
func resolve_action(actor: BattleUnit, skill: SkillData, targets: Array[BattleUnit],
		timing := DamageFormula.Timing.MISS) -> Array[ActionResult]:
	var results: Array[ActionResult] = []
	actor.mp -= skill.mp_cost
	if skill == actor.data.special:
		actor.aether = 0
	if actor.is_player and timing == DamageFormula.Timing.PERFECT \
			and actor.data.perfect_bonus == CombatantData.PerfectBonus.MAGIC_REFUND and skill.kind == SkillData.Kind.MAGIC:
		actor.mp += roundi(skill.mp_cost * MP_REFUND_SHARE)
	for target in targets:
		results.append(_apply_skill(actor, skill, target, timing))
	if not results.is_empty():
		_after_action(actor, skill, results, timing)
	queue.commit_action(skill.weight)
	return results


## Uses a consumable from `inventory`. Items are fast (weight 2) and ignore timing.
func use_item(actor: BattleUnit, item: ItemData, targets: Array[BattleUnit]) -> Array[ActionResult]:
	var results: Array[ActionResult] = []
	if int(inventory.get(item.id, 0)) <= 0:
		queue.commit_action(TurnQueue.WEIGHT_FAST)
		return results
	inventory[item.id] = int(inventory[item.id]) - 1
	if inventory[item.id] <= 0:
		inventory.erase(item.id)
	for target in targets:
		var r := ActionResult.new()
		r.actor = actor
		r.item = item
		r.target = target
		if item.revive_percent > 0.0 and not target.is_alive():
			_revive(target, item.revive_percent)
			r.revived = true
			r.amount = target.hp
		elif target.is_alive():
			r.amount = target.heal(item.heal_hp)
		if target.is_alive():
			r.mp_amount = target.restore_mp(item.heal_mp)
			for id in item.cures:
				if target.has_status(id):
					remove_status(target, id)
					r.statuses_removed.append(id)
		results.append(r)
	queue.commit_action(TurnQueue.WEIGHT_FAST)
	return results


func usable_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for id: StringName in inventory:
		var item := DataRegistry.item(id)
		if item and item.kind == ItemData.Kind.CONSUMABLE and item.battle_usable and int(inventory[id]) > 0:
			items.append(item)
	return items


## GDD 2.4: 50% + (party average speed − enemy average speed), 10–95%. Never vs bosses.
## Failing spends a fast turn.
func flee_chance() -> float:
	if enemies.any(func(e: BattleUnit) -> bool: return e.data.is_boss):
		return 0.0
	var avg := func(units: Array[BattleUnit]) -> float:
		return units.reduce(func(sum: float, u: BattleUnit) -> float: return sum + u.stat(&"speed"), 0.0) / maxf(1.0, units.size())
	return clampf(50.0 + avg.call(alive(party)) - avg.call(alive(enemies)), 10.0, 95.0)


func try_flee() -> bool:
	var chance := flee_chance()
	fled = chance > 0.0 and rng.randf() * 100.0 < chance
	queue.commit_action(TurnQueue.WEIGHT_FAST)
	return fled


## FFX-style swap: the reserve takes the active hero's place and turn counter, and acts now.
func swap(out_unit: BattleUnit, in_unit: BattleUnit) -> void:
	assert(out_unit in party and in_unit in reserves, "swap(): invalid units")
	queue.swap(out_unit, in_unit, in_unit.stat(&"speed"))
	party[party.find(out_unit)] = in_unit
	reserves[reserves.find(in_unit)] = out_unit
	out_unit.defending = false


func swappable_reserves() -> Array[BattleUnit]:
	return alive(reserves)


# ---------- Dual / Triple Techs ----------

## Techs `unit` can start now: every participant is active, able to act and has the MP.
func available_techs(unit: BattleUnit, techs: Array[DualTechData]) -> Array[DualTechData]:
	var out: Array[DualTechData] = []
	for tech in techs:
		if not unit.data.id in tech.participants:
			continue
		var members := tech_participants(tech)
		if members.size() == tech.participants.size() and members.all(_can_join_tech.bind(tech)):
			out.append(tech)
	return out


func _can_join_tech(u: BattleUnit, tech: DualTechData) -> bool:
	var silenced := u.has_status(StatusEffects.Id.SILENCE) and tech.skill.kind == SkillData.Kind.MAGIC
	return u.is_alive() and not u.is_blocked() and u.mp >= tech.mp_cost and not silenced


func tech_participants(tech: DualTechData) -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	for id in tech.participants:
		for u in party:
			if u.data.id == id:
				units.append(u)
	return units


## Resolves a Dual/Triple Tech started by `lead` (the current actor). `timings` holds one
## press per participant; each PERFECT/GOOD boosts the effect. Partners spend their turn.
func resolve_tech(tech: DualTechData, lead: BattleUnit, targets: Array[BattleUnit],
		timings: Array[int]) -> Array[ActionResult]:
	var members := tech_participants(tech)
	var bonus := 1.0
	for t in timings:
		bonus += tech.perfect_bonus if t == DamageFormula.Timing.PERFECT else (tech.good_bonus if t == DamageFormula.Timing.GOOD else 0.0)
	for u in members:
		u.mp -= tech.mp_cost
	var results: Array[ActionResult] = []
	for target in targets:
		results.append(_apply_skill(lead, tech.skill, target, DamageFormula.Timing.MISS, bonus))
	for u in members:
		if u != lead:
			queue.refill(u, tech.skill.weight)
	queue.commit_action(tech.skill.weight)
	return results


# ---------- effects ----------

func _apply_skill(actor: BattleUnit, skill: SkillData, target: BattleUnit,
		timing: DamageFormula.Timing, bonus := 1.0) -> ActionResult:
	var r := ActionResult.new()
	r.actor = actor
	r.skill = skill
	r.target = target
	r.timing = timing
	match skill.kind:
		SkillData.Kind.DEFEND:
			actor.defending = true
		SkillData.Kind.HEAL:
			if skill.revive_percent > 0.0 and not target.is_alive():
				_revive(target, skill.revive_percent)
				r.revived = true
				r.amount = target.hp
			else:
				var amount := DamageFormula.finalize(DamageFormula.heal_base(actor.stat(&"magic"), skill.power),
					DamageFormula.roll_variance(rng), false, 1.0, DamageFormula.attack_timing_mult(timing),
					aether_factor * bonus)
				r.amount = target.heal(amount)
			_apply_statuses(r)
		SkillData.Kind.SUPPORT:
			if skill.revive_percent > 0.0 and not target.is_alive():
				_revive(target, skill.revive_percent)
				r.revived = true
				r.amount = target.hp
			_apply_statuses(r)
		SkillData.Kind.ATTACK, SkillData.Kind.MAGIC:
			_resolve_offense(r, bonus)
	if skill.steals and r.hit and actor.is_alive() and not actor.is_player:
		r.stolen_item = _steal(actor)
	return r


## Takes one random consumable from the party's inventory for `thief`.
func _steal(thief: BattleUnit) -> StringName:
	var options: Array[StringName] = []
	for id: StringName in inventory:
		var item := DataRegistry.item(id)
		if int(inventory[id]) > 0 and item and item.kind == ItemData.Kind.CONSUMABLE:
			options.append(id)
	if options.is_empty():
		return &""
	var id := options[rng.randi_range(0, options.size() - 1)]
	inventory[id] = int(inventory[id]) - 1
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	thief.stolen.append(id)
	return id


func _resolve_offense(r: ActionResult, bonus: float) -> void:
	var actor := r.actor
	var target := r.target
	var skill := r.skill
	if not target.is_alive():
		r.hit = false
		return
	var physical := skill.kind == SkillData.Kind.ATTACK

	if physical:
		var chance := DamageFormula.hit_chance(actor.stat(&"precision"), target.stat(&"evasion"))
		if actor.has_status(StatusEffects.Id.BLIND):
			chance -= StatusEffects.BLIND_HIT_PENALTY
		if rng.randf() * 100.0 >= chance:
			r.hit = false
			return

	var base: float
	if physical:
		var defense := float(target.stat(&"defense"))
		if target.has_status(StatusEffects.Id.DISMANTLED):
			defense *= StatusEffects.DISMANTLED_DEFENSE_MULT
		base = DamageFormula.physical_base(actor.attack_power(), skill.multiplier, roundi(defense))
	else:
		base = DamageFormula.magical_base(actor.stat(&"magic"), skill.power, skill.multiplier, target.stat(&"spirit")) * aether_factor

	r.crit = physical and rng.randf() * 100.0 < DamageFormula.crit_chance(actor.stat(&"luck"))
	var element := DamageFormula.element_mult(target.data.affinity_for(skill.element))

	# Timing: heroes press to hit harder; heroes being hit press to take less.
	var timing_mult := 1.0
	if actor.is_player:
		timing_mult = DamageFormula.attack_timing_mult(r.timing)
		if r.timing == DamageFormula.Timing.PERFECT and actor.data.perfect_bonus == CombatantData.PerfectBonus.STEAM and physical:
			timing_mult = STEAM_PERFECT_MULT
	elif target.is_player:
		timing_mult = DamageFormula.defense_timing_mult(r.timing)

	var other := bonus
	if target.defending:
		other *= balance.defend_mult
	if physical and target.has_status(StatusEffects.Id.PROTECT):
		other *= StatusEffects.PROTECT_MULT
	if not physical and target.has_status(StatusEffects.Id.BARRIER):
		other *= StatusEffects.PROTECT_MULT
	if target.has_status(StatusEffects.Id.OVERHEAT):
		other *= StatusEffects.OVERHEAT_TAKEN_MULT
	if is_guarded(target):
		other *= target.data.guarded_damage_mult
	if physical and actor.has_status(StatusEffects.Id.OVERHEAT):
		other *= StatusEffects.OVERHEAT_ATTACK_MULT

	var amount := DamageFormula.finalize(base, DamageFormula.roll_variance(rng), r.crit,
		absf(element), timing_mult, other)
	if element < 0.0:
		r.absorbed = true
		r.amount = target.heal(amount)
		return
	r.amount = _damage(target, amount)
	if actor.is_player and r.timing == DamageFormula.Timing.PERFECT \
			and actor.data.perfect_bonus == CombatantData.PerfectBonus.EXTRA_HIT and target.is_alive():
		r.extra_amount = _damage(target, maxi(1, roundi(amount * EXTRA_HIT_SHARE)))
	actor.threat += r.amount + r.extra_amount
	# Sleep breaks on physical hits; confusion has a 50% chance to clear.
	if physical and target.has_status(StatusEffects.Id.SLEEP):
		remove_status(target, StatusEffects.Id.SLEEP)
		r.statuses_removed.append(StatusEffects.Id.SLEEP)
	if target.has_status(StatusEffects.Id.CONFUSION) and rng.randf() < 0.5:
		remove_status(target, StatusEffects.Id.CONFUSION)
		r.statuses_removed.append(StatusEffects.Id.CONFUSION)
	if not target.is_alive():
		r.knocked_out = true
		_on_knock_out(target)
	else:
		_apply_statuses(r)


## HP loss plus the target's Aether gain (heroes fill the bar when hurt).
func _damage(target: BattleUnit, amount: int) -> int:
	var lost := target.take_damage(amount)
	if target.is_player and lost > 0:
		target.add_aether(roundi(AETHER_DAMAGE_SHARE * 100.0 * lost / target.max_hp()))
	return lost


func _apply_statuses(r: ActionResult) -> void:
	var skill := r.skill
	var target := r.target
	for id: int in skill.cures:
		if target.has_status(id):
			remove_status(target, id)
			r.statuses_removed.append(id)
	if skill.inflicts.is_empty() or not target.is_alive():
		return
	if skill.mechanical_only and not target.data.mechanical:
		r.no_effect = true
		return
	for id: int in skill.inflicts:
		# Eco's Protection keeps allies from being dragged in (Triturador's Compact).
		if id == StatusEffects.Id.STUCK and target.has_status(StatusEffects.Id.PROTECT):
			r.resisted.append(id)
			continue
		var chance := float(skill.inflicts[id])
		# GDD 6: Spirit resists negative statuses — except machine-only effects (Kael hears
		# the machine; there is no will to resist).
		if StatusEffects.is_negative(id) and not skill.mechanical_only:
			chance *= 1.0 - target.stat(&"spirit") / 200.0
		if rng.randf() * 100.0 < chance and add_status(target, id, skill.status_turns):
			r.statuses_added.append(id)
		else:
			r.resisted.append(id)


func _after_action(actor: BattleUnit, skill: SkillData, results: Array[ActionResult], timing: DamageFormula.Timing) -> void:
	# The hero who pressed (attacker, or the hero being hit) fills the Aether bar.
	var presser: BattleUnit = actor if actor.is_player else (results[0].target if results[0].target.is_player else null)
	if presser:
		presser.add_aether(AETHER_PERFECT if timing == DamageFormula.Timing.PERFECT else (AETHER_GOOD if timing == DamageFormula.Timing.GOOD else 0))
	if skill.kind == SkillData.Kind.ATTACK and actor.has_status(StatusEffects.Id.OVERHEAT):
		remove_status(actor, StatusEffects.Id.OVERHEAT)  # the charged blow is spent
	if actor.is_player and timing == DamageFormula.Timing.OVERLOAD and actor.data.perfect_bonus == CombatantData.PerfectBonus.STEAM:
		add_status(actor, StatusEffects.Id.OVERHEAT)
		results[0].overheated_self = true
	# Eco's perfect block shields the whole party (GDD 4.2).
	if not actor.is_player and timing == DamageFormula.Timing.PERFECT and presser \
			and presser.data.perfect_bonus == CombatantData.PerfectBonus.GUARD_ALL:
		for hero in alive(party):
			add_status(hero, StatusEffects.Id.PROTECT, GUARD_ALL_TURNS)


func _revive(target: BattleUnit, percent: float) -> void:
	target.hp = maxi(1, roundi(target.max_hp() * percent))
	target.statuses.clear()
	queue.readd(target, target.stat(&"speed"), target.is_player)


func _on_knock_out(unit: BattleUnit) -> void:
	for id in unit.stolen:
		inventory[id] = int(inventory.get(id, 0)) + 1  # the loot falls back to the party
	unit.stolen.clear()
	unit.statuses.clear()
	unit.defending = false
	queue.remove(unit)
	if unit.is_player:
		unit.aether = 0
		for hero in alive(party):
			hero.add_aether(AETHER_ALLY_DOWN)


## Boss parts: true while a guarding part (`guarded_by`) is still standing.
func is_guarded(unit: BattleUnit) -> bool:
	if unit.data.guarded_by.is_empty():
		return false
	var mates := enemies if not unit.is_player else party
	return mates.any(func(u: BattleUnit) -> bool: return u != unit and u.is_alive() and u.data.id in unit.data.guarded_by)


# ---------- AI ----------

## Enemy AI (GDD 9): rules by priority/weight when defined, else weighted skills.
## Returns [skill, target]; multi-target skills hit every valid target when resolved.
func choose_enemy_action(unit: BattleUnit) -> Array:
	if unit.has_status(StatusEffects.Id.CONFUSION):
		return choose_confused_action(unit)
	if not unit.data.ai_rules.is_empty():
		var rule := _pick_rule(unit)
		if rule:
			return [rule.skill, _rule_target(unit, rule)]
	var options: Array[SkillData] = []
	var weights: Array[float] = []
	for i in unit.data.skills.size():
		var skill := unit.data.skills[i]
		if unit.can_use(skill):
			options.append(skill)
			weights.append(float(unit.data.ai_weights[i]) if i < unit.data.ai_weights.size() else 1.0)
	var skill := options[rng.rand_weighted(PackedFloat32Array(weights))]
	var targets := targets_for(unit, skill.target)
	return [skill, targets[rng.randi_range(0, targets.size() - 1)]]


## Confused units attack anyone (except themselves) with their basic attack.
func choose_confused_action(unit: BattleUnit) -> Array:
	var skill: SkillData = unit.data.skills[0]
	for s in unit.data.skills:
		if s.kind == SkillData.Kind.ATTACK:
			skill = s
			break
	var everyone: Array[BattleUnit] = []
	everyone.append_array(party)
	everyone.append_array(enemies)
	var candidates := alive(everyone).filter(func(u: BattleUnit) -> bool: return u != unit)
	if candidates.is_empty():
		return [skill, unit]
	return [skill, candidates[rng.randi_range(0, candidates.size() - 1)]]


func _pick_rule(unit: BattleUnit) -> AIRule:
	var valid: Array[AIRule] = []
	for rule in unit.data.ai_rules:
		if rule.skill and unit.can_use(rule.skill) and _rule_condition(unit, rule):
			valid.append(rule)
	if valid.is_empty():
		return null
	var top: int = valid.map(func(r: AIRule) -> int: return r.priority).max()
	var best := valid.filter(func(r: AIRule) -> bool: return r.priority == top)
	var weights := PackedFloat32Array(best.map(func(r: AIRule) -> float: return float(maxi(1, r.weight))))
	return best[rng.rand_weighted(weights)]


func _rule_condition(unit: BattleUnit, rule: AIRule) -> bool:
	match rule.condition:
		AIRule.Condition.SELF_HP_BELOW:
			return unit.hp * 100.0 / unit.max_hp() < rule.value
		AIRule.Condition.ALLY_DOWN:
			return not knocked_out_allies_of(unit).is_empty()
		AIRule.Condition.ANY_HERO_WITHOUT_STATUS:
			return opponents_of(unit).any(func(u: BattleUnit) -> bool: return not u.has_status(int(rule.value)))
		AIRule.Condition.EVERY_N_TURNS:
			return rule.value > 0 and unit.turns_taken % int(rule.value) == 0
	return true


func _rule_target(unit: BattleUnit, rule: AIRule) -> BattleUnit:
	var pool := targets_for(unit, rule.skill.target)
	if pool.is_empty():
		return unit
	match rule.target_mode:
		AIRule.TargetMode.SELF:
			return unit
		AIRule.TargetMode.LOWEST_HP:
			pool.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.hp * 1.0 / a.max_hp() < b.hp * 1.0 / b.max_hp())
			return pool[0]
		AIRule.TargetMode.HIGHEST_THREAT:
			pool.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.threat > b.threat)
			return pool[0]
		AIRule.TargetMode.WITHOUT_STATUS:
			var without := pool.filter(func(u: BattleUnit) -> bool: return not u.has_status(int(rule.value)))
			if not without.is_empty():
				pool = without
	return pool[rng.randi_range(0, pool.size() - 1)]


# ---------- rewards ----------

func total_xp() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + (0 if u.escaped else u.data.xp_reward), 0)


## XP of the enemies actually knocked out (story fights that end early).
func defeated_xp() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + (0 if u.is_alive() or u.escaped else u.data.xp_reward), 0)


func total_money() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + (0 if u.escaped else u.data.money_reward), 0)


func total_ap() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + (0 if u.escaped else u.data.ap_reward), 0)


## Rolls every enemy's drop table. Returns the item ids won (may repeat).
func roll_drops() -> Array[StringName]:
	var won: Array[StringName] = []
	for e in enemies:
		if e.escaped:
			continue
		for id: StringName in e.data.drops:
			if rng.randf() * 100.0 < float(e.data.drops[id]):
				won.append(id)
	return won


## Writes HP/MP/Aether back to the party and shares the XP (GDD 8.3: reserves 75%,
## KO'd heroes 50%). Returns one entry per hero: {member, xp, levels}. KO'd heroes come
## back with 1 HP (prototype rule until revive items and inns exist).
func finish_victory(xp := -1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if xp < 0:
		xp = total_xp()
	for unit in party + reserves:
		var member := unit.member
		if member == null:
			continue
		if member.data.guest:
			member.hp = maxi(unit.hp, 1)
			member.mp = unit.mp
			continue  # guests keep a fixed level
		member.hp = maxi(unit.hp, 1)
		member.mp = unit.mp
		member.aether = unit.aether
		var share := 1.0
		if unit in reserves:
			share = balance.xp_reserve_mult
		elif not unit.is_alive():
			share = balance.xp_ko_mult
		var gained := roundi(xp * share)
		results.append({"member": member, "xp": gained, "levels": member.gain_xp(gained, balance)})
	return results
