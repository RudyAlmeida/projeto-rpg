class_name SkillTreeData
extends Resource
## A character's skill tree (GDD 8.1): identity through unique techniques and stat paths.

@export var id: StringName
## CombatantData id of the owner.
@export var character: StringName
@export var nodes: Array[SkillTreeNode] = []


func node(node_id: StringName) -> SkillTreeNode:
	for n in nodes:
		if n.id == node_id:
			return n
	return null
