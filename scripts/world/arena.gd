extends Node3D
## สร้างแมพอัตโนมัติ:
## - พื้นทั้งแมพปูด้วย Floor Tile เป็นตารางช่องละ 4 ม. แต่ละช่องมีความสูงต่างกัน (สุ่มด้วย noise)
##   ขอบที่ต่างระดับเป็นหน้าผาจากโมเดล Wall และมีทางลาดเชื่อมเป็นระยะ
## - กำแพงรอบแมพ + กำแพงกลางแมพ (โมเดล Wall)
## - หิน, แพลตฟอร์มลอย, หีบ, แสง, ท้องฟ้า
## โมเดลที่ซ้ำกันเยอะๆ ใช้ MultiMesh เพื่อให้เกมไม่กระตุก
## ปรับตัวเลขได้ใน Inspector ของโหนด Arena

const CHEST := preload("res://scripts/pickups/chest.gd")
const WALL_MODEL: PackedScene = preload("res://assets/models/environment/wall.glb")
const FLOOR_MODEL: PackedScene = preload("res://assets/models/environment/floor_tile.glb")

const TILE := 4.0             ## ขนาดช่องตาราง/กระเบื้อง/กำแพง 1 ช่อง (เมตร) — โมเดลจริง 2 ม. ขยาย 2 เท่า
const WALL_MODEL_HEIGHT := 2.0
const CHUNK_SIZE := 40.0      ## ขนาดก้อน MultiMesh (เมตร)
const DIRS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
const DIR_YAW := [0.0, PI, PI / 2, -PI / 2]   ## ทิศที่หน้ากำแพงหันไป ตาม DIRS

@export var arena_size: float = 200.0
@export_group("Terrain")
@export var tier_height: float = 1.5           ## ความสูงต่อ 1 ระดับ (ผู้เล่นกระโดดได้ ~1.7 ม.)
@export var max_level: int = 3                 ## ระดับสูงสุด (3 = สูง 4.5 ม.)
@export var noise_frequency: float = 0.025     ## น้อย = เนินใหญ่, มาก = เนินเล็กถี่
@export var level_thresholds: PackedFloat32Array = [0.5, 0.6, 0.68]  ## ค่า noise (0-1) ที่ขึ้นระดับ 1, 2, 3
@export var flat_center_radius: float = 16.0   ## พื้นที่เรียบกลางแมพ (จุดเกิด)
@export var ramp_chance: float = 0.15          ## โอกาสวางทางลาดที่ขอบหน้าผาแต่ละจุด
## สีกระเบื้องแต่ละระดับ (ดิน, มอส, หินเทา, หินอ่อน) — ช่วยให้รู้ว่าอยู่สูงแค่ไหน
@export var level_colors: PackedColorArray = [
	Color(0.46, 0.4, 0.34), Color(0.38, 0.5, 0.33), Color(0.47, 0.48, 0.53), Color(0.62, 0.6, 0.56)]
@export var inner_wall_count: int = 14         ## กำแพงกลางแมพ
@export var border_wall_height: float = 7.0
@export var draw_distance: float = 120.0      ## ระยะวาดพื้น/กำแพง (ลดลงถ้าเครื่องช้า)
@export_group("Props")
@export var obstacle_count: int = 20
@export var platform_count: int = 6
@export var chest_count: int = 10
@export_group("General")
@export var safe_radius: float = 14.0          ## รัศมีกลางแมพที่ไม่มีสิ่งกีดขวาง
@export var world_seed: int = 0                ## 0 = สุ่มทุกครั้ง

var _rng := RandomNumberGenerator.new()
var _n: int = 50                 # จำนวนช่องต่อด้าน
var _levels := PackedInt32Array()
var _ramp_cells := {}            # ช่องที่มีทางลาดแล้ว
var _wall_mesh: Array            # [Mesh, Transform3D]
var _floor_mesh: Array
var _wall_xforms: Array = []
var _floor_xforms: Array = []
var _floor_colors: Array = []


func _ready() -> void:
	add_to_group("arena")
	if world_seed != 0:
		_rng.seed = world_seed
	else:
		_rng.randomize()
	_wall_mesh = ModelUtils.get_first_mesh(WALL_MODEL)
	_floor_mesh = ModelUtils.get_first_mesh(FLOOR_MODEL)

	_build_environment()
	_generate_levels()
	_build_terrain()
	_build_border_walls()
	for i in inner_wall_count:
		_try_build_inner_wall()
	for i in obstacle_count:
		_build_rock()
	for i in platform_count:
		_build_platform()
	_flush_multimeshes()
	for i in chest_count:
		_spawn_chest()


## ความสูงพื้นที่ตำแหน่ง (x, z) — ใช้ตอนเกิดมอน/วางหีบ
func get_height_at(x: float, z: float) -> float:
	var c := _cell_of(x, z)
	return _level(c.x, c.y) * tier_height if _in_grid(c.x, c.y) else 0.0


# ---------------- Grid helpers ----------------
func _cell_of(x: float, z: float) -> Vector2i:
	var half := arena_size * 0.5
	return Vector2i(floori((x + half) / TILE), floori((z + half) / TILE))


func _cell_center(ix: int, iz: int) -> Vector2:
	var half := arena_size * 0.5
	return Vector2(-half + TILE * (ix + 0.5), -half + TILE * (iz + 0.5))


func _in_grid(ix: int, iz: int) -> bool:
	return ix >= 0 and iz >= 0 and ix < _n and iz < _n


func _level(ix: int, iz: int) -> int:
	return _levels[iz * _n + ix]


func _set_level(ix: int, iz: int, v: int) -> void:
	_levels[iz * _n + ix] = v


# ---------------- Environment ----------------
func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.5, 0.9)
	sky_mat.sky_horizon_color = Color(0.75, 0.85, 1.0)
	sky_mat.ground_horizon_color = Color(0.75, 0.85, 1.0)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.85, 1.0)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)


# ---------------- Helpers ----------------
func _make_box(size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, visible_mesh: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	if visible_mesh:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		box.material = mat
		mesh.mesh = box
		body.add_child(mesh)
	body.position = pos
	body.rotation = rot
	add_child(body)
	return body


func _random_pos(margin: float = 6.0) -> Vector3:
	var half := arena_size * 0.5 - margin
	for i in 100:
		var p := Vector3(_rng.randf_range(-half, half), 0.0, _rng.randf_range(-half, half))
		var c := _cell_of(p.x, p.z)
		if Vector2(p.x, p.z).length() > safe_radius and not _ramp_cells.has(c):
			p.y = get_height_at(p.x, p.z)
			return p
	return Vector3(half, 0, half)


func _snap(v: float) -> float:
	return round(v / TILE) * TILE


## เพิ่มกำแพง 1 ช่อง (กว้าง TILE) — pos = จุดกึ่งกลางด้านล่าง, yaw = ทิศที่หน้ากำแพงหันไป
func _add_wall_piece(pos: Vector3, yaw: float, height_scale: float = -1.0) -> void:
	if height_scale < 0.0:
		height_scale = tier_height / WALL_MODEL_HEIGHT
	var s := Vector3(TILE / 2.0, height_scale, TILE / 2.0)
	_wall_xforms.append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(s), pos))


func _add_floor_tile(center: Vector3, color: Color) -> void:
	# กระเบื้องหนา 0.25 ม. — วางให้ผิวบนอยู่ที่ center.y, สุ่มหมุน 90° ให้ลายไม่ซ้ำ
	var s := Vector3(TILE / 2.0, 1.0, TILE / 2.0)
	var yaw := _rng.randi_range(0, 3) * PI / 2
	_floor_xforms.append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(s), center - Vector3(0, 0.125, 0)))
	var v := _rng.randf_range(-0.04, 0.04)
	_floor_colors.append(Color(color.r + v, color.g + v, color.b + v))


## สร้าง MultiMesh จากรายการตำแหน่งที่เก็บไว้
func _flush_multimeshes() -> void:
	for mmi in _make_multimesh(_wall_mesh, _wall_xforms):
		mmi.visibility_range_end = draw_distance
	var floor_mat := StandardMaterial3D.new()
	floor_mat.vertex_color_use_as_albedo = true   # ใช้สีต่อชิ้นจาก MultiMesh (สีตามระดับความสูง)
	floor_mat.roughness = 0.85
	for mmi in _make_multimesh(_floor_mesh, _floor_xforms, _floor_colors):
		# พื้นเรียบ ไม่ต้องสร้างเงา (ประหยัดเครื่อง) แต่ยังรับเงาได้
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.material_override = floor_mat
		mmi.visibility_range_end = draw_distance


## สร้าง MultiMesh แยกเป็นก้อนตามพื้นที่ (chunk) — ก้อนที่อยู่นอกจอ/ไกลเกินจะไม่ถูกวาด
func _make_multimesh(mesh_info: Array, xforms: Array, colors: Array = []) -> Array:
	var result: Array = []
	if mesh_info.is_empty() or xforms.is_empty():
		return result
	var chunks := {}
	for i in xforms.size():
		var o: Vector3 = xforms[i].origin
		var key := Vector2i(floori(o.x / CHUNK_SIZE), floori(o.z / CHUNK_SIZE))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(i)
	var local: Transform3D = mesh_info[1]
	for key in chunks:
		var ids: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = not colors.is_empty()
		mm.mesh = mesh_info[0]
		mm.instance_count = ids.size()
		for j in ids.size():
			mm.set_instance_transform(j, xforms[ids[j]] * local)
			if mm.use_colors:
				mm.set_instance_color(j, colors[ids[j]])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		result.append(mmi)
	return result


# ---------------- Terrain (พื้นต่างระดับ) ----------------
## สุ่มระดับความสูงของแต่ละช่องด้วย noise
func _generate_levels() -> void:
	_n = int(arena_size / TILE)
	_levels.resize(_n * _n)
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = noise_frequency
	noise.fractal_octaves = 3
	for iz in _n:
		for ix in _n:
			var c := _cell_center(ix, iz)
			var v := noise.get_noise_2d(c.x, c.y) * 0.5 + 0.5
			var lv := 0
			for t in level_thresholds:
				if v >= t:
					lv += 1
			lv = mini(lv, max_level)
			if c.length() < flat_center_radius:
				lv = 0
			_set_level(ix, iz, lv)
	# ลบยอดแหลมช่องเดียว (สูงกว่าทุกช่องรอบข้าง)
	for iz in _n:
		for ix in _n:
			var highest := -1
			for d in DIRS:
				if _in_grid(ix + d.x, iz + d.y):
					highest = maxi(highest, _level(ix + d.x, iz + d.y))
			if highest >= 0 and _level(ix, iz) > highest:
				_set_level(ix, iz, highest)


func _build_terrain() -> void:
	var half := arena_size * 0.5
	var body: Node = null
	# พื้นฐานระดับ 0
	_add_box_shape(body, Vector3(arena_size, 1.0, arena_size), Vector3(0, -0.5, 0))

	for iz in _n:
		# รวมช่องที่ระดับเท่ากันในแถวเดียวกันเป็นกล่องชนกล่องเดียว (ลดจำนวน collision)
		var ix := 0
		while ix < _n:
			var lv := _level(ix, iz)
			var run := 1
			while ix + run < _n and _level(ix + run, iz) == lv:
				run += 1
			if lv > 0:
				var h := lv * tier_height
				var x0 := -half + TILE * ix
				_add_box_shape(body, Vector3(TILE * run, h, TILE), Vector3(x0 + TILE * run / 2.0, h / 2.0, -half + TILE * (iz + 0.5)))
			ix += run

		for jx in _n:
			var lv := _level(jx, iz)
			var c := _cell_center(jx, iz)
			var top := lv * tier_height
			_add_floor_tile(Vector3(c.x, top, c.y), level_colors[mini(lv, level_colors.size() - 1)])
			# หน้าผา + ทางลาด ที่ขอบซึ่งเพื่อนบ้านต่ำกว่า
			for di in DIRS.size():
				var d: Vector2i = DIRS[di]
				var nx := jx + d.x
				var nz := iz + d.y
				if not _in_grid(nx, nz):
					continue
				var nlv := _level(nx, nz)
				if nlv >= lv:
					continue
				var edge := c + Vector2(d.x, d.y) * (TILE * 0.5 + 0.1)
				for row in range(nlv, lv):
					_add_wall_piece(Vector3(edge.x, row * tier_height, edge.y), DIR_YAW[di])
				if lv - nlv == 1 and _rng.randf() < ramp_chance:
					_try_build_ramp(jx, iz, di)


## กล่องชนแยก body ละอัน (ให้ระบบฟิสิกส์คัดกรองตามตำแหน่งได้ — เร็วกว่ารวมไว้ body เดียวมาก)
func _add_box_shape(_unused: Node, size: Vector3, pos: Vector3) -> void:
	_make_box(size, pos, Color.WHITE, Vector3.ZERO, false)


## ทางลาดลงจากช่อง (ix, iz) ไปทิศ DIRS[di] — ต้องมีที่ว่างระดับต่ำกว่า 2 ช่อง
func _try_build_ramp(ix: int, iz: int, di: int) -> void:
	var d: Vector2i = DIRS[di]
	var lv := _level(ix, iz)
	var c1 := Vector2i(ix + d.x, iz + d.y)
	var c2 := Vector2i(ix + d.x * 2, iz + d.y * 2)
	if not _in_grid(c2.x, c2.y) or _level(c2.x, c2.y) != lv - 1:
		return
	if _ramp_cells.has(c1) or _ramp_cells.has(c2):
		return
	_ramp_cells[c1] = true
	_ramp_cells[c2] = true
	var run := TILE * 1.5
	var c := _cell_center(ix, iz)
	var edge := c + Vector2(d.x, d.y) * TILE * 0.5
	var low := edge + Vector2(d.x, d.y) * run
	_make_wedge(Vector3(low.x, (lv - 1) * tier_height, low.y), Vector3(-d.x, 0, -d.y), run, tier_height, 3.2, Color(0.55, 0.42, 0.28))


## ทางลาดรูปลิ่ม: ปลายล่างแนบพื้นพอดี ไม่มีขอบให้สะดุด
## low_end = จุดกึ่งกลางปลายล่าง (บนพื้น), up_dir = ทิศที่เดินขึ้น, run = ความยาวแนวราบ, rise = ความสูง
func _make_wedge(low_end: Vector3, up_dir: Vector3, run: float, rise: float, width: float, color: Color) -> StaticBody3D:
	var prism := PrismMesh.new()
	prism.left_to_right = 0.0            # ยอดอยู่ด้าน -X ของโมเดล
	prism.size = Vector3(run, rise, width)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	prism.material = mat
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var mi := MeshInstance3D.new()
	mi.mesh = prism
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.shape = prism.create_convex_shape()
	body.add_child(cs)
	var x_axis := -up_dir.normalized()   # -X (ด้านสูง) ชี้ไปทางขึ้น
	body.basis = Basis(x_axis, Vector3.UP, x_axis.cross(Vector3.UP))
	body.position = low_end + up_dir.normalized() * run * 0.5 + Vector3.UP * rise * 0.5
	body.set_meta("ramp_up", up_dir.normalized())
	add_child(body)
	return body


func _build_border_walls() -> void:
	var half := arena_size * 0.5
	var h_scale := border_wall_height / WALL_MODEL_HEIGHT
	_make_box(Vector3(arena_size, border_wall_height, 1), Vector3(0, border_wall_height / 2, half), Color.WHITE, Vector3.ZERO, false)
	_make_box(Vector3(arena_size, border_wall_height, 1), Vector3(0, border_wall_height / 2, -half), Color.WHITE, Vector3.ZERO, false)
	_make_box(Vector3(1, border_wall_height, arena_size), Vector3(half, border_wall_height / 2, 0), Color.WHITE, Vector3.ZERO, false)
	_make_box(Vector3(1, border_wall_height, arena_size), Vector3(-half, border_wall_height / 2, 0), Color.WHITE, Vector3.ZERO, false)
	for i in _n:
		var t := -half + TILE * (i + 0.5)
		_add_wall_piece(Vector3(t, 0, half - 0.3), PI, h_scale)
		_add_wall_piece(Vector3(t, 0, -half + 0.3), 0.0, h_scale)
		_add_wall_piece(Vector3(half - 0.3, 0, t), -PI / 2, h_scale)
		_add_wall_piece(Vector3(-half + 0.3, 0, t), PI / 2, h_scale)


# ---------------- Inner walls (กำแพงกลางแมพ) ----------------
## วางกำแพงบนแถวช่องที่ระดับเท่ากัน
func _try_build_inner_wall() -> void:
	var length := _rng.randi_range(2, 5)
	var rows := _rng.randi_range(1, 2)
	var along_x := _rng.randf() < 0.5
	var step := Vector2i(1, 0) if along_x else Vector2i(0, 1)
	var wall_h := WALL_MODEL_HEIGHT
	for attempt in 40:
		var start := Vector2i(_rng.randi_range(2, _n - 3 - length), _rng.randi_range(2, _n - 3 - length))
		var lv := _level(start.x, start.y)
		var ok := true
		for i in length:
			var cc := start + step * i
			if _level(cc.x, cc.y) != lv or _ramp_cells.has(cc) or _cell_center(cc.x, cc.y).length() < safe_radius:
				ok = false
				break
		if not ok:
			continue
		var base := lv * tier_height
		var a := _cell_center(start.x, start.y)
		var b := _cell_center(start.x + step.x * (length - 1), start.y + step.y * (length - 1))
		var mid := (a + b) * 0.5
		var L := length * TILE
		var H := rows * wall_h
		var size := Vector3(L, H, 0.6) if along_x else Vector3(0.6, H, L)
		_make_box(size, Vector3(mid.x, base + H / 2.0, mid.y), Color.WHITE, Vector3.ZERO, false)
		for row in rows:
			for i in length:
				var p := _cell_center(start.x + step.x * i, start.y + step.y * i)
				var y := base + row * wall_h
				if along_x:
					_add_wall_piece(Vector3(p.x, y, p.y + 0.12), 0.0, 1.0)
					_add_wall_piece(Vector3(p.x, y, p.y - 0.12), PI, 1.0)
				else:
					_add_wall_piece(Vector3(p.x + 0.12, y, p.y), PI / 2, 1.0)
					_add_wall_piece(Vector3(p.x - 0.12, y, p.y), -PI / 2, 1.0)
		return


# ---------------- Props ----------------
func _build_rock() -> void:
	var sz := Vector3(_rng.randf_range(1.5, 3.5), _rng.randf_range(1.0, 3.0), _rng.randf_range(1.5, 3.5))
	var p := _random_pos()
	p.y += sz.y / 2.0
	var g := _rng.randf_range(0.4, 0.55)
	_make_box(sz, p, Color(g, g * 0.95, g * 0.9), Vector3(0, _rng.randf() * TAU, 0))


func _build_platform() -> void:
	var height := _rng.randf_range(3.0, 6.0)
	var p := _random_pos()
	var top := Vector3(_rng.randf_range(5.0, 8.0), 0.6, _rng.randf_range(5.0, 8.0))
	_make_box(top, Vector3(p.x, p.y + height, p.z), Color(0.5, 0.55, 0.7))
	var run := height * 2.6
	var top_y := height + 0.3
	_make_wedge(Vector3(p.x, p.y, p.z + top.z / 2.0 + run), Vector3(0, 0, -1), run, top_y, 3.0, Color(0.8, 0.65, 0.35))


func _spawn_chest() -> void:
	var c = CHEST.new()
	c.position = _random_pos()
	add_child(c)
