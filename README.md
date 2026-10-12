
กานต์ อุดมศรี 673380610-7
สิทธินนท์ ผายพันธ์ 673380644-0
นิธิวัฒน์ บ่อคุ้ม 673380631-9
กษิดิศ กุมพล 673380619-9



# Dawnbreaker Knight ⚔️🌅

เกม Roguelike Survivor 3D ทำด้วย **Godot 4.3+** (GDScript ล้วน) — ผู้เล่นต้องเอาชีวิตรอดจากฝูงมอนให้ครบ 10 นาที

## วิธีเปิด
1. ดาวน์โหลด Godot 4.3 ขึ้นไป (เวอร์ชันมาตรฐาน ไม่ใช่ .NET ก็ได้)
2. Godot → **Import** → เลือกไฟล์ `project.godot`
3. กด **F5** → หน้าเมนู → **PLAY** → เลือกตัวละคร

## การควบคุม
| ปุ่ม | การทำงาน |
|---|---|
| WASD / ลูกศร | เดิน |
| เมาส์ | หมุนกล้อง |
| Space (กดค้าง) | กระโดด / Bunny hop อัตโนมัติ (ความเร็วเพิ่มทุกครั้งที่ลงพื้นแล้วกระโดดทันที) |
| Shift / Ctrl | สไลด์ (ไถลลงเนินจะเร็วขึ้นมาก) |
| 1 / 2 / 3 | เลือกการ์ดอัปเกรด |
| Esc / P / ปุ่ม PAUSE มุมขวาบน | หยุดเกม (เกมหยุดเองเมื่อสลับหน้าต่าง) |

## คัตซีนเปิดเกม
จอดำ → ข้อความเนื้อเรื่อง 3 ประโยค → กล้องควงสว่านลงจากฟ้ามาหยุดหลังตัวละคร → เปิด HUD และเริ่มนับเวลา
(ระหว่างคัตซีน: ซ่อน HUD, ล็อกการควบคุม, ไม่เกิดมอน, ไม่นับเวลา) — กด **Enter** หรือ **Esc** เพื่อข้าม
- แก้ข้อความ → `LINES` ใน `scripts/ui/intro_cutscene.gd`
- ปรับเวลา/กล้อง/ปิดคัตซีน → โหนด `IntroCutscene` ใน `main.tscn` (`line_hold`, `sky_height`, `spiral_turns`, `descent_time`, `enabled`)
- ฟอนต์ไทย Kanit อยู่ที่ `assets/fonts/` (สัญญาอนุญาต SIL OFL — ใช้ในเกมได้ฟรี)

## ตัวละคร
| ตัวละคร | จุดเด่น | อาวุธเริ่มต้น |
|---|---|---|
| Barbarian | HP 130, เกราะ 2, ฟื้นเลือดช้าๆ | ขวาน — หันไปหามอนที่ใกล้สุดแล้วฟันวงโค้ง 90° โดนทุกตัวในวง + กระเด็น |
| Mage | HP 85, เร็วกว่า, ตีเร็วกว่า | Magic Bolt — ยิงกระสุนเวทใส่มอนที่ใกล้สุด |

## ระบบในเกม
- อาวุธยิงเองอัตโนมัติ 6 แบบ: Barbarian Axe, Magic Bolt, Holy Aura, Spinning Blades, Lightning Staff, Ground Slam (ถือได้สูงสุด 4)
- เก็บเพชร XP → เลเวลอัป → เลือก 1 จาก 3 การ์ด (มีระดับ Common → Legendary, ค่า Luck เพิ่มโอกาสของหายาก)
- ศัตรูดรอปทอง → เดินชนหีบเพื่อเปิด (ได้การ์ดระดับสูงขึ้น, ราคาเพิ่มทุกครั้ง)
- พื้นทั้งแมพปูกระเบื้อง แบ่งเป็นช่อง 4×4 ม. สูง 4 ระดับ (0 / 1.5 / 3 / 4.5 ม.) สีต่างกันตามระดับ — กระโดดขึ้นทีละระดับได้ หรือใช้ทางลาด
- มอนปีนกำแพง/หน้าผาได้ — ขึ้นไปหลบบนเนินก็ยังตามมา
- บอสทุก 3 นาที (ฆ่าแล้วได้หีบฟรี), ไอเทม Magnet และ Heal ดรอปสุ่ม
- รอดครบ 10 นาที = ชนะ

## โครงสร้างไฟล์
```
project.godot
scenes/
  main_menu.tscn           หน้าเมนู + เลือกตัวละคร (ฉากแรก)
  main.tscn                ฉากหลัก (ประกอบทุกส่วนเข้าด้วยกัน)
  player.tscn              ตัวผู้เล่น + กล้อง (โมเดลโหลดตามตัวละครที่เลือก)
  enemy.tscn               ศัตรู (ใช้ร่วมกันทุกชนิด)
  weapons/projectile.tscn  กระสุน
assets/models/
  magnet.fbx               โมเดลไอเทม Magnet
  healing_potion.glb       โมเดลไอเทม Heal (ขวดยา)
  axe.fbx                  โมเดลขวาน (ถือในมือ Barbarian + ตอนฟัน)
  chest.fbx                โมเดลหีบสมบัติ
  environment/wall.glb     โมเดลกำแพง (กำแพงรอบแมพ, กำแพงกลางแมพ, ผนังเนิน)
  environment/floor_tile.glb  โมเดลกระเบื้อง (พื้นทั้งแมพ)
  characters/barbarian.fbx, mage.fbx  โมเดลตัวละคร
resources/
  characters/barbarian.tres, mage.tres          ข้อมูลตัวละคร (ชื่อ, โมเดล, อาวุธเริ่มต้น)
  characters/barbarian_stats.tres, mage_stats.tres  สเตตัสเริ่มต้นของแต่ละตัว
  enemies/*.tres             ข้อมูลศัตรูแต่ละชนิด (slime, runner, brute, golem, boss)
scripts/
  main.gd
  autoload/game_state.gd   XP / เลเวล / ทอง / เวลา / ปุ่มควบคุม / สูตร XP
  autoload/upgrade_db.gd   รายการอาวุธ + การ์ดอัปเกรด + ระดับความหายาก
  player/player.gd         การเคลื่อนที่ สไลด์ bhop เลือด
  player/player_stats.gd   คลาส PlayerStats
  player/character_data.gd คลาส CharacterData
  weapons/weapon_base.gd   คลาสแม่ของอาวุธ (ดาเมจ, คริ, หาศัตรู)
  weapons/axe_weapon.gd    ขวาน Barbarian (ปรับมุมได้ที่ arc_degrees)
  weapons/magic_bolt.gd, aura_weapon.gd, orbit_weapon.gd,
          lightning_weapon.gd, shockwave_weapon.gd, projectile.gd
  enemies/enemy.gd         AI ศัตรู ดาเมจ การดรอปของ
  enemies/enemy_data.gd    คลาส EnemyData
  enemies/enemy_spawner.gd อัตราเกิด / ความยากตามเวลา / บอส
  pickups/xp_gem.gd, powerup.gd, chest.gd
  effects/damage_number.gd ตัวเลขดาเมจลอย
  utils/model_utils.gd     ปรับขนาด/จัดกึ่งกลางโมเดล 3D อัตโนมัติ
  world/arena.gd           สร้างแมพแบบสุ่ม (พื้นกระเบื้องต่างระดับ หน้าผา ทางลาด กำแพง หิน แพลตฟอร์ม หีบ แสง)
  ui/intro_cutscene.gd     คัตซีนเปิดเกม (ข้อความ + กล้องควงสว่าน)
  ui/main_menu.gd          หน้าเมนู / เลือกตัวละคร (พรีวิวโมเดล 3D หมุนได้)
  ui/hud.gd, level_up_ui.gd, pause_menu.gd, game_over_ui.gd, ui_utils.gd
```

## วิธีแก้ไข/ต่อยอดที่พบบ่อย
- **ปรับความรู้สึกการเคลื่อนที่** → เลือกโหนด `Player` ใน `player.tscn` แล้วแก้ค่าในหมวด *Movement Feel* ใน Inspector (`step_height` = ความสูงขอบที่ก้าวข้ามได้อัตโนมัติ)
- **ปรับสเตตัสตัวละคร** → ดับเบิลคลิก `resources/characters/xxx_stats.tres`
- **เพิ่มตัวละครใหม่** → วางโมเดลใน `assets/models/characters/`, คัดลอก `mage.tres` + `mage_stats.tres` แล้วแก้ค่า, เพิ่มลงใน `CHARACTERS` ใน `scripts/ui/main_menu.gd` (แอนิเมชันแขนจะทำงานถ้าชื่อชิ้นส่วนมีคำว่า ArmLeft / ArmRight)
- **เพิ่มศัตรูชนิดใหม่** → คัดลอกไฟล์ใน `resources/enemies/` แก้ค่า แล้วลากใส่ `Enemy Types` ของโหนด `EnemySpawner` (หรือเพิ่มใน `DEFAULT_TYPES` ใน `enemy_spawner.gd`)
- **ปรับแมพ** → โหนด `Arena` ใน `main.tscn`: `tier_height` (สูงต่อระดับ), `max_level`, `noise_frequency` (เนินใหญ่/เล็ก), `level_thresholds` (สัดส่วนพื้นสูง), `level_colors`, `ramp_chance`, `inner_wall_count`, `draw_distance` (ลดถ้าเครื่องช้า), `world_seed` (ใส่ตัวเลขเพื่อให้แมพเหมือนเดิมทุกครั้ง)
- **ปรับการปีนของมอน** → `climb_speed` ในไฟล์ `resources/enemies/*.tres` (ใส่ 0 = ปีนไม่ได้)
- **ปรับจำนวนมอน** → ค่า `max_enemies` (ตอนนี้ 120), `base_spawn_interval` (1.6 วิ), `min_spawn_interval` (0.3 วิ) ในโหนด `EnemySpawner`
- **ปรับความยาก** → `get_spawn_interval()` และ `get_hp_mult()` ใน `enemy_spawner.gd`, ค่า `max_enemies`, `boss_interval`
- **เพิ่มอาวุธใหม่**
  1. สร้าง `scripts/weapons/my_weapon.gd` ที่ `extends WeaponBase`
  2. ตั้งค่าใน `_init()` (weapon_id, display_name, base_damage, base_cooldown) และเขียน `attack()`
  3. เพิ่มรายการใน `WEAPONS` ใน `upgrade_db.gd`
- **เพิ่มการ์ดสเตตัส** → เพิ่มบรรทัดใน `STAT_UPGRADES` (ช่อง `stat` ต้องตรงกับชื่อตัวแปรใน `PlayerStats`)
- **เปลี่ยนอาวุธเริ่มต้น** → ค่า `Starting Weapon` ในไฟล์ตัวละคร .tres (เช่น `axe`, `magic_bolt`, `aura`, `orbit`, `lightning`, `shockwave`)
- **เปลี่ยนเวลาชนะ** → `run_duration` ใน `game_state.gd`
- **เปลี่ยนโมเดลขวาน/หีบ** → แก้ `AXE_MODEL` ใน `axe_weapon.gd` และ `CHEST_MODEL` ใน `chest.gd` (ปรับท่าถือขวานได้ที่ `_ready()` ของ `axe_weapon.gd`)
- **เปลี่ยนโมเดลไอเทม** → วางไฟล์ใหม่ใน `assets/models/` แล้วแก้ `MAGNET_MODEL` / `HEAL_MODEL` ใน `scripts/pickups/powerup.gd` (ขนาดปรับอัตโนมัติ, ปรับได้ที่ `model_size`)
- **ใช้โมเดลกับวัตถุอื่น** → `ModelUtils.create_fitted(preload("res://assets/models/xxx.fbx"), ขนาดเมตร)` จะได้ Node3D ที่พร้อมใส่ในฉาก
- **เปลี่ยนโมเดลศัตรู** → แทนที่ MeshInstance3D ใน `enemy.tscn` ด้วยโมเดลของคุณ

## Physics Layers
1 = world, 2 = player, 3 = enemies (กระสุนตรวจ layer 1+3)
