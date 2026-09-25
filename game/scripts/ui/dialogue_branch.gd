class_name DialogueBranch
extends Resource
## What an NPC says in a given story state, and what happens afterwards.
## NPCs use the first branch whose flag conditions hold.

## Every flag must be truthy (quest flags are "quest_<id>": "active" / "ready" / "done").
@export var require_flags: Array[StringName] = []
## No flag may be truthy.
@export var forbid_flags: Array[StringName] = []
## "quest_<id>" must equal this value (empty = ignore). Format: "quest_id=state".
@export var require_quest_state := ""
@export var lines: Array[DialogueLine] = []

@export_group("After talking")
@export var set_flags: Array[StringName] = []
@export var start_quest: StringName
@export var finish_quest: StringName
@export var give_items: Dictionary = {}
@export var give_money := 0


func matches() -> bool:
	for flag in require_flags:
		if not GameState.get_flag(flag):
			return false
	for flag in forbid_flags:
		if GameState.get_flag(flag):
			return false
	if require_quest_state != "":
		var parts := require_quest_state.split("=")
		if GameState.quest_state(StringName(parts[0])) != parts[1]:
			return false
	return true


func apply() -> void:
	for flag in set_flags:
		GameState.set_flag(flag)
	if start_quest != &"":
		GameState.start_quest(start_quest)
	if finish_quest != &"":
		GameState.finish_quest(finish_quest)
	for id: StringName in give_items:
		GameState.add_item(id, int(give_items[id]))
	if give_money != 0:
		GameState.add_money(give_money)
