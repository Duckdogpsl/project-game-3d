extends WeaponBase
## กระแทกพื้นเป็นคลื่นรอบตัว ทำดาเมจ + กระเด็น

var knockback_force: float = 14.0


func _init() -> void:
	weapon_id = "shockwave"
	display_name = "Ground Slam"
	base_damage = 18.0
	base_cooldown = 3.0


func get_radius() -> float:
	return (5.0 + 0.5 * (level - 1)) * get_area()


func attack() -> void:
	var center: Vector3 = player.global_position
	var r := get_radius()
	_spawn_ring(center, r)
	for e in get_enemies_in_range(center, r):
		deal_damage(e)
		var dir: Vector3 = e.global_position - center
		dir.y = 0.0
		e.apply_knockback(dir.normalized() * knockback_force)


func _spawn_ring(center: Vector3, r: float) -> void:
	var m := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.material = make_material(Color(1.0, 0.45, 0.2), true, 0.7)
	m.mesh = torus
	get_tree().current_scene.add_child(m)
	m.global_position = center + Vector3.UP * 0.3
	m.scale = Vector3.ONE * 0.5
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3(r, 1.0, r), 0.25)
	tw.tween_callback(m.queue_free)


func get_upgrade_desc() -> String:
	return "+20% damage\n+ radius"
