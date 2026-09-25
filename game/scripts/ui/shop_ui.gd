class_name ShopUI
extends CanvasLayer
## Shop screen: buy from `stock`, sell from the inventory at half price. Gems bought go to
## the gem bag. await run() returns when the player leaves.

signal closed

enum Mode { TOP, BUY, SELL }

const SELL_SHARE := 0.5

var _mode := Mode.TOP
var _stock: Array[ItemData] = []
var _menu: ListMenu
var _list: ListMenu
var _money: Label
var _info: Label
var _title: String


func run(title: String, stock: Array[ItemData]) -> void:
	_title = title if title != "" else "Loja"
	_stock = stock
	layer = 20
	var header := UIKit.panel(self, Rect2(8, 8, 624, 26))
	UIKit.label(header, Vector2(8, 2), _title, UIKit.GOLD)
	_money = UIKit.label(header, Vector2(440, 2), "", UIKit.TEXT, 176)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_menu = ListMenu.create(self, Rect2(8, 40, 150, 70))
	_menu.set_entries([{"text": "Comprar", "id": "buy"}, {"text": "Vender", "id": "sell"}, {"text": "Sair", "id": "exit"}])
	_list = ListMenu.create(self, Rect2(164, 40, 468, 234))
	_list.hide()
	var info_panel := UIKit.panel(self, Rect2(8, 280, 624, 72))
	_info = UIKit.label(info_panel, Vector2(10, 6), "", UIKit.TEXT)
	_info.size = Vector2(604, 60)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh()
	await closed


func buy(item: ItemData) -> bool:
	if GameState.money < item.price:
		return false
	GameState.add_money(-item.price)
	GameState.add_item(item.id)
	return true


func sell(item: ItemData) -> bool:
	if item.kind == ItemData.Kind.KEY or not GameState.remove_item(item.id):
		return false
	GameState.add_money(sell_price(item))
	return true


static func sell_price(item: ItemData) -> int:
	return floori(item.price * SELL_SHARE)


func _refresh() -> void:
	_money.text = "%d moedas" % GameState.money
	match _mode:
		Mode.BUY:
			var entries := []
			for item in _stock:
				var owned := GameState.count(item.id) if item.kind != ItemData.Kind.GEM else GameState.gem_bag.filter(func(g: GemInstance) -> bool: return g.item == item).size()
				entries.append({"text": "%s  (tem %d)" % [item.display_name, owned], "item": item, "icon": item.icon_index,
					"note": "%d" % item.price, "enabled": GameState.money >= item.price})
			_list.title = "Comprar"
			_list.set_entries(entries, true)
		Mode.SELL:
			var entries := []
			for id: StringName in GameState.inventory:
				var item := DataRegistry.item(id)
				if item and item.kind != ItemData.Kind.KEY:
					entries.append({"text": "%s  ×%d" % [item.display_name, GameState.count(id)], "item": item,
						"icon": item.icon_index, "note": "%d" % sell_price(item)})
			entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["text"] < b["text"])
			if entries.is_empty():
				entries.append({"text": "Nada para vender", "enabled": false})
			_list.title = "Vender"
			_list.set_entries(entries, true)
	_update_info()


func _update_info() -> void:
	if _mode == Mode.TOP or not _list.current().has("item"):
		_info.text = "Bem-vindo! Dê uma olhada." if _mode == Mode.TOP else ""
		return
	var item: ItemData = _list.current()["item"]
	var who := ""
	if item.is_equipment():
		var names := PackedStringArray()
		for member in GameState.party:
			if member.can_equip(item):
				names.append(member.data.display_name)
		who = "\nPode equipar: " + (", ".join(names) if not names.is_empty() else "ninguém do grupo")
	_info.text = item.description + who


func _unhandled_input(event: InputEvent) -> void:
	var active := _menu if _mode == Mode.TOP else _list
	if active.handle_navigation(event):
		get_viewport().set_input_as_handled()
		_update_info()
		return
	if UIKit.is_back(event):
		AudioManager.play_sfx(&"ui_cancel")
		get_viewport().set_input_as_handled()
		if _mode == Mode.TOP:
			closed.emit()
		else:
			_mode = Mode.TOP
			_list.hide()
			_refresh()
	elif event.is_action_pressed(&"confirm"):
		AudioManager.play_sfx(&"ui_confirm")
		get_viewport().set_input_as_handled()
		_confirm()


func _confirm() -> void:
	match _mode:
		Mode.TOP:
			match _menu.current()["id"]:
				"buy":
					_mode = Mode.BUY
				"sell":
					_mode = Mode.SELL
				"exit":
					closed.emit()
					return
			_list.index = 0
			_list.show()
			_refresh()
		Mode.BUY:
			if _list.is_enabled() and buy(_list.current()["item"]):
				_refresh()
		Mode.SELL:
			if _list.is_enabled() and sell(_list.current()["item"]):
				_refresh()
