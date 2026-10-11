extends CanvasLayer
## เมนูหยุดเกม (ESC / P)

var _stats_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var root := UIUtils.full_rect_root(self)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	UIUtils.dim_background(root, 0.6)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)
	var title := UIUtils.label("PAUSED", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_stats_label = UIUtils.label("", 18, Color(0.85, 0.85, 0.85))
	vb.add_child(_stats_label)
	var resume := UIUtils.button("Resume")
	resume.pressed.connect(toggle)
	vb.add_child(resume)
	var restart := UIUtils.button("Restart")
	restart.pressed.connect(_on_restart)
	vb.add_child(restart)
	var menu := UIUtils.button("Main Menu")
	menu.pressed.connect(GameState.go_to_menu)
	vb.add_child(menu)
	var quit := UIUtils.button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit)
	visible = false


## หยุดเกมอัตโนมัติเมื่อสลับไปหน้าต่างอื่น (Alt+Tab)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visible and not GameState.menu_open and not GameState.is_game_over:
		toggle()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.is_game_over or (GameState.menu_open and not visible):
			return
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	GameState.menu_open = visible
	get_tree().paused = visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	if visible:
		_stats_label.text = _stats_text()


func _stats_text() -> String:
	var p = GameState.player
	if not is_instance_valid(p):
		return ""
	var s = p.stats
	return "Damage x%.2f   Atk Speed x%.2f   Area x%.2f\nMove %.1f   Armor %.1f   Regen %.1f/s\nCrit %d%%  x%.2f   Luck %d%%   +%d proj" % [
		s.damage_mult, s.attack_speed_mult, s.area_mult, s.move_speed, s.armor, s.hp_regen,
		roundi(s.crit_chance * 100), s.crit_mult, roundi(s.luck * 100), s.projectile_bonus]


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
