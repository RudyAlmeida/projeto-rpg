class_name DialogueChoice
extends Resource
## One answer the player can pick at the end of a DialogueLine. It can set story flags,
## change affinity (H-06 love triangle) and play a few response lines.

@export var text := ""
@export var set_flags: Array[StringName] = []
## Character id -> affinity change, e.g. {&"lyra": 1}.
@export var affinity: Dictionary = {}
@export var response: Array[DialogueLine] = []
