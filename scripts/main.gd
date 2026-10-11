extends Node3D
## ฉากหลัก: รีเซ็ตสถานะเกมทุกครั้งที่เริ่ม/เริ่มใหม่


func _enter_tree() -> void:
	GameState.reset()   # ต้องรันก่อน Player._ready()


func _ready() -> void:
	get_tree().paused = false
