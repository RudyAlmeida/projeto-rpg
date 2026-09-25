extends GutTest
## Checks the CTB TurnQueue against GDD_Combate v1.0 (section 3).

var queue: TurnQueue
var kael := RefCounted.new()
var mira := RefCounted.new()
var brann := RefCounted.new()
var slime := RefCounted.new()


func before_each() -> void:
	queue = TurnQueue.new()


func test_base_tick_table_from_gdd() -> void:
	assert_eq(queue.base_tick(10), 100)
	assert_eq(queue.base_tick(15), 85)
	assert_eq(queue.base_tick(25), 66)
	assert_eq(queue.base_tick(40), 50)
	assert_eq(queue.base_tick(80), 30)


func test_normal_action_delay_from_gdd() -> void:
	assert_eq(queue.delay_for(25, TurnQueue.WEIGHT_NORMAL), 198)
	assert_eq(queue.delay_for(40, TurnQueue.WEIGHT_NORMAL), 150)


func test_lowest_counter_acts_first() -> void:
	queue.add(brann, 15, true)
	queue.add(mira, 40, true)
	assert_eq(queue.next(), mira)


func test_initiative_acts_before_everyone() -> void:
	queue.add(mira, 40, false)
	queue.add(brann, 15, true, true)
	assert_eq(queue.next(), brann)


func test_faster_combatant_acts_more_often() -> void:
	queue.add(mira, 40, true)
	queue.add(brann, 15, true)
	var turns := {mira: 0, brann: 0}
	for i in 60:
		var actor := queue.next()
		turns[actor] += 1
		queue.commit_action()
	# Tick 50 vs 85: Mira should act ~1.7x as often as Brann.
	assert_gt(turns[mira], turns[brann])
	assert_almost_eq(float(turns[mira]) / turns[brann], 85.0 / 50.0, 0.15)


func test_fast_actions_come_back_sooner() -> void:
	queue.add(kael, 25, true)
	queue.next()
	queue.commit_action(TurnQueue.WEIGHT_FAST)
	var fast := queue.counter_of(kael)
	queue.next()
	queue.commit_action(TurnQueue.WEIGHT_HEAVY)
	assert_lt(fast, queue.counter_of(kael))


func test_preview_matches_real_order() -> void:
	queue.add(kael, 25, true)
	queue.add(mira, 40, true)
	queue.add(slime, 10, false)
	var predicted := queue.preview(8)
	var actual: Array[Object] = []
	for i in 8:
		actual.append(queue.next())
		queue.commit_action()
	assert_eq(actual, predicted)


func test_preview_shows_where_current_actor_lands() -> void:
	queue.add(kael, 25, true, true)  # counter 0: acts now
	queue.add(mira, 40, true)        # counter 150
	assert_eq(queue.next(), kael)
	# Fast action: Kael refills to 132 < 150, so he acts again before Mira.
	assert_eq(queue.preview(2, TurnQueue.WEIGHT_FAST), [kael, mira] as Array[Object])
	# Heavy action: Kael refills to 264 > 150, so Mira goes first.
	assert_eq(queue.preview(2, TurnQueue.WEIGHT_HEAVY), [mira, kael] as Array[Object])


func test_haste_doubles_turn_frequency() -> void:
	queue.add(kael, 25, true)
	queue.next()
	queue.commit_action()
	var normal := queue.counter_of(kael)
	queue.set_speed_mult(kael, 0.5)
	queue.next()
	queue.commit_action()
	assert_eq(queue.counter_of(kael), normal / 2)


func test_swap_takes_over_counter_and_acts_now() -> void:
	queue.add(kael, 25, true)
	queue.add(slime, 10, false)
	assert_eq(queue.next(), kael)
	queue.swap(kael, brann, 15)
	assert_false(queue.has(kael))
	assert_true(queue.has(brann))
	queue.commit_action()
	assert_eq(queue.counter_of(brann), queue.delay_for(15, TurnQueue.WEIGHT_NORMAL))


func test_delay_pushes_back() -> void:
	queue.add(kael, 25, true)
	queue.add(slime, 10, false)
	var before := queue.counter_of(slime)
	queue.delay(slime, 50)
	assert_eq(queue.counter_of(slime), before + 50)


func test_remove_defeated_combatant() -> void:
	queue.add(kael, 25, true)
	queue.add(slime, 10, false)
	queue.remove(slime)
	assert_eq(queue.size(), 1)
	for i in 3:
		assert_eq(queue.next(), kael)
		queue.commit_action()


func test_speed_tie_goes_to_player() -> void:
	queue.add(slime, 25, false, true)
	queue.add(kael, 25, true, true)
	assert_eq(queue.next(), kael)
