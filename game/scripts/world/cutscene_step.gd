class_name CutsceneStep
extends Resource
## One instruction of a cutscene. `actor` is a node path relative to the map root
## ("Player", "Gerd", ...).

enum Type { SAY, MOVE, FACE, WAIT, FADE_OUT, FADE_IN, SET_FLAG, START_QUEST, GIVE_ITEM, PLAY_MUSIC }

@export var type := Type.SAY
@export var actor: NodePath
## MOVE: destination (map coordinates). Speed in px/s.
@export var position := Vector2.ZERO
@export var speed := 50.0
@export var facing := Player.Facing.DOWN
@export var lines: Array[DialogueLine] = []
@export var seconds := 0.5
## SET_FLAG / START_QUEST / GIVE_ITEM: the id.
@export var id: StringName
@export var amount := 1
@export var music: AudioStream
