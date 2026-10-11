class_name EnemyData
extends Resource
## ข้อมูลศัตรูแต่ละชนิด — สร้างไฟล์ .tres ใหม่ใน resources/enemies/ เพื่อเพิ่มชนิดศัตรู

@export var enemy_name: String = "Slime"
@export var max_hp: float = 12.0
@export var speed: float = 3.5
@export var damage: float = 6.0
@export var xp_value: float = 1.0
@export var gold_chance: float = 0.08   ## โอกาสดรอปทอง
@export var size: float = 1.0
@export var color: Color = Color(0.4, 0.9, 0.4)
@export var is_boss: bool = false
@export var climb_speed: float = 5.0    ## ความเร็วปีนกำแพง

@export_group("Spawning")
@export var unlock_time: float = 0.0    ## เริ่มเกิดหลังเวลากี่วินาที
@export var spawn_weight: float = 10.0  ## โอกาสเกิดเทียบกับชนิดอื่น
