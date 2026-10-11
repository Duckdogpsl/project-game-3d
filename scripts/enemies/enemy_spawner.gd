extends Node
## ระบบเกิดศัตรู: ยิ่งนานยิ่งเกิดถี่ เลือดยิ่งเยอะ + บอสทุก boss_interval วินาที

const DEFAULT_TYPES := [
	preload("res://resources/enemies/slime.tres"),
	preload("res://resources/enemies/runner.tres"),
	preload("res://resources/enemies/brute.tres"),
	preload("res://resources/enemies/golem.tres"),
]

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var enemy_types: Array[EnemyData] = []
@export var boss_data: EnemyData = preload("res://resources/enemies/boss.tres")

@export_group("Difficulty")
@export var max_enemies: int = 120
@export var base_spawn_interval: float = 1.6
@export var min_spawn_interval: float = 0.3
@export var spawn_radius_min: float = 22.0
@export var spawn_radius_max: float = 32.0
@export var arena_half_size: float = 95.0
@export var boss_interval: float = 180.0

var _timer: float = 1.0
var _next_boss: float = 0.0


func _ready() -> void:
	if enemy_types.is_empty():
		for t in DEFAULT_TYPES:
			enemy_types.append(t)
	_next_boss = boss_interval


func _physics_process(delta: float) -> void:
	var player = GameState.player
	if GameState.is_game_over or GameState.intro_playing or not is_instance_valid(player):
		return
	var t := GameState.elapsed

	if t >= _next_boss and boss_data:
		_next_boss += boss_interval
		_spawn(boss_data, player.global_position, get_hp_mult(t))
		GameState.boss_spawned.emit(boss_data.enemy_name)

	_timer -= delta
	if _timer > 0.0:
		return
	_timer = get_spawn_interval(t)
	var alive := get_tree().get_nodes_in_group("enemies").size()
	var batch := 1 + int(t / 150.0)
	for i in batch:
		if alive >= max_enemies:
			break
		var d := _pick_type(t)
		if d:
			_spawn(d, player.global_position, get_hp_mult(t))
			alive += 1


## สูตรความยาก — ปรับได้ตรงนี้
func get_spawn_interval(t: float) -> float:
	return max(min_spawn_interval, base_spawn_interval / (1.0 + t / 75.0))


func get_hp_mult(t: float) -> float:
	var m := t / 60.0
	return 1.0 + m * 0.4 + m * m * 0.05


func _pick_type(t: float) -> EnemyData:
	var total := 0.0
	for d in enemy_types:
		if d.unlock_time <= t:
			total += d.spawn_weight
	if total <= 0.0:
		return null
	var r := randf() * total
	for d in enemy_types:
		if d.unlock_time <= t:
			r -= d.spawn_weight
			if r <= 0.0:
				return d
	return enemy_types[0]


func _spawn(d: EnemyData, around: Vector3, hp_mult: float) -> void:
	var a := randf() * TAU
	var r := randf_range(spawn_radius_min, spawn_radius_max)
	var pos := around + Vector3(cos(a) * r, 0.0, sin(a) * r)
	pos.x = clamp(pos.x, -arena_half_size, arena_half_size)
	pos.z = clamp(pos.z, -arena_half_size, arena_half_size)
	var arena = get_tree().get_first_node_in_group("arena")
	pos.y = (arena.get_height_at(pos.x, pos.z) if arena else 0.0) + 1.0
	var e = enemy_scene.instantiate()
	e.data = d
	e.hp_mult = hp_mult
	e.position = pos
	add_child(e)
