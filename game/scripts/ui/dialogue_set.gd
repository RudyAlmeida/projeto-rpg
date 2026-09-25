class_name DialogueSet
extends Resource
## Everything an NPC can say, as branches checked in order (first match wins).

@export var id: StringName
@export var branches: Array[DialogueBranch] = []


func current_branch() -> DialogueBranch:
	for branch in branches:
		if branch.matches():
			return branch
	return null
