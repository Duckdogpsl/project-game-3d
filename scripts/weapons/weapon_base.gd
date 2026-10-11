class_name WeaponBase
extends Node3D
## คลาสแม่ของอาวุธทุกชนิด
## สร้างอาวุธใหม่: extends WeaponBase แล้ว override attack() / get_upgrade_desc()

var weapon_id: String = ""
var display_name: String = "Weapon"
var base_damage: float = 10.0
var base_cooldown: float = 1.0
var max_level: int = 8
var level: int = 1
var player = null

var _cooldown_timer: float = 0.3


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead:
		return
	_cooldown_timer -= delta * player.stats.attack_speed_mult
	if _cooldown_timer <= 0.0:
		_cooldown_timer = base_cooldown
		attack()


## override ในอาวุธลูก
func attack() -> void:
	pass


func level_up() -> void:
	level = min(level + 1, max_level)


## ข้อความที่แสดงตอนเลือกอัปเกรด
func get_upgrade_desc() -> String:
	return "+20% damage"


# ---------------- Helpers ----------------
func get_damage(mult: float = 1.0) -> float:
	return base_damage * (1.0 + 0.2 * (level - 1)) * player.stats.damage_mult * mult


## คำนวณดาเมจ + คริติคอล แล้วยิงใส่ศัตรู
func deal_damage(enemy, mult: float = 1.0) -> void:
	if not is_instance_valid(enemy) or enemy.dead or not is_instance_valid(player):
		return
	var dmg := get_damage(mult)
	var crit: bool = randf() < player.stats.crit_chance
	if crit:
		dmg *= player.stats.crit_mult
	enemy.take_damage(dmg, crit)


func get_area() -> float:
	return player.stats.area_mult


## หาศัตรูในรัศมี (วัดแนวราบ + เผื่อขนาดตัวศัตรู)
func get_enemies_in_range(center: Vector3, radius: float) -> Array:
	var result: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var d: Vector3 = e.global_position - center
		if abs(d.y) > 3.0 + e.get_radius() * 2.0:
			continue
		d.y = 0.0
		var r: float = radius + e.get_radius()
		if d.length_squared() <= r * r:
			result.append(e)
	return result


## หาศัตรูที่ใกล้ที่สุด n ตัว
func get_nearest_enemies(center: Vector3, max_range: float, count: int) -> Array:
	var list: Array = []
	var r2 := max_range * max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var d2: float = e.global_position.distance_squared_to(center)
		if d2 <= r2:
			list.append([d2, e])
	list.sort_custom(func(a, b): return a[0] < b[0])
	var result: Array = []
	for i in min(count, list.size()):
		result.append(list[i][1])
	return result


func make_material(color: Color, emissive: bool = true, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
