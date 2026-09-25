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
## Item id -> minimum count in the inventory.
@export var require_items: Dictionary = {}
@export var lines: Array[DialogueLine] = []

@export_group("After talking")
@export var set_flags: Array[StringName] = []
@export var start_quest: StringName
@export var finish_quest: StringName
@export var give_items: Dictionary = {}
@export var give_money := 0
## Item id -> count removed from the inventory (quest hand-ins, deliveries).
@export var take_items: Dictionary = {}
## "quest_id:objective_id" entries completed.
@export var complete_objectives: Array[String] = []
## Character id -> affinity change.
@export var affinity: Dictionary = {}
## Played after the lines (story beats that start from a conversation).
@export var cutscene: Cutscene


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
	for id: StringName in require_items:
		if GameState.count(id) < int(require_items[id]):
			return false
	return true


func apply() -> void:
	for id: StringName in take_items:
		GameState.remove_item(id, int(take_items[id]))
	for flag in set_flags:
		GameState.set_flag(flag)
	for entry in complete_objectives:
		var parts := entry.split(":")
		GameState.complete_objective(StringName(parts[0]), StringName(parts[1]))
	for character: StringName in affinity:
		GameState.add_affinity(character, int(affinity[character]))
	if start_quest != &"":
		GameState.start_quest(start_quest)
	if finish_quest != &"":
		GameState.finish_quest(finish_quest)
	for id: StringName in give_items:
		GameState.add_item(id, int(give_items[id]))
	if give_money != 0:
		GameState.add_money(give_money)
