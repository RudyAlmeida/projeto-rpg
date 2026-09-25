class_name Battle
extends RefCounted
## Battle rules without any nodes: who acts next (TurnQueue), what an action does
## (DamageFormula), enemy AI and the outcome. BattleScene drives it and animates the results.

enum Outcome { ONGOING, VICTORY, DEFEAT }


## What happened when an action resolved, for the UI to animate.
class ActionResult:
	var actor: BattleUnit
	var skill: SkillData
	var target: BattleUnit
	var amount := 0          # damage dealt or HP healed
	var hit := true
	var crit := false
	var knocked_out := false
	var absorbed := false    # element absorbed: the target was healed
	var timing := DamageFormula.Timing.MISS


var party: Array[BattleUnit] = []
var enemies: Array[BattleUnit] = []
var queue: TurnQueue
var rng: RandomNumberGenerator
var balance: CombatBalance


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


## Starts with the persistent party: current HP/MP and level-scaled stats carry in.
## Heroes already KO'd do not take part.
func start_with_party(members: Array[PartyMember], foes: Array[CombatantData], initiative := false) -> void:
	for member in members:
		if not member.is_alive():
			continue
		var unit := BattleUnit.new(member.data, true, member)
		party.append(unit)
		queue.add(unit, unit.stat(&"speed"), true, initiative, rng)
	for data in foes:
		var unit := BattleUnit.new(data, false)
		enemies.append(unit)
		queue.add(unit, unit.stat(&"speed"), false, false, rng)


## Writes HP/MP back to the party and shares the XP (GDD 8.3: KO'd heroes get 50%).
## Returns one entry per hero: {member, xp, levels}. KO'd heroes come back with 1 HP
## (prototype rule until revive items and inns exist).
func finish_victory() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var xp := total_xp()
	for unit in party:
		var member := unit.member
		member.hp = maxi(unit.hp, 1)
		member.mp = unit.mp
		var share := roundi(xp * (1.0 if unit.is_alive() else balance.xp_ko_mult))
		results.append({"member": member, "xp": share, "levels": member.gain_xp(share, balance)})
	return results


## Advances the CTB queue. The returned unit's defend stance ends as its turn begins.
func next_turn() -> BattleUnit:
	var unit := queue.next() as BattleUnit
	if unit:
		unit.defending = false
	return unit


func alive(units: Array[BattleUnit]) -> Array[BattleUnit]:
	return units.filter(func(u: BattleUnit) -> bool: return u.is_alive())


func opponents_of(unit: BattleUnit) -> Array[BattleUnit]:
	return alive(enemies if unit.is_player else party)


func allies_of(unit: BattleUnit) -> Array[BattleUnit]:
	return alive(party if unit.is_player else enemies)


func outcome() -> Outcome:
	if alive(enemies).is_empty():
		return Outcome.VICTORY
	if alive(party).is_empty():
		return Outcome.DEFEAT
	return Outcome.ONGOING


## Resolves `skill` from `actor` on `target` and refills the actor's turn counter.
## `timing` is the button-press result: the attacker's press for hero attacks, the
## defender's press when an enemy hits a hero.
func resolve(actor: BattleUnit, skill: SkillData, target: BattleUnit,
		timing := DamageFormula.Timing.MISS) -> ActionResult:
	var r := ActionResult.new()
	r.actor = actor
	r.skill = skill
	r.target = target
	r.timing = timing
	actor.mp -= skill.mp_cost

	match skill.kind:
		SkillData.Kind.DEFEND:
			actor.defending = true
		SkillData.Kind.HEAL:
			var amount := DamageFormula.finalize(DamageFormula.heal_base(actor.stat(&"magic"), skill.power),
				DamageFormula.roll_variance(rng), false, 1.0, DamageFormula.attack_timing_mult(timing))
			r.amount = target.heal(amount)
		SkillData.Kind.ATTACK, SkillData.Kind.MAGIC:
			_resolve_offense(r)

	queue.commit_action(skill.weight)
	return r


func _resolve_offense(r: ActionResult) -> void:
	var actor := r.actor
	var target := r.target
	var skill := r.skill
	var physical := skill.kind == SkillData.Kind.ATTACK

	if physical and rng.randf() * 100.0 >= DamageFormula.hit_chance(actor.stat(&"precision"), target.stat(&"evasion")):
		r.hit = false
		return

	var base: float
	if physical:
		base = DamageFormula.physical_base(actor.stat(&"strength") + actor.data.weapon_power, skill.multiplier, target.stat(&"defense"))
	else:
		base = DamageFormula.magical_base(actor.stat(&"magic"), skill.power, skill.multiplier, target.stat(&"spirit"))

	r.crit = physical and rng.randf() * 100.0 < DamageFormula.crit_chance(actor.stat(&"luck"))
	var element := DamageFormula.element_mult(target.data.affinity_for(skill.element))
	# Timing: heroes press to hit harder; heroes being hit press to take less.
	var timing_mult := DamageFormula.attack_timing_mult(r.timing) if actor.is_player \
		else DamageFormula.defense_timing_mult(r.timing)
	var stance := balance.defend_mult if target.defending else 1.0

	var amount := DamageFormula.finalize(base, DamageFormula.roll_variance(rng), r.crit,
		absf(element), timing_mult, stance)
	if element < 0.0:
		r.absorbed = true
		r.amount = target.heal(amount)
		return
	r.amount = target.take_damage(amount)
	if not target.is_alive():
		r.knocked_out = true
		queue.remove(target)


## Enemy AI (prototype): weighted random skill the enemy can afford, random living target.
func choose_enemy_action(unit: BattleUnit) -> Array:
	var options: Array[SkillData] = []
	var weights: Array[float] = []
	for i in unit.data.skills.size():
		var skill := unit.data.skills[i]
		if unit.can_use(skill):
			options.append(skill)
			weights.append(float(unit.data.ai_weights[i]) if i < unit.data.ai_weights.size() else 1.0)
	var skill := options[rng.rand_weighted(PackedFloat32Array(weights))]
	var targets := allies_of(unit) if skill.target == SkillData.Target.ALLY else opponents_of(unit)
	if skill.target == SkillData.Target.SELF:
		targets = [unit] as Array[BattleUnit]
	return [skill, targets[rng.randi_range(0, targets.size() - 1)]]


func total_xp() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + u.data.xp_reward, 0)


func total_money() -> int:
	return enemies.reduce(func(sum: int, u: BattleUnit) -> int: return sum + u.data.money_reward, 0)
