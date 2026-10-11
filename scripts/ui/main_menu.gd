extends Control
## หน้าเมนูหลัก: PLAY -> เลือกตัวละคร -> เริ่มเกม
## เพิ่มตัวละครใหม่: สร้าง .tres ใน resources/characters/ แล้วเพิ่มลงใน CHARACTERS

const CHARACTERS := [
	preload("res://resources/characters/barbarian.tres"),
	preload("res://resources/characters/mage.tres"),
]

var _main_panel: Control
var _select_panel: Control
var _previews: Array = []


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.1, 0.16)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_main_panel = _build_main_panel()
	add_child(_main_panel)
	_select_panel = _build_select_panel()
	add_child(_select_panel)
	_show_main()


func _process(delta: float) -> void:
	for p in _previews:
		p.rotation.y += delta * 0.8


# ---------------- หน้าแรก ----------------
func _build_main_panel() -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	center.add_child(vb)

	var title := UIUtils.label("DAWNBREAKER KNIGHT", 84, Color(1, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UIUtils.label("survive 10 minutes", 24, Color(0.8, 0.8, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(_spacer(30))

	var play := UIUtils.button("PLAY", 32)
	play.custom_minimum_size = Vector2(300, 70)
	play.pressed.connect(_show_select)
	vb.add_child(play)
	var quit := UIUtils.button("QUIT", 24)
	quit.custom_minimum_size = Vector2(300, 56)
	quit.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit)
	play.grab_focus.call_deferred()
	return center


# ---------------- หน้าเลือกตัวละคร ----------------
func _build_select_panel() -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	center.add_child(vb)

	var title := UIUtils.label("CHOOSE YOUR HERO", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	vb.add_child(row)
	for c in CHARACTERS:
		row.add_child(_make_character_card(c))

	var back := UIUtils.button("BACK", 22)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_main)
	vb.add_child(back)
	return center


func _make_character_card(c: CharacterData) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.15, 0.22)
	sb.border_color = c.theme_color
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	vb.add_child(_make_preview(c))

	var name_label := UIUtils.label(c.display_name.to_upper(), 34, c.theme_color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_label)

	var desc := UIUtils.label(c.description, 17, Color(0.85, 0.85, 0.9))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(300, 0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(desc)

	var s := c.base_stats
	var weapon_name: String = UpgradeDB.WEAPONS[c.starting_weapon]["name"] if UpgradeDB.WEAPONS.has(c.starting_weapon) else c.starting_weapon
	var stats := UIUtils.label("HP %d   Speed %.1f   Armor %d\nWeapon: %s" % [s.max_hp, s.move_speed, s.armor, weapon_name], 16, Color(1, 1, 1, 0.75))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stats)

	var btn := UIUtils.button("SELECT", 24)
	btn.pressed.connect(GameState.start_game.bind(c))
	vb.add_child(btn)
	return panel


## พรีวิวโมเดล 3D หมุนได้ ใน SubViewport
func _make_preview(c: CharacterData) -> Control:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(300, 300)
	container.stretch = true
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(300, 300)
	container.add_child(vp)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 30, 0)
	vp.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.8)
	vp.add_child(env)

	var cam := Camera3D.new()
	cam.transform = Transform3D(Basis(), Vector3(0, 1.3, 3.4)).looking_at(Vector3(0, 0.95, 0))
	cam.fov = 45
	vp.add_child(cam)

	var pivot := Node3D.new()
	vp.add_child(pivot)
	if c.model:
		var m: Node3D = c.model.instantiate()
		m.scale = Vector3.ONE * c.model_scale
		pivot.add_child(m)
	_previews.append(pivot)
	return container


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _show_main() -> void:
	_main_panel.visible = true
	_select_panel.visible = false


func _show_select() -> void:
	_main_panel.visible = false
	_select_panel.visible = true
