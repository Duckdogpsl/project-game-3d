class_name ModelUtils
extends RefCounted
## ตัวช่วยใส่โมเดล 3D (.fbx / .glb / .gltf / .obj) ลงในเกม
## ย่อ/ขยายโมเดลให้ได้ขนาดที่ต้องการและจัดให้อยู่กึ่งกลางอัตโนมัติ
## จึงไม่ต้องสนใจว่าโมเดลถูก export มาด้วยหน่วยหรือ pivot แบบไหน


## สร้างโมเดลจาก PackedScene แล้วห่อด้วย Node3D ที่ปรับขนาดแล้ว
## target_size = ความยาวด้านที่ยาวที่สุด (เมตร)
## align_bottom = true จะวางก้นโมเดลไว้ที่ y = 0 (เหมาะกับของที่ตั้งบนพื้น)
static func create_fitted(scene: PackedScene, target_size: float = 1.0, align_bottom: bool = false) -> Node3D:
	var holder := Node3D.new()
	if scene == null:
		return holder
	var model: Node3D = scene.instantiate()
	holder.add_child(model)
	var box := get_local_aabb(model)
	var longest := box.get_longest_axis_size()
	if longest <= 0.0:
		return holder
	var s := target_size / longest
	model.scale *= s
	model.position = -box.get_center() * s
	if align_bottom:
		model.position.y += box.size.y * 0.5 * s
	return holder


## รวม AABB ของทุก MeshInstance3D ในโมเดล (เทียบกับ root ของโมเดล)
static func get_local_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var xf: Transform3D = item[1]
		if node is MeshInstance3D and node.mesh:
			var box: AABB = xf * node.get_aabb()
			if first:
				result = box
				first = false
			else:
				result = result.merge(box)
		for c in node.get_children():
			if c is Node3D:
				stack.append([c, xf * c.transform])
	return result


## ดึง Mesh ตัวแรกในโมเดล แล้ว "อบ" transform ของโหนด (สเกล/หมุน) ลงในจุดยอดเลย
## ใช้ทำ MultiMesh — โมเดลบางไฟล์ mesh เล็กมากแล้วขยาย 100 เท่า ถ้าไม่อบจะเพี้ยนใน MultiMesh
## คืนค่า [Mesh, Transform3D.IDENTITY] หรือ [] ถ้าไม่เจอ
static func get_first_mesh(scene: PackedScene) -> Array:
	if scene == null:
		return []
	var root: Node3D = scene.instantiate()
	var stack: Array = [[root, Transform3D.IDENTITY]]
	var found: Array = []
	while not stack.is_empty() and found.is_empty():
		var item: Array = stack.pop_front()
		var node: Node = item[0]
		var xf: Transform3D = item[1]
		if node is MeshInstance3D and node.mesh:
			found = [node.mesh, xf]
		for c in node.get_children():
			if c is Node3D:
				stack.append([c, xf * c.transform])
	root.free()
	if found.is_empty():
		return []
	return [bake_mesh(found[0], found[1]), Transform3D.IDENTITY]


## สร้าง ArrayMesh ใหม่ที่จุดยอดถูกแปลงด้วย xf แล้ว
static func bake_mesh(src: Mesh, xf: Transform3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	var nbasis := xf.basis.inverse().transposed()
	for si in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			verts[i] = xf * verts[i]
		arrays[Mesh.ARRAY_VERTEX] = verts
		if arrays[Mesh.ARRAY_NORMAL] != null:
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in normals.size():
				normals[i] = (nbasis * normals[i]).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
		if arrays[Mesh.ARRAY_TANGENT] != null:
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			for i in range(0, tangents.size(), 4):
				var t := (xf.basis * Vector3(tangents[i], tangents[i + 1], tangents[i + 2])).normalized()
				tangents[i] = t.x
				tangents[i + 1] = t.y
				tangents[i + 2] = t.z
			arrays[Mesh.ARRAY_TANGENT] = tangents
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(si, src.surface_get_material(si))
	return out
