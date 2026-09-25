extends GutTest
## Block D: dialogue choices and affinity, quests through NPC branches, shop, inn, cutscene,
## main menu actions, options and the title screen.

const KAEL := preload("res://data/characters/kael.tres")
const LYRA := preload("res://data/characters/lyra.tres")
const POTION := preload("res://data/items/potion.tres")
const FEATHER := preload("res://data/items/phoenix_feather.tres")
const BRASS_BLADE := preload("res://data/items/brass_blade.tres")
const GEM_THUNDER := preload("res://data/items/gem_thunder.tres")
const GERD_TALK := preload("res://data/dialogue/gerd.tres")
const LYRA_TALK := preload("res://data/dialogue/lyra_house.tres")
const INTRO := preload("res://data/cutscenes/intro_gerd.tres")

var _saved_state: Dictionary
var _saved_settings := {}


func before_each() -> void:
	_saved_state = GameState.to_dict()
	_saved_settings = {"text": Settings.text_speed, "timing": Settings.timing_mode, "volume": Settings.music_volume}
	GameState.new_game([KAEL, LYRA] as Array[CombatantData], 500)
	Settings.text_speed = &"instant"
	Settings.apply()


func after_each() -> void:
	var box := DialogueManager.box()
	for i in 20:
		if not box.is_open():
			break
		box.confirm()
	GameState.from_dict(_saved_state)
	Settings.text_speed = _saved_settings["text"]
	Settings.timing_mode = _saved_settings["timing"]
	Settings.music_volume = _saved_settings["volume"]
	Settings.apply()
	get_tree().paused = false


## Clicks through a running conversation, picking `choice` when a choice list appears.
func _talk_through(choice := 0) -> void:
	var box := DialogueManager.box()
	for i in 30:
		await wait_process_frames(2)
		if not box.is_open():
			return
		if box.is_choosing():
			box.choose(choice)
		else:
			box.confirm()


# ---------- dialogue choices / affinity ----------

func test_choice_changes_affinity_and_plays_response() -> void:
	var branch := LYRA_TALK.current_branch()
	DialogueManager.play(branch.lines)
	await _talk_through(0)
	assert_eq(GameState.affinity(&"lyra"), 2)
	assert_true(GameState.get_flag(&"lyra_talked"))
	assert_eq(LYRA_TALK.current_branch().lines.size(), 1, "second visit uses the short branch")


func test_cold_answer_favours_isolde() -> void:
	DialogueManager.play(LYRA_TALK.current_branch().lines)
	await _talk_through(1)
	assert_eq(GameState.affinity(&"lyra"), -1)
	assert_eq(GameState.affinity(&"isolde"), 1)


func test_ask_returns_the_choice() -> void:
	var result := [-1]
	var run := func() -> void: result[0] = await DialogueManager.ask("Teste", "Sim ou não?", ["Sim", "Não"] as Array[String])
	run.call()
	await _talk_through(1)
	await wait_process_frames(2)
	assert_eq(result[0], 1)


# ---------- quests ----------

func test_gerd_quest_full_cycle() -> void:
	assert_eq(GameState.quest_state(&"q_village_noise"), "")
	var first := GERD_TALK.current_branch()
	first.apply()
	assert_eq(GameState.quest_state(&"q_village_noise"), "active")
	assert_eq(GERD_TALK.current_branch().require_quest_state, "q_village_noise=active")
	GameState.complete_objective(&"q_village_noise", &"defeat_sentinel")
	assert_eq(GameState.quest_state(&"q_village_noise"), "ready")
	var money := GameState.money
	GERD_TALK.current_branch().apply()
	assert_eq(GameState.quest_state(&"q_village_noise"), "done")
	assert_eq(GameState.money, money + 150)
	assert_true(GameState.gem_bag.any(func(g: GemInstance) -> bool: return g.item == GEM_THUNDER), "reward gem")
	assert_eq(GERD_TALK.current_branch().require_quest_state, "q_village_noise=done")


func test_objective_done_before_quest_counts_later() -> void:
	GameState.complete_objective(&"q_village_noise", &"defeat_sentinel")
	GameState.start_quest(&"q_village_noise")
	assert_eq(GameState.quest_state(&"q_village_noise"), "ready")


func test_quests_survive_save_round_trip() -> void:
	GameState.start_quest(&"q_village_noise")
	GameState.complete_objective(&"q_village_noise", &"defeat_sentinel")
	GameState.add_affinity(&"lyra", 3)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.new_game([KAEL] as Array[CombatantData])
	GameState.from_dict(snapshot)
	assert_eq(GameState.quest_state(&"q_village_noise"), "ready")
	assert_true(GameState.is_objective_done(&"q_village_noise", &"defeat_sentinel"))
	assert_eq(GameState.affinity(&"lyra"), 3)


# ---------- shop / inn ----------

func test_shop_buy_and_sell() -> void:
	var shop := ShopUI.new()
	add_child_autofree(shop)
	assert_true(shop.buy(BRASS_BLADE))
	assert_eq(GameState.money, 500 - 320)
	assert_eq(GameState.count(&"brass_blade"), 1)
	assert_true(shop.sell(BRASS_BLADE))
	assert_eq(GameState.money, 500 - 320 + 160, "sells at half price")
	GameState.money = 10
	assert_false(shop.buy(BRASS_BLADE), "not enough money")


func test_buying_a_gem_puts_it_in_the_bag() -> void:
	var shop := ShopUI.new()
	add_child_autofree(shop)
	shop.buy(GEM_THUNDER)
	assert_eq(GameState.gem_bag.size(), 1)
	assert_eq(GameState.count(&"gem_thunder"), 0)


func test_inn_rest_restores_everyone() -> void:
	var kael := GameState.party[0]
	var lyra := GameState.party[1]
	kael.hp = 10
	kael.mp = 0
	lyra.hp = 0
	for member in GameState.party:
		member.restore()
	assert_eq(kael.hp, kael.max_hp())
	assert_eq(kael.mp, kael.max_mp())
	assert_eq(lyra.hp, lyra.max_hp(), "KO'd heroes stand up after a night's rest")


# ---------- cutscene ----------

func test_intro_cutscene_gives_potions_and_sets_flag() -> void:
	Engine.time_scale = 8.0
	GameState.party.clear()
	var map: FieldMap = load("res://scenes/maps/test_map.tscn").instantiate()
	add_child_autofree(map)
	AudioManager.stop_music()
	await wait_process_frames(2)
	var potions := GameState.count(&"potion")
	var gerd: NPC = map.get_node("Gerd")
	var start := gerd.position
	INTRO.play(map)
	await _talk_through()
	await wait_seconds(3.0)
	await _talk_through()
	await wait_seconds(3.0)
	Engine.time_scale = 1.0
	assert_true(GameState.get_flag(&"intro_seen"))
	assert_eq(GameState.count(&"potion"), potions + 2)
	assert_eq(gerd.position, start, "Gerd walks back to his spot")
	assert_true(map.player.can_move())


# ---------- menu / options / title ----------

func test_field_item_use() -> void:
	var kael := GameState.party[0]
	GameState.add_item(&"potion", 1)
	assert_false(MainMenu.use_item_on(POTION, kael), "full HP: nothing to heal")
	kael.hp = 20
	assert_true(MainMenu.use_item_on(POTION, kael))
	assert_eq(kael.hp, 80)
	assert_eq(GameState.count(&"potion"), 0)
	kael.hp = 0
	GameState.add_item(&"phoenix_feather")
	assert_true(MainMenu.use_item_on(FEATHER, kael))
	assert_eq(kael.hp, roundi(kael.max_hp() * 0.3))


func test_main_menu_equip_flow_with_input() -> void:
	GameState.add_item(&"brass_blade")
	var menu := MainMenu.open(get_tree())
	await wait_process_frames(1)
	assert_true(get_tree().paused, "menu pauses the game")
	var press := func(action: StringName) -> void:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = true
		menu._unhandled_input(e)
	press.call(&"move_down")   # Equipar
	press.call(&"confirm")     # choose member
	press.call(&"confirm")     # Kael
	press.call(&"confirm")     # Arma slot
	press.call(&"move_down")   # skip "Remover"
	press.call(&"confirm")     # Lâmina de Latão
	assert_eq(GameState.party[0].equipment[ItemData.Kind.WEAPON], BRASS_BLADE)
	menu.close()
	await wait_process_frames(1)
	assert_false(get_tree().paused)


func test_options_cycle_and_apply() -> void:
	var panel := OptionsPanel.new()
	add_child_autofree(panel)
	Settings.timing_mode = &"normal"
	panel.change("timing", 1)
	assert_eq(Settings.timing_mode, &"hard")
	assert_eq(Settings.timing_window(), 0.5)
	Settings.timing_mode = &"auto"
	assert_eq(Settings.auto_timing(), DamageFormula.Timing.GOOD)
	panel.change("volume", -1)
	assert_almost_eq(AudioManager.music_volume, Settings.music_volume, 0.001)


func _action(action: StringName) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_options_close_with_esc_cancel_and_back_row() -> void:
	for how in [&"pause", &"cancel", &"row"]:
		var panel := OptionsPanel.new()
		add_child_autofree(panel)
		watch_signals(panel)
		if how == &"row":
			for i in 10:
				if panel._list.current()["id"] == "back":
					break
				panel._unhandled_input(_action(&"move_down"))
			assert_eq(panel._list.current()["id"], "back")
			panel._unhandled_input(_action(&"confirm"))
		else:
			panel._unhandled_input(_action(how))  # Esc / pad Start, or X / Backspace / pad B
		assert_signal_emitted(panel, "closed", "options close via %s" % how)


func test_main_menu_closes_with_esc() -> void:
	var menu := MainMenu.open(get_tree())
	await wait_process_frames(1)
	watch_signals(menu)
	menu._unhandled_input(_action(&"pause"))
	assert_signal_emitted(menu, "closed")
	await wait_process_frames(1)
	assert_false(get_tree().paused)


func test_title_menu_entries() -> void:
	var ids: Array = TitleScreenScript.menu_entries().map(func(e: Dictionary) -> String: return e["id"])
	assert_eq(ids, ["new", "continue", "options", "quit"])


const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
