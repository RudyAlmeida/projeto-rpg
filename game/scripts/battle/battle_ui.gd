class_name BattleUI
extends CanvasLayer
## Battle HUD (built in code): turn order on top, a scrolling list menu bottom-left
## (commands, techs, items, swaps), party status with Aether bars bottom-right, and a
## message box under the order strip.

const FONT := preload("res://assets/fonts/pixelify_ui.tres")
const ICONS := preload("res://assets/ui/ico_items.png")
const GOLD := Color(0.909804, 0.713725, 0.298039)
const TEXT := Color(0.909804, 0.894118, 0.862745)
const DIM := Color(0.423529, 0.415686, 0.439216)
const HP_LOW := Color(1.0, 0.419608, 0.352941)
const AETHER := Color(0.309804, 0.878431, 0.815686)
const DARK := Color(0.101961, 0.0784314, 0.137255)
const MENU_ROWS := 4
const ROW_H := 18

var _order: Label
var _menu_panel: Panel
var _menu_title: Label
var _menu_rows: Array[Control] = []
var _status_rows: Array[Label] = []
var _aether_bars: Array[ColorRect] = []
var _aether_back: Array[ColorRect] = []
var _message: Label
var _message_panel: Panel


func _ready() -> void:
	layer = 5
	var strip := _panel(Rect2(0, 0, 640, 22))
	_order = _label(Vector2(8, 1), Vector2(624, 18), GOLD)
	strip.add_child(_order)
	_menu_panel = _panel(Rect2(8, 262, 222, 90))
	_menu_title = _label(Vector2(8, -2), Vector2(206, 18), GOLD)
	_menu_panel.add_child(_menu_title)
	_menu_panel.hide()
	_message_panel = _panel(Rect2(90, 28, 460, 46))  # under the order strip, clear of the fight
	_message = _label(Vector2(0, 4), Vector2(460, 40), TEXT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_panel.add_child(_message)
	_message_panel.hide()


## Party rows in the status panel (created once per battle, one per active slot).
func setup_party(slots: int) -> void:
	var panel := _panel(Rect2(236, 262, 396, 90))
	for i in slots:
		var row := _label(Vector2(8, 2 + i * 28), Vector2(382, 18), TEXT)
		panel.add_child(row)
		_status_rows.append(row)
		var back := ColorRect.new()
		back.color = DARK.lightened(0.15)
		back.position = Vector2(26, 20 + i * 28)
		back.size = Vector2(100, 3)
		panel.add_child(back)
		_aether_back.append(back)
		var bar := ColorRect.new()
		bar.color = AETHER
		bar.position = back.position
		bar.size = Vector2(0, 3)
		panel.add_child(bar)
		_aether_bars.append(bar)


func update_party(party: Array[BattleUnit], active: BattleUnit) -> void:
	for i in _status_rows.size():
		var row := _status_rows[i]
		if i >= party.size():
			row.text = ""
			_aether_bars[i].size.x = 0
			continue
		var u := party[i]
		var tags := PackedStringArray()
		for id: int in u.statuses:
			tags.append(StatusEffects.tag(id))
		row.text = "%s%-6s HP %3d/%-3d MP %2d  %s" % ["▶" if u == active else "  ", u.display_name(), u.hp, u.max_hp(), u.mp,
			" ".join(tags)]
		row.add_theme_color_override("font_color", DIM if not u.is_alive() else (HP_LOW if u.hp * 4 < u.max_hp() else TEXT))
		_aether_bars[i].size.x = 100.0 * u.aether / BattleUnit.AETHER_MAX
		_aether_bars[i].color = GOLD if u.aether_full() else AETHER


func update_order(order: Array[Object], current: BattleUnit) -> void:
	var names: PackedStringArray = []
	for unit: BattleUnit in order:
		names.append(unit.display_name())
	_order.text = "Vez: %s    Próximos: %s" % [current.display_name(), "  ›  ".join(names)]


func clear_order() -> void:
	_order.text = ""


## entries: [{text, enabled, icon (ItemData icon_index or -1), note}]
func show_list(title: String, entries: Array, index: int) -> void:
	for row in _menu_rows:
		row.queue_free()
	_menu_rows.clear()
	_menu_title.text = title
	var first := clampi(index - MENU_ROWS + 1, 0, maxi(0, entries.size() - MENU_ROWS))
	for i in range(first, mini(entries.size(), first + MENU_ROWS)):
		var entry: Dictionary = entries[i]
		var y := 16 + (i - first) * ROW_H
		var x := 20
		if int(entry.get("icon", -1)) >= 0:
			var icon := TextureRect.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = ICONS
			atlas.region = Rect2((int(entry["icon"]) % 4) * 16, (int(entry["icon"]) / 4) * 16, 16, 16)
			icon.texture = atlas
			icon.position = Vector2(18, y + 1)
			_menu_panel.add_child(icon)
			_menu_rows.append(icon)
			x = 36
		var label := _label(Vector2(x, y), Vector2(204 - x, ROW_H), TEXT if entry.get("enabled", true) else DIM)
		label.text = entry["text"] + (("  " + str(entry["note"])) if entry.has("note") else "")
		label.clip_text = true
		_menu_panel.add_child(label)
		_menu_rows.append(label)
		if i == index:
			var cursor := _label(Vector2(6, y), Vector2(14, ROW_H), GOLD)
			cursor.text = "▶"
			_menu_panel.add_child(cursor)
			_menu_rows.append(cursor)
	if first > 0 or first + MENU_ROWS < entries.size():
		var more := _label(Vector2(204, 70), Vector2(14, ROW_H), DIM)
		more.text = "↕"
		_menu_panel.add_child(more)
		_menu_rows.append(more)
	_menu_panel.show()


func hide_menu() -> void:
	_menu_panel.hide()


func show_message(text: String) -> void:
	_message.text = text
	_message_panel.visible = text != ""
	# One line sits in the middle of the box; two lines fill it.
	_message.position.y = 13 if text.count("\n") == 0 else 4


func popup_number(world_pos: Vector2, text: String, color: Color, parent: Node) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", DARK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos - Vector2(12, 8)
	label.z_index = 50
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 16, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(label.queue_free)


func _label(pos: Vector2, size: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	return label


func _panel(rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(DARK, 0.94)
	style.set_border_width_all(2)
	style.border_color = Color(0.721569, 0.52549, 0.168627)
	style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel
