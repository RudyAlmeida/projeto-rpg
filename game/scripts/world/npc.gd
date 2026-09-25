class_name NPC
extends StaticBody2D
## Talkable NPC. Uses the same reference-sheet layout as the player (columns down/left/up,
## right = left mirrored). Turns to face the player while talking, then turns back.

@export var idle_sheet: Texture2D
@export var facing := Player.Facing.DOWN
@export var dialogue: Array[DialogueLine] = []

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_sprite.texture = idle_sheet
	_show_facing(facing)


func interact(player: Node2D) -> void:
	if dialogue.is_empty():
		return
	_show_facing(Player.facing_for(player.global_position - global_position))
	await DialogueManager.play(dialogue)
	_show_facing(facing)


func _show_facing(dir: Player.Facing) -> void:
	var column := {Player.Facing.DOWN: 0, Player.Facing.LEFT: 1, Player.Facing.UP: 2, Player.Facing.RIGHT: 1}[dir] as int
	_sprite.region_rect = Rect2(column * Player.FRAME_SIZE, 0, Player.FRAME_SIZE, Player.FRAME_SIZE)
	_sprite.flip_h = dir == Player.Facing.RIGHT
