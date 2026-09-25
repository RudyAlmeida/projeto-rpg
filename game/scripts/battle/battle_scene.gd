class_name BattleScene
extends Node2D
## Runs one battle on top of the field map (D-04): places the combatants around `center`,
## asks the player for commands, animates each action with its timing prompt and reports
## the outcome through `battle_ended`.
##
## Hero actions are Dictionaries: {type: "skill"|"item"|"tech"|"swap"|"flee",
## skill, item, tech, targets: Array[BattleUnit], swap_in: BattleUnit}.

signal command_requested(unit: BattleUnit)
signal battle_ended(outcome: Battle.Outcome)

enum Mode { BUSY, ROOT, SKILLS, ITEMS, SWAP, TARGET, RESULT }

## Staggered so the 56 px tall heroes don't stack on top of each other.
const HERO_OFFSETS: Array[Vector2] = [Vector2(-92, -30), Vector2(-136, 14), Vector2(-92, 58)]
const ENEMY_OFFSETS: Array[Vector2] = [Vector2(92, 0), Vector2(116, 48), Vector2(128, -40)]
const ENEMY_THINK_TIME := 0.35
const MAGIC_IMPACT := 0.45
const TECH_PROMPT_TIME := 0.35
const NUMBER_DAMAGE := Color(0.909804, 0.894118, 0.862745)
const NUMBER_HEAL := Color(0.713725, 0.85098, 0.478431)
const NUMBER_MP := Color(0.309804, 0.878431, 0.815686)
const NUMBER_STATUS := Color(0.74902, 0.658824, 0.478431)
## Battle themes, alternated from one fight to the next.
const BATTLE_TRACKS: Array[AudioStream] = [
	preload("res://assets/audio/music/bgm_battle_a.mp3"),
	preload("res://assets/audio/music/bgm_battle_b.mp3"),
]
const VICTORY_MUSIC := preload("res://assets/audio/music/bgm_victory_b.mp3")

var battle: Battle
## Tests / accessibility: forwarded to the timing prompt (see TimingPrompt.auto_result).
var auto_timing := -1
## Accessibility: timing window multiplier (options menu).
var timing_window_scale := 1.0
## Set before start(): shared inventory (GameState.inventory), known Dual Techs, regional
## Aether factor, and whether to play battle music.
var inventory: Dictionary = {}
var techs: Array[DualTechData] = []
var aether_factor := 1.0
var play_music := false
## Replaces the alternating battle themes (bosses, story fights).
var music_override: AudioStream
## Item ids won in the last victory.
var drops: Array[StringName] = []

static var _next_track := 0

var _views := {}  # BattleUnit -> BattlerView
var _tags := {}   # enemy BattleUnit -> Label (status badges)
var _ui: BattleUI
var _prompt: TimingPrompt
var _cursor: Label
var _mode := Mode.BUSY
var _actor: BattleUnit
var _swapped_this_turn := false
var _list_index := 0
var _list_entries: Array = []
var _pending: Dictionary = {}    # action being built while choosing a target
var _targets: Array[BattleUnit] = []
var _target_index := 0
var _target_all := false
var _return_mode := Mode.ROOT

signal _action_ready(action: Dictionary)
signal _result_confirmed


## Quick start with fresh level-1 heroes (tests, previews).
func start(heroes: Array[CombatantData], foes: Array[CombatantData], center: Vector2,
		initiative := false, rng: RandomNumberGenerator = null) -> void:
	var members: Array[PartyMember] = []
	for data in heroes:
		members.append(PartyMember.new(data))
	start_with_party(members, foes, center, initiative, rng)


## Battle with the persistent party; on victory HP/MP/Aether and XP are written back.
func start_with_party(members: Array[PartyMember], foes: Array[CombatantData], center: Vector2,
		initiative := false, rng: RandomNumberGenerator = null, ambush := false, end_after_turns := {}) -> void:
	y_sort_enabled = true
	battle = Battle.new(rng)
	battle.end_after_turns = end_after_turns
	battle.inventory = inventory
	battle.aether_factor = aether_factor
	battle.start_with_party(members, foes, initiative, ambush)
	for i in battle.party.size():
		_add_view(battle.party[i], center + HERO_OFFSETS[i % HERO_OFFSETS.size()])
	for unit in battle.reserves:
		_add_view(unit, center + HERO_OFFSETS[0]).hide()
	for i in battle.enemies.size():
		var offset := battle.enemies[i].data.formation_offset
		if offset == Vector2.ZERO:
			offset = ENEMY_OFFSETS[i % ENEMY_OFFSETS.size()]
		var view := _add_view(battle.enemies[i], center + offset)
		_tags[battle.enemies[i]] = _make_tag(view)
	_ui = BattleUI.new()
	add_child(_ui)
	_ui.setup_party(Battle.ACTIVE_MAX)
	_prompt = TimingPrompt.new()
	_prompt.auto_result = auto_timing
	_prompt.window_scale = timing_window_scale
	_prompt.z_index = 40
	add_child(_prompt)
	_cursor = Label.new()
	_cursor.text = "▼"
	_cursor.add_theme_font_override("font", BattleUI.FONT)
	_cursor.add_theme_font_size_override("font_size", UIKit.FONT_SIZE)
	_cursor.add_theme_color_override("font_color", BattleUI.GOLD)
	_cursor.z_index = 45
	_cursor.hide()
	add_child(_cursor)
	if play_music:
		AudioManager.push_music(music_override if music_override else next_battle_track())
	if initiative:
		_ui.show_message("Ataque surpresa!")
	elif ambush:
		_ui.show_message("Emboscada!")
	_run.call_deferred()


## The theme for the next fight; each call switches to the other track.
static func next_battle_track() -> AudioStream:
	var track := BATTLE_TRACKS[_next_track % BATTLE_TRACKS.size()]
	_next_track += 1
	return track


func view_of(unit: BattleUnit) -> BattlerView:
	return _views[unit]


## Gives the current hero's command (menu and tests). Multi-target skills hit every
## valid target regardless of `target`.
func submit_command(skill: SkillData, target: BattleUnit) -> void:
	var targets: Array[BattleUnit] = [target]
	if skill.is_multi_target():
		targets = battle.targets_for(_actor if _actor else target, skill.target)
	submit_action({"type": "skill", "skill": skill, "targets": targets})


func submit_action(action: Dictionary) -> void:
	_ui.hide_menu()
	_cursor.hide()
	_mode = Mode.BUSY
	# Deferred: a listener of command_requested may answer synchronously, before _run()
	# has reached `await _action_ready`; an immediate emit would be lost.
	_action_ready.emit.call_deferred(action)


func _add_view(unit: BattleUnit, pos: Vector2) -> BattlerView:
	var view := BattlerView.new()
	add_child(view)
	view.setup(unit, pos)
	_views[unit] = view
	return view


func _make_tag(view: BattlerView) -> Label:
	var tag := Label.new()
	tag.add_theme_font_override("font", BattleUI.FONT)
	tag.add_theme_font_size_override("font_size", UIKit.FONT_SIZE)
	tag.add_theme_color_override("font_color", NUMBER_STATUS)
	tag.add_theme_color_override("font_outline_color", BattleUI.DARK)
	tag.add_theme_constant_override("outline_size", 3)
	tag.position = view.position + Vector2(-16, 2)
	tag.z_index = 30
	add_child(tag)
	return tag


func _refresh() -> void:
	_ui.update_party(battle.party, _actor if _mode != Mode.BUSY else null)
	for unit: BattleUnit in _tags:
		var tags := PackedStringArray()
		if unit.is_alive():
			for id: int in unit.statuses:
				tags.append(StatusEffects.tag(id))
		(_tags[unit] as Label).text = " ".join(tags)


# ---------- turn loop ----------

func _run() -> void:
	if _ui._message_panel.visible:
		await _wait(0.8)
		_ui.show_message("")
	while battle.outcome() == Battle.Outcome.ONGOING:
		var unit := battle.next_turn()
		_actor = null
		_ui.update_order(battle.queue.preview(6), unit)
		var start := battle.begin_turn(unit)
		_refresh()
		await _show_turn_start(start)
		if start.skip:
			continue
		var action: Dictionary
		if unit.has_status(StatusEffects.Id.CONFUSION):
			var choice := battle.choose_confused_action(unit)
			_ui.show_message("%s está confuso!" % unit.display_name())
			action = {"type": "skill", "skill": choice[0], "targets": [choice[1]] as Array[BattleUnit]}
		elif unit.is_player:
			action = await _ask_hero(unit)
			unit = _actor  # a swap may have replaced the acting hero
		else:
			await _wait(ENEMY_THINK_TIME)
			action = _enemy_action(unit)
		await _perform(unit, action)
		_refresh()
	await _finish(battle.outcome())


func _ask_hero(unit: BattleUnit) -> Dictionary:
	_actor = unit
	_swapped_this_turn = false
	while true:
		_open_root()
		command_requested.emit(_actor)
		var action: Dictionary = await _action_ready
		if action.get("type") != "swap":
			return action
		var incoming: BattleUnit = action["swap_in"]
		_swap_views(_actor, incoming)
		battle.swap(_actor, incoming)
		_ui.show_message("%s entra no lugar de %s!" % [incoming.display_name(), _actor.display_name()])
		_actor = incoming
		_swapped_this_turn = true
		_refresh()
		await _wait(0.5)
		_ui.show_message("")
	return {}


func _enemy_action(unit: BattleUnit) -> Dictionary:
	var choice := battle.choose_enemy_action(unit)
	var skill: SkillData = choice[0]
	var targets: Array[BattleUnit] = [choice[1]]
	if skill.is_multi_target():
		targets = battle.targets_for(unit, skill.target)
	for rule in unit.data.ai_rules:
		if rule.skill == skill and rule.tell != "":
			_ui.show_message(rule.tell)
	return {"type": "skill", "skill": skill, "targets": targets}


func _show_turn_start(t: Battle.TurnStart) -> void:
	var view := view_of(t.unit)
	if t.escaped:
		_ui.show_message("%s fugiu com o que roubou!" % t.unit.display_name())
		var tween := create_tween()
		tween.tween_property(view, "modulate:a", 0.0, 0.4)
		await _wait(0.9)
		_ui.show_message("")
		return
	if t.damage > 0:
		_ui.popup_number(view.head_position(), str(t.damage), NUMBER_DAMAGE, self)
		await view.hurt()
	if t.heal > 0:
		_ui.popup_number(view.head_position(), str(t.heal), NUMBER_HEAL, self)
		await _wait(0.3)
	if t.knocked_out:
		await view.knock_out()
		return
	if t.skip and t.reason >= 0:
		_ui.show_message("%s: %s" % [t.unit.display_name(), StatusEffects.display_name(t.reason)])
		await _wait(0.6)
		_ui.show_message("")


# ---------- performing actions ----------

func _perform(actor: BattleUnit, action: Dictionary) -> void:
	# Menu code and tests build target lists in different ways; normalise to a typed array.
	var targets: Array[BattleUnit] = []
	targets.assign(action.get("targets", []))
	match action.get("type"):
		"skill":
			await _perform_skill(actor, action["skill"], targets)
		"item":
			await _perform_item(actor, action["item"], targets)
		"tech":
			await _perform_tech(actor, action["tech"], targets)
		"flee":
			await _perform_flee()
	_ui.show_message("")


func _perform_skill(actor: BattleUnit, skill: SkillData, targets: Array[BattleUnit]) -> void:
	var actor_view := view_of(actor)
	var target_view := view_of(targets[0])
	if actor.is_player and skill.kind != SkillData.Kind.ATTACK or skill == actor.data.special:
		_ui.show_message(skill.display_name)
	elif not actor.is_player and _ui._message.text == "":
		_ui.show_message(skill.display_name)
	var timing := DamageFormula.Timing.MISS
	var hero_target := targets.any(func(t: BattleUnit) -> bool: return t.is_player)
	match skill.kind:
		SkillData.Kind.ATTACK:
			if actor.is_player and actor.data.timing_style == CombatantData.TimingStyle.HOLD:
				# Brann: build the steam pressure first, then swing.
				timing = await _prompt_at(actor_view, 0.0, CombatantData.TimingStyle.HOLD)
				await actor_view.lunge_to(target_view)
			else:
				var done := _timed(actor.is_player or hero_target, target_view, BattlerView.LUNGE_TIME, CombatantData.TimingStyle.RING)
				await actor_view.lunge_to(target_view)
				timing = await done.call()
		SkillData.Kind.MAGIC, SkillData.Kind.HEAL, SkillData.Kind.SUPPORT:
			var style := actor.data.timing_style if actor.is_player else CombatantData.TimingStyle.RING
			if style == CombatantData.TimingStyle.HOLD:
				style = CombatantData.TimingStyle.RING
			var involved := (actor.is_player or hero_target) and skill.kind != SkillData.Kind.SUPPORT
			var done := _timed(involved, target_view, MAGIC_IMPACT, style)
			await actor_view.cast()
			timing = await done.call()
	var results := battle.resolve_action(actor, skill, targets, timing)
	await _show_results(results)
	if skill.kind == SkillData.Kind.ATTACK:
		await actor_view.return_home()


func _perform_item(actor: BattleUnit, item: ItemData, targets: Array[BattleUnit]) -> void:
	_ui.show_message(item.display_name)
	await view_of(actor).cast()
	var results := battle.use_item(actor, item, targets)
	for r in results:
		var view := view_of(r.target)
		if r.revived:
			view.revive()
			_ui.popup_number(view.head_position(), "Reviveu!", NUMBER_HEAL, self)
		elif r.amount > 0:
			_ui.popup_number(view.head_position(), str(r.amount), NUMBER_HEAL, self)
		if r.mp_amount > 0:
			_ui.popup_number(view.head_position() + Vector2(0, 12), "%d MP" % r.mp_amount, NUMBER_MP, self)
		for id in r.statuses_removed:
			_ui.popup_number(view.head_position() + Vector2(0, -12), "−" + StatusEffects.display_name(id), NUMBER_STATUS, self)
	await _wait(0.5)


func _perform_tech(lead: BattleUnit, tech: DualTechData, targets: Array[BattleUnit]) -> void:
	_ui.show_message("★ " + tech.display_name)
	var members := battle.tech_participants(tech)
	var target_view := view_of(targets[0])
	# One press per participant, in order (GDD 7).
	var timings: Array[int] = []
	for member in members:
		timings.append(await _prompt_at(target_view, TECH_PROMPT_TIME, CombatantData.TimingStyle.RING))
	if tech.skill.kind == SkillData.Kind.ATTACK:
		for member in members:
			view_of(member).lunge_to(target_view)
		await _wait(BattlerView.LUNGE_TIME)
	else:
		for member in members:
			view_of(member).cast()
		await _wait(0.3)
	var results := battle.resolve_tech(tech, lead, targets, timings)
	await _show_results(results)
	if tech.skill.kind == SkillData.Kind.ATTACK:
		for member in members:
			view_of(member).return_home()
		await _wait(BattlerView.RETURN_TIME)


func _perform_flee() -> void:
	_ui.show_message("Tentando fugir...")
	await _wait(0.4)
	if battle.try_flee():
		_ui.show_message("Fugiu!")
		for unit in battle.alive(battle.party):
			var view := view_of(unit)
			view.create_tween().tween_property(view, "position:x", view.position.x - 220, 0.5)
		await _wait(0.6)
	else:
		_ui.show_message("Não conseguiu fugir!")
		await _wait(0.6)


## Prompt centred on `at` that the caller awaits directly. The window widens with the
## options setting and the pressing hero's timing gems.
func _prompt_at(at: BattlerView, impact_time: float, style: CombatantData.TimingStyle) -> DamageFormula.Timing:
	_prompt.position = at.position + Vector2(0, -at.frame_size().y / 2.0)
	var presser := _actor if _actor else (at.unit if at.unit.is_player else null)
	var gem_mult := presser.member.timing_window_mult() if presser and presser.member else 1.0
	_prompt.window_scale = timing_window_scale * gem_mult
	return await _prompt.run(impact_time, style)


## Starts a timing prompt centred on `at` now (only when a hero is involved) and returns a
## callable that awaits its result, so the prompt runs while the attack animates.
func _timed(hero_involved: bool, at: BattlerView, impact_time: float, style: CombatantData.TimingStyle) -> Callable:
	if not hero_involved:
		return func() -> DamageFormula.Timing: return DamageFormula.Timing.MISS
	var state := {"done": false, "result": DamageFormula.Timing.MISS}
	var runner := func() -> void:
		state["result"] = await _prompt_at(at, impact_time, style)
		state["done"] = true
	runner.call()
	return func() -> DamageFormula.Timing:
		while not state["done"]:
			await get_tree().process_frame
		return state["result"]


func _show_results(results: Array[Battle.ActionResult]) -> void:
	if results.is_empty():
		return
	_play_result_sounds(results)
	_play_result_effects(results)
	var first := results[0]
	# Only a hero's press can produce a timing result: the acting hero or the hero being hit.
	if first.timing != DamageFormula.Timing.MISS:
		var label := {DamageFormula.Timing.PERFECT: "Perfeito!", DamageFormula.Timing.GOOD: "Bom!",
			DamageFormula.Timing.OVERLOAD: "Estourou!"}[first.timing] as String
		var who := view_of(first.actor) if first.actor.is_player else view_of(first.target)
		_ui.popup_number(who.head_position() + Vector2(0, -14), label, BattleUI.GOLD, self)
	if first.overheated_self:
		_ui.popup_number(view_of(first.actor).head_position(), "Sobreaquecido", BattleUI.HP_LOW, self)
	var hurt_views: Array[BattlerView] = []
	var ko_views: Array[BattlerView] = []
	for r in results:
		var view := view_of(r.target)
		if r.skill and r.skill.kind == SkillData.Kind.DEFEND:
			_ui.popup_number(view_of(r.actor).head_position(), "Defesa", BattleUI.TEXT, self)
			continue
		if r.revived:
			view.revive()
			_ui.popup_number(view.head_position(), "Reviveu!", NUMBER_HEAL, self)
		elif r.skill and (r.skill.kind == SkillData.Kind.HEAL or r.absorbed):
			_ui.popup_number(view.head_position(), str(r.amount), NUMBER_HEAL, self)
		elif r.skill and r.skill.is_offensive():
			if not r.hit:
				_ui.popup_number(view.head_position(), "Errou", BattleUI.DIM, self)
				continue
			var text := str(r.amount) + ("!" if r.crit else "")
			if r.extra_amount > 0:
				text += " +%d" % r.extra_amount
			_ui.popup_number(view.head_position(), text, NUMBER_DAMAGE, self)
			hurt_views.append(view)
			if r.knocked_out:
				ko_views.append(view)
		if r.stolen_item != &"":
			var loot := DataRegistry.item(r.stolen_item)
			_ui.popup_number(view.head_position() + Vector2(0, -24), "Roubou " + (loot.display_name if loot else ""), NUMBER_STATUS, self)
		if r.no_effect:
			_ui.popup_number(view.head_position() + Vector2(0, -12), "Sem efeito", BattleUI.DIM, self)
		for id in r.statuses_added:
			_ui.popup_number(view.head_position() + Vector2(0, -12), StatusEffects.display_name(id), NUMBER_STATUS, self)
		for id in r.statuses_removed:
			if id != StatusEffects.Id.CONFUSION or not r.skill.is_offensive():
				_ui.popup_number(view.head_position() + Vector2(0, -24), "−" + StatusEffects.display_name(id), NUMBER_STATUS, self)
	for view in hurt_views:
		view.hurt()
	await _wait(0.35)
	for view in ko_views:
		view.knock_out()
	if not ko_views.is_empty():
		await _wait(0.4)
	_refresh()


## Visual effect on each target (BattleVFX sheet): slashes and impacts for attacks,
## elements for magic, sparkles for healing.
func _play_result_effects(results: Array[Battle.ActionResult]) -> void:
	for r in results:
		if r.skill == null and r.item == null:
			continue
		var effect := &""
		if r.item or (r.skill and (r.skill.kind == SkillData.Kind.HEAL or r.revived)):
			effect = &"heal"
		elif r.skill.kind == SkillData.Kind.MAGIC:
			effect = {SkillData.Element.FIRE: &"fire", SkillData.Element.ICE: &"ice",
				SkillData.Element.THUNDER: &"thunder"}.get(r.skill.element, &"impact")
		elif r.skill.kind == SkillData.Kind.ATTACK and r.hit:
			effect = &"slash" if r.actor.is_player and r.actor.data.id == &"kael" else &"impact"
			if r.skill.weight >= TurnQueue.WEIGHT_HEAVY and r.skill.is_multi_target():
				effect = &"steam"
		if effect == &"":
			continue
		var view := view_of(r.target)
		BattleVFX.spawn(self, effect, view.position + Vector2(0, -view.frame_size().y / 2.0), not r.actor.is_player)
		if r.knocked_out and not r.target.is_player and r.target.data.is_boss:
			BattleVFX.spawn(self, &"explosion", view.position + Vector2(0, -view.frame_size().y / 2.0))


## Sound effects for an action (Kenney CC0 sounds, AudioManager.play_sfx).
func _play_result_sounds(results: Array[Battle.ActionResult]) -> void:
	var first := results[0]
	var pitch := randf_range(0.92, 1.08)
	if first.timing == DamageFormula.Timing.PERFECT:
		AudioManager.play_sfx(&"perfect")
	var skill := first.skill
	if first.item:
		AudioManager.play_sfx(&"item")
	elif skill == null:
		pass
	elif skill.kind == SkillData.Kind.DEFEND:
		AudioManager.play_sfx(&"guard")
	elif skill.kind == SkillData.Kind.HEAL or first.revived:
		AudioManager.play_sfx(&"heal")
	elif skill.kind == SkillData.Kind.SUPPORT:
		AudioManager.play_sfx(&"magic", pitch)
	elif not first.hit:
		AudioManager.play_sfx(&"miss", pitch)
	elif skill.kind == SkillData.Kind.MAGIC:
		var by_element := {SkillData.Element.FIRE: &"fire", SkillData.Element.ICE: &"ice", SkillData.Element.THUNDER: &"thunder"}
		AudioManager.play_sfx(by_element.get(skill.element, &"magic"), pitch)
	else:
		var hit_sound := &"hit_heavy" if first.crit or skill.weight >= TurnQueue.WEIGHT_HEAVY else &"hit"
		if first.target.data.mechanical:
			hit_sound = &"hit_metal"
		elif first.actor.is_player and first.actor.data.id == &"kael":
			hit_sound = &"slash"
		AudioManager.play_sfx(hit_sound, pitch)
		if not first.actor.is_player and first.timing != DamageFormula.Timing.MISS:
			AudioManager.play_sfx(&"guard", pitch, 0.7)  # the hero blocked in time
	if results.any(func(r: Battle.ActionResult) -> bool: return r.knocked_out):
		AudioManager.play_sfx(&"knockout")
	if results.any(func(r: Battle.ActionResult) -> bool: return r.stolen_item != &""):
		AudioManager.play_sfx(&"steal")


func _swap_views(out_unit: BattleUnit, in_unit: BattleUnit) -> void:
	var out_view := view_of(out_unit)
	var in_view := view_of(in_unit)
	in_view.home = out_view.home
	in_view.position = out_view.home
	out_view.hide()
	in_view.show()


func _finish(outcome: Battle.Outcome) -> void:
	_actor = null
	_refresh()
	_ui.clear_order()
	match outcome:
		Battle.Outcome.VICTORY:
			if play_music:
				AudioManager.play_music(VICTORY_MUSIC, false)
			for unit in battle.party:
				view_of(unit).victory()
			var text := "Vitória!  +%d XP   +%d moedas" % [battle.total_xp(), battle.total_money()]
			drops = battle.roll_drops()
			var promoted: PackedStringArray = []
			for result in battle.finish_victory():
				if result["levels"] > 0:
					var member: PartyMember = result["member"]
					promoted.append("%s nv. %d" % [member.data.display_name, member.level])
			var line2 := PackedStringArray()
			if not promoted.is_empty():
				line2.append("Subiu de nível: " + ", ".join(promoted))
				AudioManager.play_sfx(&"level_up")
			for id in drops:
				inventory[id] = int(inventory.get(id, 0)) + 1
				var item := DataRegistry.item(id)
				line2.append("Obteve: " + (item.display_name if item else str(id)))
			# Pontos de Éter for socketed gems (GDD 8.2).
			var ap := battle.total_ap()
			for unit in battle.party + battle.reserves:
				if unit.member:
					for gem in unit.member.gain_ap(ap):
						line2.append("%s nv. %d" % [gem.item.display_name, gem.level()])
			_ui.show_message((text + "\n" + "   ".join(line2)).strip_edges())
		Battle.Outcome.DEFEAT:
			_ui.show_message("Derrota...\nConfirmar: tentar de novo")
		Battle.Outcome.FLED:
			pass
		Battle.Outcome.SCRIPTED:
			battle.finish_victory(battle.defeated_xp())  # soldiers beaten still count
	if outcome != Battle.Outcome.FLED and outcome != Battle.Outcome.SCRIPTED:
		_mode = Mode.RESULT
		if auto_timing < 0:
			await _result_confirmed
	if play_music:
		AudioManager.pop_music()
	battle_ended.emit(outcome)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ---------- player input ----------

func _open_root() -> void:
	_mode = Mode.ROOT
	_list_index = 0
	_list_entries = _root_entries()
	_ui.show_list(_actor.display_name(), _list_entries, _list_index)
	_refresh()


func _root_entries() -> Array:
	var entries := [{"text": "Atacar", "id": "attack"}]
	if _actor.data.special and _actor.aether_full():
		entries.append({"text": "★ " + _actor.data.special.display_name, "id": "special"})
	entries.append({"text": "Técnicas", "id": "skills"})
	entries.append({"text": "Itens", "id": "items", "enabled": not battle.usable_items().is_empty()})
	entries.append({"text": "Defender", "id": "defend"})
	if not battle.swappable_reserves().is_empty() and not _actor.data.guest:
		entries.append({"text": "Trocar", "id": "swap", "enabled": not _swapped_this_turn})
	entries.append({"text": "Fugir", "id": "flee", "enabled": battle.flee_chance() > 0.0})
	return entries


func _skill_entries() -> Array:
	var entries := []
	for skill in _actor.skill_list():
		if skill.kind == SkillData.Kind.ATTACK and skill.id == &"attack" or skill.kind == SkillData.Kind.DEFEND:
			continue
		entries.append({"text": skill.display_name, "skill": skill, "enabled": _actor.can_use(skill),
			"note": "%d MP" % skill.mp_cost if skill.mp_cost > 0 else ""})
	for tech in battle.available_techs(_actor, techs):
		entries.append({"text": "★ " + tech.display_name, "tech": tech, "note": "%d MP" % tech.mp_cost})
	return entries


func _item_entries() -> Array:
	var entries := []
	for item in battle.usable_items():
		entries.append({"text": item.display_name, "item": item, "icon": item.icon_index, "note": "×%d" % int(inventory.get(item.id, 0))})
	return entries


func _swap_entries() -> Array:
	var entries := []
	for unit in battle.swappable_reserves():
		entries.append({"text": unit.display_name(), "unit": unit, "note": "HP %d" % unit.hp})
	return entries


func _unhandled_input(event: InputEvent) -> void:
	match _mode:
		Mode.ROOT, Mode.SKILLS, Mode.ITEMS, Mode.SWAP:
			_list_input(event)
		Mode.TARGET:
			_target_input(event)
		Mode.RESULT:
			if event.is_action_pressed(&"confirm"):
				get_viewport().set_input_as_handled()
				_mode = Mode.BUSY
				_result_confirmed.emit()


func _list_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_up"):
		var step := 1 if event.is_action_pressed(&"move_down") else -1
		_list_index = wrapi(_list_index + step, 0, _list_entries.size())
		_ui.show_list(_menu_title(), _list_entries, _list_index)
		get_viewport().set_input_as_handled()
	elif UIKit.is_back(event) and _mode != Mode.ROOT:
		AudioManager.play_sfx(&"ui_cancel")
		get_viewport().set_input_as_handled()
		_open_root()
	elif event.is_action_pressed(&"confirm"):
		AudioManager.play_sfx(&"ui_confirm")
		get_viewport().set_input_as_handled()
		var entry: Dictionary = _list_entries[_list_index]
		if not entry.get("enabled", true):
			return
		match _mode:
			Mode.ROOT:
				_choose_root(entry["id"])
			Mode.SKILLS:
				if entry.has("tech"):
					var tech: DualTechData = entry["tech"]
					_choose_targets({"type": "tech", "tech": tech}, tech.skill.target, Mode.SKILLS)
				else:
					var skill: SkillData = entry["skill"]
					_choose_targets({"type": "skill", "skill": skill}, skill.target, Mode.SKILLS)
			Mode.ITEMS:
				var item: ItemData = entry["item"]
				_choose_targets({"type": "item", "item": item}, item.target, Mode.ITEMS)
			Mode.SWAP:
				submit_action({"type": "swap", "swap_in": entry["unit"]})


func _choose_root(id: String) -> void:
	match id:
		"attack":
			_choose_targets({"type": "skill", "skill": _actor.skill_list()[0]}, SkillData.Target.ENEMY, Mode.ROOT)
		"special":
			var special := _actor.data.special
			_choose_targets({"type": "skill", "skill": special}, special.target, Mode.ROOT)
		"defend":
			for skill in _actor.skill_list():
				if skill.kind == SkillData.Kind.DEFEND:
					submit_action({"type": "skill", "skill": skill, "targets": [_actor] as Array[BattleUnit]})
					return
		"skills":
			_open_list(Mode.SKILLS, _skill_entries())
		"items":
			_open_list(Mode.ITEMS, _item_entries())
		"swap":
			_open_list(Mode.SWAP, _swap_entries())
		"flee":
			submit_action({"type": "flee"})


func _open_list(mode: Mode, entries: Array) -> void:
	if entries.is_empty():
		return
	_mode = mode
	_list_index = 0
	_list_entries = entries
	_ui.show_list(_menu_title(), _list_entries, _list_index)


func _menu_title() -> String:
	match _mode:
		Mode.SKILLS:
			return "Técnicas"
		Mode.ITEMS:
			return "Itens"
		Mode.SWAP:
			return "Trocar"
	return _actor.display_name()


func _choose_targets(action: Dictionary, target: SkillData.Target, back_to: Mode) -> void:
	_pending = action
	_return_mode = back_to
	_targets = battle.targets_for(_actor, target)
	if _targets.is_empty():
		return
	if target == SkillData.Target.SELF:
		action["targets"] = [_actor] as Array[BattleUnit]
		submit_action(action)
		return
	_target_all = target == SkillData.Target.ALL_ENEMIES or target == SkillData.Target.ALL_ALLIES
	_target_index = 0
	_mode = Mode.TARGET
	_place_cursor()


func _target_input(event: InputEvent) -> void:
	var step := 0
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_right"):
		step = 1
	elif event.is_action_pressed(&"move_up") or event.is_action_pressed(&"move_left"):
		step = -1
	if step != 0 and not _target_all:
		_target_index = wrapi(_target_index + step, 0, _targets.size())
		_place_cursor()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm"):
		AudioManager.play_sfx(&"ui_confirm")
		get_viewport().set_input_as_handled()
		_pending["targets"] = _targets.duplicate() if _target_all else [_targets[_target_index]]
		_ui.show_message("")
		submit_action(_pending)
	elif UIKit.is_back(event):
		AudioManager.play_sfx(&"ui_cancel")
		get_viewport().set_input_as_handled()
		_cursor.hide()
		_ui.show_message("")
		if _return_mode == Mode.ROOT:
			_open_root()
		else:
			_mode = _return_mode
			_ui.show_list(_menu_title(), _list_entries, _list_index)


func _place_cursor() -> void:
	var view := view_of(_targets[_target_index])
	_cursor.position = view.head_position() + Vector2(-5, -18)
	_cursor.show()
	_ui.show_message("Todos" if _target_all else _targets[_target_index].display_name())
