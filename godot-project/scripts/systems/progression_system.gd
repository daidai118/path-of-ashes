## 进度系统
## 管理玩家升级、属性分配、技能升级
class_name ProgressionSystem
extends Node

# ============================================================
# 信号
# ============================================================
signal level_up(new_level: int)
signal stat_increased(stat_name: String, new_value: int)
signal skill_upgraded(skill_id: String, new_level: int)
signal insufficient_souls(required: int, available: int)

# ============================================================
# 属性定义
# ============================================================
enum Stat { VITALITY, ENDURANCE, STRENGTH, DEXTERITY, FAITH }

const STAT_NAMES = {
	Stat.VITALITY: "vitality",
	Stat.ENDURANCE: "endurance",
	Stat.STRENGTH: "strength",
	Stat.DEXTERITY: "dexterity",
	Stat.FAITH: "faith",
}

const STAT_DESCRIPTIONS = {
	Stat.VITALITY: "增加最大生命值",
	Stat.ENDURANCE: "增加最大体力值",
	Stat.STRENGTH: "增加物理伤害",
	Stat.DEXTERITY: "增加攻击速度和翻滚距离",
	Stat.FAITH: "增加技能效果",
}

# ============================================================
# 升级消耗表
# ============================================================
var level_up_costs: Dictionary = {}

func _ready() -> void:
	_init_level_up_costs()

func _init_level_up_costs() -> void:
	# 生成升级消耗表
	for level in range(1, 100):
		level_up_costs[level] = _calculate_level_up_cost(level)

func _calculate_level_up_cost(level: int) -> int:
	# 升级消耗公式
	if level <= 10:
		return 100 + (level - 1) * 50
	elif level <= 20:
		return 600 + (level - 10) * 100
	elif level <= 30:
		return 1600 + (level - 20) * 200
	elif level <= 40:
		return 3600 + (level - 30) * 300
	else:
		return 6600 + (level - 40) * 400

# ============================================================
# 升级操作
# ============================================================
## 获取升级所需灵魂
func get_level_up_cost(current_level: int) -> int:
	return level_up_costs.get(current_level, 99999)

## 检查是否可以升级
func can_level_up() -> bool:
	if not GameManager:
		return false
	
	var current_level = GameManager.player_stats.level
	var cost = get_level_up_cost(current_level)
	return GameManager.player_stats.souls >= cost

## 执行升级
func level_up_player() -> bool:
	if not GameManager:
		return false
	
	var current_level = GameManager.player_stats.level
	var cost = get_level_up_cost(current_level)
	
	# 检查灵魂
	if GameManager.player_stats.souls < cost:
		insufficient_souls.emit(cost, GameManager.player_stats.souls)
		return false
	
	# 扣除灵魂
	GameManager.player_stats.souls -= cost
	
	# 提升等级
	GameManager.player_stats.level = current_level + 1
	
	# 恢复状态
	GameManager.player_stats.current_hp = GameManager.player_stats.max_hp
	GameManager.player_stats.current_fp = GameManager.player_stats.max_fp
	GameManager.player_stats.current_stamina = GameManager.player_stats.max_stamina
	
	level_up.emit(GameManager.player_stats.level)
	EventBus.player_leveled_up.emit(GameManager.player_stats.level)
	
	return true

# ============================================================
# 属性分配
# ============================================================
## 增加属性点
func increase_stat(stat: Stat) -> bool:
	if not GameManager:
		return false
	
	var stat_name = STAT_NAMES[stat]
	var current_value = GameManager.player_stats.get(stat_name)
	
	# 检查硬上限
	if current_value >= 50:
		return false
	
	# 增加属性
	GameManager.player_stats.set(stat_name, current_value + 1)
	
	# 应用属性效果
	_apply_stat_bonus(stat, current_value + 1)
	
	stat_increased.emit(stat_name, current_value + 1)
	return true

## 应用属性效果
func _apply_stat_bonus(stat: Stat, new_value: int) -> void:
	match stat:
		Stat.VITALITY:
			# 增加最大生命值
			var old_max_hp = GameManager.player_stats.max_hp
			GameManager.player_stats.max_hp = 500 + (new_value - 10) * 25
			# 同步当前HP
			GameManager.player_stats.current_hp += (GameManager.player_stats.max_hp - old_max_hp)
		
		Stat.ENDURANCE:
			# 增加最大体力值
			GameManager.player_stats.max_stamina = 100 + (new_value - 10) * 5
		
		Stat.STRENGTH:
			# 增加物理伤害（在伤害计算时使用）
			pass
		
		Stat.DEXTERITY:
			# 增加攻击速度和翻滚距离（在相应系统中使用）
			pass
		
		Stat.FAITH:
			# 增加最大专注值和技能效果
			GameManager.player_stats.max_fp = 100 + (new_value - 10) * 3

## 获取属性收益描述
func get_stat_bonus_description(stat: Stat) -> String:
	match stat:
		Stat.VITALITY:
			return "+25 最大生命值"
		Stat.ENDURANCE:
			return "+5 最大体力值"
		Stat.STRENGTH:
			return "+3% 物理伤害"
		Stat.DEXTERITY:
			return "+2% 攻击速度"
		Stat.FAITH:
			return "+3 最大专注值，+3% 技能效果"
	return ""

## 获取属性软上限信息
func get_stat_soft_cap_info(stat: Stat) -> Dictionary:
	var current_value = GameManager.player_stats.get(STAT_NAMES[stat])
	
	if current_value < 40:
		return {"phase": "normal", "multiplier": 1.0, "description": "正常收益"}
	elif current_value < 50:
		return {"phase": "soft_cap", "multiplier": 0.5, "description": "收益递减"}
	else:
		return {"phase": "hard_cap", "multiplier": 0.25, "description": "收益极低"}

# ============================================================
# 技能升级
# ============================================================
## 升级技能
func upgrade_skill(skill_id: String) -> bool:
	# TODO: 实现技能升级逻辑
	# 需要与技能系统配合
	return false

## 获取技能升级成本
func get_skill_upgrade_cost(skill_id: String, current_level: int) -> int:
	# 技能升级成本
	match current_level:
		1:
			return 100
		2:
			return 200
		3:
			return 400
		_:
			return 999999

# ============================================================
# 查询
# ============================================================
func get_player_stats() -> Dictionary:
	if not GameManager:
		return {}
	
	return {
		"level": GameManager.player_stats.level,
		"souls": GameManager.player_stats.souls,
		"vitality": GameManager.player_stats.vitality,
		"endurance": GameManager.player_stats.endurance,
		"strength": GameManager.player_stats.strength,
		"dexterity": GameManager.player_stats.dexterity,
		"faith": GameManager.player_stats.faith,
		"max_hp": GameManager.player_stats.max_hp,
		"max_fp": GameManager.player_stats.max_fp,
		"max_stamina": GameManager.player_stats.max_stamina,
	}

func get_level_up_info() -> Dictionary:
	if not GameManager:
		return {}
	
	var current_level = GameManager.player_stats.level
	var cost = get_level_up_cost(current_level)
	var can_upgrade = GameManager.player_stats.souls >= cost
	
	return {
		"current_level": current_level,
		"cost": cost,
		"can_upgrade": can_upgrade,
		"available_souls": GameManager.player_stats.souls,
	}

func get_all_stats_info() -> Array[Dictionary]:
	var stats: Array[Dictionary] = []
	
	for stat in Stat.values():
		var stat_name = STAT_NAMES[stat]
		var current_value = GameManager.player_stats.get(stat_name)
		var cap_info = get_stat_soft_cap_info(stat)
		
		stats.append({
			"stat": stat,
			"name": stat_name,
			"value": current_value,
			"description": STAT_DESCRIPTIONS[stat],
			"bonus_description": get_stat_bonus_description(stat),
			"cap_info": cap_info,
		})
	
	return stats
