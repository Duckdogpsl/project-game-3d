extends Node3D
## ไอเทมพิเศษ: MAGNET = ดูด XP ทั้งแมพ, HEAL = ฟื้นเลือด 30%

enum Kind { MAGNET, HEAL }

## โมเดลของไอเทม — เปลี่ยนไฟล์ได้ที่นี่ (รองรับ .fbx .glb .gltf .obj)
const MAGNET_MODEL: PackedScene = preload("res://assets/models/magnet.fbx")
const HEAL_MODEL: PackedScene = preload("res://assets/models/healing_potion.glb")
const MAGNET_GLOW := Color(1, 0.3, 0.3)
const HEAL_GLOW := Color(0.3, 1, 0.4)

var kind: int = Kind.HEAL
var model_size: float = 0.9   ## ขนาดโมเดลในเกม (เมตร)
var _t: float = 0.0
var _mesh: Node3D
var _life: float = 40.0


func _ready() -> void:
	var color := MAGNET_GLOW if kind == Kind.MAGNET else HEAL_GLOW
	var model_scene: PackedScene = MAGNET_MODEL if kind == Kind.MAGNET else HEAL_MODEL
	if model_scene:
		_mesh = ModelUtils.create_fitted(model_scene, model_size)
	else:
		_mesh = _fallback_mesh(color)
	add_child(_mesh)
	# แสงเรืองรอบไอเทมให้มองเห็นง่าย
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 2.5
	light.position.y = 0.5
	add_child(light)


## ใช้รูปทรงพื้นฐานแทน ถ้าไม่มีไฟล์โมเดล
func _fallback_mesh(color: Color) -> Node3D:
	var m := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	sphere.material = mat
	m.mesh = sphere
	return m


func _process(delta: float) -> void:
	_t += delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	_mesh.position.y = 0.6 + sin(_t * 3.0) * 0.15
	rotation.y += 2.0 * delta
	var p = GameState.player
	if is_instance_valid(p) and global_position.distance_to(p.global_position + Vector3.UP * 0.9) < 1.6:
		_collect(p)


func _collect(p) -> void:
	if kind == Kind.MAGNET:
		for g in get_tree().get_nodes_in_group("xp_gems"):
			g.attract()
	else:
		p.heal(p.stats.max_hp * 0.3)
	queue_free()
