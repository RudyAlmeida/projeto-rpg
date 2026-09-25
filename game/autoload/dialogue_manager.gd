extends Node
## Autoload "DialogueManager": owns the single dialogue box and tells gameplay code when a
## conversation is running (the player cannot move or interact meanwhile).

signal dialogue_started
signal dialogue_finished

const BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var is_active := false

var _box: DialogueBox
var _closed_frame := -1


func _ready() -> void:
	_box = BOX_SCENE.instantiate()
	add_child(_box)


## Plays the lines and returns when the player has read the last one.
func play(lines: Array[DialogueLine]) -> void:
	if is_active or lines.is_empty():
		return
	is_active = true
	dialogue_started.emit()
	_box.show_lines(lines)
	await _box.finished
	is_active = false
	_closed_frame = Engine.get_process_frames()
	dialogue_finished.emit()


## True on the frame the box closed, so the confirm press that closed it cannot
## immediately start the same conversation again.
func just_closed() -> bool:
	return Engine.get_process_frames() - _closed_frame <= 1


func box() -> DialogueBox:
	return _box
