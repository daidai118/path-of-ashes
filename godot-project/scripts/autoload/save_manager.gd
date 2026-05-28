## 存档管理器 - 全局自动加载
## 管理游戏存档、读档、存档槽
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".json"
const MAX_SAVE_SLOTS = 3

# 存档元数据
var save_meta: Dictionary = {}

func _ready() -> void:
	# 确保存档目录存在
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	# 扫描现有存档
	_scan_save_files()

# ============================================================
# 存档操作
# ============================================================

## 保存游戏到指定槽位
func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("无效的存档槽位: " + str(slot))
		return false
	
	var save_data = _collect_save_data()
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("无法创建存档文件: " + save_path)
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	# 更新元数据
	save_meta[slot] = {
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": GameManager.player_stats.play_time if GameManager else 0,
		"level": GameManager.player_stats.level if GameManager else 1,
		"area": GameManager.game_data.current_area if GameManager else "graveyard",
	}
	
	EventBus.game_saved.emit()
	print("游戏已保存到槽位 ", slot)
	return true

## 从指定槽位加载游戏
func load_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("无效的存档槽位: " + str(slot))
		return false
	
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		push_error("存档文件不存在: " + save_path)
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("无法读取存档文件: " + save_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("存档文件格式错误: " + json.get_error_message())
		return false
	
	var save_data = json.data
	_apply_save_data(save_data)
	
	EventBus.game_loaded.emit()
	print("已从槽位 ", slot, " 加载游戏")
	return true

## 删除指定槽位的存档
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
	
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		save_meta.erase(slot)
		print("已删除槽位 ", slot, " 的存档")
		return true
	
	return false

## 检查指定槽位是否有存档
func has_save(slot: int) -> bool:
	return save_meta.has(slot)

## 获取存档元数据
func get_save_meta(slot: int) -> Dictionary:
	return save_meta.get(slot, {})

# ============================================================
# 自动存档
# ============================================================

## 篝火休息时自动存档
func _on_bonfire_rest(bonfire_id: String) -> void:
	save_game(0)  # 自动存档到槽位0

# ============================================================
# 内部方法
# ============================================================

## 收集存档数据
func _collect_save_data() -> Dictionary:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"player_stats": {},
		"game_data": {},
		"world_state": {},
		"inventory": {},
		"skills": {},
	}
	
	if GameManager:
		save_data["player_stats"] = {
			"level": GameManager.player_stats.level,
			"souls": GameManager.player_stats.souls,
			"max_hp": GameManager.player_stats.max_hp,
			"current_hp": GameManager.player_stats.current_hp,
			"max_fp": GameManager.player_stats.max_fp,
			"current_fp": GameManager.player_stats.current_fp,
			"max_stamina": GameManager.player_stats.max_stamina,
			"current_stamina": GameManager.player_stats.current_stamina,
			"vitality": GameManager.player_stats.vitality,
			"endurance": GameManager.player_stats.endurance,
			"strength": GameManager.player_stats.strength,
			"dexterity": GameManager.player_stats.dexterity,
			"faith": GameManager.player_stats.faith,
			"play_time": GameManager.player_stats.play_time,
		}
		
		save_data["game_data"] = {
			"current_area": GameManager.game_data.current_area,
			"last_bonfire": GameManager.game_data.last_bonfire,
			"defeated_bosses": GameManager.game_data.defeated_bosses,
			"discovered_areas": GameManager.game_data.discovered_areas,
			"unlocked_skills": GameManager.game_data.unlocked_skills,
		}
	
	return save_data

## 应用存档数据
func _apply_save_data(save_data: Dictionary) -> void:
	if not GameManager:
		return
	
	# 恢复玩家属性
	var stats = save_data.get("player_stats", {})
	GameManager.player_stats.level = stats.get("level", 1)
	GameManager.player_stats.souls = stats.get("souls", 0)
	GameManager.player_stats.max_hp = stats.get("max_hp", 500)
	GameManager.player_stats.current_hp = stats.get("current_hp", 500)
	GameManager.player_stats.max_fp = stats.get("max_fp", 100)
	GameManager.player_stats.current_fp = stats.get("current_fp", 100)
	GameManager.player_stats.max_stamina = stats.get("max_stamina", 100)
	GameManager.player_stats.current_stamina = stats.get("current_stamina", 100)
	GameManager.player_stats.vitality = stats.get("vitality", 10)
	GameManager.player_stats.endurance = stats.get("endurance", 10)
	GameManager.player_stats.strength = stats.get("strength", 10)
	GameManager.player_stats.dexterity = stats.get("dexterity", 10)
	GameManager.player_stats.faith = stats.get("faith", 10)
	GameManager.player_stats.play_time = stats.get("play_time", 0)
	
	# 恢复游戏数据
	var game = save_data.get("game_data", {})
	GameManager.game_data.current_area = game.get("current_area", "graveyard")
	GameManager.game_data.last_bonfire = game.get("last_bonfire", "graveyard_start")
	GameManager.game_data.defeated_bosses = game.get("defeated_bosses", [])
	GameManager.game_data.discovered_areas = game.get("discovered_areas", ["graveyard"])
	GameManager.game_data.unlocked_skills = game.get("unlocked_skills", ["dodge", "grapple", "slash"])

## 扫描存档文件
func _scan_save_files() -> void:
	for slot in range(MAX_SAVE_SLOTS):
		var save_path = SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
		if FileAccess.file_exists(save_path):
			# 读取元数据
			var file = FileAccess.open(save_path, FileAccess.READ)
			if file:
				var json = JSON.new()
				var error = json.parse(file.get_as_text())
				file.close()
				if error == OK:
					var data = json.data
					save_meta[slot] = {
						"timestamp": data.get("timestamp", 0),
						"play_time": data.get("player_stats", {}).get("play_time", 0),
						"level": data.get("player_stats", {}).get("level", 1),
						"area": data.get("game_data", {}).get("current_area", "graveyard"),
					}
