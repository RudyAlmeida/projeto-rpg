class_name UIKit
extends RefCounted
## Shared look for every menu: palette colours, the gold-bordered dark panel, pixel-font
## labels and item icons. Screens are built in code with these helpers.

const FONT := preload("res://assets/fonts/pixelify_ui.tres")
const ICONS := preload("res://assets/ui/ico_items.png")
const GOLD := Color(0.909804, 0.713725, 0.298039)
const TEXT := Color(0.909804, 0.894118, 0.862745)
const DIM := Color(0.423529, 0.415686, 0.439216)
const GOOD := Color(0.713725, 0.85098, 0.478431)
const BAD := Color(1.0, 0.419608, 0.352941)
const AETHER := Color(0.309804, 0.878431, 0.815686)
const DARK := Color(0.101961, 0.0784314, 0.137255)
const BORDER := Color(0.721569, 0.52549, 0.168627)


static func panel(parent: Node, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(DARK, 0.95)
	style.set_border_width_all(2)
	style.border_color = BORDER
	style.anti_aliasing = false
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p


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
