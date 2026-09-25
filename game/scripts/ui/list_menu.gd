class_name ListMenu
extends Panel
## Scrolling list with a cursor, optional icons, right-aligned notes and disabled rows.
## The owner feeds input with move() / current() and redraws with set_entries().
## entry: {text, enabled = true, icon = -1, note = "", ...any payload}

const ROW_H := 18

var entries: Array = []
var index := 0
var rows_visible := 4
var title := ""

var _content: Control


static func create(parent: Node, rect: Rect2, p_title := "") -> ListMenu:
	var menu := ListMenu.new()
	menu.position = rect.position
	menu.size = rect.size
	menu.title = p_title
	menu.add_theme_stylebox_override("panel", UIKit.window_style())
	menu.rows_visible = maxi(1, int((rect.size.y - (22 if p_title != "" else 6)) / ROW_H))
	parent.add_child(menu)
	return menu


func set_entries(p_entries: Array, keep_index := false) -> void:
	entries = p_entries
	if not keep_index:
		index = 0
	index = clampi(index, 0, maxi(0, entries.size() - 1))
	_redraw()


func current() -> Dictionary:
	return entries[index] if index < entries.size() else {}


func is_enabled() -> bool:
	return not entries.is_empty() and current().get("enabled", true)


## Returns true if the cursor moved.
func move(step: int) -> bool:
	if entries.is_empty():
		return false
	index = wrapi(index + step, 0, entries.size())
	AudioManager.play_sfx(&"ui_move", 1.0, 0.6)
	_redraw()
	return true


## Handles up/down; returns true if the event was consumed.
func handle_navigation(event: InputEvent) -> bool:
	if event.is_action_pressed(&"move_down", true):
		return move(1)
	if event.is_action_pressed(&"move_up", true):
		return move(-1)
	return false


func _redraw() -> void:
	if _content:
		_content.queue_free()
	_content = Control.new()
	add_child(_content)
	var top := 6
	if title != "":
		UIKit.label(_content, Vector2(8, 0), title, UIKit.GOLD)
		top = 20
	var first := clampi(index - rows_visible + 1, 0, maxi(0, entries.size() - rows_visible))
	for i in range(first, mini(entries.size(), first + rows_visible)):
		var e: Dictionary = entries[i]
		var y := top + (i - first) * ROW_H
		var x := 20.0
		if int(e.get("icon", -1)) >= 0:
			UIKit.icon(_content, Vector2(20, y + 1), int(e["icon"]))
			x = 38.0
		var color := UIKit.TEXT if e.get("enabled", true) else UIKit.DIM
		if e.has("color"):
			color = e["color"]
		var note := str(e.get("note", ""))
		var note_w := 0.0
		if note != "":
			var n := UIKit.number_label(_content, Vector2(0, y), note, UIKit.DIM if not e.get("enabled", true) else UIKit.GOLD)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			n.size = Vector2(size.x - 12, 18)
			note_w = n.get_minimum_size().x + 8
		UIKit.label(_content, Vector2(x, y), str(e.get("text", "")), color, size.x - x - 10 - note_w)
		if i == index:
			UIKit.cursor(_content, Vector2(6, y))
	if first > 0:
		UIKit.label(_content, Vector2(size.x - 16, top - 12), "▲", UIKit.DIM)
	if first + rows_visible < entries.size():
		UIKit.label(_content, Vector2(size.x - 16, size.y - 18), "▼", UIKit.DIM)
