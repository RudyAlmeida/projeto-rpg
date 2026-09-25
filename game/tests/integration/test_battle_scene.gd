extends GutTest
## Full battles through BattleScene (animations, prompts, menu). Time runs 8x faster.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const BRANN := preload("res://data/characters/brann.tres")
const SLIME := preload("res://data/enemies/oil_slime.tres")
const ATTACK := preload("res://data/skills/attack.tres")
const FIRE := preload("res://data/skills/fire.tres")

var scene: BattleScene


func before_each() -> void:
	Engine.time_scale = 8.0
	scene = BattleScene.new()
	add_child_autofree(scene)


func after_each() -> void:
	Engine.time_scale = 1.0


func _start(auto_timing: int) -> void:
	scene.auto_timing = auto_timing
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	scene.start([KAEL, LYRA, BRANN] as Array[CombatantData], [SLIME, SLIME] as Array[CombatantData], Vector2(320, 180), false, rng)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	scene._unhandled_input(event)


func test_views_for_every_combatant() -> void:
	_start(DamageFormula.Timing.PERFECT)
	for unit in scene.battle.party + scene.battle.enemies:
		assert_not_null(scene.view_of(unit))
	assert_lt(scene.view_of(scene.battle.party[0]).position.x, scene.view_of(scene.battle.enemies[0]).position.x,
		"heroes on the left, enemies on the right")


func test_scripted_battle_ends_in_victory() -> void:
	watch_signals(scene)
	_start(DamageFormula.Timing.PERFECT)
	scene.command_requested.connect(func(unit: BattleUnit) -> void:
		var target := scene.battle.opponents_of(unit)[0]
		scene.submit_command(FIRE if unit.can_use(FIRE) and FIRE in unit.data.skills else ATTACK, target))
	await wait_for_signal(scene.battle_ended, 30.0)
	assert_signal_emitted_with_parameters(scene, "battle_ended", [Battle.Outcome.VICTORY])


func test_menu_confirm_twice_attacks_first_enemy() -> void:
	_start(DamageFormula.Timing.MISS)
	await wait_for_signal(scene.command_requested, 10.0)
	assert_not_null(scene._actor, "a hero turn came up")
	var slime_hp := scene.battle.enemies.map(func(e: BattleUnit) -> int: return e.hp)
	_press(&"confirm")  # Atacar
	_press(&"confirm")  # first target
	await wait_seconds(3.0)
	var after := scene.battle.enemies.map(func(e: BattleUnit) -> int: return e.hp)
	assert_ne(after, slime_hp, "an enemy took damage")


func test_cancel_in_target_mode_returns_to_menu() -> void:
	_start(DamageFormula.Timing.MISS)
	await wait_for_signal(scene.command_requested, 10.0)
	_press(&"confirm")
	assert_eq(scene._mode, BattleScene.Mode.TARGET)
	_press(&"cancel")
	assert_eq(scene._mode, BattleScene.Mode.ROOT)


func test_timing_windows() -> void:
	assert_eq(TimingPrompt.evaluate(0.0), DamageFormula.Timing.PERFECT)
	assert_eq(TimingPrompt.evaluate(0.04), DamageFormula.Timing.PERFECT)
	assert_eq(TimingPrompt.evaluate(-0.1), DamageFormula.Timing.GOOD)
	assert_eq(TimingPrompt.evaluate(0.2), DamageFormula.Timing.MISS)
	assert_eq(TimingPrompt.evaluate(INF), DamageFormula.Timing.MISS, "no press")
	assert_eq(TimingPrompt.evaluate(0.2, 2.0), DamageFormula.Timing.GOOD, "easy mode doubles windows")


func test_battle_themes_alternate() -> void:
	var first := BattleScene.next_battle_track()
	var second := BattleScene.next_battle_track()
	assert_ne(first, second, "consecutive fights use different themes")
	assert_eq(BattleScene.next_battle_track(), first, "and then come back to the first")
