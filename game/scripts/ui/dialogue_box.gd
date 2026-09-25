class_name DialogueBox
extends CanvasLayer
## Text box with portrait, speaker name and typewriter text.
## Confirm while typing reveals the whole line; confirm on a full line advances.
## Lines with choices show a list above the box; picking one plays its response lines.

signal finished
signal choice_made(choice: DialogueChoice, index: int)

@export var chars_per_second := 40.0

var last_choice := -1

var _lines: Array[DialogueLine] = []
var _index := -1
var _shown := 0.0
var _choices: ListMenu

@onready var _panel: Control = $Panel
@onready var _portrait: TextureRect = $Panel/Portrait
@onready var _name: Label = $Panel/Name
@onready var _text: Label = $Panel/Text
@onready var _next: Label = $Panel/Next


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UIKit.window_style())
	_panel.hide()
	set_process(false)


func show_lines(lines: Array[DialogueLine]) -> void:
	assert(not lines.is_empty(), "show_lines() needs at least one line")
	_lines = lines.duplicate()
	_index = -1
	last_choice = -1
	_panel.show()
	_advance()


func is_open() -> bool:
	return _panel.visible


func is_choosing() -> bool:
	return _choices != null


func is_typing() -> bool:
	# -1 means "all visible" in Godot, so it must not count as still typing.
	return _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count()


## Same as pressing confirm: finish typing, pick the highlighted choice, or go on / close.
func confirm() -> void:
	if not is_open():
		return
	if is_typing():
		_shown = _text.get_total_character_count()
		_text.visible_characters = _text.get_total_character_count()
		_open_choices()
	elif is_choosing():
		choose(_choices.index)
	else:
		_advance()


## Picks choice `index` of the current line (menu and tests).
func choose(index: int) -> void:
	var line := _lines[_index]
	if index < 0 or index >= line.choices.size():
		return
	var choice := line.choices[index]
	last_choice = index
	_choices.queue_free()
	_choices = null
	choice_made.emit(choice, index)
	for i in choice.response.size():
		_lines.insert(_index + 1 + i, choice.response[i])
	_advance()


func _process(delta: float) -> void:
	var was_typing := is_typing()
	_shown += delta * chars_per_second
	_text.visible_characters = mini(int(_shown), _text.get_total_character_count())
	if was_typing and not is_typing():
		_open_choices()
	_next.visible = not is_typing() and not is_choosing() and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.4


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if is_choosing() and _choices.handle_navigation(event):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		confirm()


func _open_choices() -> void:
	var line := _lines[_index]
	if line.choices.is_empty() or is_choosing():
		return
	var height := line.choices.size() * ListMenu.ROW_H + 12
	_choices = ListMenu.create(self, Rect2(192, 262 - height, 440, height))  # wide: answers are sentences
	_choices.set_entries(line.choices.map(func(c: DialogueChoice) -> Dictionary: return {"text": c.text}))


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_panel.hide()
		set_process(false)
		finished.emit()
		return
	var line := _lines[_index]
	_name.text = line.speaker
	_portrait.texture = line.portrait
	_portrait.visible = line.portrait != null
	# Without a portrait the text uses the whole box.
	_name.position.x = 84.0 if line.portrait else 12.0
	_text.position.x = 84.0 if line.portrait else 12.0
	_text.text = line.text
	_text.visible_characters = 0
	_shown = 0.0
	_next.hide()
	set_process(true)
