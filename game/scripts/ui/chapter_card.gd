class_name ChapterCard
extends CanvasLayer
## Full-screen title card on black ("Fim do Prólogo — ..."). Fades in, waits for confirm
## (or `auto_close` seconds in tests), fades out.

signal closed

## Tests: close by itself after this many seconds (0 = wait for the player).
static var auto_close := 0.0

var _text := ""
var _ready_for_input := false


static func show_card(tree: SceneTree, text: String) -> void:
	var card := ChapterCard.new()
	card._text = text
	tree.root.add_child(card)
	await card.closed
	card.queue_free()


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var label := UIKit.label(black, Vector2(0, 0), _text, UIKit.GOLD)
	label.size = Vector2(640, 360)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	black.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(black, "modulate:a", 1.0, 1.2)
	await tween.finished
	_ready_for_input = true
	if auto_close > 0.0:
		await get_tree().create_timer(auto_close).timeout
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _ready_for_input and event.is_action_pressed(&"confirm"):
		_ready_for_input = false
		get_viewport().set_input_as_handled()
		closed.emit()
