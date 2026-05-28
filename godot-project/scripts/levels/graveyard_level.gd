## 初始墓地关卡
## 垂直切片关卡，包含教程、战斗、篝火、Boss
extends Node2D

## 导出变量
@export var level_name: String = "初始墓地"
@export var level_id: String = "graveyard_01"

## 节点引用
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: CanvasLayer = $PlayerHUD
@onready var enemies_container: Node2D = $Enemies
@onready var bonfires_container: Node2D = $Bonfires
@onready var props_container: Node2D = $Props
@onready var puzzles_container: Node2D = $Puzzles
@onready var pause_menu: Control = $PauseMenu

## 关卡状态
var is_level_loaded: bool = false
var enemies_defeated: int = 0
var total_enemies: int = 0

func _ready() -> void:
	# 设置GameManager状态
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)
		GameManager.game_data.current_area = level_id
	
	# 初始化关卡
	_init_level()
	
	# 连接信号
	_connect_signals()
	
	# 加载存档位置
	_load_player_position()
	
	is_level_loaded = true

func _init_level() -> void:
	# 统计敌人数量
	total_enemies = enemies_container.get_child_count()
	
	# 初始化篝火
	for bonfire in bonfires_container.get_children():
		if bonfire.has_signal("bonfire_rest"):
			bonfire.bonfire_rest.connect(_on_bonfire_rest)
	
	# 初始化敌人
	for enemy in enemies_container.get_children():
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)
	
	# 初始化机关谜题
	_init_puzzles()

func _connect_signals() -> void:
	# 连接玩家信号
	if player:
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)

func _init_puzzles() -> void:
	# 连接拉杆和门
	var lever1 = puzzles_container.get_node_or_null("Lever1")
	var gate1 = puzzles_container.get_node_or_null("Gate1")
	
	if lever1 and gate1:
		if lever1.has_method("connect_object"):
			lever1.connect_object(gate1)

func _load_player_position() -> void:
	# 如果有存档，传送到最后的篝火
	if GameManager and GameManager.game_data.last_bonfire:
		var bonfire_id = GameManager.game_data.last_bonfire
		for bonfire in bonfires_container.get_children():
			if bonfire.has_method("get_bonfire_id") and bonfire.get_bonfire_id() == bonfire_id:
				player.global_position = bonfire.get_respawn_position()
				break

func _on_player_died() -> void:
	# 玩家死亡处理
	if GameManager:
		GameManager.on_player_death()

func _on_enemy_died(souls: int) -> void:
	enemies_defeated += 1
	
	# 更新玩家灵魂
	if GameManager:
		GameManager.player_stats.souls += souls
	
	# 检查是否击败Boss
	if enemies_defeated >= total_enemies:
		_on_all_enemies_defeated()

func _on_bonfire_rest(_bonfire_id: String) -> void:
	# 篝火休息时重置敌人
	_reset_enemies()

func _reset_enemies() -> void:
	# 重置所有敌人
	for enemy in enemies_container.get_children():
		if enemy.has_method("reset"):
			enemy.reset()
	
	enemies_defeated = 0

func _on_all_enemies_defeated() -> void:
	# 所有敌人被击败
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	if GameManager:
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.change_state(GameManager.GameState.PAUSED)
			if pause_menu:
				pause_menu.show_pause_menu()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			GameManager.change_state(GameManager.GameState.PLAYING)
			if pause_menu:
				pause_menu.hide_pause_menu()

## 获取关卡信息
func get_level_info() -> Dictionary:
	return {
		"name": level_name,
		"id": level_id,
		"enemies_defeated": enemies_defeated,
		"total_enemies": total_enemies
	}
