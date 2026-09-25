class_name BattleScene
extends Node2D
## Runs one battle on top of the field map (D-04): places the combatants around `center`,
## asks the player for commands, animates each action with its timing prompt and reports
## the outcome through `battle_ended`.

signal command_requested(unit: BattleUnit)
signal battle_ended(outcome: Battle.Outcome)

enum Mode { BUSY, MENU, TARGET, RESULT }

## Staggered so the 56 px tall heroes don't stack on top of each other.
const HERO_OFFSETS: Array[Vector2] = [Vector2(-92, -30), Vector2(-136, 14), Vector2(-92, 58)]
const ENEMY_OFFSETS: Array[Vector2] = [Vector2(92, 0), Vector2(116, 48), Vector2(128, -40)]
const ENEMY_THINK_TIME := 0.35
const NUMBER_DAMAGE := Color(0.909804, 0.894118, 0.862745)
const NUMBER_HEAL := Color(0.713725, 0.85098, 0.478431)

var battle: Battle
## Tests / accessibility: forwarded to the timing prompt (see TimingPrompt.auto_result).
var auto_timing := -1

var _views := {}  # BattleUnit -> BattlerView
var _ui: BattleUI
var _prompt: TimingPrompt
var _cursor: Label
var _mode := Mode.BUSY
var _actor: BattleUnit
var _menu_index := 0
var _targets: Array[BattleUnit] = []
var _target_index := 0
var _chosen_skill: SkillData

signal _command_ready(skill: SkillData, target: BattleUnit)
signal _result_confirmed


## Quick start with fresh level-1 heroes (tests, previews).
func start(heroes: Array[CombatantData], foes: Array[CombatantData], center: Vector2,
		initiative := false, rng: RandomNumberGenerator = null) -> void:
	var members: Array[PartyMember] = []
	for data in heroes:
		members.append(PartyMember.new(data))
	start_with_party(members, foes, center, initiative, rng)


## Battle with the persistent party; on victory HP/MP and XP are written back to `members`.
func start_with_party(members: Array[PartyMember], foes: Array[CombatantData], center: Vector2,
		initiative := false, rng: RandomNumberGenerator = null) -> void:
	y_sort_enabled = true
	battle = Battle.new(rng)
	battle.start_with_party(members, foes, initiative)
	for i in battle.party.size():
		_add_view(battle.party[i], center + HERO_OFFSETS[i % HERO_OFFSETS.size()])
	for i in battle.enemies.size():
		_add_view(battle.enemies[i], center + ENEMY_OFFSETS[i % ENEMY_OFFSETS.size()])
	_ui = BattleUI.new()
	add_child(_ui)
	_ui.setup_party(battle.party)
	_prompt = TimingPrompt.new()
	_prompt.auto_result = auto_timing
	_prompt.z_index = 40
	add_child(_prompt)
	_cursor = Label.new()
	_cursor.text = "▼"
	_cursor.add_theme_font_override("font", BattleUI.FONT)
	_cursor.add_theme_font_size_override("font_size", 16)
	_cursor.add_theme_color_override("font_color", BattleUI.GOLD)
	_cursor.z_index = 45
	_cursor.hide()
	add_child(_cursor)
	_run.call_deferred()


func view_of(unit: BattleUnit) -> BattlerView:
	return _views[unit]


## Gives the current hero's command (used by the menu and by tests).
func submit_command(skill: SkillData, target: BattleUnit) -> void:
	_ui.hide_menu()
	_cursor.hide()
	_mode = Mode.BUSY
	# Deferred: a listener of command_requested may answer synchronously, before _run()
	# has reached `await _command_ready`; an immediate emit would be lost.
	_command_ready.emit.call_deferred(skill, target)


func _add_view(unit: BattleUnit, pos: Vector2) -> void:
	var view := BattlerView.new()
	add_child(view)
	view.setup(unit, pos)
	_views[unit] = view


func _run() -> void:
	while battle.outcome() == Battle.Outcome.ONGOING:
		var unit := battle.next_turn()
		_ui.update_order(battle.queue.preview(6), unit)
		_ui.update_party(battle.party, unit if unit.is_player else null)
		var skill: SkillData
		var target: BattleUnit
		if unit.is_player:
			_open_menu(unit)
			command_requested.emit(unit)
			var command: Array = await _command_ready
			skill = command[0]
			target = command[1]
		else:
			await get_tree().create_timer(ENEMY_THINK_TIME).timeout
			var choice := battle.choose_enemy_action(unit)
			skill = choice[0]
			target = choice[1]
		await _perform(unit, skill, target)
		_ui.update_party(battle.party, null)
	await _finish(battle.outcome())


func _perform(actor: BattleUnit, skill: SkillData, target: BattleUnit) -> void:
	var actor_view := view_of(actor)
	var target_view := view_of(target)
	_ui.show_message(skill.display_name if not actor.is_player or skill.kind != SkillData.Kind.ATTACK else "")
	var timing := DamageFormula.Timing.MISS
	match skill.kind:
		SkillData.Kind.ATTACK:
			# Heroes time their own swing, heroes being hit time their block; either way the
			# ring closes on the point of impact (the target).
			var prompt_done := _timed(actor.is_player or target.is_player, target_view, BattlerView.LUNGE_TIME)
			await actor_view.lunge_to(target_view)
			timing = await prompt_done.call()
		SkillData.Kind.MAGIC, SkillData.Kind.HEAL:
			var prompt_done := _timed(actor.is_player or target.is_player, target_view, 0.4)
			await actor_view.cast()
			timing = await prompt_done.call()
	var r := battle.resolve(actor, skill, target, timing)
	await _show_result(r)
	if skill.kind == SkillData.Kind.ATTACK:
		await actor_view.return_home()
	_ui.show_message("")


## Starts a timing prompt centred on `at` now (only when a hero is involved) and returns a
## callable that awaits its result.
func _timed(hero_involved: bool, at: BattlerView, impact_time: float) -> Callable:
	if not hero_involved:
		return func() -> DamageFormula.Timing: return DamageFormula.Timing.MISS
	_prompt.position = at.position + Vector2(0, -at.frame_size().y / 2.0)
	var state := {"done": false, "result": DamageFormula.Timing.MISS}
	var runner := func() -> void:
		state["result"] = await _prompt.run(impact_time)
		state["done"] = true
	runner.call()
	return func() -> DamageFormula.Timing:
		while not state["done"]:
			await get_tree().process_frame
		return state["result"]


func _show_result(r: Battle.ActionResult) -> void:
	var target_view := view_of(r.target)
	# Only a hero's press can produce a timing result: the attacking hero or the hero being hit.
	if r.timing != DamageFormula.Timing.MISS:
		var label := "Perfeito!" if r.timing == DamageFormula.Timing.PERFECT else "Bom!"
		var who := view_of(r.actor) if r.actor.is_player else target_view
		_ui.popup_number(who.head_position() + Vector2(0, -14), label, BattleUI.GOLD, self)
	match r.skill.kind:
		SkillData.Kind.DEFEND:
			_ui.popup_number(view_of(r.actor).head_position(), "Defesa", BattleUI.TEXT, self)
			await get_tree().create_timer(0.3).timeout
		SkillData.Kind.HEAL:
			_ui.popup_number(target_view.head_position(), str(r.amount), NUMBER_HEAL, self)
			await get_tree().create_timer(0.4).timeout
		_:
			if not r.hit:
				_ui.popup_number(target_view.head_position(), "Errou", BattleUI.DIM, self)
				await get_tree().create_timer(0.3).timeout
				return
			if r.absorbed:
				_ui.popup_number(target_view.head_position(), str(r.amount), NUMBER_HEAL, self)
				return
			_ui.popup_number(target_view.head_position(), str(r.amount) + ("!" if r.crit else ""), NUMBER_DAMAGE, self)
			await target_view.hurt()
			if r.knocked_out:
				await target_view.knock_out()


func _finish(outcome: Battle.Outcome) -> void:
	_ui.update_party(battle.party, null)
	_ui.clear_order()
	if outcome == Battle.Outcome.VICTORY:
		var text := "Vitória!  +%d XP   +%d moedas" % [battle.total_xp(), battle.total_money()]
		var promoted: PackedStringArray = []
		for result in battle.finish_victory():
			if result["levels"] > 0:
				var member: PartyMember = result["member"]
				promoted.append("%s nv. %d" % [member.data.display_name, member.level])
		text += "\n" + ("Subiu de nível: " + ", ".join(promoted) if not promoted.is_empty() else "")
		_ui.show_message(text.strip_edges())
	else:
		_ui.show_message("Derrota...\nConfirmar: tentar de novo")
	_mode = Mode.RESULT
	if auto_timing < 0:
		await _result_confirmed
	battle_ended.emit(outcome)


# ---------- player input ----------

func _open_menu(unit: BattleUnit) -> void:
	_actor = unit
	_menu_index = 0
	_mode = Mode.MENU
	_ui.show_menu(unit, _menu_index)


func _unhandled_input(event: InputEvent) -> void:
	match _mode:
		Mode.MENU:
			_menu_input(event)
		Mode.TARGET:
			_target_input(event)
		Mode.RESULT:
			if event.is_action_pressed(&"confirm"):
				get_viewport().set_input_as_handled()
				_mode = Mode.BUSY
				_result_confirmed.emit()


func _menu_input(event: InputEvent) -> void:
	var skills := _actor.data.skills
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_up"):
		var step := 1 if event.is_action_pressed(&"move_down") else -1
		_menu_index = wrapi(_menu_index + step, 0, skills.size())
		_ui.show_menu(_actor, _menu_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		var skill := skills[_menu_index]
		if not _actor.can_use(skill):
			return
		if skill.target == SkillData.Target.SELF:
			submit_command(skill, _actor)
			return
		_chosen_skill = skill
		_targets = battle.allies_of(_actor) if skill.target == SkillData.Target.ALLY else battle.opponents_of(_actor)
		_target_index = 0
		_mode = Mode.TARGET
		_place_cursor()


func _target_input(event: InputEvent) -> void:
	var step := 0
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_right"):
		step = 1
	elif event.is_action_pressed(&"move_up") or event.is_action_pressed(&"move_left"):
		step = -1
	if step != 0:
		_target_index = wrapi(_target_index + step, 0, _targets.size())
		_place_cursor()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		submit_command(_chosen_skill, _targets[_target_index])
	elif event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_cursor.hide()
		_open_menu(_actor)


func _place_cursor() -> void:
	var view := view_of(_targets[_target_index])
	_cursor.position = view.head_position() + Vector2(-5, -18)
	_cursor.show()
	_ui.show_message(_targets[_target_index].display_name())
