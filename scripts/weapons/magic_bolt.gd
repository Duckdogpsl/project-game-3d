extends WeaponBase
## ยิงกระสุนเวทใส่ศัตรูที่ใกล้ที่สุด

const PROJECTILE := preload("res://scenes/weapons/projectile.tscn")

var projectile_speed: float = 24.0
var attack_range: float = 28.0


func _init() -> void:
	weapon_id = "magic_bolt"
	display_name = "Magic Bolt"
	base_damage = 12.0
	base_cooldown = 0.9


func get_count() -> int:
	return 1 + int(level / 3.0) + player.stats.projectile_bonus


func get_pierce() -> int:
	return int(level / 4.0)


func attack() -> void:
	var origin: Vector3 = player.global_position + Vector3.UP * 1.2
	var targets := get_nearest_enemies(origin, attack_range, get_count())
	if targets.is_empty():
		return
	var count := get_count()
	for i in count:
		var t = targets[i % targets.size()]
		var aim: Vector3 = t.global_position + Vector3.UP * t.get_radius()
		var dir := (aim - origin).normalized()
		if i >= targets.size():  # กระสุนเกินจำนวนเป้า -> กระจายมุม
			dir = dir.rotated(Vector3.UP, randf_range(-0.3, 0.3))
		var p = PROJECTILE.instantiate()
		p.velocity = dir * projectile_speed
		p.weapon = self
		p.pierce = get_pierce()
		p.scale = Vector3.ONE * get_area()
		get_tree().current_scene.add_child(p)
		p.global_position = origin


func get_upgrade_desc() -> String:
	var txt := "+20% damage"
	if (level + 1) % 3 == 0:
		txt += "\n+1 projectile"
	if (level + 1) % 4 == 0:
		txt += "\n+1 pierce"
	return txt
