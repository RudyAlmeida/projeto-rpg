extends Node
## Generates the prototype data resources (skills, items, techs, heroes, enemies, trees,
## quests, dialogue, cutscenes) with the real classes and saves them with ResourceSaver —
## safer than hand-written .tres. Runs as a scene so autoload-dependent classes compile.
## Run: godot --headless --path game res://tools/build_data.tscn
## Edit the tables below and re-run; the .tres files are the output, not the source.

const S := StatusEffects.Id
const E := SkillData.Element
const K := SkillData.Kind
const T := SkillData.Target

var _skills := {}
var _saved := 0


func _ready() -> void:
	_build_skills()
	_build_items()
	_build_equipment_and_gems()
	_build_characters()
	_build_enemies()
	_build_techs()
	_build_trees()
	_build_village_content()
	print("build_data: %d resources written" % _saved)
	get_tree().quit()


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
	# Skill-tree techniques.
	_skill("kael_piston", "Golpe de Pistão", K.ATTACK, T.ENEMY, {"mp_cost": 4, "multiplier": 1.6, "description": "Golpe carregado pelo pistão da lâmina."})
	_skill("kael_quick", "Engrenagem Rápida", K.SUPPORT, T.SELF, {"mp_cost": 5, "weight": 2, "inflicts": {S.HASTE: 100}, "description": "Kael acelera: Pressa."})
	_skill("lyra_poison", "Espinhos Venenosos", K.SUPPORT, T.ENEMY, {"mp_cost": 3, "inflicts": {S.POISON: 85}, "description": "Envenena o alvo."})
	_skill("lyra_regen", "Seiva", K.SUPPORT, T.ALLY, {"mp_cost": 5, "inflicts": {S.REGEN: 100}, "description": "Regeneração em um aliado."})
	_skill("brann_scald", "Vapor Escaldante", K.ATTACK, T.ALL_ENEMIES, {"mp_cost": 5, "multiplier": 0.8, "weight": 4, "description": "Jato de vapor em todos os inimigos."})
	_skill("brann_barrier", "Barreira de Vapor", K.SUPPORT, T.ALL_ALLIES, {"mp_cost": 6, "inflicts": {S.BARRIER: 100}, "description": "Barreira para o grupo."})
	_skill("eco_barrier", "Campo Etéreo", K.SUPPORT, T.ALLY, {"mp_cost": 3, "inflicts": {S.BARRIER: 100}, "description": "Barreira em um aliado."})
	# Gem magic (levels 1–3).
	_skill("fire2", "Labareda", K.MAGIC, T.ENEMY, {"mp_cost": 9, "power": 42, "element": E.FIRE})
	_skill("fire3", "Inferno", K.MAGIC, T.ALL_ENEMIES, {"mp_cost": 16, "power": 38, "element": E.FIRE, "weight": 4})
	_skill("ice2", "Nevasca", K.MAGIC, T.ENEMY, {"mp_cost": 9, "power": 42, "element": E.ICE})
	_skill("ice3", "Era do Gelo", K.MAGIC, T.ALL_ENEMIES, {"mp_cost": 16, "power": 38, "element": E.ICE, "weight": 4})
	_skill("thunder", "Raio", K.MAGIC, T.ENEMY, {"mp_cost": 5, "power": 22, "element": E.THUNDER, "description": "Descarga elétrica. Forte contra máquinas."})
	_skill("thunder2", "Trovão", K.MAGIC, T.ENEMY, {"mp_cost": 10, "power": 44, "element": E.THUNDER})
	_skill("thunder3", "Tempestade", K.MAGIC, T.ALL_ENEMIES, {"mp_cost": 17, "power": 40, "element": E.THUNDER, "weight": 4})
	_skill("heal", "Cura", K.HEAL, T.ALLY, {"mp_cost": 4, "power": 30, "description": "Recupera HP de um aliado."})
	_skill("heal2", "Cura em Grupo", K.HEAL, T.ALL_ALLIES, {"mp_cost": 10, "power": 30})
	_skill("heal3", "Renascer", K.HEAL, T.ALLY_KO, {"mp_cost": 18, "revive_percent": 0.5, "description": "Revive um aliado com 50% do HP."})
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


# ---------- equipment & gems ----------

var _items := {}


func _gear(id: String, name: String, kind: ItemData.Kind, icon: int, price: int, attack: int, bonuses: Dictionary,
		slots: int, who: Array, description: String) -> void:
	var owners: Array[StringName] = []
	for w: String in who:
		owners.append(StringName(w))
	_items[id] = _item(id, name, kind, icon, price, {"attack": attack, "stat_bonuses": bonuses, "gem_slots": slots,
		"equippable_by": owners, "battle_usable": false, "field_usable": false, "description": description})


func _gem(id: String, name: String, icon: int, price: int, skills: Array, bonuses: Dictionary, effects: Dictionary,
		description: String) -> void:
	_items[id] = _item(id, name, ItemData.Kind.GEM, icon, price, {"gem_skills": _skills_of(skills),
		"gem_stat_bonuses": bonuses, "gem_effects": effects, "battle_usable": false, "field_usable": false,
		"description": description})


func _build_equipment_and_gems() -> void:
	var W := ItemData.Kind.WEAPON
	var A := ItemData.Kind.ARMOR
	var X := ItemData.Kind.ACCESSORY
	# Starting gear.
	_gear("gear_blade", "Lâmina-engrenagem", W, 4, 0, 10, {}, 2, ["kael"], "A espada de Kael, com pistão no guarda-mão.")
	_gear("root_staff", "Cajado de Raiz", W, 5, 0, 4, {&"magic": 2}, 2, ["lyra"], "Raiz viva com um cristal quase apagado.")
	_gear("steam_gauntlet", "Manopla a Vapor", W, 6, 0, 12, {}, 1, ["brann"], "O braço de Brann.")
	_gear("leather_coat", "Casaco de Couro", A, 7, 80, 0, {&"defense": 3}, 1, [], "Couro resistente de oficina.")
	# Shop gear.
	_gear("brass_blade", "Lâmina de Latão", W, 4, 320, 17, {}, 2, ["kael"], "Lâmina reforçada com latão.")
	_gear("oak_staff", "Cajado de Carvalho", W, 5, 300, 6, {&"magic": 6}, 3, ["lyra"], "Cajado antigo de Sylvaran.")
	_gear("heavy_gauntlet", "Manopla Reforçada", W, 6, 340, 20, {}, 2, ["brann"], "Pistões duplos e mais pressão.")
	_gear("aviator_coat", "Casaco de Aviador", A, 7, 260, 0, {&"defense": 7, &"spirit": 2}, 2, [], "Couro forrado dos aeronautas.")
	_gear("eco_plating", "Placas de Aethel", A, 7, 300, 0, {&"defense": 10}, 2, ["eco"], "Placas de pedra antiga para Eco.")
	_gear("brass_amulet", "Amuleto de Latão", X, 8, 150, 0, {&"spirit": 2, &"luck": 2}, 0, [], "Proteção contra o azar.")
	_gear("gear_amulet", "Amuleto de Engrenagem", X, 8, 220, 0, {&"speed": 3}, 0, [], "Uma engrenagem que nunca para de girar.")
	# Gems (levels at 20 and 80 AP).
	_gem("gem_fire", "Gema de Fogo", 9, 400, ["fire", "fire2", "fire3"], {&"magic": 1}, {}, "Fogo → Labareda → Inferno.")
	_gem("gem_ice", "Gema de Gelo", 10, 400, ["ice", "ice2", "ice3"], {&"magic": 1}, {}, "Gelo → Nevasca → Era do Gelo.")
	_gem("gem_thunder", "Gema de Raio", 11, 450, ["thunder", "thunder2", "thunder3"], {&"magic": 1}, {}, "Raio → Trovão → Tempestade.")
	_gem("gem_heal", "Gema de Cura", 12, 450, ["heal", "heal2", "heal3"], {&"spirit": 1}, {}, "Cura → Cura em Grupo → Renascer.")
	_gem("gem_strength", "Gema de Força", 13, 500, [], {&"strength": 3, &"max_hp": 10}, {}, "+3 FOR e +10 HP por nível.")
	_gem("gem_timing", "Olho de Relojoeiro", 14, 600, [], {}, {&"timing_window": 1.25}, "Janela de timing +25% por nível.")


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
	_hero("kael", {"starting_equipment": [_items["gear_blade"], _items["leather_coat"]] as Array[ItemData],
		"skills": _skills_of(["attack", "kael_resonance", "defend"]), "special": _skills["kael_special"],
		"timing_style": CombatantData.TimingStyle.RING, "perfect_bonus": CombatantData.PerfectBonus.EXTRA_HIT,
		"portrait": load("res://assets/portraits/por_kael_neutral.png")})
	_hero("lyra", {"starting_equipment": [_items["root_staff"], _items["leather_coat"]] as Array[ItemData],
		"skills": _skills_of(["attack", "fire", "ice", "lyra_sleep", "defend"]), "special": _skills["lyra_special"],
		"timing_style": CombatantData.TimingStyle.CHANNEL, "perfect_bonus": CombatantData.PerfectBonus.MAGIC_REFUND})
	_hero("brann", {"starting_equipment": [_items["steam_gauntlet"], _items["leather_coat"]] as Array[ItemData],
		"skills": _skills_of(["attack", "defend"]), "special": _skills["brann_special"],
		"timing_style": CombatantData.TimingStyle.HOLD, "perfect_bonus": CombatantData.PerfectBonus.STEAM})
	_hero("eco", {"starting_equipment": [_items["leather_coat"]] as Array[ItemData],
		"display_name": "Eco", "battle_sheet": load("res://assets/sprites/characters/eco/chr_eco_ref.png"),
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


# ---------- skill trees ----------

func _node(id: String, name: String, cost: int, pos: Vector2i, props := {}) -> SkillTreeNode:
	var n := SkillTreeNode.new()
	n.id = StringName(id)
	n.display_name = name
	n.cost = cost
	n.grid_position = pos
	for key: String in props:
		if key == "requires":
			for r: String in props[key]:
				n.requires.append(StringName(r))
		elif key == "skill":
			n.skill = _skills[props[key]]
		else:
			n.set(key, props[key])
	return n


func _tree(character: String, nodes: Array) -> void:
	var t := SkillTreeData.new()
	t.id = StringName(character + "_tree")
	t.character = StringName(character)
	t.nodes.assign(nodes)
	_save(t, "res://data/trees/%s.tres" % character)


func _build_trees() -> void:
	_tree("kael", [
		_node("k_vigor", "Vigor", 1, Vector2i(0, 0), {"stat_bonuses": {&"max_hp": 15}, "description": "+15 HP"}),
		_node("k_str1", "Força I", 1, Vector2i(0, 1), {"stat_bonuses": {&"strength": 2}, "description": "+2 FOR"}),
		_node("k_piston", "Golpe de Pistão", 2, Vector2i(1, 0), {"requires": ["k_vigor"], "skill": "kael_piston", "description": "Nova técnica"}),
		_node("k_str2", "Força II", 2, Vector2i(1, 1), {"requires": ["k_str1"], "stat_bonuses": {&"strength": 3}, "description": "+3 FOR"}),
		_node("k_quick", "Engrenagem Rápida", 3, Vector2i(2, 0), {"requires": ["k_piston"], "skill": "kael_quick", "description": "Nova técnica: Pressa"}),
		_node("k_reflex", "Reflexos", 2, Vector2i(2, 1), {"requires": ["k_str2"], "stat_bonuses": {&"speed": 2, &"evasion": 2}, "description": "+2 VEL, +2 EVA"}),
	])
	_tree("lyra", [
		_node("l_mind1", "Mente I", 1, Vector2i(0, 0), {"stat_bonuses": {&"magic": 2}, "description": "+2 MAG"}),
		_node("l_breath", "Fôlego", 1, Vector2i(0, 1), {"stat_bonuses": {&"max_mp": 10}, "description": "+10 MP"}),
		_node("l_poison", "Espinhos Venenosos", 2, Vector2i(1, 0), {"requires": ["l_mind1"], "skill": "lyra_poison", "description": "Nova técnica: Veneno"}),
		_node("l_bark", "Casca de Árvore", 2, Vector2i(1, 1), {"requires": ["l_breath"], "stat_bonuses": {&"defense": 3, &"spirit": 2}, "description": "+3 DEF, +2 ESP"}),
		_node("l_regen", "Seiva", 3, Vector2i(2, 0), {"requires": ["l_poison"], "skill": "lyra_regen", "description": "Nova técnica: Regeneração"}),
		_node("l_mind2", "Mente II", 2, Vector2i(2, 1), {"requires": ["l_bark"], "stat_bonuses": {&"magic": 3}, "description": "+3 MAG"}),
	])
	_tree("brann", [
		_node("b_armor1", "Couraça I", 1, Vector2i(0, 0), {"stat_bonuses": {&"defense": 2}, "description": "+2 DEF"}),
		_node("b_str1", "Punho de Ferro", 1, Vector2i(0, 1), {"stat_bonuses": {&"strength": 2}, "description": "+2 FOR"}),
		_node("b_scald", "Vapor Escaldante", 2, Vector2i(1, 0), {"requires": ["b_armor1"], "skill": "brann_scald", "description": "Nova técnica: todos os inimigos"}),
		_node("b_armor2", "Couraça II", 2, Vector2i(1, 1), {"requires": ["b_str1"], "stat_bonuses": {&"defense": 3, &"max_hp": 20}, "description": "+3 DEF, +20 HP"}),
		_node("b_barrier", "Barreira de Vapor", 3, Vector2i(2, 0), {"requires": ["b_scald"], "skill": "brann_barrier", "description": "Nova técnica: Barreira no grupo"}),
		_node("b_boiler", "Fôlego de Caldeira", 2, Vector2i(2, 1), {"requires": ["b_armor2"], "stat_bonuses": {&"max_mp": 8}, "description": "+8 MP"}),
	])
	_tree("eco", [
		_node("e_plate1", "Blindagem I", 1, Vector2i(0, 0), {"stat_bonuses": {&"defense": 3}, "description": "+3 DEF"}),
		_node("e_core", "Núcleo Estável", 1, Vector2i(0, 1), {"stat_bonuses": {&"max_hp": 20}, "description": "+20 HP"}),
		_node("e_field", "Campo Etéreo", 2, Vector2i(1, 0), {"requires": ["e_plate1"], "skill": "eco_barrier", "description": "Nova técnica: Barreira"}),
		_node("e_sensors", "Sensores", 2, Vector2i(1, 1), {"requires": ["e_core"], "stat_bonuses": {&"precision": 2, &"spirit": 2}, "description": "+2 PRE, +2 ESP"}),
		_node("e_plate2", "Blindagem II", 3, Vector2i(2, 0), {"requires": ["e_field"], "stat_bonuses": {&"defense": 4}, "description": "+4 DEF"}),
		_node("e_surge", "Sobrecarga de Éter", 2, Vector2i(2, 1), {"requires": ["e_sensors"], "stat_bonuses": {&"magic": 3}, "description": "+3 MAG"}),
	])


# ---------- Vila Caldeira test content (quests, NPC dialogue, cutscene) ----------

const POR_GERD := "res://assets/portraits/por_gerd_neutral.png"
const POR_KAEL := "res://assets/portraits/por_kael_neutral.png"


func _line(speaker: String, text: String, portrait := "") -> DialogueLine:
	return DialogueLine.make(speaker, text, load(portrait) if portrait != "" else null)


func _lines(items: Array) -> Array[DialogueLine]:
	var out: Array[DialogueLine] = []
	for item: Array in items:
		out.append(_line(item[0], item[1], item[2] if item.size() > 2 else ""))
	return out


func _branch(lines: Array[DialogueLine], props := {}) -> DialogueBranch:
	var b := DialogueBranch.new()
	b.lines = lines
	for key: String in props:
		if key in ["require_flags", "forbid_flags", "set_flags"]:
			var arr: Array[StringName] = []
			for f: String in props[key]:
				arr.append(StringName(f))
			b.set(key, arr)
		else:
			b.set(key, props[key])
	return b


func _dialogue_set(id: String, branches: Array) -> void:
	var s := DialogueSet.new()
	s.id = StringName(id)
	s.branches.assign(branches)
	_save(s, "res://data/dialogue/%s.tres" % id)


func _choice(text: String, affinity: Dictionary, response: Array[DialogueLine]) -> DialogueChoice:
	var c := DialogueChoice.new()
	c.text = text
	c.affinity = affinity
	c.set_flags = [&"lyra_talked"] as Array[StringName]
	c.response = response
	return c


func _step(type: CutsceneStep.Type, props := {}) -> CutsceneStep:
	var s := CutsceneStep.new()
	s.type = type
	for key: String in props:
		s.set(key, props[key])
	return s


func _build_village_content() -> void:
	var quest := QuestData.new()
	quest.id = &"q_village_noise"
	quest.title = "Barulhos na Vila"
	quest.description = "Mestre Gerd viu uma máquina imperial rondando o sudoeste de Vila Caldeira."
	quest.main_story = true
	quest.objective_ids = [&"defeat_sentinel"] as Array[StringName]
	quest.objective_texts = ["Derrote a Sentinela de Latão no sudoeste da vila"] as Array[String]
	quest.reward_money = 150
	quest.reward_xp = 40
	quest.reward_items = {&"gem_thunder": 1}
	_save(quest, "res://data/quests/q_village_noise.tres")

	var G := "Mestre Gerd"
	_dialogue_set("gerd", [
		_branch(_lines([
			[G, "Uma Sentinela imperial? Aqui, tão longe da capital...", POR_GERD],
			["Kael", "Ela estava rondando a vila, mestre. Mas já era.", POR_KAEL],
			[G, "Hmpf. Bom trabalho, garoto. Leve esta gema: ela ouve o raio melhor do que eu.", POR_GERD],
		]), {"require_quest_state": "q_village_noise=ready", "finish_quest": &"q_village_noise"}),
		_branch(_lines([
			[G, "A tal máquina ainda está lá fora, perto das casas do sudoeste. Cuidado com o canhão dela.", POR_GERD],
		]), {"require_quest_state": "q_village_noise=active"}),
		_branch(_lines([
			[G, "Continue treinando com a lâmina. E passe na casa do noroeste: a Lyra perguntou de você.", POR_GERD],
		]), {"require_quest_state": "q_village_noise=done"}),
		_branch(_lines([
			[G, "Kael! Até que enfim. A caldeira da senhora Brisa voltou a assobiar.", POR_GERD],
			["Kael", "De novo? Mas eu troquei a válvula ontem, mestre!", POR_KAEL],
			[G, "Hmpf. As máquinas não mentem, garoto. Se ela assobia, é porque quer dizer alguma coisa.", POR_GERD],
			[G, "Aliás... vi uma máquina imperial rondando o sudoeste da vila. Dá uma olhada? Com cuidado.", POR_GERD],
		]), {"start_quest": &"q_village_noise"}),
	])
	_dialogue_set("merchant", [
		_branch(_lines([["Lojista", "Bem-vindo à Engrenagem Dourada! Poções, peças e gemas — tudo com garantia de latão."]])),
	])
	_dialogue_set("innkeeper", [
		_branch(_lines([["Estalajadeira", "Estalagem da Chaleira! A sopa está quente e as camas, macias."]])),
	])
	var L := "Lyra"
	var question := _line(L, "Então você é o garoto que conversa com máquinas. Diga: elas merecem viver mais do que as florestas?")
	question.choices = [
		_choice("Elas também sentem. Dá para cuidar de ambas.", {&"lyra": 2},
			_lines([[L, "...Talvez você não seja como os outros do Império."]])),
		_choice("Máquinas são o futuro. É assim que as coisas são.", {&"lyra": -1, &"isolde": 1},
			_lines([[L, "É exatamente esse \"futuro\" que está matando a floresta."]])),
		_choice("Eu só conserto coisas.", {},
			_lines([[L, "Hmpf. Veremos se é só isso."]])),
	] as Array[DialogueChoice]
	_dialogue_set("lyra_house", [
		_branch(_lines([[L, "A floresta ainda sente falta do Éter... mas obrigada por ouvir."]]), {"require_flags": ["lyra_talked"]}),
		_branch([question] as Array[DialogueLine]),
	])

	var intro := Cutscene.new()
	intro.id = &"intro_gerd"
	intro.once_flag = &"intro_seen"
	intro.steps = [
		_step(CutsceneStep.Type.SAY, {"lines": _lines([[G, "Ei, Kael! Espere aí!", POR_GERD]])}),
		_step(CutsceneStep.Type.MOVE, {"actor": NodePath("Gerd"), "position": Vector2(330, 232), "speed": 70.0}),
		_step(CutsceneStep.Type.FACE, {"actor": NodePath("Player"), "facing": Player.Facing.RIGHT}),
		_step(CutsceneStep.Type.SAY, {"lines": _lines([
			[G, "Antes de sair por aí, pegue estas poções. Ninguém da minha oficina anda desprevenido.", POR_GERD],
			["Kael", "Valeu, mestre!", POR_KAEL],
		])}),
		_step(CutsceneStep.Type.GIVE_ITEM, {"id": &"potion", "amount": 2}),
		_step(CutsceneStep.Type.MOVE, {"actor": NodePath("Gerd"), "position": Vector2(424, 232), "speed": 70.0}),
		_step(CutsceneStep.Type.FACE, {"actor": NodePath("Gerd"), "facing": Player.Facing.LEFT}),
	] as Array[CutsceneStep]
	_save(intro, "res://data/cutscenes/intro_gerd.tres")


func _build_techs() -> void:
	_tech("spark", "Faísca Viva", ["kael", "lyra"], "tech_spark", 4, "Kael + Lyra: a lâmina ganha a chama de Lyra.")
	_tech("iron_wall", "Muralha de Ferro", ["brann", "eco"], "tech_iron_wall", 4, "Brann + Eco: escudo e regeneração para o grupo.")
	_tech("earth_roar", "Rugido da Terra", ["lyra", "brann", "eco"], "tech_earth_roar", 6, "Lyra + Brann + Eco: terremoto de vapor e raízes.")
