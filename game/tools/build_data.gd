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
	_build_prologue()
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
	_gear("wrench", "Chave de Oficina", W, 4, 0, 6, {}, 1, ["kael"], "A chave inglesa de Kael. Serve para apertar parafusos... e cabeças.")
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
	slime.field_comment = "Slime de óleo. Onde tem vazamento, tem desses. Fogo resolve."
	slime.field_comment_by = &"gerd"
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
	sentinel.field_comment = "Uma Sentinela imperial?! Aqui? Quando ela esquentar o canhão, se protege!"
	sentinel.field_comment_by = &"gerd"
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


# ---------- Prologue (vertical slice): "A Máquina que Sabia meu Nome" ----------
# Script: docs/Roteiro_Prologo.docx. Maps are generated by tools/build_maps.gd.

const MUSIC_BOSS := "res://assets/audio/music/bgm_boss_a.mp3"
const MUSIC_EMPIRE := "res://assets/audio/music/bgm_empire_a.mp3"
const MUSIC_FAREWELL := "res://assets/audio/music/bgm_farewell_a.mp3"
const MAP_OFICINA := "res://scenes/maps/prologue/oficina.tscn"
const MAP_VILA := "res://scenes/maps/prologue/vila_caldeira.tscn"
const KEY_ICON := 15

var _enemies := {}


## Enemy with a battle sheet (falls back to the slime sheet until its art exists).
func _enemy(id: String, name: String, sheet: String, frame: Vector2i, stats: Dictionary, skill_ids: Array,
		props := {}) -> CombatantData:
	var d := CombatantData.new()
	d.id = StringName(id)
	d.display_name = name
	var path := "res://assets/sprites/enemies/%s.png" % sheet
	d.idle_frame = 0
	d.attack_frame = 2
	d.hurt_frame = 3
	if ResourceLoader.exists(path):
		d.battle_sheet = load(path)
		d.frame_size = frame
	else:
		d.battle_sheet = load("res://assets/sprites/enemies/enm_oil_slime.png")
		d.frame_size = Vector2i(56, 48)
		props = props.duplicate()
		for key in ["idle_frame", "attack_frame", "hurt_frame"]:
			props.erase(key)
	for key: String in stats:
		d.set(key, stats[key])
	d.skills = _skills_of(skill_ids)
	for key: String in props:
		d.set(key, props[key])
	_enemies[id] = d
	_save(d, "res://data/enemies/%s.tres" % id)
	return d


func _say(items: Array) -> CutsceneStep:
	return _step(CutsceneStep.Type.SAY, {"lines": _lines(items)})


func _cutscene(id: String, once_flag: String, steps: Array) -> Cutscene:
	var c := Cutscene.new()
	c.id = StringName(id)
	c.once_flag = StringName(once_flag)
	c.steps.assign(steps)
	_save(c, "res://data/cutscenes/%s.tres" % id)
	return c


func _quest(id: String, title: String, description: String, objectives: Array, rewards := {}) -> void:
	var q := QuestData.new()
	q.id = StringName(id)
	q.title = title
	q.description = description
	q.main_story = rewards.get("main", false)
	for o: Array in objectives:
		q.objective_ids.append(StringName(o[0]))
		q.objective_texts.append(o[1])
	q.reward_money = rewards.get("money", 0)
	q.reward_xp = rewards.get("xp", 0)
	q.reward_items = rewards.get("items", {})
	_save(q, "res://data/quests/%s.tres" % id)


func _build_prologue() -> void:
	_build_prologue_combat()
	_build_prologue_story()


func _build_prologue_combat() -> void:
	var KEY := ItemData.Kind.KEY
	# Key items and quest materials.
	_item("gear_box", "Caixa de Engrenagens", KEY, KEY_ICON, 0, {"battle_usable": false, "field_usable": false,
		"description": "Encomenda do mestre Gerd para o Tobias. Pesada e barulhenta."})
	_item("bronze_valve", "Válvula de Bronze", KEY, KEY_ICON, 0, {"battle_usable": false, "field_usable": false,
		"description": "Válvula antiga para a caldeira da estalagem."})
	_item("brass_spring", "Mola de Latão", KEY, KEY_ICON, 0, {"battle_usable": false, "field_usable": false,
		"description": "Mola roída por um Rato-Engrenagem. O Sr. Anselmo precisa de três."})

	# Skills of the new enemies, Gerd and the boss.
	_skill("rat_bite", "Mordida", K.ATTACK, T.ENEMY, {"multiplier": 0.9, "weight": 2})
	_skill("crow_peck", "Bicada", K.ATTACK, T.ENEMY, {"multiplier": 0.9})
	_skill("crow_snatch", "Furto", K.ATTACK, T.ENEMY, {"multiplier": 0.5, "steals": true, "description": "Rouba um item."})
	_skill("spider_sting", "Ferrão", K.ATTACK, T.ENEMY, {"inflicts": {S.POISON: 60}})
	_skill("lamp_bolt", "Faísca Errante", K.MAGIC, T.ENEMY, {"power": 16, "element": E.THUNDER})
	_skill("lamp_glow", "Brilhar", K.SUPPORT, T.SELF, {"inflicts": {S.PROTECT: 100}, "status_turns": 2})
	_skill("soldier_shot", "Tiro a Vapor", K.ATTACK, T.ENEMY, {"multiplier": 1.1})
	_skill("gerd_bomb", "Bomba de Oficina", K.MAGIC, T.ALL_ENEMIES, {"mp_cost": 5, "power": 16, "element": E.FIRE,
		"weight": 4, "description": "Uma lata de parafusos e pólvora. Fogo em todos os inimigos."})
	_skill("gerd_patch", "Remendo", K.HEAL, T.ALLY, {"mp_cost": 4, "power": 26, "description": "Gerd remenda um aliado."})
	_skill("claw_crush", "Esmagar", K.ATTACK, T.ENEMY, {"multiplier": 1.5, "weight": 4})
	_skill("core_steam", "Vapor Escaldante", K.ATTACK, T.ALL_ENEMIES, {"multiplier": 0.7, "weight": 4})
	_skill("core_compact", "Compactar", K.ATTACK, T.ENEMY, {"multiplier": 0.8, "weight": 4, "inflicts": {S.STUCK: 100}})
	_skill("voss_punch", "Punho de Pistão", K.ATTACK, T.ENEMY, {"multiplier": 1.4, "weight": 4})
	_skill("voss_order", "Ordem de Captura", K.SUPPORT, T.SELF, {"weight": 2})
	_skill("tech_spark_iron", "Faísca e Ferro", K.ATTACK, T.ENEMY, {"multiplier": 2.4})
	_tech("spark_iron", "Faísca e Ferro", ["kael", "gerd"], "tech_spark_iron", 4, "Kael + Gerd: \"Eu seguro, você corta.\"")

	# Gerd: guest in the prologue (fixed level, no equipment).
	_hero("gerd", {"display_name": "Gerd", "guest": true,
		"battle_sheet": load("res://assets/sprites/characters/gerd/npc_gerd_ref.png"), "idle_frame": 3,
		"portrait": load(POR_GERD),
		"max_hp": 190, "max_mp": 30, "strength": 13, "weapon_power": 9, "magic": 11, "defense": 12, "spirit": 10,
		"speed": 16, "luck": 8, "precision": 10, "evasion": 4,
		"skills": _skills_of(["attack", "gerd_bomb", "gerd_patch", "defend"]),
		"timing_style": CombatantData.TimingStyle.RING, "perfect_bonus": CombatantData.PerfectBonus.NONE})

	var comment := {"field_comment_by": &"gerd"}
	var mech := [S.POISON, S.SLEEP] as Array[int]

	_enemy("gear_rat", "Rato-Engrenagem", "enm_gear_rat", Vector2i(52, 28),
		{"max_hp": 38, "strength": 8, "weapon_power": 3, "defense": 4, "spirit": 3, "speed": 34, "luck": 4,
		"precision": 10, "evasion": 10, "xp_reward": 9, "money_reward": 6, "ap_reward": 2}, ["rat_bite"],
		{"mechanical": true, "drops": {&"brass_spring": 45.0},
		"field_comment": "Ratos comendo cobre. Até a praga daqui é mecânica."}.merged(comment))
	_enemy("scrap_crow", "Corvo de Sucata", "enm_scrap_crow", Vector2i(48, 40),
		{"max_hp": 44, "strength": 9, "weapon_power": 4, "defense": 5, "spirit": 5, "speed": 28, "luck": 8,
		"precision": 11, "evasion": 14, "xp_reward": 12, "money_reward": 14, "ap_reward": 3}, ["crow_peck", "crow_snatch"],
		{"ai_weights": [55, 45] as Array[int], "escape_after_turns": 3, "drops": {&"potion": 30.0},
		"affinities": {E.WIND: DamageFormula.Affinity.WEAK},
		"field_comment": "Esses bichos roubam parafuso até do meu bolso. Acerta antes que ele fuja!"}.merged(comment))
	_enemy("bolt_spider", "Aranha-Parafuso", "enm_bolt_spider", Vector2i(52, 36),
		{"max_hp": 56, "strength": 10, "weapon_power": 5, "defense": 8, "spirit": 4, "speed": 18, "luck": 4,
		"precision": 10, "evasion": 5, "xp_reward": 16, "money_reward": 12, "ap_reward": 3}, ["rat_bite", "spider_sting"],
		{"ai_weights": [40, 60] as Array[int], "mechanical": true, "status_immunities": mech, "drops": {&"antidote": 35.0},
		"affinities": {E.ICE: DamageFormula.Affinity.WEAK},
		"field_comment": "Cuidado com o veneno. Tem antídoto na bolsa?"}.merged(comment))
	_enemy("wander_lamp", "Lâmpada Errante", "enm_wander_lamp", Vector2i(45, 48),
		{"max_hp": 42, "max_mp": 40, "strength": 5, "weapon_power": 2, "magic": 12, "defense": 4, "spirit": 12,
		"speed": 22, "luck": 6, "precision": 10, "evasion": 8, "xp_reward": 18, "money_reward": 20, "ap_reward": 4},
		["lamp_bolt", "lamp_glow"],
		{"ai_rules": [
			_rule(2, AIRule.Condition.EVERY_N_TURNS, 3, "lamp_glow", AIRule.TargetMode.SELF, 1, "A lâmpada brilha forte..."),
			_rule(1, AIRule.Condition.ALWAYS, 0, "lamp_bolt", AIRule.TargetMode.RANDOM),
		] as Array[AIRule], "drops": {&"ether": 25.0},
		"affinities": {E.THUNDER: DamageFormula.Affinity.ABSORB, E.ICE: DamageFormula.Affinity.WEAK},
		"field_comment": "Éter vazado criando vida própria... Isso não é natural, Kael."}.merged(comment))
	_enemy("imperial_soldier", "Soldado Imperial", "enm_imperial_soldier", Vector2i(48, 56),
		{"max_hp": 70, "strength": 12, "weapon_power": 8, "defense": 10, "spirit": 6, "speed": 20, "luck": 5,
		"precision": 12, "evasion": 5, "xp_reward": 20, "money_reward": 15, "ap_reward": 3}, ["soldier_shot"], {})

	# Boss: the Triturador, in three parts (the claws guard the core).
	var boss := {"mechanical": true, "is_boss": true, "status_immunities": [S.POISON, S.SLEEP, S.CONFUSION] as Array[int],
		"affinities": {E.THUNDER: DamageFormula.Affinity.WEAK}}
	_enemy("crusher_claw_up", "Garra Superior", "enm_crusher_claw_up", Vector2i(64, 56),
		{"max_hp": 110, "strength": 15, "weapon_power": 8, "defense": 12, "spirit": 5, "speed": 14, "precision": 10,
		"xp_reward": 0, "money_reward": 0}, ["claw_crush"],
		{"ai_rules": [_rule(1, AIRule.Condition.ALWAYS, 0, "claw_crush", AIRule.TargetMode.RANDOM, 1,
			"A garra superior se ergue...")] as Array[AIRule], "formation_offset": Vector2(72, -46),
		"idle_frame": 0, "attack_frame": 1, "hurt_frame": 2}.merged(boss))
	_enemy("crusher_claw_down", "Garra Inferior", "enm_crusher_claw_down", Vector2i(64, 56),
		{"max_hp": 110, "strength": 15, "weapon_power": 8, "defense": 12, "spirit": 5, "speed": 13, "precision": 10,
		"xp_reward": 0, "money_reward": 0}, ["claw_crush"],
		{"ai_rules": [_rule(1, AIRule.Condition.ALWAYS, 0, "claw_crush", AIRule.TargetMode.RANDOM, 1,
			"A garra inferior se ergue...")] as Array[AIRule], "formation_offset": Vector2(72, 50),
		"idle_frame": 0, "attack_frame": 1, "hurt_frame": 2}.merged(boss))
	_enemy("crusher_core", "Triturador", "enm_crusher_core", Vector2i(104, 104),
		{"max_hp": 330, "strength": 14, "weapon_power": 6, "defense": 10, "spirit": 8, "speed": 12, "precision": 10,
		"xp_reward": 120, "money_reward": 200, "ap_reward": 15}, ["core_steam", "core_compact"],
		{"guarded_by": [&"crusher_claw_up", &"crusher_claw_down"] as Array[StringName], "guarded_damage_mult": 0.25,
		"formation_offset": Vector2(128, 4), "idle_frame": 0, "attack_frame": 1, "hurt_frame": 2,
		"ai_rules": [
			_rule(4, AIRule.Condition.SELF_HP_BELOW, 30, "core_compact", AIRule.TargetMode.RANDOM, 1,
				"A fornalha do Triturador se escancara!"),
			_rule(3, AIRule.Condition.ALLY_DOWN, 0, "core_steam", AIRule.TargetMode.ALL, 1, "O Triturador ruge de dor!"),
			_rule(1, AIRule.Condition.ALWAYS, 0, "core_steam", AIRule.TargetMode.ALL, 1, "Vapor escapa das chaminés..."),
		] as Array[AIRule]}.merged(boss))

	# General Voss: story fight, ends after his 4th turn (no game over).
	_enemy("voss", "General Voss", "enm_voss", Vector2i(64, 64),
		{"max_hp": 2400, "strength": 20, "weapon_power": 14, "defense": 45, "spirit": 30, "speed": 12, "luck": 10,
		"precision": 14, "evasion": 3, "xp_reward": 0, "money_reward": 0}, ["voss_punch", "voss_order"],
		{"is_boss": true, "status_immunities": [S.POISON, S.SLEEP, S.CONFUSION, S.PARALYSIS, S.STUCK] as Array[int],
		"idle_frame": 0, "attack_frame": 2, "hurt_frame": 3, "formation_offset": Vector2(116, 0),
		"ai_rules": [
			_rule(2, AIRule.Condition.EVERY_N_TURNS, 2, "voss_order", AIRule.TargetMode.SELF, 1, "\"Soldados! Cerquem-nos!\""),
			_rule(1, AIRule.Condition.ALWAYS, 0, "voss_punch", AIRule.TargetMode.HIGHEST_THREAT, 1, "Voss carrega a manopla..."),
		] as Array[AIRule]})


## Map cell (16 px grid) -> position; used by cutscene moves. Must match build_maps.gd.
static func _cell(x: int, y: int) -> Vector2:
	return Vector2(x * 16 + 8, y * 16 + 8)


func _build_prologue_story() -> void:
	var G := "Mestre Gerd"
	var KA := "Kael"
	var EC := "Eco"
	var TIP := "Dica"
	var ST := CutsceneStep.Type

	_quest("q_prologue", "A Válvula de Bronze", "Serviços do mestre Gerd para a oficina Brunor.",
		[["deliver_box", "Entregar a caixa de engrenagens ao Tobias"],
		["fetch_valve", "Buscar a válvula de bronze no Ferro-Velho do Sul"],
		["return_home", "Voltar para a oficina"]], {"main": true, "xp": 30})
	_quest("q_cat", "O Gato da Dona Berta", "Fuligem, o gato da estalajadeira, fugiu para o Ferro-Velho do Sul.",
		[["find_cat", "Encontrar Fuligem no galpão da esteira"]], {"items": {&"phoenix_feather": 1}, "xp": 20})
	_quest("q_springs", "Peças para o Relojoeiro", "O Sr. Anselmo precisa de três Molas de Latão (os Ratos-Engrenagem roem as molas do ferro-velho).",
		[["bring_springs", "Entregar 3 Molas de Latão"]], {"items": {&"gear_amulet": 1}, "money": 60, "xp": 20})

	# ----- NPC dialogue -----
	_dialogue_set("p_gerd_morning", [
		_branch(_lines([
			[G, "Oitenta? Hah! Aprendeu alguma coisa comigo, afinal.", POR_GERD],
			[G, "Agora o serviço de verdade: a caldeira da estalagem precisa de uma válvula de bronze antiga. Só tem no Ferro-Velho do Sul.", POR_GERD],
			[KA, "O Ferro-Velho? O guarda disse que é proibido.", POR_KAEL],
			[G, "O guarda também disse que a esposa dele cozinha bem. ...Eu vou junto. Minhas costas reclamam, mas este braço aqui ainda funciona.", POR_GERD],
		]), {"require_flags": ["delivered"], "cutscene": _cutscene("p3_gerd_joins", "gerd_joined", [
			_step(ST.JOIN_PARTY, {"id": &"gerd", "amount": 1}),
			_step(ST.COMPLETE_OBJECTIVE, {"id": &"q_prologue:deliver_box"}),
			_say([["", "Gerd entrou no grupo como convidado."],
				[TIP, "Convidados lutam com você, mas não usam equipamento nem saem da linha de frente."],
				[G, "Portão sul, garoto. E não conta pro Olavo.", POR_GERD]]),
		])}),
		_branch(_lines([[G, "A caixa, Kael. Pro Tobias. Oitenta moedas, nem uma a menos.", POR_GERD]])),
	])
	_dialogue_set("p_gerd_evening", [
		_branch(_lines([[G, "Vai dormir, garoto. A cama não vai se deitar sozinha.", POR_GERD]])),
	])
	_dialogue_set("p_eco_home", [
		_branch(_lines([[EC, "Observação: esta casa tem 214 parafusos. 3 estão soltos. Recomendo reparo."]])),
	])
	_dialogue_set("p_tobias", [
		_branch(_lines([
			["Tobias", "Ah, a encomenda do Gerd! Sessenta moedas, e isso é um favor que eu faço."],
			[KA, "Ele disse que o senhor ia chorar miséria.", POR_KAEL],
			["Tobias", "...Oitenta. Mas diz pra ele que eu não chorei."],
			["", "Kael recebeu 80 moedas."],
			[TIP, "Na loja você compra e vende itens. Leve algumas Poções antes de sair da vila!"],
		]), {"require_items": {&"gear_box": 1}, "take_items": {&"gear_box": 1}, "give_money": 80, "set_flags": ["delivered"]}),
		_branch(_lines([["Tobias", "Soldados na praça, na minha vila! Leva o que precisar, garoto. Hoje é por conta... não, espera. Metade."]]),
			{"require_flags": ["empire_arrived"]}),
		_branch(_lines([["Tobias", "Bem-vindo à Engrenagem Dourada! Poções, peças e gemas — tudo com garantia de latão."]])),
	])
	_dialogue_set("p_berta", [
		_branch(_lines([
			["Dona Berta", "Fuligem! Meu menino! Onde você se meteu, seu ingrato?"],
			["Dona Berta", "Obrigada, Kael. Tome, é uma pena de fênix que meu falecido guardava. Deve servir mais pra você."],
			[G, "Você tem jeito com bicho arisco. Puxou a mim.", POR_GERD],
		]), {"require_quest_state": "q_cat=ready", "finish_quest": &"q_cat", "affinity": {&"gerd": 1}}),
		_branch(_lines([["Dona Berta", "Nenhum sinal do Fuligem? Ele adora se esconder atrás de máquinas quentes..."]]),
			{"require_quest_state": "q_cat=active"}),
		_branch(_lines([["Dona Berta", "Os soldados levaram o Olavo... Kael, tome cuidado, pelo amor de tudo."]]),
			{"require_flags": ["empire_arrived"]}),
		_branch(_lines([["Dona Berta", "Fuligem está dormindo em cima da caldeira de novo. Nunca vi gato gostar tanto de vapor."]]),
			{"require_quest_state": "q_cat=done"}),
		_branch(_lines([
			["Dona Berta", "O Éter subiu de novo. Daqui a pouco uma lamparina vai custar mais que um jantar."],
			["Dona Berta", "E pra piorar, meu gato Fuligem fugiu pro Ferro-Velho! Se você passar por lá, traz ele pra mim?"],
		]), {"start_quest": &"q_cat"}),
	])
	_dialogue_set("p_anselmo", [
		_branch(_lines([
			["Sr. Anselmo", "Três molas, perfeitas! Bem... roídas, mas perfeitas."],
			["Sr. Anselmo", "Engraçado... meus relógios pararam todos às 3 da manhã, ontem. Todos ao mesmo tempo."],
			["Sr. Anselmo", "Fique com este amuleto. Uma engrenagem que nunca para. Ao contrário dos meus relógios."],
		]), {"require_quest_state": "q_springs=active", "require_items": {&"brass_spring": 3},
			"take_items": {&"brass_spring": 3}, "complete_objectives": ["q_springs:bring_springs"], "finish_quest": &"q_springs"}),
		_branch(_lines([["Sr. Anselmo", "Tique, taque... Ainda preciso daquelas três Molas de Latão. Os ratos do ferro-velho vivem roendo."]]),
			{"require_quest_state": "q_springs=active"}),
		_branch(_lines([["Sr. Anselmo", "Os relógios voltaram a andar. Mas atrasam um minuto sempre que aquele dirigível passa."]]),
			{"require_quest_state": "q_springs=done"}),
		_branch(_lines([
			["Sr. Anselmo", "Kael! Preciso de três Molas de Latão pra consertar a torre do relógio."],
			["Sr. Anselmo", "Os Ratos-Engrenagem do ferro-velho vivem roendo molas. Se conseguir três, pago bem."],
		]), {"start_quest": &"q_springs"}),
	])
	_dialogue_set("p_pip", [
		_branch(_lines([["Pip", "Eu vi! O senhor Gerd empurrando um carrinho cheio de barris pro lado da praça!"]]),
			{"require_flags": ["empire_arrived"]}),
		_branch(_lines([["Pip", "Você foi no Ferro-Velho?! E achou um ROBÔ?! Me leva da próxima vez!"]]),
			{"require_flags": ["eco_awake"]}),
		_branch(_lines([["Pip", "Você viu o dirigível ontem à noite? Era ENORME! Tinha uma bandeira azul com uma engrenagem!"]])),
	])
	_dialogue_set("p_olavo", [
		_branch(_lines([["Guarda Olavo", "Voltaram inteiros? Ótimo. Eu não vi nada. Eu nunca vejo nada."]]),
			{"require_flags": ["gerd_joined"]}),
		_branch(_lines([["Guarda Olavo", "Ordem da capital: ninguém entra no Ferro-Velho sem autorização. ...Mas eu almoço ao meio-dia, se é que me entende."]])),
	])
	_dialogue_set("p_ilse", [
		_branch(_lines([["Velha Ilse", "Um autômato dos Antigos... Minha avó dizia que eles cantavam. Você ouviu ele cantar, menino?"]]),
			{"require_flags": ["eco_awake"]}),
		_branch(_lines([["Velha Ilse", "Minha avó dizia que o canal brilhava à noite. Hoje só brilha quando derramam Éter nele."]])),
	])
	_dialogue_set("p_soldier", [
		_branch(_lines([["Soldado Imperial", "Circulando! Ordem do General Voss."]])),
	])
	_dialogue_set("p_cat", [
		_branch(_lines([
			["Fuligem", "Miau."],
			[KA, "Fuligem! A Dona Berta tá louca atrás de você.", POR_KAEL],
			["", "Fuligem pula para o ombro de Kael e se recusa a descer."],
		]), {"complete_objectives": ["q_cat:find_cat"], "set_flags": ["cat_found"]}),
	])

	# ----- Cena 1: manhã de oficina -----
	_cutscene("p1_morning", "prologue_started", [
		_step(ST.WAIT, {"seconds": 0.6}),
		_say([
			[G, "Kael! Se você ficar mais um minuto roncando em cima dessa válvula, ela vai aprender a roncar também.", POR_GERD],
			[KA, "Hm... eu não tava dormindo. Tava... escutando.", POR_KAEL],
			[G, "Escutando. Claro. E o que ela disse?", POR_GERD],
			[KA, "Que a rosca tá espanada e que o senhor apertou com força demais.", POR_KAEL],
			[G, "...Hmpf. Vai lavar a cara. Tenho uma entrega pra você.", POR_GERD],
			[G, "Leva essa caixa de engrenagens pro Tobias, na loja. E não aceita menos de 80 moedas, ouviu? Aquele pão-duro vai chorar miséria.", POR_GERD],
			["", "Kael recebeu: Caixa de Engrenagens."],
			[TIP, "Mova-se com as setas ou o analógico. Converse e examine com Z / Enter (A no controle). O menu abre com C / Tab (Y)."],
		]),
		_step(ST.GIVE_ITEM, {"id": &"gear_box"}),
		_step(ST.START_QUEST, {"id": &"q_prologue"}),
	])

	# ----- Cena 3: Estrada do Sul, tutorial de batalha -----
	var slime: CombatantData = load("res://data/enemies/oil_slime.tres")
	_cutscene("p3_road", "road_tutorial", [
		_say([[G, "Olha ali na estrada. Slimes de óleo. Vazou alguma coisa do ferro-velho de novo.", POR_GERD]]),
		_say([
			[TIP, "No topo da tela fica a fila de turnos: quem é mais rápido age mais vezes."],
			[TIP, "Ao atacar, aperte Z / A quando o anel dourado fechar sobre o alvo: golpe Perfeito!"],
			[TIP, "Na vez do inimigo, aperte no momento do impacto para se defender e receber menos dano."],
		]),
		_step(ST.BATTLE, {"enemies": [slime, slime] as Array[CombatantData]}),
		_say([[G, "Bom reflexo. Quando o anel fechar, é aí que a máquina quer que você bata. Escuta ela.", POR_GERD]]),
	])

	# ----- Cena 4: Ferro-Velho -----
	_cutscene("p4_enter", "junkyard_entered", [
		_say([
			[G, "O Ferro-Velho do Sul. Trinta anos de sucata do Império jogada aqui.", POR_GERD],
			[G, "A válvula deve estar lá no fundo, perto do poço das engrenagens. Fica de olho nos bichos.", POR_GERD],
			[TIP, "Os inimigos aparecem no mapa. Encoste neles pelas costas para agir primeiro; se eles te pegarem pelas costas, é emboscada."],
		]),
	])
	_cutscene("p4_boiler", "boiler_talk", [
		_say([
			[KA, "(Ela tá... cansada. Como se alguém tivesse esquecido de desligar ela há anos.)", POR_KAEL],
			[G, "Kael? Tá falando sozinho de novo?", POR_GERD],
			[KA, "Tô falando com a caldeira. É diferente.", POR_KAEL],
			[TIP, "Caldeiras antigas são pontos de salvamento: recuperam o grupo e salvam o jogo."],
		]),
	])
	_cutscene("p4_lever", "", [
		_step(ST.SHAKE, {"seconds": 0.8, "strength": 3.0}),
		_say([["", "A esteira range, estala... e empurra o bloco de sucata para fora do caminho!"],
			[G, "Hah! Ainda tem vida nessa lata.", POR_GERD]]),
	])
	_cutscene("p4_tech", "gerd_tech_taught", [
		_say([
			[G, "Espera, garoto. Esses bichos daqui de baixo são mais cascudos.", POR_GERD],
			[G, "Eu seguro, você corta. Igual na oficina, só que o parafuso morde de volta.", POR_GERD],
			[TIP, "Técnica combinada liberada: Faísca e Ferro (Kael + Gerd). Use pelo menu Técnicas quando os dois puderem agir."],
		]),
	])

	# ----- Cenas 5 e 6: Eco desperta, o Triturador -----
	var parts := [_enemies["crusher_claw_up"], _enemies["crusher_core"], _enemies["crusher_claw_down"]]
	_cutscene("p5_eco", "boss_beaten", [
		_step(ST.STOP_MUSIC),
		_step(ST.WAIT, {"seconds": 0.8}),
		_say([
			[KA, "Mestre... o senhor tá ouvindo isso?", POR_KAEL],
			[G, "(pausa) ...Ouvindo o quê, garoto?", POR_GERD],
		]),
		_step(ST.MOVE, {"actor": NodePath("Player"), "position": _cell(12, 7), "speed": 30.0}),
		_step(ST.FLASH, {"color": Color(0.31, 0.88, 0.82), "seconds": 0.8}),
		_say([
			["???", "...Kael."],
			[KA, "Ele... ele sabe meu nome!", POR_KAEL],
			[G, "(baixinho, para si) ...Então ainda funciona.", POR_GERD],
			[KA, "O senhor disse alguma coisa?", POR_KAEL],
			[G, "Disse que isso aí deve valer uma fortuna. Vamos embora.", POR_GERD],
			["???", "Designação: E-C-O. Diretiva: ...dado corrompido. Kael: presente. Diretiva parcialmente cumprida."],
			[KA, "Eco. Tá bom, Eco. Você... vem com a gente?", POR_KAEL],
			[EC, "Afirmativo. Pergunta: o que é \"a gente\"?"],
			["", "Eco entrou no grupo!"],
		]),
		_step(ST.JOIN_PARTY, {"id": &"eco", "amount": 0}),
		_step(ST.SET_FLAG, {"id": &"eco_awake"}),
		_step(ST.SHAKE, {"seconds": 1.2, "strength": 5.0}),
		_say([
			["", "O pulso de Éter do despertar reativa algo enorme na sucata acima da câmara..."],
			[EC, "Alerta. Máquina hostil. Nível de irritação: elevado."],
			[KA, "Ela tá com dor! Os braços tão travados... se eu soltar as garras, ela para!", POR_KAEL],
			[TIP, "As garras protegem o núcleo: ele só recebe dano cheio depois que uma garra cai."],
			[TIP, "Ressonância (Kael) desmonta inimigos mecânicos. E se a fornalha se abrir, o Proteger de Eco impede que alguém seja puxado."],
		]),
		_step(ST.BATTLE, {"enemies": parts as Array[CombatantData], "music": load(MUSIC_BOSS)}),
		_say([
			[KA, "(Ela tá... quieta agora. Obrigada, ela disse. Eu acho.)", POR_KAEL],
			[EC, "Observação: Kael conversa com máquinas desligadas. Registrando como comportamento normal."],
			[G, "Pega a válvula e vamos pra casa. Esse lugar me dá arrepio.", POR_GERD],
			["", "Kael encontrou: Válvula de Bronze e Lâmina-engrenagem!"],
		]),
		_step(ST.GIVE_ITEM, {"id": &"bronze_valve"}),
		_step(ST.GIVE_ITEM, {"id": &"gear_blade"}),
		_step(ST.COMPLETE_OBJECTIVE, {"id": &"q_prologue:fetch_valve"}),
		_step(ST.FADE_OUT),
		_step(ST.CHANGE_SCENE, {"text": MAP_OFICINA, "id": &"dinner"}),
	])

	# ----- Cena 7: jantar -----
	var sad := _line(EC, "Registrando: \"triste\". Pedido de definição.")
	sad.choices = [
		_story_choice("\"Triste é quando falta alguém na mesa.\"", {&"eco": 2},
			_lines([["", "Gerd fica em silêncio e olha para a foto antiga na prateleira."]])),
		_story_choice("\"Triste é sopa sem sal. Né, mestre?\"", {&"gerd": 1},
			_lines([[G, "Hah! Hahaha! Engraçadinho. ...Passa o sal.", POR_GERD]])),
		_story_choice("\"Eu te explico amanhã, Eco.\"", {},
			_lines([[EC, "Amanhã. Registrado."]])),
	] as Array[DialogueChoice]
	_cutscene("p7_dinner", "dinner_done", [
		_step(ST.WAIT, {"seconds": 0.4}),
		_say([
			[EC, "Pergunta: por que humanos se sentam juntos para abastecer?"],
			[G, "Porque comer sozinho é triste, lata velha.", POR_GERD],
		]),
		_step(ST.SAY, {"lines": [sad] as Array[DialogueLine]}),
		_say([
			[G, "Kael... se um dia aparecer alguém perguntando por essa máquina, você não sabe de nada. Entendeu?", POR_GERD],
			[KA, "Por quê? O senhor sabe o que ele é?", POR_KAEL],
			[G, "Sei que é tarde. Vai dormir.", POR_GERD],
			[TIP, "Durma na cama do mezanino para descansar e salvar."],
		]),
		_step(ST.COMPLETE_OBJECTIVE, {"id": &"q_prologue:return_home"}),
		_step(ST.FINISH_QUEST, {"id": &"q_prologue"}),
	])

	# ----- Cena 8: o Império chega -----
	_cutscene("p8_morning", "empire_arrived", [
		_step(ST.FADE_OUT),
		_step(ST.SET_FLAG, {"id": &"slept"}),
		_step(ST.TELEPORT, {"actor": NodePath("Player"), "position": _cell(11, 5), "facing": Player.Facing.DOWN}),
		_step(ST.WAIT, {"seconds": 1.0}),
		_step(ST.FADE_IN),
		_step(ST.SHAKE, {"seconds": 1.6, "strength": 2.0}),
		_step(ST.PLAY_MUSIC, {"music": load(MUSIC_EMPIRE)}),
		_say([["", "Um ronco grave faz as janelas tremerem. Uma sombra enorme cobre a vila."]]),
		_step(ST.MOVE, {"actor": NodePath("Pip"), "position": _cell(7, 7), "speed": 90.0}),
		_say([
			["Pip", "Kael! Os soldados tão revirando as casas atrás de um \"artefato\"! O Guarda Olavo tentou impedir e levaram ele!"],
			[G, "...Soldados. Eu sabia que esse dia ia chegar.", POR_GERD],
			[G, "Fiquem aqui, os dois. Eu preciso buscar uma coisa. E você, Pip, pra casa. AGORA.", POR_GERD],
		]),
		_step(ST.MOVE, {"actor": NodePath("GerdEvening"), "position": _cell(7, 9), "speed": 70.0}),
		_step(ST.MOVE, {"actor": NodePath("Pip"), "position": _cell(7, 10), "speed": 90.0}),
		_step(ST.SET_FLAG, {"id": &"gerd_out"}),
		_say([
			[EC, "Pergunta: \"fiquem aqui\" inclui olhar pela janela?"],
			[KA, "Não. Inclui ir até a praça. Vamos, Eco.", POR_KAEL],
		]),
	])
	var soldier: CombatantData = _enemies["imperial_soldier"]
	_cutscene("p8_voss", "voss_fought", [
		_step(ST.TELEPORT, {"actor": NodePath("Eco"), "position": _cell(33, 16), "facing": Player.Facing.LEFT}),
		_step(ST.MOVE, {"actor": NodePath("Player"), "position": _cell(30, 15), "speed": 60.0}),
		_step(ST.FACE, {"actor": NodePath("Player"), "facing": Player.Facing.LEFT}),
		_step(ST.MOVE, {"actor": NodePath("Eco"), "position": _cell(31, 16), "speed": 60.0}),
		_say([
			["General Voss", "Uma máquina foi ativada no Ferro-Velho ontem. Os medidores de Brasaforte registraram o pulso daqui."],
			["General Voss", "Entreguem-na, e ninguém se machuca."],
			[EC, "Declaração: sou a máquina."],
			[KA, "Eco!", POR_KAEL],
			["General Voss", "...Um aetheliano funcionando. Então o velho Brunor mentiu esse tempo todo. Peguem."],
		]),
		_step(ST.BATTLE, {"enemies": [soldier, _enemies["voss"], soldier] as Array[CombatantData],
			"music": load(MUSIC_EMPIRE), "end_after_turns": {&"voss": 4}}),
		_say([["General Voss", "Coragem. Falta de juízo, mas coragem. Algemas."]]),
		_step(ST.FLASH, {"color": Color(1.0, 0.6, 0.25), "seconds": 0.6}),
		_step(ST.SHAKE, {"seconds": 1.0, "strength": 6.0}),
		_step(ST.TELEPORT, {"actor": NodePath("GerdSquare"), "position": _cell(29, 17), "facing": Player.Facing.UP}),
		_say([
			["", "Um carrinho de oficina em chamas atravessa a praça e explode entre os soldados!"],
			[G, "Pela oficina! Porta dos fundos! AGORA!", POR_GERD],
		]),
		_step(ST.LEAVE_PARTY, {"id": &"gerd"}),
		_step(ST.RESTORE_PARTY),
		_say([[TIP, "Corra para a oficina Brunor, a leste da praça!"]]),
	])

	# ----- Cena 9: corre, garoto -----
	_cutscene("p9_farewell", "escaped", [
		_step(ST.PLAY_MUSIC, {"music": load(MUSIC_FAREWELL)}),
		_say([
			[KA, "O senhor vem com a gente!", POR_KAEL],
			[G, "Esses joelhos não correm mais, garoto. Mas esta oficina ainda sabe fazer barulho.", POR_GERD],
			[G, "Vai pro norte. Pra floresta. E Kael...", POR_GERD],
			[G, "...escuta ele. Ele sabe mais do que parece. Eu devia ter te contado tudo antes.", POR_GERD],
			[EC, "Gerd Brunor. Pergunta: você vem \"amanhã\"?"],
			[G, "(sorri) ...Cuida dele, lata velha.", POR_GERD],
		]),
		_step(ST.MOVE, {"actor": NodePath("GerdFarewell"), "position": _cell(3, 4), "speed": 50.0}),
		_say([["", "Gerd abre todas as válvulas da fornalha. O vapor começa a uivar."]]),
		_step(ST.SHAKE, {"seconds": 0.6, "strength": 2.0}),
		_step(ST.MOVE, {"actor": NodePath("Player"), "position": _cell(14, 5), "speed": 90.0}),
		_step(ST.FADE_OUT),
		_step(ST.CHANGE_SCENE, {"text": MAP_VILA, "id": &"back_door"}),
	])
	_cutscene("p9_escape", "prologue_done", [
		_step(ST.WAIT, {"seconds": 0.8}),
		_step(ST.FLASH, {"color": Color(1.0, 0.55, 0.2), "seconds": 1.2}),
		_step(ST.SHAKE, {"seconds": 1.4, "strength": 7.0}),
		_say([
			["", "A oficina Brunor explode numa coluna de vapor e fogo."],
			[KA, "MESTRE!", POR_KAEL],
			[EC, "...Registrando: \"triste\"."],
		]),
		_step(ST.FADE_OUT),
		_step(ST.TELEPORT, {"actor": NodePath("Player"), "position": _cell(24, 2), "facing": Player.Facing.DOWN}),
		_step(ST.FADE_IN),
		_step(ST.WAIT, {"seconds": 1.2}),
		_step(ST.FACE, {"actor": NodePath("Player"), "facing": Player.Facing.UP}),
		_step(ST.WAIT, {"seconds": 0.8}),
		_step(ST.END_CHAPTER, {"text": "Fim do Prólogo\n\nA Máquina que Sabia meu Nome"}),
	])



func _story_choice(text: String, affinity: Dictionary, response: Array[DialogueLine]) -> DialogueChoice:
	var c := DialogueChoice.new()
	c.text = text
	c.affinity = affinity
	c.response = response
	return c
