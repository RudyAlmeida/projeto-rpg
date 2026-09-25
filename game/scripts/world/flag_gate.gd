class_name FlagGate
extends RefCounted
## Story gating shared by map nodes: shown only when `show_if` is set (empty = always) and
## `hide_if` is not.


static func passes(show_if: StringName, hide_if: StringName) -> bool:
	if show_if != &"" and not GameState.get_flag(show_if):
		return false
	if hide_if != &"" and GameState.get_flag(hide_if):
		return false
	return true


## Applies the gate to a node with a collision (NPCs, triggers, warps): hidden and inert
## while the gate is closed.
static func apply(node: Node, show_if: StringName, hide_if: StringName) -> void:
	var open := passes(show_if, hide_if)
	if node is CanvasItem:
		(node as CanvasItem).visible = open
	node.process_mode = Node.PROCESS_MODE_INHERIT if open else Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", not open)
