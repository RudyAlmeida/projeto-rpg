class_name BattleVFX
extends Sprite2D
## One-shot battle effect from assets/vfx/vfx_battle.png: one effect per row, FRAMES frames
## of CELL px each (sliced from a Codex sheet by tools/art/tiles.mjs). Plays once and frees
## itself. Missing art = no effect (the battle still works).

const SHEET_PATH := "res://assets/vfx/vfx_battle.png"
const CELL := 48
const FRAMES := 4
const FPS := 14.0
## Effect id -> row in the sheet.
const ROWS := {&"slash": 0, &"impact": 1, &"fire": 2, &"ice": 3, &"thunder": 4, &"heal": 5, &"steam": 6,
	&"explosion": 7}

static var _sheet: Texture2D
static var _checked := false

var _frame_time := 0.0
var _frame_index := 0


## Spawns `effect` centred at `pos` (parent coordinates). Returns null if the art is missing.
static func spawn(parent: Node, effect: StringName, pos: Vector2, flip := false) -> BattleVFX:
	if not _checked:
		_checked = true
		_sheet = load(SHEET_PATH) if ResourceLoader.exists(SHEET_PATH) else null
	if _sheet == null or not ROWS.has(effect):
		return null
	var v := BattleVFX.new()
	v.texture = _sheet
	v.region_enabled = true
	v.flip_h = flip
	v.position = pos
	v.z_index = 45
	v.set_meta(&"row", ROWS[effect])
	v._show(0)
	parent.add_child(v)
	return v


func _process(delta: float) -> void:
	_frame_time += delta
	if _frame_time < 1.0 / FPS:
		return
	_frame_time = 0.0
	_frame_index += 1
	if _frame_index >= FRAMES:
		queue_free()
		return
	_show(_frame_index)


func _show(i: int) -> void:
	region_rect = Rect2(i * CELL, int(get_meta(&"row")) * CELL, CELL, CELL)
