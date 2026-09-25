class_name MainMenu
extends CanvasLayer
## Pause menu (field): items, equipment, gems, skill tree, status, formation, quests,
## options and saving. Built in code with UIKit / ListMenu; pauses the tree while open.

signal closed

enum Screen { ROOT, ITEMS, ITEM_TARGET, MEMBER, EQUIP_SLOTS, EQUIP_PICK, GEM_SOCKETS, GEM_PICK, TREE,
	STATUS, FORMATION, QUESTS, OPTIONS, SAVE }

const SAVE_SLOTS := 3
const SLOT_NAMES := {ItemData.Kind.WEAPON: "Arma", ItemData.Kind.ARMOR: "Armadura", ItemData.Kind.ACCESSORY: "Acessório"}
const STAT_LABELS := {&"max_hp": "HP", &"max_mp": "MP", &"strength": "FOR", &"magic": "MAG", &"defense": "DEF",
	&"spirit": "ESP", &"speed": "VEL", &"luck": "SOR", &"precision": "PRE", &"evasion": "EVA"}

var _screen := Screen.ROOT
var _save_only := false
var _commands: ListMenu
var _content: Panel
var _list: ListMenu
var _sub: ListMenu
var _detail: Label
var _footer: Label
var _member: PartyMember
var _member_action := ""  # which command asked for a member
var _item: ItemData
var _slot_kind: ItemData.Kind
var _socket := 0
var _formation_first := -1
var _options: OptionsPanel


static func open(tree: SceneTree) -> MainMenu:
	var menu := MainMenu.new()
	tree.root.add_child(menu)
	return menu


## Save points: the menu opens straight on the save slots and closes when leaving them.
static func open_save(tree: SceneTree) -> MainMenu:
	var menu := open(tree)
	menu._save_only = true
	menu._show_save()
	return menu


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_commands = ListMenu.create(self, Rect2(8, 8, 150, 256))
	_commands.set_entries([
		{"text": "Itens", "id": "items"}, {"text": "Equipar", "id": "equip"}, {"text": "Gemas", "id": "gems"},
		{"text": "Árvore", "id": "tree"}, {"text": "Status", "id": "status"}, {"text": "Formação", "id": "formation"},
		{"text": "Missões", "id": "quests"}, {"text": "Opções", "id": "options"}, {"text": "Salvar", "id": "save"},
		{"text": "Fechar", "id": "close"},
	])
	var info := UIKit.panel(self, Rect2(8, 270, 150, 82))
	_footer = UIKit.label(info, Vector2(8, 6), "", UIKit.TEXT)
	_footer.size = Vector2(134, 70)
	_content = UIKit.panel(self, Rect2(164, 8, 468, 344))
	_show_party()


func close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


# ---------- screens ----------

func _clear_content() -> void:
	UIKit.clear(_content)
	_list = null
	_sub = null
	_detail = null


func _update_footer() -> void:
	var minutes := int(GameState.play_time / 60.0)
	_footer.text = "Moedas\n%d\nTempo %d:%02d" % [GameState.money, minutes / 60, minutes % 60]


func _show_party() -> void:
	_screen = Screen.ROOT
	_clear_content()
	_update_footer()
	for i in GameState.party.size():
		var m := GameState.party[i]
		var y := 6 + i * 84
		if m.data.battle_sheet:
			UIKit.sprite_frame(_content, Vector2(4, y + 4), m.data, 0)
		var active := "" if i < Battle.ACTIVE_MAX else "  (reserva)"
		UIKit.label(_content, Vector2(72, y + 4), "%s   Nv. %d%s" % [m.data.display_name, m.level, active], UIKit.GOLD)
		UIKit.label(_content, Vector2(72, y + 22), "HP %d/%d    MP %d/%d" % [m.hp, m.max_hp(), m.mp, m.max_mp()],
			UIKit.TEXT if m.is_alive() else UIKit.BAD)
		UIKit.label(_content, Vector2(72, y + 40), "Próx. nível: %d XP    PH: %d    Éter: %d%%" % [
			PartyMember.xp_to_next(m.level) - m.xp, m.skill_points, m.aether], UIKit.DIM)


func _pick_member(action: String) -> void:
	_member_action = action
	_screen = Screen.MEMBER
	_clear_content()
	_list = ListMenu.create(_content, Rect2(8, 8, 452, 120), "Quem?")
	_list.set_entries(GameState.party.map(func(m: PartyMember) -> Dictionary:
		# Guests (Gerd in the prologue) only show their status.
		var guest_locked := m.data.guest and action != "status"
		return {"text": "%s  Nv. %d" % [m.data.display_name, m.level], "member": m, "enabled": not guest_locked,
			"note": "convidado" if m.data.guest else "HP %d/%d" % [m.hp, m.max_hp()]}))


func _show_items() -> void:
	_screen = Screen.ITEMS
	_clear_content()
	_list = ListMenu.create(_content, Rect2(8, 8, 452, 250), "Itens")
	var entries := []
	for item in GameState.items_of_kind(ItemData.Kind.CONSUMABLE):
		entries.append({"text": item.display_name, "item": item, "icon": item.icon_index,
			"note": "×%d" % GameState.count(item.id), "enabled": item.field_usable})
	for kind in [ItemData.Kind.WEAPON, ItemData.Kind.ARMOR, ItemData.Kind.ACCESSORY, ItemData.Kind.KEY]:
		for item in GameState.items_of_kind(kind):
			entries.append({"text": item.display_name, "item": item, "icon": item.icon_index,
				"note": "×%d" % GameState.count(item.id), "enabled": false})
	if entries.is_empty():
		entries.append({"text": "Nenhum item", "enabled": false})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 264, 452, 72))
	_update_item_detail()


func _update_item_detail() -> void:
	if _detail and _list and _list.current().has("item"):
		_detail.text = (_list.current()["item"] as ItemData).description


func _show_item_target() -> void:
	_screen = Screen.ITEM_TARGET
	_sub = ListMenu.create(_content, Rect2(120, 60, 300, 110), _item.display_name + " em quem?")
	_sub.set_entries(GameState.party.map(func(m: PartyMember) -> Dictionary:
		return {"text": m.data.display_name, "member": m, "note": "HP %d/%d  MP %d" % [m.hp, m.max_hp(), m.mp]}))


func _show_equip_slots() -> void:
	_screen = Screen.EQUIP_SLOTS
	_clear_content()
	UIKit.label(_content, Vector2(10, 4), _member.data.display_name + " — Equipamento", UIKit.GOLD)
	_list = ListMenu.create(_content, Rect2(8, 24, 452, 76))
	var entries := []
	for kind in PartyMember.SLOT_KINDS:
		var item: ItemData = _member.equipment.get(kind)
		entries.append({"text": "%s: %s" % [SLOT_NAMES[kind], item.display_name if item else "—"], "kind": kind,
			"icon": item.icon_index if item else -1, "note": _sockets_note(item.gem_slots) if item else ""})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 106, 452, 230))
	_detail.text = _stats_text(_member, null)


static func _sockets_note(count: int) -> String:
	match count:
		0:
			return ""
		1:
			return "1 encaixe"
	return "%d encaixes" % count


func _show_equip_pick() -> void:
	_screen = Screen.EQUIP_PICK
	var entries := [{"text": "— Remover —", "item": null}]
	var kind := _slot_kind
	for item in GameState.items_of_kind(kind):
		if _member.can_equip(item):
			entries.append({"text": item.display_name, "item": item, "icon": item.icon_index, "note": "×%d" % GameState.count(item.id)})
	_sub = ListMenu.create(_content, Rect2(8, 106, 220, 230), SLOT_NAMES[kind])
	_sub.set_entries(entries)
	_detail.position = Vector2(236, 110)
	_detail.size = Vector2(224, 222)
	_update_equip_preview()


func _update_equip_preview() -> void:
	if _screen != Screen.EQUIP_PICK:
		return
	var item: ItemData = _sub.current().get("item")
	_detail.text = _stats_text(_member, item, _slot_kind, item == null)


## Stat listing; with a candidate item (or a removal) shows "old → new".
func _stats_text(m: PartyMember, candidate: ItemData, kind := ItemData.Kind.WEAPON, removing := false) -> String:
	var preview: PartyMember = null
	if candidate or removing:
		preview = PartyMember.from_dict(m.to_dict())
		if candidate:
			preview.equip(candidate)
		else:
			preview.unequip(kind)
	var lines := PackedStringArray()
	var atk := m.stat(&"strength") + m.weapon_attack()
	var atk_new := preview.stat(&"strength") + preview.weapon_attack() if preview else atk
	lines.append(_stat_line("ATQ", atk, atk_new))
	for name: StringName in STAT_LABELS:
		lines.append(_stat_line(STAT_LABELS[name], m.stat(name), preview.stat(name) if preview else m.stat(name)))
	return "\n".join(lines)


static func _stat_line(label: String, old: int, new: int) -> String:
	if old == new:
		return "%-4s %4d" % [label, old]
	return "%-4s %4d  →  %d  %s" % [label, old, new, "▲" if new > old else "▼"]


func _show_gem_sockets() -> void:
	_screen = Screen.GEM_SOCKETS
	_clear_content()
	UIKit.label(_content, Vector2(10, 4), _member.data.display_name + " — Gemas", UIKit.GOLD)
	_list = ListMenu.create(_content, Rect2(8, 24, 452, 130))
	var entries := []
	for i in _member.sockets.size():
		var gem := _member.sockets[i]
		entries.append({"text": "Encaixe %d: %s" % [i + 1, gem.item.display_name if gem else "vazio"], "socket": i,
			"icon": gem.item.icon_index if gem else -1, "note": _gem_note(gem) if gem else ""})
	if entries.is_empty():
		entries.append({"text": "Nenhum encaixe — equipe peças com encaixes", "enabled": false})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 160, 452, 176))
	_update_gem_detail()


static func _gem_note(gem: GemInstance) -> String:
	return "Nv. %d  %s" % [gem.level(), "MÁX" if gem.is_mastered() else "%d AP" % gem.ap_to_next()]


func _update_gem_detail() -> void:
	if _detail == null:
		return
	var gem: GemInstance = null
	if _screen == Screen.GEM_PICK:
		gem = _sub.current().get("gem")
	elif _list and _list.current().has("socket"):
		gem = _member.sockets[_list.current()["socket"]]
	if gem == null:
		_detail.text = "Gemas dão magias, atributos ou efeitos e sobem de nível com os Pontos de Éter das batalhas."
		return
	var skills := PackedStringArray(gem.skills().map(func(s: SkillData) -> String: return s.display_name))
	_detail.text = "%s — Nv. %d/%d\n%s\nTécnicas: %s" % [gem.item.display_name, gem.level(), gem.max_level(),
		gem.item.description, ", ".join(skills) if not skills.is_empty() else "—"]


func _show_gem_pick() -> void:
	_screen = Screen.GEM_PICK
	var entries := [{"text": "— Remover —", "gem": null}]
	for gem in GameState.gem_bag:
		entries.append({"text": gem.item.display_name, "gem": gem, "icon": gem.item.icon_index, "note": _gem_note(gem)})
	_sub = ListMenu.create(_content, Rect2(120, 40, 340, 150), "Bolsa de gemas")
	_sub.set_entries(entries)
	_update_gem_detail()


func _show_tree() -> void:
	_screen = Screen.TREE
	_clear_content()
	UIKit.label(_content, Vector2(10, 4), "%s — Árvore   (PH: %d)" % [_member.data.display_name, _member.skill_points], UIKit.GOLD)
	_list = ListMenu.create(_content, Rect2(8, 24, 452, 150))
	var tree := _member.tree()
	var entries := []
	if tree:
		for node in tree.nodes:
			var learned := node.id in _member.learned
			entries.append({"text": ("✓ " if learned else "") + node.display_name, "node": node,
				"note": "" if learned else "%d PH" % node.cost, "enabled": learned or _member.can_learn(node),
				"color": UIKit.GOOD if learned else (UIKit.TEXT if _member.can_learn(node) else UIKit.DIM)})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 180, 452, 156))
	_update_tree_detail()


func _update_tree_detail() -> void:
	if _detail == null or not _list.current().has("node"):
		return
	var node: SkillTreeNode = _list.current()["node"]
	var reqs := PackedStringArray()
	for req in node.requires:
		var r := _member.tree().node(req)
		reqs.append(r.display_name if r else str(req))
	_detail.text = "%s\n%s\nCusto: %d PH%s" % [node.display_name, node.description, node.cost,
		("\nRequer: " + ", ".join(reqs)) if not reqs.is_empty() else ""]


func _show_status() -> void:
	_screen = Screen.STATUS
	_clear_content()
	var m := _member
	if m.data.battle_sheet:
		UIKit.sprite_frame(_content, Vector2(8, 8), m.data, m.data.idle_frame)
	UIKit.label(_content, Vector2(80, 8), "%s   Nv. %d" % [m.data.display_name, m.level], UIKit.GOLD)
	UIKit.label(_content, Vector2(80, 26), "XP para o próximo nível: %d" % (PartyMember.xp_to_next(m.level) - m.xp), UIKit.DIM)
	UIKit.label(_content, Vector2(80, 44), "HP %d/%d   MP %d/%d   Éter %d%%" % [m.hp, m.max_hp(), m.mp, m.max_mp(), m.aether])
	var stats := _detail_label(Rect2(8, 80, 200, 256))
	stats.text = _stats_text(m, null)
	var right := _detail_label(Rect2(216, 80, 244, 256))
	var gear := PackedStringArray()
	for kind in PartyMember.SLOT_KINDS:
		var item: ItemData = m.equipment.get(kind)
		gear.append("%s: %s" % [SLOT_NAMES[kind], item.display_name if item else "—"])
	var skills := PackedStringArray(m.all_skills().map(func(s: SkillData) -> String: return s.display_name))
	right.text = "\n".join(gear) + "\n\nTécnicas:\n" + ", ".join(skills) + ("\n\nEspecial: " + m.data.special.display_name if m.data.special else "")


func _show_formation() -> void:
	_screen = Screen.FORMATION
	_clear_content()
	_list = ListMenu.create(_content, Rect2(8, 8, 452, 130), "Formação (os 3 primeiros lutam)")
	var entries := []
	for i in GameState.party.size():
		var m := GameState.party[i]
		entries.append({"text": ("● " if i == _formation_first else "") + m.data.display_name,
			"note": "convidado" if m.data.guest else ("ativo" if i < Battle.ACTIVE_MAX else "reserva"),
			"enabled": not m.data.guest})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 144, 452, 60))
	_detail.text = "Escolha dois personagens para trocar de posição."


func _show_quests() -> void:
	_screen = Screen.QUESTS
	_clear_content()
	_list = ListMenu.create(_content, Rect2(8, 8, 452, 130), "Missões")
	var entries := []
	for id: StringName in GameState.quests:
		var quest := DataRegistry.quest(id)
		if quest:
			var state := GameState.quest_state(id)
			entries.append({"text": ("★ " if quest.main_story else "") + quest.title, "quest": quest,
				"note": {"active": "em andamento", "ready": "entregar", "done": "concluída"}.get(state, ""),
				"color": UIKit.DIM if state == "done" else UIKit.TEXT})
	if entries.is_empty():
		entries.append({"text": "Nenhuma missão ainda", "enabled": false})
	_list.set_entries(entries, true)
	_detail = _detail_label(Rect2(8, 144, 452, 192))
	_update_quest_detail()


func _update_quest_detail() -> void:
	if _detail == null or not _list.current().has("quest"):
		return
	var quest: QuestData = _list.current()["quest"]
	var lines := PackedStringArray([quest.description, ""])
	for i in quest.objective_ids.size():
		var done := GameState.is_objective_done(quest.id, quest.objective_ids[i])
		lines.append(("✓ " if done else "○ ") + quest.objective_texts[i])
	_detail.text = "\n".join(lines)


func _show_save() -> void:
	_screen = Screen.SAVE
	_clear_content()
	_list = ListMenu.create(_content, Rect2(8, 8, 452, 90), "Salvar em qual espaço?")
	_list.set_entries(save_slot_entries())
	_detail = _detail_label(Rect2(8, 104, 452, 60))


static func save_slot_entries() -> Array:
	var entries := []
	for slot in range(1, SAVE_SLOTS + 1):
		var data := SaveManager.read_save(slot)
		if data.is_empty():
			entries.append({"text": "Espaço %d — vazio" % slot, "slot": slot})
		else:
			var party: Array = data["state"].get("party", [])
			var level := int(party[0]["level"]) if not party.is_empty() else 1
			var minutes := int(float(data["state"].get("play_time", 0.0)) / 60.0)
			entries.append({"text": "Espaço %d — Nv. %d  %d:%02d" % [slot, level, minutes / 60, minutes % 60], "slot": slot,
				"note": str(data.get("saved_at", "")).replace("T", " ").left(16)})
	return entries


func _show_options() -> void:
	_screen = Screen.OPTIONS
	_options = OptionsPanel.new()
	_options.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_options)
	_options.closed.connect(func() -> void:
		_options.queue_free()
		_options = null
		_show_party())


func _detail_label(rect: Rect2) -> Label:
	var label := UIKit.label(_content, rect.position, "", UIKit.TEXT)
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", -3)  # 11 stat lines must fit the panels
	return label


# ---------- input ----------

func _unhandled_input(event: InputEvent) -> void:
	if _screen == Screen.OPTIONS:
		return
	var active := _active_list()
	if active and active.handle_navigation(event):
		get_viewport().set_input_as_handled()
		_on_cursor_moved()
		return
	if UIKit.is_back(event) or (event.is_action_pressed(&"menu") and _screen == Screen.ROOT):
		get_viewport().set_input_as_handled()
		_back()
	elif event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		_confirm()


func _active_list() -> ListMenu:
	match _screen:
		Screen.ROOT:
			return _commands
		Screen.ITEM_TARGET, Screen.EQUIP_PICK, Screen.GEM_PICK:
			return _sub
	return _list


func _on_cursor_moved() -> void:
	match _screen:
		Screen.ITEMS:
			_update_item_detail()
		Screen.EQUIP_PICK:
			_update_equip_preview()
		Screen.GEM_SOCKETS, Screen.GEM_PICK:
			_update_gem_detail()
		Screen.TREE:
			_update_tree_detail()
		Screen.QUESTS:
			_update_quest_detail()


func _back() -> void:
	if _save_only:
		close()
		return
	match _screen:
		Screen.ROOT:
			close()
		Screen.ITEM_TARGET:
			_show_items()
		Screen.EQUIP_PICK:
			_show_equip_slots()
		Screen.GEM_PICK:
			_show_gem_sockets()
		Screen.EQUIP_SLOTS, Screen.GEM_SOCKETS, Screen.TREE, Screen.STATUS:
			_pick_member(_member_action)
		_:
			_formation_first = -1
			_show_party()


func _confirm() -> void:
	match _screen:
		Screen.ROOT:
			match _commands.current()["id"]:
				"items":
					_show_items()
				"equip", "gems", "tree", "status":
					_pick_member(_commands.current()["id"])
				"formation":
					_show_formation()
				"quests":
					_show_quests()
				"options":
					_show_options()
				"save":
					_show_save()
				"close":
					close()
		Screen.MEMBER:
			if not _list.is_enabled():
				return
			_member = _list.current()["member"]
			match _member_action:
				"equip":
					_show_equip_slots()
				"gems":
					_show_gem_sockets()
				"tree":
					_show_tree()
				"status":
					_show_status()
		Screen.ITEMS:
			if _list.is_enabled() and _list.current().has("item"):
				_item = _list.current()["item"]
				_show_item_target()
		Screen.ITEM_TARGET:
			var member: PartyMember = _sub.current()["member"]
			if use_item_on(_item, member):
				_show_items()
				if GameState.count(_item.id) > 0:
					_show_item_target()
		Screen.EQUIP_SLOTS:
			_slot_kind = _list.current()["kind"]
			_show_equip_pick()
		Screen.EQUIP_PICK:
			var item: ItemData = _sub.current().get("item")
			if item:
				GameState.equip(_member, item)
			else:
				GameState.unequip(_member, _slot_kind)
			_show_equip_slots()
		Screen.GEM_SOCKETS:
			if _list.current().has("socket"):
				_socket = _list.current()["socket"]
				_show_gem_pick()
		Screen.GEM_PICK:
			var gem: GemInstance = _sub.current().get("gem")
			if gem:
				GameState.socket_gem(_member, _socket, gem)
			else:
				GameState.unsocket_gem(_member, _socket)
			_show_gem_sockets()
		Screen.TREE:
			if _list.current().has("node") and _member.learn((_list.current()["node"] as SkillTreeNode).id):
				_show_tree()
		Screen.FORMATION:
			if not _list.is_enabled():
				return
			if _formation_first < 0:
				_formation_first = _list.index
			else:
				var a := _formation_first
				var b := _list.index
				var tmp := GameState.party[a]
				GameState.party[a] = GameState.party[b]
				GameState.party[b] = tmp
				_formation_first = -1
			_show_formation()
		Screen.SAVE:
			var err := SaveManager.save_game(_list.current()["slot"])
			_list.set_entries(save_slot_entries(), true)
			_detail.text = "Jogo salvo!" if err == OK else "Não foi possível salvar aqui."


## Uses a consumable outside battle. Returns false if it would do nothing.
static func use_item_on(item: ItemData, member: PartyMember) -> bool:
	if not item.field_usable or GameState.count(item.id) <= 0:
		return false
	var changed := false
	if item.revive_percent > 0.0 and not member.is_alive():
		member.hp = maxi(1, roundi(member.max_hp() * item.revive_percent))
		changed = true
	elif member.is_alive():
		if item.heal_hp > 0 and member.hp < member.max_hp():
			member.hp = mini(member.max_hp(), member.hp + item.heal_hp)
			changed = true
		if item.heal_mp > 0 and member.mp < member.max_mp():
			member.mp = mini(member.max_mp(), member.mp + item.heal_mp)
			changed = true
	if changed:
		GameState.remove_item(item.id)
	return changed
