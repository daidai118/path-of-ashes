## 锈蚀钩索技能
## 战斗：拉近小型敌人/拉向大型敌人
## 探索：钩住钩环平台、拉动机关
extends Node2D

## 信号
signal grapple_started
signal grapple_hit(target: Node2D)
signal grapple_released

## 导出变量
@export_group("Skill Stats")
@export var focus_cost: float = 20.0
@export var cooldown: float = 1.0
@export var max_range: float = 300.0  # 8格（约300像素）
@export var pull_speed: float = 800.0

@export_group("Combat")
@export var small_enemy_stagger: float = 0.5  # 小型敌人硬直时间
@export var large_enemy_pull_speed: float = 600.0  # 拉向大型敌人的速度

## 节点引用
@onready var chain_line: Line2D = $ChainLine
@onready var hook_area: Area2D = $HookArea
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 状态
enum GrappleState {
	READY,
	EXTENDING,
	PULLING,
	RETRACTING,
	COOLDOWN
}

var current_state: GrappleState = GrappleState.READY
var player_ref: CharacterBody2D = null
var target_point: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var chain_points: Array[Vector2] = []
var is_active: bool = false

## 钩索视觉
var chain_color: Color = Color(0.6, 0.4, 0.2)  # 锈蚀颜色
var chain_width: float = 3.0
var hook_size: float = 8.0

func _ready() -> void:
	# 初始化节点
	if chain_line:
		chain_line.visible = false
		chain_line.width = chain_width
		chain_line.default_color = chain_color
	
	if hook_area:
		hook_area.monitoring = false
		hook_area.body_entered.connect(_on_hook_body_entered)
	
	if cooldown_timer:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(_on_cooldown_timeout)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	match current_state:
		GrappleState.EXTENDING:
			_process_extending(delta)
		GrappleState.PULLING:
			_process_pulling(delta)
		GrappleState.RETRACTING:
			_process_retracting(delta)
	
	_update_chain_visual()

## 激活钩索
func activate(player: CharacterBody2D, direction: Vector2) -> bool:
	if current_state != GrappleState.READY:
		return false
	
	# 检查专注值
	if player.has_method("consume_focus"):
		if not player.consume_focus(focus_cost):
			return false
	else:
		return false
	
	player_ref = player
	is_active = true
	current_state = GrappleState.EXTENDING
	
	# 设置目标点
	target_point = player.global_position + direction * max_range
	
	# 启用碰撞检测
	if hook_area:
		hook_area.monitoring = true
		hook_area.global_position = player.global_position
	
	# 射线检测
	if ray_cast:
		ray_cast.target_position = direction * max_range
		ray_cast.force_raycast_update()
		if ray_cast.is_colliding():
			target_point = ray_cast.get_collision_point()
	
	# 播放动画
	if animation_player and animation_player.has_animation("shoot"):
		animation_player.play("shoot")
	
	grapple_started.emit()
	return true

## 处理伸出过程
func _process_extending(delta: float) -> void:
	if not hook_area:
		return
	
	var hook_pos = hook_area.global_position
	var direction = (target_point - hook_pos).normalized()
	
	hook_area.global_position += direction * pull_speed * delta
	
	# 检查是否到达目标
	if hook_pos.distance_to(target_point) < 10:
		_on_hook_reached_target()

## 处理拉动过程
func _process_pulling(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_release_grapple()
		return
	
	if target_node and is_instance_valid(target_node):
		# 拉动目标（小型敌人）
		var direction = (player_ref.global_position - target_node.global_position).normalized()
		target_node.global_position += direction * pull_speed * delta
		
		# 检查是否到达玩家
		if target_node.global_position.distance_to(player_ref.global_position) < 30:
			_release_grapple()
	else:
		# 拉向目标点（大型敌人或钩环）
		var direction = (target_point - player_ref.global_position).normalized()
		player_ref.global_position += direction * pull_speed * delta
		
		# 检查是否到达目标
		if player_ref.global_position.distance_to(target_point) < 30:
			_release_grapple()

## 处理回收过程
func _process_retracting(_delta: float) -> void:
	if not hook_area:
		return
	
	# 钩索快速回收
	if player_ref and is_instance_valid(player_ref):
		hook_area.global_position = hook_area.global_position.lerp(player_ref.global_position, 0.3)
		
		if hook_area.global_position.distance_to(player_ref.global_position) < 10:
			_reset_grapple()

## 更新链条视觉
func _update_chain_visual() -> void:
	if not chain_line or not player_ref:
		return
	
	chain_line.clear_points()
	chain_line.add_point(player_ref.global_position)
	
	if current_state == GrappleState.EXTENDING and hook_area:
		chain_line.add_point(hook_area.global_position)
	elif target_point != Vector2.ZERO:
		chain_line.add_point(target_point)
	
	chain_line.visible = is_active

## 钩索到达目标
func _on_hook_reached_target() -> void:
	if hook_area:
		hook_area.monitoring = false
	
	# 检查目标类型
	if target_node:
		_handle_target_hit(target_node)
	else:
		# 没有命中任何东西，开始回收
		current_state = GrappleState.RETRACTING

## 处理命中目标
func _handle_target_hit(target: Node2D) -> void:
	grapple_hit.emit(target)
	
	# 检查目标类型
	if target.is_in_group("enemies"):
		var enemy_size = _get_enemy_size(target)
		
		if enemy_size == "small":
			# 小型敌人：拉向玩家
			target_node = target
			_apply_stagger(target, small_enemy_stagger)
			current_state = GrappleState.PULLING
		else:
			# 大型敌人：拉向敌人
			target_point = target.global_position
			current_state = GrappleState.PULLING
	
	elif target.is_in_group("grapple_points"):
		# 钩环点：拉向目标
		target_point = target.global_position
		current_state = GrappleState.PULLING
	
	elif target.is_in_group("levers"):
		# 机关：拉动
		if target.has_method("activate"):
			target.activate()
		current_state = GrappleState.RETRACTING
	
	else:
		current_state = GrappleState.RETRACTING

## 获取敌人大小
func _get_enemy_size(enemy: Node2D) -> String:
	if enemy.has_method("get_size"):
		return enemy.get_size()
	
	# 默认根据碰撞形状判断
	if enemy is CharacterBody2D:
		var collision = enemy.get_node_or_null("CollisionShape2D")
		if collision and collision.shape:
			var rect_size = collision.shape.get_rect().size
			if rect_size.x < 40 and rect_size.y < 60:
				return "small"
	
	return "large"

## 施加硬直
func _apply_stagger(target: Node2D, duration: float) -> void:
	if target.has_method("apply_stagger"):
		target.apply_stagger(duration)

## 碰撞检测
func _on_hook_body_entered(body: Node2D) -> void:
	if current_state != GrappleState.EXTENDING:
		return
	
	# 忽略玩家
	if body == player_ref:
		return
	
	# 命中目标
	target_node = body
	_on_hook_reached_target()

## 释放钩索
func _release_grapple() -> void:
	grapple_released.emit()
	current_state = GrappleState.RETRACTING

## 重置钩索
func _reset_grapple() -> void:
	is_active = false
	current_state = GrappleState.COOLDOWN
	target_node = null
	target_point = Vector2.ZERO
	
	if chain_line:
		chain_line.visible = false
	
	if hook_area:
		hook_area.monitoring = false
		hook_area.global_position = player_ref.global_position if player_ref else Vector2.ZERO
	
	# 启动冷却
	if cooldown_timer:
		cooldown_timer.start()

## 冷却完成
func _on_cooldown_timeout() -> void:
	current_state = GrappleState.READY

## 获取状态
func get_state() -> GrappleState:
	return current_state

## 是否就绪
func is_ready() -> bool:
	return current_state == GrappleState.READY

## 取消钩索
func cancel() -> void:
	if is_active:
		_release_grapple()
