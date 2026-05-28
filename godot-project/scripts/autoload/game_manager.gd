## 游戏管理器 - 全局自动加载
## 管理游戏状态、存档、进度
extends Node

## 信号
signal player_died
signal player_respawned
signal bonfire_rest
signal boss_defeated(boss_name: String)
signal area_discovered(area_name: String)

## 游戏状态
enum GameState { MENU, PLAYING, PAUSED, DEAD, DIALOG, CUTSCENE }

var current_state: GameState = GameState.MENU
var player_stats: PlayerStats = PlayerStats.new()
var game_data: GameData = GameData.new()

## 玩家数据类
class PlayerStats:
	var level: int = 1
	var souls: int = 0
	var max_hp: int = 500
	var current_hp: int = 500
	var max_fp: int = 100
	var current_fp: int = 100
	var max_stamina: int = 100
	var current_stamina: int = 100
	var play_time: float = 0.0
	
	## 属性点数
	var vitality: int = 10
	var endurance: int = 10
	var strength: int = 10
	var dexterity: int = 10
	var faith: int = 10
	
	## 装备
	var equipped_weapon: String = "sword_rusty"
	var equipped_skills: Array[String] = ["dodge", "grapple", ""]
	var equipped_amulets: Array[String] = ["", ""]
	
	## 消耗品
	var estus_charges: int = 3
	var max_estus: int = 3

## 游戏数据类
class GameData:
	var current_area: String = "graveyard"
	var last_bonfire: String = "graveyard_start"
	var defeated_bosses: Array[String] = []
	var discovered_areas: Array[String] = ["graveyard"]
	var unlocked_skills: Array[String] = ["dodge", "grapple", "slash"]
	var inventory: Dictionary = {}
	var souls_on_ground: int = 0
	var soul_position: Vector2 = Vector2.ZERO

## 状态管理
func change_state(new_state: GameState) -> void:
	current_state = new_state
	get_tree().paused = (new_state == GameState.PAUSED)

## 玩家死亡
func on_player_death() -> void:
	change_state(GameState.DEAD)
	player_died.emit()
	# 留下灵魂
	game_data.souls_on_ground = player_stats.souls
	game_data.soul_position = Vector2.ZERO  # 需要从玩家获取

## 复活
func respawn() -> void:
	player_stats.current_hp = player_stats.max_hp
	player_stats.current_fp = player_stats.max_fp
	player_stats.current_stamina = player_stats.max_stamina
	player_stats.estus_charges = player_stats.max_estus
	change_state(GameState.PLAYING)
	player_respawned.emit()

## 篝火休息
func rest_at_bonfire(bonfire_id: String) -> void:
	game_data.last_bonfire = bonfire_id
	player_stats.current_hp = player_stats.max_hp
	player_stats.current_fp = player_stats.max_fp
	player_stats.current_stamina = player_stats.max_stamina
	player_stats.estus_charges = player_stats.max_estus
	bonfire_rest.emit()

## 保存游戏
func save_game() -> void:
	var save_data = {
		"player_stats": player_stats_to_dict(),
		"game_data": game_data_to_dict()
	}
	var save_file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(save_data, "\t"))
	save_file.close()

## 加载游戏
func load_game() -> bool:
	if not FileAccess.file_exists("user://save_game.json"):
		return false
	var save_file = FileAccess.open("user://save_game.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(save_file.get_as_text())
	save_file.close()
	var save_data = json.data
	player_stats_from_dict(save_data["player_stats"])
	game_data_from_dict(save_data["game_data"])
	return true

func player_stats_to_dict() -> Dictionary:
	return {
		"level": player_stats.level,
		"souls": player_stats.souls,
		"max_hp": player_stats.max_hp,
		"vitality": player_stats.vitality,
		"endurance": player_stats.endurance,
		"strength": player_stats.strength,
		"dexterity": player_stats.dexterity,
		"faith": player_stats.faith
	}

func game_data_to_dict() -> Dictionary:
	return {
		"current_area": game_data.current_area,
		"last_bonfire": game_data.last_bonfire,
		"defeated_bosses": game_data.defeated_bosses,
		"discovered_areas": game_data.discovered_areas
	}

func player_stats_from_dict(data: Dictionary) -> void:
	player_stats.level = data.get("level", 1)
	player_stats.souls = data.get("souls", 0)
	player_stats.max_hp = data.get("max_hp", 500)
	player_stats.vitality = data.get("vitality", 10)
	player_stats.endurance = data.get("endurance", 10)
	player_stats.strength = data.get("strength", 10)
	player_stats.dexterity = data.get("dexterity", 10)
	player_stats.faith = data.get("faith", 10)

func game_data_from_dict(data: Dictionary) -> void:
	game_data.current_area = data.get("current_area", "graveyard")
	game_data.last_bonfire = data.get("last_bonfire", "graveyard_start")
	game_data.defeated_bosses = data.get("defeated_bosses", [])
	game_data.discovered_areas = data.get("discovered_areas", ["graveyard"])
