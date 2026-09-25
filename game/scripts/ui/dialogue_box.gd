class_name DialogueBox
extends CanvasLayer
## Text box with portrait, speaker name and typewriter text.
## Confirm while typing reveals the whole line; confirm on a full line advances.

signal finished

@export var chars_per_second := 40.0

var _lines: Array[DialogueLine] = []
var _index := -1
var _shown := 0.0

@onready var _panel: Control = $Panel
@onready var _portrait: TextureRect = $Panel/Portrait
@onready var _name: Label = $Panel/Name
@onready var _text: Label = $Panel/Text
@onready var _next: Label = $Panel/Next


func _ready() -> void:
	_panel.hide()
	set_process(false)


func show_lines(lines: Array[DialogueLine]) -> void:
	assert(not lines.is_empty(), "show_lines() needs at least one line")
	_lines = lines
	_index = -1
	_panel.show()
	_advance()


func is_open() -> bool:
	return _panel.visible


func is_typing() -> bool:
	# -1 means "all visible" in Godot, so it must not count as still typing.
	return _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count()


## Same as pressing confirm: finish typing, or go to the next line / close.
func confirm() -> void:
	if not is_open():
		return
	if is_typing():
		_shown = _text.get_total_character_count()
		_text.visible_characters = _text.get_total_character_count()
	else:
		_advance()


func _process(delta: float) -> void:
	_shown += delta * chars_per_second
	_text.visible_characters = mini(int(_shown), _text.get_total_character_count())
	_next.visible = not is_typing() and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.4


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		confirm()


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
	_text.text = line.text
	_text.visible_characters = 0
	_shown = 0.0
	_next.hide()
	set_process(true)
