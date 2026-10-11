extends CanvasLayer
## หน้าจอจบเกม (ตาย / รอดครบเวลา)

var _title: Label
var _stats: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var root := UIUtils.full_rect_root(self)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	UIUtils.dim_background(root, 0.75)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	center.add_child(vb)
	_title = UIUtils.label("", 64)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_stats = UIUtils.label("", 24)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_stats)
	var restart := UIUtils.button("Play Again")
	restart.pressed.connect(_on_restart)
	vb.add_child(restart)
	var menu := UIUtils.button("Main Menu")
	menu.pressed.connect(GameState.go_to_menu)
	vb.add_child(menu)
	var quit := UIUtils.button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit)
	visible = false
	GameState.game_over.connect(_on_game_over)


func _on_game_over(won: bool) -> void:
	visible = true
	GameState.menu_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title.text = "YOU SURVIVED!" if won else "YOU DIED"
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if won else Color(1, 0.3, 0.3))
	var t := GameState.elapsed
	_stats.text = "Time  %02d:%02d\nLevel  %d\nKills  %d\nGold  %d" % [
		floori(t / 60.0), floori(t) % 60, GameState.level, GameState.kills, GameState.gold]


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
