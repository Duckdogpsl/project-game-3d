extends Node
## สถานะเกมกลาง (Autoload ชื่อ "GameState")
## เก็บ เลเวล / XP / ทอง / เวลา / จำนวนศัตรูที่ฆ่า และส่งสัญญาณให้ UI

signal level_up_requested
signal chest_opened
signal boss_spawned(boss_name: String)
signal game_over(won: bool)

## เวลาที่ต้องเอาชีวิตรอดเพื่อชนะ (วินาที) 600 = 10 นาที
@export var run_duration: float = 600.0

var level: int = 1
var xp: float = 0.0
var xp_to_next: float = 5.0
var gold: int = 0
var kills: int = 0
var chests_opened: int = 0
var elapsed: float = 0.0
var is_game_over: bool = false
var menu_open: bool = false
var intro_playing: bool = false   ## ระหว่างคัตซีน: ไม่นับเวลา ไม่เกิดมอน
var player = null  # อ้างอิงถึง Player (ตั้งค่าโดย player.gd)
## ตัวละครที่เลือกจากหน้าเมนู (ไม่ถูกรีเซ็ตตอนเริ่มเกมใหม่)
var selected_character: Resource = null

const MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"


func _ready() -> void:
	_setup_input()
	reset()


func reset() -> void:
	level = 1
	xp = 0.0
	xp_to_next = calc_xp_needed(1)
	gold = 0
	kills = 0
	chests_opened = 0
	elapsed = 0.0
	is_game_over = false
	menu_open = false
	intro_playing = false
	player = null


func _process(delta: float) -> void:
	if is_game_over or intro_playing or not is_instance_valid(player):
		return
	elapsed += delta
	if elapsed >= run_duration:
		trigger_game_over(true)


# ---------------- XP / Level ----------------
## สูตร XP ที่ต้องใช้ต่อเลเวล — ปรับความเร็วการเลเวลอัปได้ที่นี่
func calc_xp_needed(lv: int) -> float:
	return 5.0 + (lv - 1) * 4.0 + pow(lv - 1, 1.5)


func add_xp(amount: float) -> void:
	if is_game_over:
		return
	var mult: float = 1.0
	if is_instance_valid(player):
		mult = player.stats.xp_mult
	xp += amount * mult
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = calc_xp_needed(level)
		level_up_requested.emit()


# ---------------- Gold / Chest ----------------
func add_gold(amount: int) -> void:
	gold += amount


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


## ราคาหีบ เพิ่มขึ้นทุกครั้งที่เปิด
func get_chest_cost() -> int:
	return 10 + chests_opened * 8


func open_chest() -> void:
	chests_opened += 1
	chest_opened.emit()


func register_kill() -> void:
	kills += 1


func trigger_game_over(won: bool) -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit(won)


# ---------------- Scene ----------------
func start_game(character: Resource) -> void:
	selected_character = character
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


# ---------------- Input ----------------
## ตั้งปุ่มควบคุมด้วยโค้ด (แก้ปุ่มได้ที่นี่ หรือใน Project Settings > Input Map)
func _setup_input() -> void:
	_add_keys("move_forward", [KEY_W, KEY_UP])
	_add_keys("move_back", [KEY_S, KEY_DOWN])
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE])
	_add_keys("slide", [KEY_SHIFT, KEY_CTRL])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])


func _add_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
