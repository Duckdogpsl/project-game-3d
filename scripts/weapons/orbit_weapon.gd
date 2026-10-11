extends WeaponBase
## ใบมีดหมุนรอบตัว ฟันศัตรูที่โดน (แต่ละตัวโดนซ้ำได้ทุก base_cooldown วินาที)

var orbit_speed: float = 3.2
var _blades: Array = []
var _angle: float = 0.0
var _hit_cd: Dictionary = {}
var _mat: StandardMaterial3D


func _init() -> void:
	weapon_id = "orbit"
	display_name = "Spinning Blades"
	base_damage = 9.0
	base_cooldown = 0.45


func _ready() -> void:
	_mat = make_material(Color(0.3, 1.0, 0.9))


func get_count() -> int:
	return 2 + int((level - 1) / 2.0) + player.stats.projectile_bonus


func get_radius() -> float:
	return 2.6 * get_area()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead:
		return
	_angle += orbit_speed * delta * player.stats.attack_speed_mult
	_sync_blades()
	var r := get_radius()
	var center: Vector3 = player.global_position + Vector3.UP * 1.0
	var now := Time.get_ticks_msec() / 1000.0
	if _hit_cd.size() > 600:
		_hit_cd.clear()
	for i in _blades.size():
		var a := _angle + TAU * i / _blades.size()
		var pos := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var blade: MeshInstance3D = _blades[i]
		blade.global_position = pos
		blade.rotation = Vector3(0.0, -a, 0.0)
		for e in get_enemies_in_range(pos, 0.7 * get_area()):
			var id: int = e.get_instance_id()
			if now >= _hit_cd.get(id, 0.0):
				_hit_cd[id] = now + base_cooldown
				deal_damage(e)


func _sync_blades() -> void:
	var want := get_count()
	while _blades.size() < want:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, 0.12, 1.1)
		box.material = _mat
		m.mesh = box
		m.top_level = true
		add_child(m)
		_blades.append(m)
	while _blades.size() > want:
		_blades.pop_back().queue_free()


func get_upgrade_desc() -> String:
	var txt := "+20% damage"
	if level % 2 == 0:
		txt += "\n+1 blade"
	return txt
