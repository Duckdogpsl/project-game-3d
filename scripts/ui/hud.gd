extends CanvasLayer
## HUD: เลือด, XP, เลเวล, เวลา, ทอง, kill, ความเร็ว, รายการอาวุธ

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _stats_label: Label
var _weapons_label: Label
var _speed_label: Label
var _banner: Label
var _hint: Label
var _flash: ColorRect
var _last_hp: float = -1.0
var _banner_time: float = 0.0


func _ready() -> void:
	var root := UIUtils.full_rect_root(self)

	_flash = ColorRect.new()
	_flash.color = Color(1, 0, 0, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	# XP bar ด้านบนสุด
	_xp_bar = UIUtils.bar(Color(0.3, 0.7, 1.0), 16)
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_left = 10
	_xp_bar.offset_right = -10
	_xp_bar.offset_top = 6
	_xp_bar.offset_bottom = 22
	root.add_child(_xp_bar)

	_level_label = UIUtils.label("Lv 1", 18)
	_level_label.position = Vector2(16, 24)
	root.add_child(_level_label)

	# HP
	_hp_bar = UIUtils.bar(Color(0.9, 0.2, 0.25), 26)
	_hp_bar.position = Vector2(16, 52)
	_hp_bar.size = Vector2(320, 26)
	root.add_child(_hp_bar)
	_hp_label = UIUtils.label("100 / 100", 18)
	_hp_label.position = Vector2(24, 53)
	root.add_child(_hp_label)

	# เวลา (กลางบน)
	_time_label = UIUtils.label("00:00", 34)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_left = -150
	_time_label.offset_right = 150
	_time_label.offset_top = 26
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_time_label)

	# สถิติ (ขวาบน)
	_stats_label = UIUtils.label("", 20)
	_stats_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stats_label.offset_left = -300
	_stats_label.offset_right = -16
	_stats_label.offset_top = 28
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_stats_label)

	# อาวุธ (ซ้ายล่าง)
	_weapons_label = UIUtils.label("", 18, Color(1, 0.9, 0.5))
	_weapons_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_weapons_label.offset_left = 16
	_weapons_label.offset_top = -170
	_weapons_label.offset_right = 400
	_weapons_label.offset_bottom = -16
	_weapons_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	root.add_child(_weapons_label)

	# ความเร็ว (ขวาล่าง)
	_speed_label = UIUtils.label("", 26, Color(0.6, 1, 1))
	_speed_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_speed_label.offset_left = -300
	_speed_label.offset_top = -60
	_speed_label.offset_right = -16
	_speed_label.offset_bottom = -16
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_speed_label)

	# ป้ายเตือนบอส (กลางจอ)
	_banner = UIUtils.label("", 48, Color(1, 0.3, 0.3))
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -400
	_banner.offset_right = 400
	_banner.offset_top = -200
	_banner.offset_bottom = -130
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_banner)

	_hint = UIUtils.label("WASD move · Mouse look · SPACE jump (hold = bunny hop) · SHIFT slide · ESC pause", 18, Color(1, 1, 1, 0.8))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -500
	_hint.offset_right = 500
	_hint.offset_top = -40
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	# ปุ่ม Pause (คลิกได้เมื่อเมาส์ไม่ได้ถูกล็อก หรือกด ESC / P)
	var pause_btn := Button.new()
	pause_btn.text = "II  PAUSE (Esc)"
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -200
	pause_btn.offset_right = -16
	pause_btn.offset_top = 90
	pause_btn.offset_bottom = 130
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(_on_pause_pressed)
	root.add_child(pause_btn)

	GameState.boss_spawned.connect(_on_boss_spawned)


func _process(delta: float) -> void:
	var p = GameState.player
	if not is_instance_valid(p):
		return
	_hp_bar.max_value = p.stats.max_hp
	_hp_bar.value = p.hp
	_hp_label.text = "%d / %d" % [ceili(p.hp), roundi(p.stats.max_hp)]
	if _last_hp >= 0.0 and p.hp < _last_hp - 0.01:
		_flash.color.a = 0.3
	_last_hp = p.hp
	_flash.color.a = max(0.0, _flash.color.a - delta * 1.5)

	_xp_bar.max_value = GameState.xp_to_next
	_xp_bar.value = GameState.xp
	_level_label.text = "Lv %d" % GameState.level

	var t := GameState.elapsed
	var left: float = max(0.0, GameState.run_duration - t)
	_time_label.text = "%02d:%02d" % [floori(left / 60.0), floori(left) % 60]
	_stats_label.text = "Kills  %d\nGold  %d" % [GameState.kills, GameState.gold]
	_speed_label.text = "%s%.1f m/s" % ["SLIDE  " if p.is_sliding else "", p.get_speed()]

	var lines := PackedStringArray()
	for id in p.weapons:
		var w = p.weapons[id]
		lines.append("%s  Lv %d" % [w.display_name, w.level])
	_weapons_label.text = "\n".join(lines)

	if t > 20.0:
		_hint.modulate.a = max(0.0, _hint.modulate.a - delta)
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clamp(_banner_time, 0.0, 1.0)


func _on_pause_pressed() -> void:
	var menu := get_tree().current_scene.get_node_or_null("PauseMenu")
	if menu and not GameState.menu_open:
		menu.toggle()


func _on_boss_spawned(boss_name: String) -> void:
	_banner.text = "⚠ %s HAS APPEARED ⚠" % boss_name.to_upper()
	_banner_time = 4.0
