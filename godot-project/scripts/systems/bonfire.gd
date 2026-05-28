## 篝火系统
## 存档点、回复、升级、传送
extends Area2D

## 信号
signal bonfire_activated(bonfire_id: String)
signal bonfire_rest(bonfire_id: String)

## 导出变量
@export var bonfire_id: String = "graveyard_start"
@export var bonfire_name: String = "起始墓地"
@export var is_active: bool = true
@export var auto_activate: bool = true

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea
@onready var ui_prompt: Label = $UIPrompt

## 状态
var player_nearby: bool = false
var is_resting: bool = false
var is_lit: bool = false

## 篝火火焰效果
var flame_intensity: float = 1.0
var flame_timer: float = 0.0

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 初始化UI
	if ui_prompt:
		ui_prompt.visible = false
	
	# 初始化火焰
	if light:
		light.energy = 0.8 if is_lit else 0.0
	
	# 检查是否已经激活
	if GameManager and bonfire_id in GameManager.game_data.discovered_areas:
		is_lit = true
		_update_visual()

func _process(delta: float) -> void:
	# 火焰闪烁效果
	if is_lit and light:
		flame_timer += delta
		var flicker = sin(flame_timer * 5.0) * 0.1 + sin(flame_timer * 13.0) * 0.05
		light.energy = 0.8 + flicker
	
	# 检测玩家输入
	if player_nearby and Input.is_action_just_pressed("interact"):
		_interact_with_bonfire()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if ui_prompt:
			ui_prompt.visible = true
			ui_prompt.text = "按 E 休息" if is_lit else "按 E 点燃篝火"

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if ui_prompt:
			ui_prompt.visible = false

func _interact_with_bonfire() -> void:
	if is_resting:
		return
	
	is_resting = true
	
	# 点燃篝火
	if not is_lit:
		_light_bonfire()
	
	# 播放休息动画
	if animation_player.has_animation("rest"):
		animation_player.play("rest")
	
	# 通知GameManager
	if GameManager:
		GameManager.rest_at_bonfire(bonfire_id)
	
	# 发送信号
	bonfire_rest.emit(bonfire_id)
	
	# 恢复玩家状态
	_heal_player()
	
	# 重置敌人
	_reset_enemies()
	
	# 显示篝火菜单
	_show_bonfire_menu()
	
	# 等待一段时间后恢复
	await get_tree().create_timer(1.0).timeout
	is_resting = false

func _light_bonfire() -> void:
	is_lit = true
	
	# 播放点燃动画
	if animation_player.has_animation("light"):
		animation_player.play("light")
	
	# 启用灯光
	if light:
		var tween = create_tween()
		tween.tween_property(light, "energy", 0.8, 0.5)
	
	# 通知GameManager发现新篝火
	if GameManager:
		if not bonfire_id in GameManager.game_data.discovered_areas:
			GameManager.game_data.discovered_areas.append(bonfire_id)
	
	bonfire_activated.emit(bonfire_id)
	
	# 更新视觉
	_update_visual()

func _update_visual() -> void:
	if ui_prompt and player_nearby:
		ui_prompt.text = "按 E 休息"

func _heal_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal"):
		player.heal(player.max_hp)
	
	# 恢复原素瓶
	if GameManager:
		GameManager.player_stats.estus_charges = GameManager.player_stats.max_estus

func _reset_enemies() -> void:
	# 通知所有敌人重置
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("reset"):
			enemy.reset()

func _show_bonfire_menu() -> void:
	# TODO: 显示篝火菜单UI
	# 菜单包含：升级、更换技能、传送、离开
	pass

## 获取篝火位置（用于重生）
func get_respawn_position() -> Vector2:
	return global_position + Vector2(0, -20)  # 稍微偏上，避免卡在篝火里

## 检查篝火是否已点燃
func is_bonfire_lit() -> bool:
	return is_lit

## 获取篝火ID
func get_bonfire_id() -> String:
	return bonfire_id
