extends CharacterBody3D
## ศัตรู: เดินตามผู้เล่น ชนแล้วทำดาเมจ ตายแล้วดรอป XP
## ค่าพลังมาจาก EnemyData (resources/enemies/*.tres)

const XP_GEM := preload("res://scripts/pickups/xp_gem.gd")
const POWERUP := preload("res://scripts/pickups/powerup.gd")
const CHEST := preload("res://scripts/pickups/chest.gd")
const DAMAGE_NUMBER := preload("res://scripts/effects/damage_number.gd")
const GRAVITY := 24.0

@export var data: EnemyData
@export var show_damage_numbers: bool = true

@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $CollisionShape3D

var hp_mult: float = 1.0   # ตั้งโดย spawner ตามเวลา
var max_hp: float = 10.0
var hp: float = 10.0
var dead: bool = false

var _mat: StandardMaterial3D
var _flash: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _contact_cd: float = 0.0
var _boss_label: Label3D
var _climbing: bool = false


func _ready() -> void:
	add_to_group("enemies")
	if data == null:
		data = EnemyData.new()
	max_hp = data.max_hp * hp_mult
	hp = max_hp
	# ปรับขนาดตามข้อมูล
	var shape := collision.shape.duplicate() as SphereShape3D
	shape.radius = 0.5 * data.size
	collision.shape = shape
	collision.position.y = 0.5 * data.size
	mesh.scale = Vector3.ONE * data.size
	mesh.position.y = 0.5 * data.size
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = data.color
	mesh.material_override = _mat
	if data.is_boss:
		_boss_label = Label3D.new()
		_boss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_boss_label.font_size = 64
		_boss_label.outline_size = 12
		_boss_label.modulate = Color(1, 0.3, 0.3)
		_boss_label.position.y = data.size + 1.0
		add_child(_boss_label)
		_update_boss_label()


func get_radius() -> float:
	return 0.5 * data.size


func _physics_process(delta: float) -> void:
	if dead:
		return
	var player = GameState.player
	if not is_instance_valid(player):
		return
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	var dir := to_p / dist if dist > 0.01 else Vector3.ZERO

	velocity.x = dir.x * data.speed + _knockback.x
	velocity.z = dir.z * data.speed + _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, 40.0 * delta)

	# ปีนกำแพง: ถ้าเดินชนกำแพง/หน้าผาในทิศที่จะไปหาผู้เล่น ให้ไต่ขึ้นตรงๆ
	var wall_n := _get_wall_normal()
	_climbing = wall_n != Vector3.ZERO and dir.dot(-wall_n) > 0.3
	if _climbing:
		velocity.y = data.climb_speed
		velocity.x += -wall_n.x * 1.5   # ดันเข้าหากำแพงให้ติดผนัง
		velocity.z += -wall_n.z * 1.5
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if dir != Vector3.ZERO:
		mesh.rotation.y = atan2(dir.x, dir.z)
	mesh.rotation.x = lerp(mesh.rotation.x, -0.7 if _climbing else 0.0, 12.0 * delta)

	# ดาเมจเมื่อชน
	_contact_cd -= delta
	var dy: float = abs(player.global_position.y - global_position.y)
	if _contact_cd <= 0.0 and dist < get_radius() + 0.6 and dy < data.size + 1.2:
		player.take_damage(data.damage)
		_contact_cd = 0.5

	# กระพริบขาวตอนโดนตี
	if _flash > 0.0:
		_flash -= delta
		_mat.albedo_color = Color.WHITE if _flash > 0.0 else data.color

	# ไกลเกินไป / ตกแมพ -> ลบทิ้ง (spawner จะเกิดใหม่ใกล้ๆ)
	if (dist > 70.0 and not data.is_boss) or global_position.y < -30.0:
		queue_free()


## หากำแพง (StaticBody ที่ผิวเกือบตั้งฉาก) ที่ชนอยู่ในเฟรมก่อน
func _get_wall_normal() -> Vector3:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is StaticBody3D:
			var n := c.get_normal()
			if abs(n.y) < 0.4:
				return Vector3(n.x, 0.0, n.z).normalized()
	return Vector3.ZERO


func apply_knockback(force: Vector3) -> void:
	_knockback += force / max(1.0, data.size * 0.8)


func take_damage(amount: float, crit: bool = false) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.08
	if show_damage_numbers:
		var n = DAMAGE_NUMBER.new()
		n.setup(amount, crit)
		get_tree().current_scene.add_child.call_deferred(n)
		n.position = global_position + Vector3.UP * (data.size + 0.5)
	var player = GameState.player
	if is_instance_valid(player):
		var away: Vector3 = global_position - player.global_position
		away.y = 0.0
		apply_knockback(away.normalized() * 2.5)
	if _boss_label:
		_update_boss_label()
	if hp <= 0.0:
		_die()


func _update_boss_label() -> void:
	_boss_label.text = "%s  %d%%" % [data.enemy_name, ceili(max(hp, 0.0) / max_hp * 100.0)]


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	GameState.register_kill()
	var scene := get_tree().current_scene
	var drop_pos := global_position + Vector3.UP * 0.5

	var gem = XP_GEM.new()
	gem.value = data.xp_value
	gem.position = drop_pos
	scene.add_child.call_deferred(gem)

	var luck: float = 0.0
	if is_instance_valid(GameState.player):
		luck = GameState.player.stats.luck
	if randf() < data.gold_chance * (1.0 + luck):
		GameState.add_gold(randi_range(1, 3) * max(1, int(data.size)))

	var roll := randf()
	if roll < 0.006 * (1.0 + luck):
		_drop_powerup(POWERUP.Kind.MAGNET, drop_pos)
	elif roll < 0.018 * (1.0 + luck):
		_drop_powerup(POWERUP.Kind.HEAL, drop_pos)

	if data.is_boss:
		var chest = CHEST.new()
		chest.free_chest = true
		chest.position = Vector3(global_position.x, 0.0, global_position.z)
		scene.add_child.call_deferred(chest)
	queue_free()


func _drop_powerup(kind: int, pos: Vector3) -> void:
	var p = POWERUP.new()
	p.kind = kind
	p.position = pos
	get_tree().current_scene.add_child.call_deferred(p)
