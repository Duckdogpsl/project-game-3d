extends Area3D
## กระสุนทั่วไป: บินตรง ชนศัตรูแล้วทำดาเมจผ่าน weapon.deal_damage()

var velocity: Vector3 = Vector3.ZERO
var weapon = null
var damage_mult: float = 1.0
var pierce: int = 0
var lifetime: float = 2.0
var _hit: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if _hit.has(body) or body.dead:
			return
		_hit[body] = true
		if is_instance_valid(weapon):
			weapon.deal_damage(body, damage_mult)
		if pierce <= 0:
			queue_free()
		else:
			pierce -= 1
	elif body is StaticBody3D:
		queue_free()
