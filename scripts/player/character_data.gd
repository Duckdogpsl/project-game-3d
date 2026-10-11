class_name CharacterData
extends Resource
## ข้อมูลตัวละครที่เลือกได้ในหน้าเมนู — เพิ่มตัวละครใหม่โดยสร้าง .tres ใน resources/characters/
## แล้วเพิ่มลงใน CHARACTERS ของ scripts/ui/main_menu.gd

@export var display_name: String = "Hero"
@export_multiline var description: String = ""
@export var model: PackedScene                ## โมเดล 3D (.fbx / .glb)
@export var model_scale: float = 0.9
@export var base_stats: PlayerStats           ## สเตตัสเริ่มต้นของตัวละครนี้
@export var starting_weapon: String = "magic_bolt"
@export var theme_color: Color = Color.WHITE
