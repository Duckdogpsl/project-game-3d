extends WeaponBase
## ขวานของ Barbarian: หันไปหามอนที่ใกล้ที่สุด แล้วฟันเป็นวงโค้ง 90 องศา
## โดนทุกตัวที่อยู่ในวงโค้ง + กระเด็นถอยหลัง

const AXE_MODEL: PackedScene = preload("res://assets/models/axe.fbx")
const AXE_LENGTH := 0.95   # ความยาวโมเดลขวาน (หน่วยในไฟล์)

var arc_degrees: float = 90.0
var knockback_force: float = 7.0
var _held_axe: Node3D


func _init() -> void:
	weapon_id = "axe"
	display_name = "Barbarian Axe"
	base_damage = 20.0
	base_cooldown = 1.0


func _ready() -> void:
	# ให้ตัวละครถือขวานไว้ในมือขวา
	var hand: Node3D = player.get_hand() if player.has_method("get_hand") else null
	if hand:
		_held_axe = AXE_MODEL.instantiate()
		# หมุนใบขวานไปข้างหน้า แล้วเอียงด้ามขึ้น 45° ไปข้างหน้า
		_held_axe.basis = Basis(Vector3.RIGHT, deg_to_rad(45)) * Basis(Vector3.UP, deg_to_rad(90))
		_held_axe.scale = Vector3.ONE * 1.3
		hand.add_child(_held_axe)


func _exit_tree() -> void:
	if is_instance_valid(_held_axe):
		_held_axe.queue_free()


func get_radius() -> float:
	return (3.2 + 0.25 * (level - 1)) * get_area()


## จำนวนครั้งที่ฟันต่อรอบ (ฟันไปหามอนคนละตัว)
func get_swings() -> int:
	return 1 + int(level / 4.0) + player.stats.projectile_bonus


func attack() -> void:
	var center: Vector3 = player.global_position
	var r := get_radius()
	var targets := get_nearest_enemies(center, r + 1.5, get_swings())
	if targets.is_empty():
		return
	for i in targets.size():
		var dir: Vector3 = targets[i].global_position - center
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
		if i == 0:
			player.face_direction(dir)
			player.play_attack()
		_swing(center, dir, r)


func _swing(center: Vector3, dir: Vector3, r: float) -> void:
	var half := deg_to_rad(arc_degrees * 0.5)
	for e in get_enemies_in_range(center, r):
		var to: Vector3 = e.global_position - center
		to.y = 0.0
		var dist := to.length()
		var hit: bool = dist < e.get_radius() + 0.6
		if not hit:
			var angle: float = abs(dir.signed_angle_to(to / dist, Vector3.UP))
			hit = angle <= half + atan2(e.get_radius(), dist)   # เผื่อขนาดตัวมอน
		if hit:
			deal_damage(e)
			e.apply_knockback((to.normalized() if dist > 0.01 else dir) * knockback_force)
	_spawn_visual(center, dir, r)


# ---------------- Visual ----------------
func _spawn_visual(center: Vector3, dir: Vector3, r: float) -> void:
	var half := deg_to_rad(arc_degrees * 0.5)
	var pivot := Node3D.new()
	get_tree().current_scene.add_child(pivot)
	pivot.global_position = center + Vector3.UP * 0.9
	pivot.rotation.y = atan2(dir.x, dir.z)

	# วงโค้งโปร่งแสง
	var arc := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.2, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arc.mesh = _make_arc_mesh(r, half)
	arc.material_override = mat
	pivot.add_child(arc)

	# ขวานที่กวาดจาก +45° ไป -45°
	var sweep := Node3D.new()
	sweep.rotation.y = half
	pivot.add_child(sweep)
	sweep.add_child(_make_axe(r))

	var tw := pivot.create_tween()
	tw.tween_property(sweep, "rotation:y", -half, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25).set_delay(0.15)
	tw.tween_callback(pivot.queue_free)


func _make_arc_mesh(r: float, half: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 14
	for i in segments:
		var a0 := -half + 2.0 * half * i / segments
		var a1 := -half + 2.0 * half * (i + 1) / segments
		st.add_vertex(Vector3(sin(a0) * 0.6, 0, cos(a0) * 0.6))
		st.add_vertex(Vector3(sin(a0) * r, 0, cos(a0) * r))
		st.add_vertex(Vector3(sin(a1) * r, 0, cos(a1) * r))
		st.add_vertex(Vector3(sin(a0) * 0.6, 0, cos(a0) * 0.6))
		st.add_vertex(Vector3(sin(a1) * r, 0, cos(a1) * r))
		st.add_vertex(Vector3(sin(a1) * 0.6, 0, cos(a1) * 0.6))
	return st.commit()


## ขวานขนาดใหญ่ที่กวาดเป็นวง: ด้ามชี้ออกจากตัวผู้เล่น ใบขวานหันไปทางที่ฟัน
func _make_axe(r: float) -> Node3D:
	var holder := Node3D.new()
	var axe: Node3D = AXE_MODEL.instantiate()
	var scale_f := (r * 0.8) / AXE_LENGTH
	axe.scale = Vector3.ONE * scale_f
	axe.rotation_degrees = Vector3(90, 0, 0)          # +Y (ด้าม) -> +Z (ชี้ออกไป)
	axe.position = Vector3(0, 0, r * 0.15)
	holder.add_child(axe)
	return holder


func get_upgrade_desc() -> String:
	var txt := "+20% damage\n+ reach"
	if (level + 1) % 4 == 0:
		txt += "\n+1 swing"
	return txt
