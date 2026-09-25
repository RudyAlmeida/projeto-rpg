class_name SkillTreeNode
extends Resource
## One node of a character's skill tree: costs Pontos de Habilidade, may require other
## nodes, and unlocks a skill and/or permanent stat bonuses.

@export var id: StringName
@export var display_name := ""
@export var cost := 1
@export var requires: Array[StringName] = []
@export var skill: SkillData
## Stat name (CombatantData.STATS) -> flat bonus.
@export var stat_bonuses: Dictionary = {}
@export_multiline var description := ""
## Layout position in the tree screen (column, row).
@export var grid_position := Vector2i.ZERO
