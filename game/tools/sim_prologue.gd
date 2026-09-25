extends Node
## Balance simulation of the prologue encounters (Battle logic only, no nodes).
## Heroes: heal an ally under 40% HP when they can, otherwise hit the weakest foe; timing
## skill is modelled per profile (PERFECT / GOOD / MISS chances, attack and defence).
## Run: godot --headless --path game res://tools/sim_prologue.tscn
## Prints win rate, average hero turns and the HP the party has left, per encounter.

const RUNS := 300
const PROFILES := {
	"casual": [0.10, 0.45, 0.45],   # perfect, good, miss
	"medio": [0.25, 0.50, 0.25],
	"bom": [0.50, 0.40, 0.10],
}
## [label, party [[id, level]], enemies, end_after_turns]
const FIGHTS := [
	["Estrada: 2 Slimes", [["kael", 1], ["gerd", 1]], ["oil_slime", "oil_slime"], {}],
	["FV1: 2 Ratos", [["kael", 2], ["gerd", 1]], ["gear_rat", "gear_rat"], {}],
	["FV1: Corvo", [["kael", 2], ["gerd", 1]], ["scrap_crow"], {}],
	["FV1: Slime + Rato", [["kael", 2], ["gerd", 1]], ["oil_slime", "gear_rat"], {}],
	["FV2: Aranha", [["kael", 3], ["gerd", 1]], ["bolt_spider"], {}],
	["FV2: Corvo + Rato", [["kael", 3], ["gerd", 1]], ["scrap_crow", "gear_rat"], {}],
	["FV2: Slime + Aranha", [["kael", 3], ["gerd", 1]], ["oil_slime", "bolt_spider"], {}],
	["FV3: Sentinela + Slime", [["kael", 3], ["gerd", 1]], ["brass_sentinel", "oil_slime"], {}],
	["FV3: Lâmpada", [["kael", 3], ["gerd", 1]], ["wander_lamp"], {}],
	["FV3: Aranha + Lâmpada", [["kael", 4], ["gerd", 1]], ["bolt_spider", "wander_lamp"], {}],
	["CHEFE: Triturador", [["kael", 4], ["gerd", 1], ["eco", 4]], ["crusher_claw_up", "crusher_core", "crusher_claw_down"], {}],
	["Voss (roteiro)", [["kael", 5], ["gerd", 1], ["eco", 5]], ["imperial_soldier", "voss", "imperial_soldier"], {&"voss": 4}],
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2026
	for profile: String in PROFILES:
		print("\n=== perfil: %s ===" % profile)
		for fight: Array in FIGHTS:
			_simulate(fight, PROFILES[profile])
	get_tree().quit()


func _timing(chances: Array) -> DamageFormula.Timing:
	var roll := _rng.randf()
	if roll < chances[0]:
		return DamageFormula.Timing.PERFECT
	if roll < chances[0] + chances[1]:
		return DamageFormula.Timing.GOOD
	return DamageFormula.Timing.MISS


func _simulate(fight: Array, chances: Array) -> void:
	var wins := 0
	var turns := 0
	var hp_left := 0.0
	var ko := 0
	for run in RUNS:
		var b := Battle.new(_rng)
		b.inventory = {&"potion": 3}
		var members: Array[PartyMember] = []
		for entry: Array in fight[1]:
			members.append(PartyMember.new(load("res://data/characters/%s.tres" % entry[0]), entry[1]))
		if members[0].data.id == &"kael" and int(fight[1][0][1]) < 4:
			members[0].equip(load("res://data/items/wrench.tres"))
		var foes: Array[CombatantData] = []
		for id: String in fight[2]:
			foes.append(load("res://data/enemies/%s.tres" % id))
		b.start_with_party(members, foes)
		b.end_after_turns = fight[3]
		var hero_turns := 0
		for step in 400:
			if b.outcome() != Battle.Outcome.ONGOING:
				break
			var unit := b.next_turn()
			if b.begin_turn(unit).skip:
				continue
			if unit.is_player:
				hero_turns += 1
				_hero_act(b, unit, chances)
			else:
				var choice := b.choose_enemy_action(unit)
				var skill: SkillData = choice[0]
				var targets: Array[BattleUnit] = [choice[1]]
				if skill.is_multi_target():
					targets = b.targets_for(unit, skill.target)
				b.resolve_action(unit, skill, targets, _timing(chances))
		var outcome := b.outcome()
		if outcome == Battle.Outcome.VICTORY or (outcome == Battle.Outcome.SCRIPTED and not b.alive(b.party).is_empty()):
			wins += 1
		turns += hero_turns
		var hp := 0.0
		for u in b.party:
			hp += float(u.hp) / u.max_hp()
			if not u.is_alive():
				ko += 1
		hp_left += hp / b.party.size()
	print("%-26s vitória %3d%%  turnos %4.1f  HP restante %3d%%  KOs/luta %.2f" % [fight[0], 100 * wins / RUNS,
		float(turns) / RUNS, roundi(100 * hp_left / RUNS), float(ko) / RUNS])


func _hero_act(b: Battle, unit: BattleUnit, chances: Array) -> void:
	var skills := unit.skill_list()
	# Heal someone below 40% if this hero can.
	var hurt: Array = b.alive(b.party).filter(func(u: BattleUnit) -> bool: return float(u.hp) / u.max_hp() < 0.4)
	if not hurt.is_empty():
		for s in skills:
			if s.kind == SkillData.Kind.HEAL and s.target == SkillData.Target.ALLY and unit.can_use(s):
				var who: Array[BattleUnit] = [hurt[0]]
				b.resolve_action(unit, s, who, _timing(chances))
				return
	if unit.data.special and unit.aether_full():
		var sp := unit.data.special
		var sp_targets: Array[BattleUnit] = []
		if sp.is_multi_target():
			sp_targets = b.targets_for(unit, sp.target)
		else:
			sp_targets.append(b.alive(b.opponents_of(unit))[0])
		b.resolve_action(unit, sp, sp_targets, _timing(chances))
		return
	var foes: Array[BattleUnit] = b.alive(b.opponents_of(unit))
	# Kael dismantles mechanical foes once; otherwise attack the weakest (claws first).
	foes.sort_custom(func(x: BattleUnit, y: BattleUnit) -> bool: return x.hp < y.hp)
	var target: BattleUnit = foes[0]
	var skill: SkillData = skills[0]
	for s in skills:
		if s.mechanical_only and target.data.mechanical and not target.has_status(StatusEffects.Id.DISMANTLED) and unit.can_use(s):
			skill = s
	var one: Array[BattleUnit] = [target]
	b.resolve_action(unit, skill, one, _timing(chances))
