class_name UIKit
extends RefCounted
## Shared look for every menu: palette colours, the gold-bordered dark panel, pixel-font
## labels and item icons. Screens are built in code with these helpers.

const FONT := preload("res://assets/fonts/pixelify_ui.tres")
## Numbers (HP, damage, prices): Press Start 2P at its native 8 px — Pixelify's 5 reads as 8.
const NUMBER_FONT := preload("res://assets/fonts/numbers.tres")
const NUMBER_SIZE := 8
const ICONS := preload("res://assets/ui/ico_items.png")
const GOLD := Color(0.909804, 0.713725, 0.298039)
const TEXT := Color(0.909804, 0.894118, 0.862745)
const DIM := Color(0.423529, 0.415686, 0.439216)
const GOOD := Color(0.713725, 0.85098, 0.478431)
const BAD := Color(1.0, 0.419608, 0.352941)
const AETHER := Color(0.309804, 0.878431, 0.815686)
const DARK := Color(0.101961, 0.0784314, 0.137255)
const BORDER := Color(0.721569, 0.52549, 0.168627)


const WINDOW_PATH := "res://assets/ui/ui_window.png"
const CURSOR_PATH := "res://assets/ui/ui_cursor.png"
## 9-slice margin of the brass window frame.
const WINDOW_MARGIN := 8

static var _window_style: StyleBox
static var _cursor: Texture2D
static var _checked := false


static func _load_skin() -> void:
	if _checked:
		return
	_checked = true
	if ResourceLoader.exists(WINDOW_PATH):
		var tex := StyleBoxTexture.new()
		tex.texture = load(WINDOW_PATH)
		tex.set_texture_margin_all(WINDOW_MARGIN)
		tex.set_content_margin_all(4)
		tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		tex.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		_window_style = tex
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(DARK, 0.95)
		flat.set_border_width_all(2)
		flat.border_color = BORDER
		flat.anti_aliasing = false
		_window_style = flat
	if ResourceLoader.exists(CURSOR_PATH):
		_cursor = load(CURSOR_PATH)


## Window panel: the brass frame art (9-slice) when it exists, else a flat gold border.
static func panel(parent: Node, rect: Rect2) -> Panel:
	_load_skin()
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _window_style)
	parent.add_child(p)
	return p


## Menu cursor at `pos`: the brass pointing hand (two bobbing frames) or a gold "▶".
static func cursor(parent: Node, pos: Vector2) -> Control:
	_load_skin()
	if _cursor == null:
		return label(parent, pos, "▶", GOLD)
	var rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = _cursor
	var frame := _cursor.get_height()
	atlas.region = Rect2(0, 0, frame, frame)
	rect.texture = atlas
	rect.position = pos + Vector2(-4, 1)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(rect)
	var tween := rect.create_tween().set_loops()
	tween.tween_callback(func() -> void: atlas.region.position.x = frame).set_delay(0.35)
	tween.tween_callback(func() -> void: atlas.region.position.x = 0).set_delay(0.35)
	return rect


## Label in the number font (vertically centred on a 16 px text row).
static func number_label(parent: Node, pos: Vector2, text := "", color := TEXT) -> Label:
	var l := Label.new()
	l.position = pos + Vector2(0, 5)
	l.text = text
	l.add_theme_font_override("font", NUMBER_FONT)
	l.add_theme_font_size_override("font_size", NUMBER_SIZE)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


static func label(parent: Node, pos: Vector2, text := "", color := TEXT, width := 0.0) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	if width > 0.0:
		l.size = Vector2(width, 18)
		l.clip_text = true
	parent.add_child(l)
	return l


static func icon(parent: Node, pos: Vector2, index: int) -> TextureRect:
	var rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2((index % 4) * 16, (index / 4) * 16, 16, 16)
	rect.texture = atlas
	rect.position = pos
	parent.add_child(rect)
	return rect


## Battle-sheet frame of a character as a small portrait (menus without art portraits).
static func sprite_frame(parent: Node, pos: Vector2, data: CombatantData, column := 0) -> TextureRect:
	var rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = data.battle_sheet
	atlas.region = Rect2(column * data.frame_size.x, 0, data.frame_size.x, data.frame_size.y)
	rect.texture = atlas
	rect.position = pos
	parent.add_child(rect)
	return rect


static func clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


static func pressed(event: InputEvent, action: StringName) -> bool:
	return event.is_action_pressed(action, false)


## "Back" in every menu: cancel (X, Backspace, pad B) or pause (Esc, pad Start).
static func is_back(event: InputEvent) -> bool:
	return event.is_action_pressed(&"cancel") or event.is_action_pressed(&"pause")
