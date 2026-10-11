extends CanvasLayer
## คัตซีนเปิดเกม (Text Sequence + กล้องควงสว่านลงจากฟ้า)
## ลำดับ: จอดำ -> ข้อความทีละประโยค -> จอค่อยๆ สว่าง + กล้องหมุนลงมาหลังตัวละคร -> เปิด HUD/การควบคุม/นับเวลา
## กด Enter หรือ Esc เพื่อข้ามได้
## แก้ข้อความได้ที่ LINES, ปรับเวลาได้ใน Inspector

const THAI_FONT: FontFile = preload("res://assets/fonts/kanit_thai_500.woff2")
const LATIN_FONT: FontFile = preload("res://assets/fonts/kanit_latin_500.woff2")

const LINES := [
	"ณ อาณาจักรอโลเรีย...\nคริสตัลรุ่งอรุณได้แตกสลายลง",
	"ราตรีจึงกลายเป็นนิรันดร์\nและคลื่นอสูรแห่งป่าดำได้กลืนกินแผ่นดิน",
	"จงยืนหยัดต้านทานให้ถึงเวลาฟ้าสาง...\nอัศวินแห่งรุ่งอรุณ!",
]

@export var enabled: bool = true
@export_group("Text")
@export var line_fade_in: float = 0.7
@export var line_hold: float = 2.3        ## เวลาค้างข้อความ (รวมเฟดแล้วประมาณ 3.5 วิ/ประโยค)
@export var line_fade_out: float = 0.6
@export var start_delay: float = 0.6
@export_group("Camera")
@export var sky_height: float = 45.0       ## ความสูงกล้องตอนเริ่ม (Y 40-50)
@export var sky_radius: float = 16.0       ## ระยะห่างแนวราบตอนเริ่ม
@export var spiral_turns: float = 2.0      ## จำนวนรอบที่ควงสว่าน
@export var descent_time: float = 5.0
@export var black_fade_time: float = 1.2

var _t: float = 0.0
var _running: bool = false
var _overlay: ColorRect
var _label: Label
var _skip_hint: Label
var _cam: Camera3D
var _player = null
var _player_cam: Camera3D
var _text_end: float
var _end: float


func _ready() -> void:
	layer = 50
	_build_ui()
	if not enabled:
		visible = false
		return
	_text_end = start_delay + LINES.size() * (line_fade_in + line_hold + line_fade_out)
	_end = _text_end + descent_time
	_start.call_deferred()


func _build_ui() -> void:
	var thai: FontFile = THAI_FONT
	thai.fallbacks = [LATIN_FONT]

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", thai)
	_label.add_theme_font_size_override("font_size", 42)
	_label.add_theme_constant_override("line_spacing", 10)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	_label.modulate.a = 0.0
	add_child(_label)

	_skip_hint = Label.new()
	_skip_hint.text = "Enter = ข้าม"
	_skip_hint.add_theme_font_override("font", thai)
	_skip_hint.add_theme_font_size_override("font_size", 18)
	_skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.offset_left = -200
	_skip_hint.offset_top = -50
	_skip_hint.offset_right = -24
	_skip_hint.offset_bottom = -16
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_skip_hint)


func _start() -> void:
	_player = GameState.player
	if not is_instance_valid(_player):
		_finish()
		return
	_running = true
	GameState.intro_playing = true
	GameState.menu_open = true              # กันไม่ให้กด Pause ระหว่างคัตซีน
	_set_hud_visible(false)
	# ล็อกการควบคุมตัวละคร
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_player_cam = _player.get_node("CameraPivot/SpringArm3D/Camera3D")
	# กล้องคัตซีน
	_cam = Camera3D.new()
	_cam.fov = _player_cam.fov
	_cam.far = 500.0
	get_tree().current_scene.add_child(_cam)
	_cam.current = true
	_update_camera(0.0)


func _process(delta: float) -> void:
	if not _running:
		return
	_t += delta
	_update_text()
	# จอดำค่อยๆ จางหลังข้อความจบ
	var fade_k: float = clamp((_t - _text_end) / black_fade_time, 0.0, 1.0)
	_overlay.color.a = 1.0 - fade_k
	_skip_hint.modulate.a = 1.0 - fade_k
	# กล้องเริ่มหมุนลงหลังข้อความจบ
	var cam_k: float = clamp((_t - _text_end) / descent_time, 0.0, 1.0)
	_update_camera(cam_k)
	if _t >= _end:
		_finish()


func _update_text() -> void:
	var line_len := line_fade_in + line_hold + line_fade_out
	var lt := _t - start_delay
	if lt < 0.0 or lt >= LINES.size() * line_len:
		_label.modulate.a = 0.0
		return
	var idx := int(lt / line_len)
	var local := lt - idx * line_len
	_label.text = LINES[idx]
	if local < line_fade_in:
		_label.modulate.a = local / line_fade_in
	elif local < line_fade_in + line_hold:
		_label.modulate.a = 1.0
	else:
		_label.modulate.a = 1.0 - (local - line_fade_in - line_hold) / line_fade_out


## k = 0 (บนฟ้า) -> 1 (หลังตัวละคร) : ควงสว่านรอบตัวละคร รัศมี/ความสูงลดลงเรื่อยๆ
func _update_camera(k: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_cam):
		return
	var focus: Vector3 = _player.global_position + Vector3.UP * 1.2
	var target: Transform3D = _player_cam.global_transform
	var off := target.origin - focus
	var r_end := Vector2(off.x, off.z).length()
	var a_end := atan2(off.x, off.z)
	var e := _ease_in_out(k)
	var a: float = lerp(a_end + TAU * spiral_turns, a_end, e)
	var r: float = lerp(sky_radius, r_end, e)
	var h: float = lerp(sky_height - focus.y, off.y, e)
	var pos := focus + Vector3(sin(a) * r, h, cos(a) * r)
	var xf := Transform3D(Basis(), pos).looking_at(focus, Vector3.UP)
	# ช่วงท้ายค่อยๆ เข้าหามุมกล้องจริงให้ต่อกันเนียน
	if k > 0.85:
		xf = xf.interpolate_with(target, (k - 0.85) / 0.15)
	_cam.global_transform = xf


func _ease_in_out(x: float) -> float:
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	_running = false
	visible = false
	if is_instance_valid(_player_cam):
		_player_cam.current = true
	if is_instance_valid(_cam):
		_cam.queue_free()
	if is_instance_valid(_player):
		_player.set_physics_process(true)
		_player.set_process_unhandled_input(true)
	_set_hud_visible(true)
	GameState.intro_playing = false
	GameState.menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_hud_visible(v: bool) -> void:
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.visible = v
