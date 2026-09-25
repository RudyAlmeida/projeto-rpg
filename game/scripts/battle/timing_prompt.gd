class_name TimingPrompt
extends Node2D
## Timed button press (GDD_Combate, section 4), three styles:
## RING    – a gold ring shrinks onto the impact point; press "action_timing" as it closes.
##           Pressing too early spends the attempt, so mashing does not work.
## CHANNEL – same ring, but hold the button and RELEASE as it closes (Lyra).
## HOLD    – hold to build steam pressure, release in the gold zone; holding too long
##           bursts (OVERLOAD) (Brann).

const PERFECT_WINDOW := 3.0 / 60.0  # ±50 ms
const GOOD_WINDOW := 8.0 / 60.0     # ±133 ms
const RING_START := 26.0
const RING_END := 7.0
const HOLD_FULL := 0.9              # seconds to fill the gauge
const HOLD_TIMEOUT := 2.0           # never pressed
const HOLD_PERFECT_FROM := 0.85
const HOLD_GOOD_FROM := 0.65
const HOLD_BURST_AT := 1.12
const GOLD := Color(0.909804, 0.713725, 0.298039)
const GREEN := Color(0.435294, 0.658824, 0.290196)
const RED := Color(1.0, 0.419608, 0.352941)
const DARK := Color(0.101961, 0.0784314, 0.137255)

## Tests / accessibility: when >= 0, skip input and return this DamageFormula.Timing.
var auto_result := -1
## Accessibility: multiplies the timing windows (easy = 2.0, hard = 0.5).
var window_scale := 1.0

var _style := CombatantData.TimingStyle.RING
var _elapsed := 0.0
var _impact := 0.0
var _pressed_at := -1.0
var _released_at := -1.0
var _running := false


func _ready() -> void:
	hide()
	set_process(false)


## Runs one prompt. RING/CHANNEL: the impact happens `impact_time` seconds from now.
## HOLD ignores `impact_time` and returns when the button is released (or bursts).
func run(impact_time: float, style := CombatantData.TimingStyle.RING) -> DamageFormula.Timing:
	if auto_result >= 0:
		await get_tree().create_timer(impact_time if style != CombatantData.TimingStyle.HOLD else HOLD_FULL).timeout
		return auto_result as DamageFormula.Timing
	_style = style
	_elapsed = 0.0
	_impact = impact_time
	_pressed_at = -1.0
	_released_at = -1.0
	_running = true
	show()
	set_process(true)
	var result := DamageFormula.Timing.MISS
	if style == CombatantData.TimingStyle.HOLD:
		result = await _run_hold()
	else:
		await get_tree().create_timer(impact_time + GOOD_WINDOW * window_scale).timeout
		if style == CombatantData.TimingStyle.CHANNEL:
			result = evaluate(_released_at - _impact if _pressed_at >= 0.0 and _released_at >= 0.0 else INF, window_scale)
		else:
			result = evaluate(_pressed_at - _impact if _pressed_at >= 0.0 else INF, window_scale)
	_running = false
	hide()
	set_process(false)
	return result


func _run_hold() -> DamageFormula.Timing:
	while true:
		await get_tree().process_frame
		if _pressed_at < 0.0 and _elapsed > HOLD_TIMEOUT:
			return DamageFormula.Timing.MISS
		if _pressed_at >= 0.0:
			var fill := hold_fill()
			if _released_at >= 0.0:
				return evaluate_hold(fill, window_scale)
			if fill >= HOLD_BURST_AT:
				return DamageFormula.Timing.OVERLOAD
	return DamageFormula.Timing.MISS


## Gauge fill (0 = empty, 1 = full) from how long the button has been held.
func hold_fill() -> float:
	if _pressed_at < 0.0:
		return 0.0
	var end := _released_at if _released_at >= 0.0 else _elapsed
	return (end - _pressed_at) / HOLD_FULL


## `offset` = press (or release) time minus impact time, in seconds.
static func evaluate(offset: float, scale := 1.0) -> DamageFormula.Timing:
	var distance := absf(offset)
	if distance <= PERFECT_WINDOW * scale:
		return DamageFormula.Timing.PERFECT
	if distance <= GOOD_WINDOW * scale:
		return DamageFormula.Timing.GOOD
	return DamageFormula.Timing.MISS


## Release point on the steam gauge; the gold zone widens with `scale` (easy mode).
static func evaluate_hold(fill: float, scale := 1.0) -> DamageFormula.Timing:
	if fill >= HOLD_BURST_AT:
		return DamageFormula.Timing.OVERLOAD
	var perfect_from := 1.0 - (1.0 - HOLD_PERFECT_FROM) * scale
	var good_from := 1.0 - (1.0 - HOLD_GOOD_FROM) * scale
	if fill >= perfect_from:
		return DamageFormula.Timing.PERFECT
	if fill >= good_from:
		return DamageFormula.Timing.GOOD
	return DamageFormula.Timing.MISS


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed(&"action_timing") and _pressed_at < 0.0:
		_pressed_at = _elapsed
		get_viewport().set_input_as_handled()
	elif event.is_action_released(&"action_timing") and _pressed_at >= 0.0 and _released_at < 0.0:
		_released_at = _elapsed
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if _style == CombatantData.TimingStyle.HOLD:
		_draw_gauge()
		return
	var t := clampf(_elapsed / _impact, 0.0, 1.0) if _impact > 0.0 else 1.0
	var radius := lerpf(RING_START, RING_END, t)
	var spent := _pressed_at >= 0.0 if _style == CombatantData.TimingStyle.RING else _released_at >= 0.0
	var color := GOLD if not spent else Color(GOLD, 0.35)
	if _style == CombatantData.TimingStyle.CHANNEL and _pressed_at >= 0.0 and _released_at < 0.0:
		color = Color(0.309804, 0.878431, 0.815686)  # Aether cyan while channelling
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, color, 2.0)
	if t >= 1.0:
		draw_circle(Vector2.ZERO, RING_END - 2.0, Color(GOLD, 0.6))


func _draw_gauge() -> void:
	var size := Vector2(8, 34)
	var origin := Vector2(-size.x / 2.0, -size.y / 2.0)
	draw_rect(Rect2(origin - Vector2.ONE, size + Vector2(2, 2)), DARK)
	# Zones: good (green) and perfect (gold), burst line (red) at the top.
	var good_h := size.y * (1.0 - HOLD_GOOD_FROM * 1.0)
	draw_rect(Rect2(origin, Vector2(size.x, good_h)), Color(GREEN, 0.35))
	draw_rect(Rect2(origin, Vector2(size.x, size.y * (1.0 - HOLD_PERFECT_FROM))), Color(GOLD, 0.45))
	var fill := clampf(hold_fill(), 0.0, 1.0)
	var fill_color := RED if hold_fill() >= 1.0 else GOLD
	draw_rect(Rect2(origin + Vector2(0, size.y * (1.0 - fill)), Vector2(size.x, size.y * fill)), fill_color)
	draw_line(origin, origin + Vector2(size.x, 0), RED, 1.0)
