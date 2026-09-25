class_name FieldEnemy
extends Area2D
## Visible enemy on the field (no random encounters). Patrols a little around its start
## point; touching the player emits `touched_player` and FieldMap starts the battle.

signal touched_player(enemy: FieldEnemy)

const BOB_FRAMES := [0, 1]  # idle / squashed columns of the battle sheet
const BOB_TIME := 0.45

## The enemy group this encounter fights.
@export var enemies: Array[CombatantData] = []
@export var patrol_distance := 24.0
@export var patrol_speed := 14.0

var _home := Vector2.ZERO
var _time := 0.0
var _active := true

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_home = position
	body_entered.connect(_on_body_entered)
	if not enemies.is_empty():
		var data := enemies[0]
		_sprite.texture = data.battle_sheet
		_sprite.region_enabled = true
		_sprite.offset = Vector2(0, -data.frame_size.y / 2.0)
		_show_frame(0)


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	_show_frame(BOB_FRAMES[int(_time / BOB_TIME) % BOB_FRAMES.size()])
	if patrol_distance > 0.0:
		var offset := sin(_time * patrol_speed / patrol_distance) * patrol_distance
		position.x = _home.x + roundf(offset)
		_sprite.flip_h = cos(_time * patrol_speed / patrol_distance) > 0.0  # face where it moves


## Stops moving and hides (the battle shows its own sprites).
func freeze() -> void:
	_active = false
	hide()
	set_deferred("monitoring", false)


func _show_frame(column: int) -> void:
	var size := Vector2(enemies[0].frame_size)
	_sprite.region_rect = Rect2(column * size.x, 0, size.x, size.y)


func _on_body_entered(body: Node2D) -> void:
	if _active and body is Player:
		touched_player.emit(self)
