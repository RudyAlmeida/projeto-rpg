class_name NPC
extends StaticBody2D
## Talkable NPC. Uses the reference-sheet layout (columns down/left/up, right = left
## mirrored; `sheet_row` picks the character on multi-character sheets). Turns to face the
## player while talking. Dialogue comes from `dialogue_set` branches (story state) or the
## plain `dialogue` lines. Shopkeepers and innkeepers open their service afterwards.

enum Role { TALK, SHOP, INN }

const INN_TEXT := "Um quarto e uma refeição quente por %d moedas?"

@export var idle_sheet: Texture2D
@export var sheet_row := 0
@export var facing := Player.Facing.DOWN
@export var dialogue: Array[DialogueLine] = []
@export var dialogue_set: DialogueSet
@export var role := Role.TALK
@export var shop_stock: Array[ItemData] = []
@export var inn_price := 20
@export var display_name := ""
## Story gating (FlagGate): present only when `show_if_flag` is set and `hide_if_flag` is not.
@export var show_if_flag: StringName
@export var hide_if_flag: StringName

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_sprite.texture = idle_sheet
	_show_facing(facing)
	if show_if_flag != &"" or hide_if_flag != &"":
		GameState.flag_changed.connect(func(_name: StringName) -> void: FlagGate.apply(self, show_if_flag, hide_if_flag))
		FlagGate.apply(self, show_if_flag, hide_if_flag)


func interact(player: Node2D) -> void:
	_show_facing(Player.facing_for(player.global_position - global_position))
	var branch := dialogue_set.current_branch() if dialogue_set else null
	var lines: Array[DialogueLine] = branch.lines if branch else dialogue
	if not lines.is_empty():
		await DialogueManager.play(lines)
	if branch:
		branch.apply()
		if branch.cutscene:
			await branch.cutscene.play(get_parent())
	match role:
		Role.SHOP:
			await _open_shop(player)
		Role.INN:
			await _offer_rest(player)
	_show_facing(facing)


## Cutscenes: walk to `target` (local position) at `speed` px/s, bobbing.
func walk_to(target: Vector2, speed := 50.0) -> void:
	var delta := target - position
	if delta.length() < 1.0:
		return
	_show_facing(Player.facing_for(delta))
	var tween := create_tween()
	tween.tween_property(self, "position", target, delta.length() / speed)
	var bob := create_tween().set_loops(int(delta.length() / speed / 0.2) + 1)
	bob.tween_property(_sprite, "position:y", -2.0, 0.1)
	bob.tween_property(_sprite, "position:y", 0.0, 0.1)
	await tween.finished
	bob.kill()
	_sprite.position.y = 0.0


func face(dir: Player.Facing) -> void:
	_show_facing(dir)


func _open_shop(player: Node2D) -> void:
	var shop := ShopUI.new()
	get_tree().root.add_child(shop)
	if player is Player:
		player.locked = true
	await shop.run(display_name, shop_stock)
	shop.queue_free()
	if player is Player:
		player.locked = false


func _offer_rest(player: Node2D) -> void:
	var answer := await DialogueManager.ask(display_name, INN_TEXT % inn_price, ["Sim", "Não"] as Array[String])
	if answer != 0:
		return
	if GameState.money < inn_price:
		await DialogueManager.say(display_name, "Ah... parece que faltam moedas. Volte quando puder!")
		return
	GameState.add_money(-inn_price)
	if player is Player:
		player.locked = true
	await SceneManager.fade_out()
	for member in GameState.party:
		member.restore()
	await get_tree().create_timer(0.6).timeout
	await SceneManager.fade_in()
	if player is Player:
		player.locked = false
	await DialogueManager.say(display_name, "Bom dia! Todos descansados e prontos para a estrada.")


func _show_facing(dir: Player.Facing) -> void:
	var column := {Player.Facing.DOWN: 0, Player.Facing.LEFT: 1, Player.Facing.UP: 2, Player.Facing.RIGHT: 1}[dir] as int
	_sprite.region_rect = Rect2(column * Player.FRAME_SIZE, sheet_row * Player.FRAME_SIZE, Player.FRAME_SIZE, Player.FRAME_SIZE)
	_sprite.flip_h = dir == Player.Facing.RIGHT
