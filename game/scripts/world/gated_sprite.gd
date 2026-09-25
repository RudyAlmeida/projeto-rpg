class_name GatedSprite
extends Sprite2D
## Big map decoration that follows the story (FlagGate): the imperial airship over the
## village, the workshop ruins after the explosion. Optional slow hover (`bob`).

@export var show_if_flag: StringName
@export var hide_if_flag: StringName
## Hover amplitude in pixels (0 = static).
@export var bob := 0.0

var _time := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	GameState.flag_changed.connect(func(_flag: StringName) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	visible = FlagGate.passes(show_if_flag, hide_if_flag)


func _process(delta: float) -> void:
	if bob <= 0.0 or not visible:
		return
	_time += delta
	position.y = _base_y + roundf(sin(_time * 1.6) * bob)
