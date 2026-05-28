## 关卡基类
## 所有关卡继承此类，提供通用的关卡管理框架
class_name LevelBase
extends Node2D

# ============================================================
# 信号
# ============================================================
signal level_loaded
signal level_completed
signal all_enemies_defeated

# ============================================================
# 导出变量
# ============================================================
@export_group("Level Info")
@export var level_id: String = ""
@export var level_name: String = ""
@export var level_description: String = ""

@export_group("Settings")
@export var auto_save_on_bonfire: bool = true
@export var reset_enemies_on_bonfire: bool = true

# ============================================================
# 节点引用
# ============================================================
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D if has_node("Player/Camera2D") else null
@onready var enemies_container: Node2D = $Enemies if has_node("Enemies") else null
@onready var bonfires_container: Node2D = $Bonfires if has_node("Bonfires") else null
@onready var puzzles_container: Node2D = $Puzzles if has_node("Puzzles") else null
@onready var collectibles_container: Node2D = $Collectibles if has_node("Collectibles") else null
@onready var triggers_container: Node2D = $Triggers if has_node("Triggers") else null

# ============================================================
# 状态
# ============================================================
var is_level_loaded: bool = false
var enemies_defeated: int = 0
var total_enemies: int = 0
var discovered_bonfires: Array[String] = []

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_init_level()
	_connect_signals()
	_load_player_position()
	
	is_level_loaded = true
	level_loaded.emit()

# ============================================================
# 初始化
# ============================================================
func _init_level() -> void:
	# 设置GameManager状态
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)
		GameManager.game_data.current_area = level_id
	
	# 统计敌人数量
	if enemies_container:
		total_enemies = enemies_container.get_child_count()
	
	# 初始化篝火
	_init_bonfires()
	
	# 初始化敌人
	_init_enemies()
	
	# 初始化机关
	_init_puzzles()
	
	# 初始化收集品
	_init_collectibles()
	
	# 初始化触发器
	_init_triggers()

func _init_bonfires() -> void:
	if not bonfires_container:
		return
	
	for bonfire in bonfires_container.get_children():
		if bonfire.has_signal("bonfire_rest"):
			bonfire.bonfire_rest.connect(_on_bonfire_rest)
		if bonfire.has_signal("bonfire_activated"):
			bonfire.bonfire_activated.connect(_on_bonfire_activated)

func _init_enemies() -> void:
	if not enemies_container:
		return
	
	for enemy in enemies_container.get_children():
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

func _init_puzzles() -> void:
	# 子类可重写以初始化机关
	pass

func _init_collectibles() -> void:
	if not collectibles_container:
		return
	
	for collectible in collectibles_container.get_children():
		if collectible.has_signal("collected"):
			collectible.collected.connect(_on_collectible_collected)

func _init_triggers() -> void:
	if not triggers_container:
		return
	
	for trigger in triggers_container.get_children():
		if trigger.has_signal("triggered"):
			trigger.triggered.connect(_on_trigger_triggered)

# ============================================================
# 信号连接
# ============================================================
func _connect_signals() -> void:
	# 连接玩家信号
	if player:
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)

# ============================================================
# 玩家位置
# ============================================================
func _load_player_position() -> void:
	if not player or not GameManager:
		return
	
	# 如果有存档，传送到最后的篝火
	var last_bonfire = GameManager.game_data.last_bonfire
	if last_bonfire and bonfires_container:
		for bonfire in bonfires_container.get_children():
			if bonfire.has_method("get_bonfire_id") and bonfire.get_bonfire_id() == last_bonfire:
				player.global_position = bonfire.get_respawn_position()
				break

# ============================================================
# 信号回调
# ============================================================
func _on_player_died() -> void:
	if GameManager:
		GameManager.on_player_death()

func _on_enemy_died(souls: int) -> void:
	enemies_defeated += 1
	
	# 更新玩家灵魂
	if GameManager:
		GameManager.player_stats.souls += souls
		EventBus.enemy_died.emit("", souls)
	
	# 检查是否所有敌人被击败
	if enemies_defeated >= total_enemies:
		all_enemies_defeated.emit()
		_on_all_enemies_defeated()

func _on_bonfire_rest(bonfire_id: String) -> void:
	# 记录篝火
	if not bonfire_id in discovered_bonfires:
		discovered_bonfires.append(bonfire_id)
	
	# 重置敌人
	if reset_enemies_on_bonfire:
		_reset_enemies()
	
	# 自动存档
	if auto_save_on_bonfire and SaveManager:
		SaveManager.save_game()
	
	# 发送事件
	EventBus.bonfire_rest.emit(bonfire_id)

func _on_bonfire_activated(bonfire_id: String) -> void:
	if not bonfire_id in discovered_bonfires:
		discovered_bonfires.append(bonfire_id)
	EventBus.bonfire_lit.emit(bonfire_id)

func _on_collectible_collected(item_id: String, quantity: int) -> void:
	EventBus.item_acquired.emit(item_id, quantity)

func _on_trigger_triggered(trigger_id: String) -> void:
	# 子类可重写以处理触发器
	pass

func _on_all_enemies_defeated() -> void:
	# 子类可重写以处理所有敌人被击败
	pass

# ============================================================
# 敌人管理
# ============================================================
func _reset_enemies() -> void:
	if not enemies_container:
		return
	
	for enemy in enemies_container.get_children():
		if enemy.has_method("reset"):
			enemy.reset()
	
	enemies_defeated = 0

func get_remaining_enemies() -> int:
	return total_enemies - enemies_defeated

# ============================================================
# 关卡完成
# ============================================================
func complete_level() -> void:
	level_completed.emit()
	
	# 子类可重写以处理关卡完成逻辑

# ============================================================
# 暂停
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	if not GameManager:
		return
	
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.change_state(GameManager.GameState.PAUSED)
		EventBus.game_paused.emit()
	elif GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.change_state(GameManager.GameState.PLAYING)
		EventBus.game_resumed.emit()

# ============================================================
# 查询
# ============================================================
func get_level_info() -> Dictionary:
	return {
		"id": level_id,
		"name": level_name,
		"description": level_description,
		"enemies_defeated": enemies_defeated,
		"total_enemies": total_enemies,
		"discovered_bonfires": discovered_bonfires,
	}
