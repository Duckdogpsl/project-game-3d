extends CharacterBody3D
## ผู้เล่น: เดิน / กระโดด / สไลด์ / Bunny hop + กล้องบุคคลที่สาม + ระบบเลือด
## อาวุธทั้งหมดจะถูกใส่เป็นลูกของโหนด WeaponHolder

signal health_changed(hp: float, max_hp: float)
signal died

## ตัวละครที่ใช้ถ้าไม่ได้เลือกจากเมนู (เช่น กด F6 รันฉาก main ตรงๆ)
@export var default_character: CharacterData = preload("res://resources/characters/mage.tres")

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -1.3
@export var max_pitch: float = 0.35

@export_group("Movement Feel")
@export var gravity: float = 24.0
@export var ground_accel: float = 70.0
@export var air_accel: float = 25.0
@export var bhop_window: float = 0.12      ## เวลาหลังแตะพื้นที่ยังรักษาความเร็วไว้ได้
@export var bhop_gain: float = 1.06        ## คูณความเร็วทุกครั้งที่ bhop สำเร็จ
@export var max_speed: float = 32.0
@export var slide_boost: float = 5.0
@export var slide_friction: float = 0.9
@export var slide_slope_accel: float = 30.0
@export var invincibility_time: float = 0.5
@export var step_height: float = 0.45      ## ก้าวข้ามขอบ/ก้อนหินเตี้ยๆ ได้อัตโนมัติ

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var visual: Node3D = $Visual
@onready var weapon_holder: Node3D = $WeaponHolder

var stats: PlayerStats
var hp: float = 100.0
var weapons: Dictionary = {}   # id -> weapon node
var is_sliding: bool = false
var is_dead: bool = false

var _pitch: float = -0.35
var _iframe: float = 0.0
var _ground_time: float = 0.0
var _hurt_flash: float = 0.0
var _hurt_mat: StandardMaterial3D

# ---- โมเดลและแอนิเมชัน (ทำด้วยโค้ด เพราะโมเดลไม่มีกระดูก) ----
var character: CharacterData
var _model: Node3D
var _meshes: Array = []
var _arm_left: Node3D
var _arm_right: Node3D
var _hand: Node3D
var _anim_t: float = 0.0
var _attack_t: float = 0.0
var _face_dir: Vector3 = Vector3.ZERO
var _face_timer: float = 0.0


func _ready() -> void:
	character = GameState.selected_character if GameState.selected_character else default_character
	stats = character.base_stats.duplicate() if character.base_stats else PlayerStats.new()
	hp = stats.max_hp
	_load_model()
	add_to_group("player")
	GameState.player = self
	spring_arm.rotation.x = _pitch
	visual.rotation.y = camera_pivot.rotation.y + PI   # เริ่มเกมหันหลังให้กล้อง
	_hurt_mat = StandardMaterial3D.new()
	_hurt_mat.albedo_color = Color(1, 0.1, 0.1, 0.6)
	_hurt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hurt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if character.starting_weapon != "":
		UpgradeDB.give_weapon(self, character.starting_weapon)
	health_changed.emit(hp, stats.max_hp)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		spring_arm.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_iframe = max(0.0, _iframe - delta)
	if stats.hp_regen > 0.0 and hp < stats.max_hp:
		heal(stats.hp_regen * delta)

	var on_floor := is_on_floor()
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := Basis(Vector3.UP, camera_pivot.rotation.y) * Vector3(input_dir.x, 0.0, input_dir.y)
	var hvel := Vector3(velocity.x, 0.0, velocity.z)

	if not on_floor:
		velocity.y -= gravity * delta

	# ---- Slide ----
	if on_floor and Input.is_action_just_pressed("slide") and hvel.length() > 2.0:
		is_sliding = true
		hvel += hvel.normalized() * slide_boost
	if is_sliding and not Input.is_action_pressed("slide"):
		is_sliding = false

	# ---- Horizontal movement ----
	if on_floor and is_sliding:
		hvel *= max(0.0, 1.0 - slide_friction * delta)
		var n := get_floor_normal()
		hvel += Vector3(n.x, 0.0, n.z) * slide_slope_accel * delta  # ไถลลงเนินเร็วขึ้น
		hvel += wish_dir * air_accel * 0.3 * delta
		if hvel.length() < 2.0:
			is_sliding = false
	elif on_floor and _ground_time > bhop_window:
		hvel = hvel.move_toward(wish_dir * stats.move_speed, ground_accel * delta)
	else:
		# ควบคุมกลางอากาศ: เปลี่ยนทิศได้แต่ไม่เร่งเกินความเร็วเดิม
		var new_vel := hvel + wish_dir * air_accel * delta
		var limit: float = max(hvel.length(), stats.move_speed)
		if new_vel.length() > limit:
			new_vel = new_vel.normalized() * limit
		hvel = new_vel

	# ---- Jump / Bunny hop (กดค้างเพื่อ bhop อัตโนมัติ) ----
	if on_floor and Input.is_action_pressed("jump"):
		velocity.y = stats.jump_velocity
		if _ground_time <= bhop_window or is_sliding:
			hvel *= bhop_gain
		is_sliding = false

	if hvel.length() > max_speed:
		hvel = hvel.normalized() * max_speed
	velocity.x = hvel.x
	velocity.z = hvel.z
	var was_on_floor := is_on_floor()
	move_and_slide()
	if was_on_floor and is_on_wall():
		_try_step_up(hvel * delta)

	_ground_time = _ground_time + delta if is_on_floor() else 0.0
	_update_visual(hvel, delta)

	if global_position.y < -30.0:
		global_position = Vector3(0, 3, 0)
		velocity = Vector3.ZERO


## ก้าวขึ้นขอบเตี้ย: ถ้าข้างหน้าติด แต่ยกตัวขึ้น step_height แล้วไปต่อได้ ให้ยกขึ้น
func _try_step_up(motion: Vector3) -> void:
	if motion.length() < 0.001:
		return
	var up := Vector3.UP * step_height
	if test_move(global_transform, up):
		return                                  # หัวชนเพดาน
	var raised := global_transform.translated(up)
	if test_move(raised, motion):
		return                                  # สูงเกินกว่าจะก้าวขึ้น
	global_position += up + motion
	apply_floor_snap()


func _update_visual(hvel: Vector3, delta: float) -> void:
	var speed := hvel.length()
	# หันหน้า: ตอนโจมตีหันไปหามอน ไม่งั้นหันตามทิศที่วิ่ง
	_face_timer -= delta
	if _face_timer > 0.0:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(_face_dir.x, _face_dir.z), 25.0 * delta)
	elif speed > 0.5:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(hvel.x, hvel.z), 12.0 * delta)

	# เดิน: แกว่งแขน + ตัวเด้ง / สไลด์: เอนตัวไปข้างหลัง
	var move_amt: float = clamp(speed / max(stats.move_speed, 0.1), 0.0, 1.5)
	if not is_on_floor():
		move_amt = 0.3
	_anim_t += delta * (6.0 + speed * 0.8)
	var swing := sin(_anim_t) * 0.9 * move_amt
	if _model:
		var bob: float = abs(sin(_anim_t)) * 0.08 * move_amt if is_on_floor() and not is_sliding else 0.0
		_model.position.y = bob
		_model.rotation.x = lerp(_model.rotation.x, -0.9 if is_sliding else 0.0, 12.0 * delta)
	if _arm_left:
		_arm_left.rotation.x = swing
	if _arm_right:
		if _attack_t > 0.0:
			_attack_t -= delta
			var k: float = _attack_t / 0.3          # 1 -> 0
			_arm_right.rotation.x = lerp(-0.4, -2.6, k)  # ยกแขนแล้วฟันลง
		else:
			_arm_right.rotation.x = -swing

	# กระพริบแดงเมื่อโดนตี
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		if _hurt_flash <= 0.0:
			_set_overlay(null)


## โหลดโมเดลตัวละครเข้า Visual และหาแขนซ้าย/ขวาไว้ทำแอนิเมชัน
func _load_model() -> void:
	if character == null or character.model == null:
		return
	_model = Node3D.new()
	visual.add_child(_model)
	var m: Node3D = character.model.instantiate()
	m.scale = Vector3.ONE * character.model_scale
	_model.add_child(m)
	var stack: Array = [m]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			_meshes.append(n)
			var lname := n.name.to_lower()
			if "armleft" in lname or "arnleft" in lname:
				_arm_left = n
			elif "armright" in lname:
				_arm_right = n
		stack.append_array(n.get_children())
	# จุดยึดอาวุธที่ปลายแขนขวา
	if _arm_right:
		var box: AABB = (_arm_right as MeshInstance3D).get_aabb()
		_hand = Node3D.new()
		_hand.name = "Hand"
		_hand.position = Vector3(box.get_center().x, box.position.y + 0.08, box.get_center().z)
		_arm_right.add_child(_hand)


func _set_overlay(mat: Material) -> void:
	for mesh in _meshes:
		mesh.material_overlay = mat


## จุดยึดอาวุธในมือขวา (null ถ้าโมเดลไม่มีแขนขวา)
func get_hand() -> Node3D:
	return _hand


## เรียกจากอาวุธ: หันหน้าไปทางเป้าหมายชั่วครู่
func face_direction(dir: Vector3, duration: float = 0.35) -> void:
	_face_dir = dir
	_face_timer = duration


## เรียกจากอาวุธ: เล่นท่าฟัน
func play_attack() -> void:
	_attack_t = 0.3


func get_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


# ---------------- Health ----------------
func take_damage(amount: float) -> void:
	if is_dead or _iframe > 0.0:
		return
	var dmg: float = max(1.0, amount - stats.armor)
	hp -= dmg
	_iframe = invincibility_time
	_hurt_flash = 0.12
	_set_overlay(_hurt_mat)
	health_changed.emit(hp, stats.max_hp)
	if hp <= 0.0:
		_die()


func heal(amount: float) -> void:
	hp = min(stats.max_hp, hp + amount)
	health_changed.emit(hp, stats.max_hp)


func _die() -> void:
	hp = 0.0
	is_dead = true
	died.emit()
	GameState.trigger_game_over(false)


# ---------------- Weapons ----------------
func add_weapon_node(id: String, weapon: Node) -> void:
	weapons[id] = weapon
	weapon_holder.add_child(weapon)
