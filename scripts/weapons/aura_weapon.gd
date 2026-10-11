extends WeaponBase
## วงออร่ารอบตัว ทำดาเมจศัตรูทุกตัวในวงเป็นระยะ

var _mesh: MeshInstance3D


func _init() -> void:
	weapon_id = "aura"
	display_name = "Holy Aura"
	base_damage = 6.0
	base_cooldown = 0.5


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	cyl.material = make_material(Color(1.0, 0.9, 0.3), false, 0.22)
	_mesh.mesh = cyl
	_mesh.position.y = 0.08
	add_child(_mesh)


func get_radius() -> float:
	return (3.0 + 0.35 * (level - 1)) * get_area()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var r := get_radius()
	_mesh.scale = Vector3(r, 1.0, r)
	_mesh.rotation.y += delta


func attack() -> void:
	for e in get_enemies_in_range(player.global_position, get_radius()):
		deal_damage(e)


func get_upgrade_desc() -> String:
	return "+20% damage\n+ radius"
