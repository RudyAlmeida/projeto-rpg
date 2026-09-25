class_name Player
extends CharacterBody2D
## Field-map player (Phase 1 prototype).
## Idle frames come from the reference sheet (0 = down, 1 = left, 2 = up); walking uses
## `walk_sheet` (rows down / left / up, WALK_FRAMES columns). Right = left mirrored.
## Without a walk sheet the sprite just bobs.

enum Facing { DOWN, LEFT, UP, RIGHT }

const FRAME_SIZE := 64
const WALK_FRAMES := 4
const WALK_FPS := 8.0
const BOB_HEIGHT := 2.0

@export var walk_speed := 80.0
@export var run_multiplier := 1.75
@export var idle_sheet: Texture2D
@export var walk_sheet: Texture2D

var facing := Facing.DOWN

var _anim_time := 0.0
var _moving := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	_update_frame()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var speed := walk_speed * (run_multiplier if Input.is_action_pressed(&"run") else 1.0)
	velocity = direction * speed
	move_and_slide()

	_moving = direction != Vector2.ZERO
	if _moving:
		facing = facing_for(direction)
		_anim_time += delta * (speed / walk_speed)
	else:
		_anim_time = 0.0
	_update_frame()


## Dominant axis wins; horizontal wins exact diagonals so side sprites show while strafing.
static func facing_for(direction: Vector2) -> Facing:
	if absf(direction.x) >= absf(direction.y):
		return Facing.RIGHT if direction.x > 0 else Facing.LEFT
	return Facing.DOWN if direction.y > 0 else Facing.UP


## Current walk frame (0..WALK_FRAMES-1) for the elapsed animation time.
static func walk_frame_at(time: float) -> int:
	return floori(time * WALK_FPS) % WALK_FRAMES


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y


func _update_frame() -> void:
	var direction_index := {Facing.DOWN: 0, Facing.LEFT: 1, Facing.UP: 2, Facing.RIGHT: 1}[facing] as int
	_sprite.flip_h = facing == Facing.RIGHT
	var bob := 0.0
	if _moving and walk_sheet:
		_sprite.texture = walk_sheet
		_sprite.region_rect = Rect2(walk_frame_at(_anim_time) * FRAME_SIZE, direction_index * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	else:
		_sprite.texture = idle_sheet
		_sprite.region_rect = Rect2(direction_index * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		if _moving:
			bob = roundf(absf(sin(_anim_time * 14.0)) * BOB_HEIGHT)  # fallback: whole pixels only
	_sprite.offset.y = -FRAME_SIZE / 2.0 - bob
