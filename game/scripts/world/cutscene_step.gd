class_name CutsceneStep
extends Resource
## One instruction of a cutscene. `actor` is a node path relative to the map root
## ("Player", "Gerd", ...).

enum Type { SAY, MOVE, FACE, WAIT, FADE_OUT, FADE_IN, SET_FLAG, START_QUEST, GIVE_ITEM, PLAY_MUSIC,
	JOIN_PARTY, LEAVE_PARTY, BATTLE, CHANGE_SCENE, SHAKE, FLASH, SHOW, HIDE, TELEPORT, END_CHAPTER,
	RESTORE_PARTY, GIVE_MONEY, REMOVE_ITEM, STOP_MUSIC, COMPLETE_OBJECTIVE, FINISH_QUEST, SFX }

@export var type := Type.SAY
@export var actor: NodePath
## MOVE / TELEPORT: destination (map coordinates). Speed in px/s.
@export var position := Vector2.ZERO
@export var speed := 50.0
@export var facing := Player.Facing.DOWN
@export var lines: Array[DialogueLine] = []
## WAIT / SHAKE / FLASH duration.
@export var seconds := 0.5
## SET_FLAG / START_QUEST / GIVE_ITEM / REMOVE_ITEM / JOIN_PARTY / LEAVE_PARTY: the id.
## SFX: the sound id (assets/audio/sfx/<id>.ogg).
## COMPLETE_OBJECTIVE: "quest_id:objective_id".
@export var id: StringName
## GIVE_ITEM / REMOVE_ITEM / GIVE_MONEY: amount. JOIN_PARTY: level (0 = party average).
@export var amount := 1
@export var music: AudioStream
## BATTLE: enemies, and enemy id -> turns for story fights that end on their own.
@export var enemies: Array[CombatantData] = []
@export var end_after_turns: Dictionary = {}
## CHANGE_SCENE: scene path (+ spawn id in `id`). END_CHAPTER: the title card text.
@export var text := ""
## SHAKE: strength in pixels. FLASH: colour.
@export var strength := 4.0
@export var color := Color.WHITE
