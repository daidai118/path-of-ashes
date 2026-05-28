## 技能基类
## 所有技能继承此类，提供通用的技能行为框架
class_name SkillBase
extends Node

# ============================================================
# 信号
# ============================================================
signal skill_activated
signal skill_completed
signal cooldown_started(duration: float)
signal cooldown_ended

# ============================================================
# 导出变量
# ============================================================
@export_group("Skill Info")
@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_icon: Texture2D

@export_group("Cost")
@export var focus_cost: float = 0.0
@export var stamina_cost: float = 0.0
@export var hp_cost: float = 0.0

@export_group("Cooldown")
@export var cooldown: float = 1.0
@export var cooldown_reduction_per_level: float = 0.0

@export_group("Upgrade")
@export var max_level: int = 3
@export var current_level: int = 1

# ============================================================
# 状态
# ============================================================
var current_cooldown: float = 0.0
var is_ready: bool = true
var is_active: bool = false

# ============================================================
# 升级分支
# ============================================================
enum UpgradeBranch { COMBAT, EXPLORATION, SPECIAL }
var unlocked_branches: Array[UpgradeBranch] = []

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_init_skill()

func _process(delta: float) -> void:
	# 更新冷却
	if not is_ready:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0.0
			is_ready = true
			cooldown_ended.emit()

# ============================================================
# 初始化（子类重写）
# ============================================================
func _init_skill() -> void:
	pass

# ============================================================
# 激活技能
# ============================================================
## 激活技能，返回是否成功
func activate(caster: Node2D, direction: Vector2 = Vector2.ZERO) -> bool:
	if not is_ready:
		return false
	
	if is_active:
		return false
	
	# 检查资源
	if not _check_resources(caster):
		return false
	
	# 消耗资源
	_consume_resources(caster)
	
	# 执行技能
	is_active = true
	_execute(caster, direction)
	skill_activated.emit()
	
	# 开始冷却
	_start_cooldown()
	
	return true

## 检查资源是否足够
func _check_resources(caster: Node2D) -> bool:
	if focus_cost > 0 and caster.has_method("get_focus"):
		if caster.get_focus() < focus_cost:
			return false
	
	if stamina_cost > 0 and caster.has_method("get_stamina"):
		if caster.get_stamina() < stamina_cost:
			return false
	
	if hp_cost > 0 and caster.has_method("get_hp"):
		if caster.get_hp() <= hp_cost:  # 不能消耗到死亡
			return false
	
	return true

## 消耗资源
func _consume_resources(caster: Node2D) -> void:
	if focus_cost > 0 and caster.has_method("consume_focus"):
		caster.consume_focus(focus_cost)
	
	if stamina_cost > 0 and caster.has_method("consume_stamina"):
		caster.consume_stamina(stamina_cost)
	
	if hp_cost > 0 and caster.has_method("take_damage"):
		caster.take_damage(hp_cost, Vector2.ZERO)

## 执行技能（子类必须重写）
func _execute(caster: Node2D, direction: Vector2) -> void:
	push_warning("SkillBase._execute() 未被重写")

## 完成技能
func _complete() -> void:
	is_active = false
	skill_completed.emit()

# ============================================================
# 冷却
# ============================================================
func _start_cooldown() -> void:
	is_ready = false
	current_cooldown = cooldown * (1.0 - cooldown_reduction_per_level * (current_level - 1))
	cooldown_started.emit(current_cooldown)

## 获取冷却进度（0.0 - 1.0）
func get_cooldown_progress() -> float:
	if is_ready:
		return 1.0
	return 1.0 - (current_cooldown / cooldown)

# ============================================================
# 升级
# ============================================================
## 升级技能
func upgrade() -> bool:
	if current_level >= max_level:
		return false
	
	current_level += 1
	_on_level_up()
	return true

## 解锁升级分支
func unlock_branch(branch: UpgradeBranch) -> void:
	if not branch in unlocked_branches:
		unlocked_branches.append(branch)
		_on_branch_unlocked(branch)

## 升级时调用（子类重写）
func _on_level_up() -> void:
	pass

## 分支解锁时调用（子类重写）
func _on_branch_unlocked(branch: UpgradeBranch) -> void:
	pass

# ============================================================
# 查询
# ============================================================
## 获取技能信息
func get_info() -> Dictionary:
	return {
		"id": skill_id,
		"name": skill_name,
		"description": skill_description,
		"icon": skill_icon,
		"level": current_level,
		"max_level": max_level,
		"focus_cost": focus_cost,
		"stamina_cost": stamina_cost,
		"hp_cost": hp_cost,
		"cooldown": cooldown,
		"is_ready": is_ready,
		"cooldown_progress": get_cooldown_progress(),
	}

## 是否可以升级
func can_upgrade() -> bool:
	return current_level < max_level

## 获取当前等级的效果倍率
func get_level_multiplier() -> float:
	return 1.0 + (current_level - 1) * 0.2  # 每级+20%
