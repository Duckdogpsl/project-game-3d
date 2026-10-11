extends Node3D
## หีบสมบัติ: เดินชนเพื่อเปิด (เสียทอง) แล้วได้เลือกอัปเกรดแบบหายาก

const CHEST_MODEL: PackedScene = preload("res://assets/models/chest.fbx")
const CHEST_SIZE := 1.6   ## ความกว้างหีบในเกม (เมตร)

var free_chest: bool = false
var opened: bool = false
var _label: Label3D
var _model: Node3D
var _t: float = 0.0


func _ready() -> void:
	add_to_group("chests")
	_model = ModelUtils.create_fitted(CHEST_MODEL, CHEST_SIZE, true)
	add_child(_model)
	rotation.y = randf() * TAU

	# หีบฟรี (จากบอส) มีแสงเรืองสีทอง
	if free_chest:
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.8, 0.2)
		light.light_energy = 2.0
		light.omni_range = 4.0
		light.position.y = 1.2
		add_child(light)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.outline_size = 10
	_label.position.y = 1.6
	add_child(_label)


func _process(delta: float) -> void:
	if opened:
		return
	_t += delta
	var cost := 0 if free_chest else GameState.get_chest_cost()
	_label.text = "FREE CHEST" if free_chest else "Chest: %d gold" % cost
	_label.modulate = Color(1, 0.85, 0.2) if GameState.gold >= cost else Color(1, 0.4, 0.4)
	_label.position.y = 1.6 + sin(_t * 2.0) * 0.08
	var p = GameState.player
	if not is_instance_valid(p):
		return
	if global_position.distance_to(p.global_position) < 2.0 and GameState.spend_gold(cost):
		_open()


func _open() -> void:
	opened = true
	_label.text = "!"
	GameState.open_chest()
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.25, 1.4, 1.25), 0.15)
	tw.tween_property(_model, "scale", Vector3.ZERO, 0.3)
	tw.tween_callback(queue_free)
