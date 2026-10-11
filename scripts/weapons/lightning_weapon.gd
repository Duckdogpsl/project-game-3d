extends WeaponBase
## ฟ้าผ่าศัตรูแบบสุ่มในระยะ พร้อมดาเมจกระจายรอบจุดที่ผ่า

var attack_range: float = 20.0


func _init() -> void:
	weapon_id = "lightning"
	display_name = "Lightning Staff"
	base_damage = 22.0
	base_cooldown = 1.6


func get_count() -> int:
	return 1 + int(level / 2.0) + player.stats.projectile_bonus


func attack() -> void:
	var pool := get_enemies_in_range(player.global_position, attack_range)
	if pool.is_empty():
		return
	pool.shuffle()
	for i in min(get_count(), pool.size()):
		var target = pool[i]
		var p: Vector3 = target.global_position
		_spawn_bolt(p)
		for e in get_enemies_in_range(p, 1.6 * get_area()):
			deal_damage(e)


func _spawn_bolt(pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.15
	cyl.height = 24.0
	cyl.material = make_material(Color(1.0, 1.0, 0.5))
	m.mesh = cyl
	get_tree().current_scene.add_child(m)
	m.global_position = pos + Vector3.UP * 12.0
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3(0.05, 1.0, 0.05), 0.2)
	tw.tween_callback(m.queue_free)


func get_upgrade_desc() -> String:
	var txt := "+20% damage"
	if (level + 1) % 2 == 0:
		txt += "\n+1 strike"
	return txt
