class_name TimingPrompt
extends Node2D
## Timed button press (GDD_Combate, section 4): a gold ring shrinks onto the character and
## closes exactly at the impact. Pressing "action_timing" then gives PERFECT / GOOD.
## Pressing too early spends the attempt (MISS), so mashing does not work.

const PERFECT_WINDOW := 3.0 / 60.0  # ±50 ms
const GOOD_WINDOW := 8.0 / 60.0     # ±133 ms
const RING_START := 26.0
const RING_END := 7.0
const RING_COLOR := Color(0.909804, 0.713725, 0.298039)

## Tests / accessibility: when >= 0, skip input and return this DamageFormula.Timing.
var auto_result := -1
## Accessibility: multiplies both windows (easy = 2.0, hard = 0.5).
var window_scale := 1.0

var _elapsed := 0.0
var _impact := 0.0
var _pressed_at := -1.0
var _running := false


func _ready() -> void:
	hide()
	set_process(false)


## Runs one prompt whose impact happens `impact_time` seconds from now; returns the result
## once the good window after the impact has closed.
func run(impact_time: float) -> DamageFormula.Timing:
	if auto_result >= 0:
		await get_tree().create_timer(impact_time).timeout
		return auto_result as DamageFormula.Timing
	_elapsed = 0.0
	_impact = impact_time
	_pressed_at = -1.0
	_running = true
	show()
	set_process(true)
	await get_tree().create_timer(impact_time + GOOD_WINDOW * window_scale).timeout
	_running = false
	hide()
	set_process(false)
	return evaluate(_pressed_at - _impact if _pressed_at >= 0.0 else INF, window_scale)


## `offset` = press time minus impact time, in seconds.
static func evaluate(offset: float, scale := 1.0) -> DamageFormula.Timing:
	var distance := absf(offset)
	if distance <= PERFECT_WINDOW * scale:
		return DamageFormula.Timing.PERFECT
	if distance <= GOOD_WINDOW * scale:
		return DamageFormula.Timing.GOOD
	return DamageFormula.Timing.MISS


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _running and _pressed_at < 0.0 and event.is_action_pressed(&"action_timing"):
		_pressed_at = _elapsed
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var t := clampf(_elapsed / _impact, 0.0, 1.0) if _impact > 0.0 else 1.0
	var radius := lerpf(RING_START, RING_END, t)
	var color := RING_COLOR if _pressed_at < 0.0 else Color(RING_COLOR, 0.35)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, color, 2.0)
	if t >= 1.0:
		draw_circle(Vector2.ZERO, RING_END - 2.0, Color(RING_COLOR, 0.6))
