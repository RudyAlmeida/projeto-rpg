class_name BattleUI
extends CanvasLayer
## Battle HUD (built in code): turn order on top, command menu bottom-left, party status
## bottom-right, a centred message line, and a target cursor drawn in the world.

const FONT := preload("res://assets/fonts/pixelify_ui.tres")
const GOLD := Color(0.909804, 0.713725, 0.298039)
const TEXT := Color(0.909804, 0.894118, 0.862745)
const DIM := Color(0.423529, 0.415686, 0.439216)
const HP_LOW := Color(1.0, 0.419608, 0.352941)

var _order: Label
var _menu_panel: Panel
var _menu_items: Array[Label] = []
var _status_labels: Array[Label] = []
var _message: Label
var _message_panel: Panel


func _ready() -> void:
	layer = 5
	var strip := _panel(Rect2(0, 0, 640, 22))
	_order = _label(Vector2(8, 1), Vector2(624, 18), GOLD)
	strip.add_child(_order)
	_menu_panel = _panel(Rect2(8, 268, 150, 84))
	_menu_panel.hide()
	_message_panel = _panel(Rect2(170, 28, 300, 46))  # under the order strip, clear of the fight
	_message = _label(Vector2(0, 4), Vector2(300, 40), TEXT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_panel.add_child(_message)
	_message_panel.hide()


## Party rows in the status panel (created once per battle).
func setup_party(party: Array[BattleUnit]) -> void:
	var panel := _panel(Rect2(372, 268, 260, 84))
	for i in party.size():
		var row := _label(Vector2(10, 6 + i * 24), Vector2(240, 20), TEXT)
		panel.add_child(row)
		_status_labels.append(row)
	update_party(party, null)


func update_party(party: Array[BattleUnit], active: BattleUnit) -> void:
	for i in party.size():
		var u := party[i]
		var row := _status_labels[i]
		row.text = "%s %s  HP %3d/%d  MP %2d" % ["▶" if u == active else " ", u.display_name(), u.hp, u.data.max_hp, u.mp]
		row.add_theme_color_override("font_color", DIM if not u.is_alive() else (HP_LOW if u.hp * 4 < u.data.max_hp else TEXT))


func update_order(order: Array[Object], current: BattleUnit) -> void:
	var names: PackedStringArray = []
	for unit: BattleUnit in order:
		names.append(unit.display_name())
	_order.text = "Vez: %s    Próximos: %s" % [current.display_name(), "  ›  ".join(names)]


func clear_order() -> void:
	_order.text = ""


func show_menu(unit: BattleUnit, index: int) -> void:
	for item in _menu_items:
		item.queue_free()
	_menu_items.clear()
	for i in unit.data.skills.size():
		var skill := unit.data.skills[i]
		var cost := "  %d MP" % skill.mp_cost if skill.mp_cost > 0 else ""
		var item := _label(Vector2(10, 6 + i * 20), Vector2(134, 20), TEXT if unit.can_use(skill) else DIM)
		item.text = "%s %s%s" % ["▶" if i == index else "  ", skill.display_name, cost]
		_menu_panel.add_child(item)
		_menu_items.append(item)
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
	label.add_theme_color_override("font_outline_color", Color(0.101961, 0.0784314, 0.137255))
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos - Vector2(12, 8)
	label.z_index = 50
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 16, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.3)
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
	style.bg_color = Color(0.101961, 0.0784314, 0.137255, 0.94)
	style.set_border_width_all(2)
	style.border_color = Color(0.721569, 0.52549, 0.168627)
	style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel
