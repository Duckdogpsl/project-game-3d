extends Node
## ฐานข้อมูลอัปเกรด (Autoload ชื่อ "UpgradeDB")
## - เพิ่มอาวุธใหม่: สร้างสคริปต์ใน scripts/weapons/ แล้วเพิ่มใน WEAPONS
## - เพิ่มอัปเกรดสเตตัส: เพิ่มรายการใน STAT_UPGRADES (stat ต้องตรงกับชื่อตัวแปรใน PlayerStats)

const WEAPONS := {
	"axe": {
		"name": "Barbarian Axe",
		"desc": "Swings in a 90° arc toward the nearest enemy.",
		"script": preload("res://scripts/weapons/axe_weapon.gd"),
	},
	"magic_bolt": {
		"name": "Magic Bolt",
		"desc": "Fires homing bolts at the nearest enemies.",
		"script": preload("res://scripts/weapons/magic_bolt.gd"),
	},
	"aura": {
		"name": "Holy Aura",
		"desc": "Damages every enemy standing near you.",
		"script": preload("res://scripts/weapons/aura_weapon.gd"),
	},
	"orbit": {
		"name": "Spinning Blades",
		"desc": "Blades orbit around you and slice enemies.",
		"script": preload("res://scripts/weapons/orbit_weapon.gd"),
	},
	"lightning": {
		"name": "Lightning Staff",
		"desc": "Calls lightning on random nearby enemies.",
		"script": preload("res://scripts/weapons/lightning_weapon.gd"),
	},
	"shockwave": {
		"name": "Ground Slam",
		"desc": "Periodic shockwave that knocks enemies back.",
		"script": preload("res://scripts/weapons/shockwave_weapon.gd"),
	},
}

## pct = แสดงเป็นเปอร์เซ็นต์ / int = ปัดเป็นจำนวนเต็ม / weight = โอกาสออก
const STAT_UPGRADES := [
	{"id": "damage", "name": "Power", "stat": "damage_mult", "amount": 0.12, "pct": true, "label": "Damage"},
	{"id": "atk_speed", "name": "Haste", "stat": "attack_speed_mult", "amount": 0.10, "pct": true, "label": "Attack Speed"},
	{"id": "max_hp", "name": "Vitality", "stat": "max_hp", "amount": 20.0, "label": "Max HP"},
	{"id": "move_speed", "name": "Swift Boots", "stat": "move_speed", "amount": 0.6, "label": "Move Speed"},
	{"id": "pickup", "name": "Magnet", "stat": "pickup_range", "amount": 1.0, "label": "Pickup Range"},
	{"id": "area", "name": "Expand", "stat": "area_mult", "amount": 0.12, "pct": true, "label": "Area"},
	{"id": "projectile", "name": "Multishot", "stat": "projectile_bonus", "amount": 1, "int": true, "weight": 0.35, "label": "Projectiles"},
	{"id": "regen", "name": "Regeneration", "stat": "hp_regen", "amount": 0.4, "label": "HP Regen /s"},
	{"id": "armor", "name": "Armor", "stat": "armor", "amount": 1.5, "label": "Armor"},
	{"id": "crit", "name": "Precision", "stat": "crit_chance", "amount": 0.05, "pct": true, "label": "Crit Chance"},
	{"id": "crit_dmg", "name": "Brutality", "stat": "crit_mult", "amount": 0.25, "pct": true, "label": "Crit Damage"},
	{"id": "xp", "name": "Wisdom", "stat": "xp_mult", "amount": 0.10, "pct": true, "label": "XP Gain"},
	{"id": "luck", "name": "Clover", "stat": "luck", "amount": 0.10, "pct": true, "label": "Luck"},
	{"id": "jump", "name": "Spring Legs", "stat": "jump_velocity", "amount": 0.8, "label": "Jump Height", "weight": 0.5},
]

const RARITIES := [
	{"name": "Common", "mult": 1.0, "color": Color(0.8, 0.8, 0.8), "weight": 60.0},
	{"name": "Uncommon", "mult": 1.3, "color": Color(0.35, 0.9, 0.35), "weight": 25.0},
	{"name": "Rare", "mult": 1.7, "color": Color(0.3, 0.6, 1.0), "weight": 10.0},
	{"name": "Epic", "mult": 2.2, "color": Color(0.75, 0.35, 1.0), "weight": 4.0},
	{"name": "Legendary", "mult": 3.0, "color": Color(1.0, 0.65, 0.1), "weight": 1.0},
]

const WEAPON_COLOR := Color(1.0, 0.85, 0.3)


## สร้างอาวุธแล้วใส่ให้ผู้เล่น
func give_weapon(player, id: String) -> void:
	if not WEAPONS.has(id) or player.weapons.has(id):
		return
	var w = WEAPONS[id]["script"].new()
	w.name = id
	w.player = player
	player.add_weapon_node(id, w)


## สุ่มตัวเลือกอัปเกรด (boosted = จากหีบ ได้ของหายากขึ้น)
func roll_choices(player, count: int, boosted: bool = false) -> Array:
	var pool: Array = []
	for id in WEAPONS.keys():
		if player.weapons.has(id):
			var w = player.weapons[id]
			if w.level < w.max_level:
				pool.append({"type": "weapon_up", "id": id, "weight": 1.2})
		elif player.weapons.size() < player.stats.max_weapons:
			pool.append({"type": "weapon_new", "id": id, "weight": 0.8})
	for s in STAT_UPGRADES:
		pool.append({"type": "stat", "data": s, "weight": s.get("weight", 1.0)})

	var picked: Array = []
	while picked.size() < count and not pool.is_empty():
		var idx := _weighted_index(pool)
		picked.append(pool[idx])
		pool.remove_at(idx)

	var luck: float = player.stats.luck
	var result: Array = []
	for p in picked:
		result.append(_build_choice(p, player, luck, boosted))
	return result


func _build_choice(p: Dictionary, player, luck: float, boosted: bool) -> Dictionary:
	var c := p.duplicate()
	match p["type"]:
		"weapon_new":
			var info: Dictionary = WEAPONS[p["id"]]
			c["title"] = info["name"]
			c["rarity_name"] = "NEW WEAPON"
			c["color"] = WEAPON_COLOR
			c["desc"] = info["desc"]
		"weapon_up":
			var w = player.weapons[p["id"]]
			c["title"] = w.display_name
			c["rarity_name"] = "UPGRADE  Lv %d → %d" % [w.level, w.level + 1]
			c["color"] = WEAPON_COLOR
			c["desc"] = w.get_upgrade_desc()
		"stat":
			var s: Dictionary = p["data"]
			var rarity: Dictionary = RARITIES[_roll_rarity(luck, boosted)]
			var value: float = s["amount"] * rarity["mult"]
			if s.get("int", false):
				value = max(1.0, floor(rarity["mult"]))
			c["value"] = value
			c["title"] = s["name"]
			c["rarity_name"] = rarity["name"]
			c["color"] = rarity["color"]
			if s.get("pct", false):
				c["desc"] = "+%d%% %s" % [roundi(value * 100.0), s["label"]]
			elif s.get("int", false):
				c["desc"] = "+%d %s" % [int(value), s["label"]]
			else:
				c["desc"] = "+%s %s" % [str(snappedf(value, 0.1)), s["label"]]
	return c


func apply_choice(player, c: Dictionary) -> void:
	match c["type"]:
		"weapon_new":
			give_weapon(player, c["id"])
		"weapon_up":
			player.weapons[c["id"]].level_up()
		"stat":
			var stat: String = c["data"]["stat"]
			var v: float = c["value"]
			if c["data"].get("int", false):
				player.stats.set(stat, player.stats.get(stat) + int(v))
			else:
				player.stats.set(stat, player.stats.get(stat) + v)
			if stat == "max_hp":
				player.heal(v)


func _roll_rarity(luck: float, boosted: bool) -> int:
	var weights: Array = []
	for i in RARITIES.size():
		var w: float = RARITIES[i]["weight"] * (1.0 + luck * i)
		if boosted:
			w = 0.0 if i == 0 else w * 2.5
		weights.append(w)
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return 0


func _weighted_index(pool: Array) -> int:
	var total := 0.0
	for p in pool:
		total += p["weight"]
	var r := randf() * total
	for i in pool.size():
		r -= pool[i]["weight"]
		if r <= 0.0:
			return i
	return pool.size() - 1
