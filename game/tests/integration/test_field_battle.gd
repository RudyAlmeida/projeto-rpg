extends GutTest
## Touching a field enemy starts a battle on the map; winning removes it and frees the player.

const ATTACK := preload("res://data/skills/attack.tres")
const FIRE := preload("res://data/skills/fire.tres")

var level: FieldMap
var slime: FieldEnemy


func before_each() -> void:
	Engine.time_scale = 8.0
	level = load("res://scenes/maps/test_map.tscn").instantiate()
	level.battle_auto_timing = DamageFormula.Timing.PERFECT
	add_child_autofree(level)
	AudioManager.stop_music()
	slime = level.get_node("OilSlimes")
	# Auto-play every hero turn: Fire when possible, otherwise attack.
	level.battle_started.connect(func(battle: BattleScene) -> void:
		battle.command_requested.connect(func(unit: BattleUnit) -> void:
			var skill := FIRE if FIRE in unit.data.skills and unit.can_use(FIRE) else ATTACK
			battle.submit_command(skill, battle.battle.opponents_of(unit)[0])))
	await wait_physics_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0
	Input.action_release(&"move_right")


func test_enemy_stands_on_walkable_ground() -> void:
	var cell := level.map.local_to_map(slime.position)
	for dx in [-2, -1, 0, 1, 2]:
		assert_false(level.map.is_solid_at(cell + Vector2i(dx, 0)), "patrol path must be walkable")


func test_touching_enemy_starts_battle() -> void:
	watch_signals(level)
	level.player.position = slime.position + Vector2(-30, 0)
	await wait_physics_frames(2)
	Input.action_press(&"move_right")
	await wait_for_signal(level.battle_started, 5.0)
	Input.action_release(&"move_right")
	assert_signal_emitted(level, "battle_started")
	assert_true(level.in_battle())
	assert_false(level.player.can_move(), "player is locked during battle")
	assert_false(level.player.visible, "field sprite steps aside for the battle formation")


func test_victory_removes_enemy_and_frees_player() -> void:
	watch_signals(level)
	level.start_battle(slime)
	await wait_for_signal(level.battle_finished, 40.0)
	assert_signal_emitted_with_parameters(level, "battle_finished", [Battle.Outcome.VICTORY])
	await wait_process_frames(2)
	assert_false(is_instance_valid(slime), "defeated field enemy is gone")
	assert_false(level.in_battle())
	assert_true(level.player.visible)
	assert_true(level.player.can_move())


func test_battle_uses_party_and_enemy_group() -> void:
	level.start_battle(slime)
	await wait_process_frames(2)
	var battle: BattleScene = level._battle
	assert_eq(battle.battle.party.size(), 3)
	assert_eq(battle.battle.enemies.size(), 2)
	assert_eq(battle.battle.party[0].display_name(), "Kael")
	await wait_for_signal(level.battle_finished, 40.0)
