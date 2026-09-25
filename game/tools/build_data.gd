extends SceneTree
## Generates the prototype data resources (skills, items, techs, heroes, enemies) with the
## real classes and saves them with ResourceSaver — safer than hand-written .tres.
## Run: godot --headless --path game -s res://tools/build_data.gd
## Edit the tables below and re-run; the .tres files are the output, not the source.

const S := StatusEffects.Id
const E := SkillData.Element
const K := SkillData.Kind
const T := SkillData.Target

var _skills := {}
var _saved := 0


func _init() -> void:
	_build_skills()
	_build_items()
	_build_characters()
	_build_enemies()
	_build_techs()
	print("build_data: %d resources written" % _saved)
	quit()


# ---------- helpers ----------

func _skill(id: String, name: String, kind: K, target: T, props := {}) -> SkillData:
	var s := SkillData.new()
	s.id = StringName(id)
	s.display_name = name
	s.kind = kind
	s.target = target
	for key: String in props:
		s.set(key, props[key])
	_skills[id] = s
	_save(s, "res://data/skills/%s.tres" % id)
	return s


func _save(res: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	# Reuse the existing path so scenes that reference it keep working.
	res.take_over_path(path)
	var err := ResourceSaver.save(res, path)
	assert(err == OK, "could not save %s: %s" % [path, error_string(err)])
	_saved += 1


func _skills_of(ids: Array) -> Array[SkillData]:
	var out: Array[SkillData] = []
	for id: String in ids:
		out.append(_skills[id])
	return out


func _rule(priority: int, condition: AIRule.Condition, value: float, skill_id: String,
		target: AIRule.TargetMode, weight := 1, tell := "") -> AIRule:
	var r := AIRule.new()
	r.priority = priority
	r.condition = condition
	r.value = value
	r.skill = _skills[skill_id]
	r.target_mode = target
	r.weight = weight
	r.tell = tell
	return r


# ---------- skills ----------

func _build_skills() -> void:
	_skill("attack", "Atacar", K.ATTACK, T.ENEMY, {"description": "Ataque físico com a arma equipada."})
	_skill("defend", "Defender", K.DEFEND, T.SELF, {"weight": 2, "description": "Reduz o dano recebido pela metade até o próximo turno."})
	_skill("fire", "Fogo", K.MAGIC, T.ENEMY, {"mp_cost": 4, "power": 20, "element": E.FIRE, "description": "Chama mágica. Forte contra criaturas de óleo."})
	_skill("ice", "Gelo", K.MAGIC, T.ENEMY, {"mp_cost": 4, "power": 20, "element": E.ICE, "description": "Estilhaços de gelo."})
	_skill("lyra_sleep", "Sono", K.SUPPORT, T.ENEMY, {"mp_cost": 5, "inflicts": {S.SLEEP: 75}, "description": "Faz o alvo dormir."})
	_skill("kael_resonance", "Ressonância", K.ATTACK, T.ENEMY, {"mp_cost": 3, "multiplier": 0.6, "inflicts": {S.DISMANTLED: 100},
		"mechanical_only": true, "description": "Kael ouve a máquina e solta uma peça: inimigos mecânicos ficam Desmontados (DEF −50%)."})
	_skill("eco_protect", "Protocolo Escudo", K.SUPPORT, T.ALL_ALLIES, {"mp_cost": 6, "inflicts": {S.PROTECT: 100}, "description": "Proteção para todo o grupo."})
	_skill("eco_repair", "Reparo", K.HEAL, T.ALLY, {"mp_cost": 4, "power": 25, "description": "Recupera HP de um aliado."})
	# Specials (Aether bar full).
	_skill("kael_special", "Engrenagem Final", K.ATTACK, T.ENEMY, {"multiplier": 2.8, "description": "Sequência de cortes com vapor."})
	_skill("lyra_special", "Floração", K.MAGIC, T.ALL_ENEMIES, {"power": 45, "element": E.FIRE, "description": "Uma explosão de chamas floresce sobre os inimigos."})
	_skill("brann_special", "Martelo de Caldeira", K.ATTACK, T.ALL_ENEMIES, {"multiplier": 1.8, "weight": 4, "description": "Golpe de vapor que atinge todos os inimigos."})
	_skill("eco_special", "Protocolo Aegis", K.SUPPORT, T.ALL_ALLIES, {"inflicts": {S.PROTECT: 100, S.BARRIER: 100, S.REGEN: 100}, "description": "Barreira completa para o grupo."})
	# Enemy skills.
	_skill("slime_tackle", "Investida", K.ATTACK, T.ENEMY, {"description": "O slime se atira contra o alvo."})
	_skill("slime_oil_jet", "Jato de Óleo", K.SUPPORT, T.ENEMY, {"inflicts": {S.SLOW: 70}, "description": "Óleo grudento que deixa o alvo lento."})
	_skill("sentinel_club", "Clava Cravada", K.ATTACK, T.ENEMY, {"multiplier": 1.2})
	_skill("sentinel_cannon", "Canhão de Vapor", K.ATTACK, T.ALL_ENEMIES, {"multiplier": 0.75, "weight": 4})
	_skill("sentinel_repair", "Autorreparo", K.HEAL, T.SELF, {"power": 30})
	# Dual/Triple Tech effects (used through DualTechData).
	_skill("tech_spark", "Faísca Viva", K.ATTACK, T.ENEMY, {"multiplier": 2.0, "element": E.FIRE})
	_skill("tech_iron_wall", "Muralha de Ferro", K.SUPPORT, T.ALL_ALLIES, {"inflicts": {S.PROTECT: 100, S.REGEN: 100}})
	_skill("tech_earth_roar", "Rugido da Terra", K.MAGIC, T.ALL_ENEMIES, {"power": 40, "element": E.EARTH, "weight": 4})


# ---------- items ----------

func _item(id: String, name: String, kind: ItemData.Kind, icon: int, price: int, props := {}) -> ItemData:
	var it := ItemData.new()
	it.id = StringName(id)
	it.display_name = name
	it.kind = kind
	it.icon_index = icon
	it.price = price
	for key: String in props:
		it.set(key, props[key])
	_save(it, "res://data/items/%s.tres" % id)
	return it


func _build_items() -> void:
	var C := ItemData.Kind.CONSUMABLE
	_item("potion", "Poção", C, 0, 30, {"heal_hp": 60, "description": "Recupera 60 HP."})
	_item("ether", "Éter Engarrafado", C, 1, 90, {"heal_mp": 25, "description": "Recupera 25 MP."})
	_item("phoenix_feather", "Pena Fênix", C, 2, 200, {"target": T.ALLY_KO, "revive_percent": 0.3, "description": "Revive um aliado com 30% do HP."})
	_item("antidote", "Antídoto", C, 3, 20, {"cures": [S.POISON] as Array[int], "description": "Cura Veneno."})
	_item("smelling_salts", "Sais de Vapor", C, 3, 40, {"cures": [S.SLEEP, S.CONFUSION, S.PARALYSIS, S.SILENCE, S.BLIND] as Array[int],
		"description": "Cura Sono, Confusão, Paralisia, Silêncio e Cegueira."})


# ---------- heroes ----------

func _hero(id: String, props: Dictionary) -> CombatantData:
	var path := "res://data/characters/%s.tres" % id
	var d: CombatantData = load(path) if ResourceLoader.exists(path) else CombatantData.new()
	d.id = StringName(id)
	for key: String in props:
		d.set(key, props[key])
	_save(d, path)
	return d


func _build_characters() -> void:
	_hero("kael", {"skills": _skills_of(["attack", "kael_resonance", "defend"]), "special": _skills["kael_special"],
		"timing_style": CombatantData.TimingStyle.RING, "perfect_bonus": CombatantData.PerfectBonus.EXTRA_HIT,
		"portrait": load("res://assets/portraits/por_kael_neutral.png")})
	_hero("lyra", {"skills": _skills_of(["attack", "fire", "ice", "lyra_sleep", "defend"]), "special": _skills["lyra_special"],
		"timing_style": CombatantData.TimingStyle.CHANNEL, "perfect_bonus": CombatantData.PerfectBonus.MAGIC_REFUND})
	_hero("brann", {"skills": _skills_of(["attack", "defend"]), "special": _skills["brann_special"],
		"timing_style": CombatantData.TimingStyle.HOLD, "perfect_bonus": CombatantData.PerfectBonus.STEAM})
	_hero("eco", {"display_name": "Eco", "battle_sheet": load("res://assets/sprites/characters/eco/chr_eco_ref.png"),
		"idle_frame": 3, "mechanical": true,
		"max_hp": 150, "max_mp": 25, "strength": 11, "weapon_power": 6, "magic": 8, "defense": 16, "spirit": 10,
		"speed": 18, "luck": 5, "precision": 9, "evasion": 3,
		"growth": {&"max_hp": 14.0, &"max_mp": 2.0, &"strength": 1.0, &"magic": 0.8, &"defense": 1.6, &"spirit": 1.0,
			&"speed": 0.4, &"luck": 0.3, &"precision": 0.4, &"evasion": 0.2},
		"skills": _skills_of(["attack", "eco_protect", "eco_repair", "defend"]), "special": _skills["eco_special"],
		"timing_style": CombatantData.TimingStyle.RING, "perfect_bonus": CombatantData.PerfectBonus.GUARD_ALL,
		"status_immunities": [S.POISON, S.SLEEP] as Array[int]})


# ---------- enemies ----------

func _build_enemies() -> void:
	var slime_path := "res://data/enemies/oil_slime.tres"
	var slime: CombatantData = load(slime_path)
	slime.id = &"oil_slime"
	slime.skills = _skills_of(["slime_tackle", "slime_oil_jet"])
	slime.ai_weights = [70, 30] as Array[int]
	slime.ai_rules = [
		_rule(1, AIRule.Condition.ALWAYS, 0, "slime_tackle", AIRule.TargetMode.RANDOM, 70),
		_rule(1, AIRule.Condition.ANY_HERO_WITHOUT_STATUS, S.SLOW, "slime_oil_jet", AIRule.TargetMode.WITHOUT_STATUS, 30),
	] as Array[AIRule]
	slime.ap_reward = 3
	slime.drops = {&"potion": 25.0}
	_save(slime, slime_path)

	var sentinel := CombatantData.new()
	sentinel.id = &"brass_sentinel"
	sentinel.display_name = "Sentinela de Latão"
	sentinel.battle_sheet = load("res://assets/sprites/enemies/enm_brass_sentinel.png")
	sentinel.frame_size = Vector2i(72, 48)
	sentinel.idle_frame = 0
	sentinel.attack_frame = 2
	sentinel.hurt_frame = 3
	sentinel.max_hp = 110
	sentinel.strength = 14
	sentinel.weapon_power = 8
	sentinel.magic = 6
	sentinel.defense = 16
	sentinel.spirit = 6
	sentinel.speed = 14
	sentinel.luck = 3
	sentinel.precision = 9
	sentinel.evasion = 2
	sentinel.mechanical = true
	sentinel.status_immunities = [S.POISON, S.SLEEP] as Array[int]
	sentinel.affinities = {E.THUNDER: DamageFormula.Affinity.WEAK, E.FIRE: DamageFormula.Affinity.RESIST}
	sentinel.skills = _skills_of(["sentinel_club", "sentinel_cannon", "sentinel_repair"])
	sentinel.ai_rules = [
		_rule(3, AIRule.Condition.SELF_HP_BELOW, 35, "sentinel_repair", AIRule.TargetMode.SELF),
		_rule(2, AIRule.Condition.EVERY_N_TURNS, 3, "sentinel_cannon", AIRule.TargetMode.ALL, 1,
			"A Sentinela acumula vapor no canhão..."),
		_rule(1, AIRule.Condition.ALWAYS, 0, "sentinel_club", AIRule.TargetMode.HIGHEST_THREAT),
	] as Array[AIRule]
	sentinel.xp_reward = 30
	sentinel.money_reward = 25
	sentinel.ap_reward = 6
	sentinel.drops = {&"ether": 20.0}
	_save(sentinel, "res://data/enemies/brass_sentinel.tres")


# ---------- techs ----------

func _tech(id: String, name: String, participants: Array, skill_id: String, mp: int, description: String) -> void:
	var t := DualTechData.new()
	t.id = StringName(id)
	t.display_name = name
	for p: String in participants:
		t.participants.append(StringName(p))
	t.skill = _skills[skill_id]
	t.mp_cost = mp
	t.description = description
	_save(t, "res://data/techs/%s.tres" % id)


func _build_techs() -> void:
	_tech("spark", "Faísca Viva", ["kael", "lyra"], "tech_spark", 4, "Kael + Lyra: a lâmina ganha a chama de Lyra.")
	_tech("iron_wall", "Muralha de Ferro", ["brann", "eco"], "tech_iron_wall", 4, "Brann + Eco: escudo e regeneração para o grupo.")
	_tech("earth_roar", "Rugido da Terra", ["lyra", "brann", "eco"], "tech_earth_roar", 6, "Lyra + Brann + Eco: terremoto de vapor e raízes.")
