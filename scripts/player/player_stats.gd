class_name PlayerStats
extends Resource
## สเตตัสของผู้เล่น — ค่าเริ่มต้นของแต่ละตัวละครอยู่ที่ resources/characters/*_stats.tres

@export_group("Survival")
@export var max_hp: float = 100.0
@export var hp_regen: float = 0.0          ## ฟื้นเลือดต่อวินาที
@export var armor: float = 0.0             ## ลดดาเมจที่ได้รับแบบคงที่

@export_group("Movement")
@export var move_speed: float = 8.0
@export var jump_velocity: float = 9.0

@export_group("Offense")
@export var damage_mult: float = 1.0
@export var attack_speed_mult: float = 1.0
@export var area_mult: float = 1.0
@export var projectile_bonus: int = 0
@export var crit_chance: float = 0.05
@export var crit_mult: float = 2.0

@export_group("Utility")
@export var pickup_range: float = 4.0
@export var xp_mult: float = 1.0
@export var luck: float = 0.0
@export var max_weapons: int = 4
