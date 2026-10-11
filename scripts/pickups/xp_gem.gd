extends Node3D
## เพชร XP: ดูดเข้าหาผู้เล่นเมื่ออยู่ในระยะ pickup_range

var value: float = 1.0
var _magnet: bool = false
var _speed: float = 4.0
var _t: float = 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("xp_gems")
	_t = randf() * TAU
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	var s: float = 0.3 + min(value, 30.0) * 0.02
	box.size = Vector3(s, s, s)
	var mat := StandardMaterial3D.new()
	var c := Color(0.3, 0.6, 1.0)
	if value >= 15.0:
		c = Color(1.0, 0.3, 0.4)
	elif value >= 4.0:
		c = Color(0.4, 1.0, 0.4)
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	box.material = mat
	_mesh.mesh = box
	_mesh.rotation = Vector3(PI / 4.0, 0.0, PI / 4.0)
	add_child(_mesh)


func attract() -> void:
	_magnet = true


func _process(delta: float) -> void:
	_t += delta
	_mesh.rotation.y += 3.0 * delta
	_mesh.position.y = sin(_t * 3.0) * 0.12
	var p = GameState.player
	if not is_instance_valid(p):
		return
	var target: Vector3 = p.global_position + Vector3.UP * 0.9
	var d := global_position.distance_to(target)
	if not _magnet and d < p.stats.pickup_range:
		_magnet = true
	if _magnet:
		_speed += 50.0 * delta
		global_position = global_position.move_toward(target, (_speed + p.get_speed()) * delta)
		if d < 0.9:
			GameState.add_xp(value)
			queue_free()
