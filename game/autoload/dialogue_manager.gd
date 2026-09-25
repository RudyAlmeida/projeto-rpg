extends Node
## Autoload "DialogueManager": owns the single dialogue box and tells gameplay code when a
## conversation is running (the player cannot move or interact meanwhile). Choice effects
## (story flags, affinity) are applied here.

signal dialogue_started
signal dialogue_finished

const BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var is_active := false

var _box: DialogueBox
var _closed_frame := -1


func _ready() -> void:
	_box = BOX_SCENE.instantiate()
	add_child(_box)
	_box.choice_made.connect(_on_choice)


## Plays the lines and returns the index of the last choice picked (-1 if none).
func play(lines: Array[DialogueLine]) -> int:
	if is_active or lines.is_empty():
		return -1
	is_active = true
	dialogue_started.emit()
	_box.show_lines(lines)
	await _box.finished
	is_active = false
	_closed_frame = Engine.get_process_frames()
	dialogue_finished.emit()
	return _box.last_choice


## Convenience for one-off lines (shops, inns, signs).
func say(speaker: String, text: String, portrait: Texture2D = null) -> void:
	await play([DialogueLine.make(speaker, text, portrait)] as Array[DialogueLine])


## Yes/No style question; returns the chosen index.
func ask(speaker: String, text: String, options: Array[String], portrait: Texture2D = null) -> int:
	var line := DialogueLine.make(speaker, text, portrait)
	for option in options:
		var choice := DialogueChoice.new()
		choice.text = option
		line.choices.append(choice)
	return await play([line] as Array[DialogueLine])


## True on the frame the box closed, so the confirm press that closed it cannot
## immediately start the same conversation again.
func just_closed() -> bool:
	return Engine.get_process_frames() - _closed_frame <= 1


func box() -> DialogueBox:
	return _box


func _on_choice(choice: DialogueChoice, _index: int) -> void:
	for flag in choice.set_flags:
		GameState.set_flag(flag)
	for character: StringName in choice.affinity:
		GameState.add_affinity(character, int(choice.affinity[character]))
