class_name QuestData
extends Resource
## A main or side quest (Fase 2: missões e diário). Objectives are completed by game
## events (defeating a field enemy, talking to someone); finishing pays the rewards.

@export var id: StringName
@export var title := ""
@export_multiline var description := ""
@export var main_story := false
@export var objective_ids: Array[StringName] = []
@export var objective_texts: Array[String] = []

@export_group("Rewards")
@export var reward_money := 0
@export var reward_xp := 0
@export var reward_items: Dictionary = {}
