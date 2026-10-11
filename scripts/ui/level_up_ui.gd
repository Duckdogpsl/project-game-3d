extends CanvasLayer
## หน้าจอเลือกอัปเกรด (ตอนเลเวลอัป และตอนเปิดหีบ) — กด 1/2/3 หรือคลิกการ์ด

@export var choice_count: int = 3

var _queue: Array = []
var _choices: Array = []
var _title: Label
var _cards: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := UIUtils.full_rect_root(self)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	UIUtils.dim_background(root, 0.65)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	center.add_child(vb)
	_title = UIUtils.label("LEVEL UP!", 48, Color(1, 0.9, 0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 24)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_cards)
	var hint := UIUtils.label("Click a card or press 1 / 2 / 3", 18, Color(1, 1, 1, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	visible = false

	GameState.level_up_requested.connect(_enqueue.bind("level"))
	GameState.chest_opened.connect(_enqueue.bind("chest"))


func _enqueue(kind: String) -> void:
	_queue.append(kind)
	if not visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty() or GameState.is_game_over or not is_instance_valid(GameState.player):
		_queue.clear()
		visible = false
		GameState.menu_open = false
		if not GameState.is_game_over:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	var kind: String = _queue.pop_front()
	visible = true
	GameState.menu_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title.text = "TREASURE CHEST!" if kind == "chest" else "LEVEL UP!  (Lv %d)" % GameState.level
	_choices = UpgradeDB.roll_choices(GameState.player, choice_count, kind == "chest")
	for c in _cards.get_children():
		c.queue_free()
	for i in _choices.size():
		_cards.add_child(_make_card(_choices[i], i))
	if _choices.is_empty():
		_show_next()


func _make_card(choice: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(250, 320)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_color = choice["color"]
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(12)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.2, 0.3, 0.95)
	hover.set_border_width_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16
	vb.offset_right = -16
	vb.offset_top = 16
	vb.offset_bottom = -16
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 14)
	btn.add_child(vb)

	vb.add_child(UIUtils.label("[%d]  %s" % [index + 1, choice["rarity_name"]], 16, choice["color"]))
	var title := UIUtils.label(choice["title"], 28)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(title)
	var desc := UIUtils.label(choice["desc"], 20, Color(0.9, 0.9, 0.9))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	btn.pressed.connect(_pick.bind(index))
	return btn


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < _choices.size():
			_pick(idx)
			get_viewport().set_input_as_handled()


func _pick(index: int) -> void:
	if index >= _choices.size():
		return
	UpgradeDB.apply_choice(GameState.player, _choices[index])
	_choices = []
	_show_next()
