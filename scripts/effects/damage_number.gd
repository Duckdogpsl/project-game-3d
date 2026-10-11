extends Label3D
## ตัวเลขดาเมจลอยขึ้นแล้วจางหาย

var _life: float = 0.6
var _vel: Vector3 = Vector3.ZERO


func setup(amount: float, crit: bool) -> void:
	text = str(roundi(amount))
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = false
	font_size = 72 if crit else 48
	outline_size = 12
	modulate = Color(1, 0.8, 0.1) if crit else Color.WHITE
	pixel_size = 0.01
	_vel = Vector3(randf_range(-1.0, 1.0), 4.0, randf_range(-1.0, 1.0))


func _process(delta: float) -> void:
	position += _vel * delta
	_vel.y -= 9.0 * delta
	_life -= delta
	var a: float = clamp(_life / 0.3, 0.0, 1.0)
	modulate.a = a
	outline_modulate.a = a
	if _life <= 0.0:
		queue_free()
