## 灰烬回响技能
## 战斗：留下残影，残影重复玩家动作造成伤害
## 探索：残影可以踩住机关
extends Node2D

## 信号
signal skill_activated
signal skill_completed

## 导出变量
@export_group("Skill Stats")
@export var focus_cost: float = 35.0
@export var cooldown: float = 5.0
@export var echo_duration: float = 3.0
@export var echo_damage_multiplier: float = 0.6  # 残影造成60%伤害

## 节点引用
@onready var cooldown_timer: Timer = $CooldownTimer

## 状态
var current_cooldown: float = 0.0
var is_ready: bool = true
var is_active: bool = false

## 残影
var echo_instance: Node2D = null
var player_ref: CharacterBody2D = null

func _ready() -> void:
	if cooldown_timer:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(_on_cooldown_timeout)

func _process(delta: float) -> void:
	if not is_ready:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0.0
			is_ready = true

## 激活技能
func activate(player: CharacterBody2D, _direction: Vector2 = Vector2.ZERO) -> bool:
	if not is_ready or is_active:
		return false
	
	# 检查专注值
	if player.has_method("consume_focus"):
		if not player.consume_focus(focus_cost):
			return false
	else:
		return false
	
	player_ref = player
	is_active = true
	
	# 创建残影
	_create_echo(player)
	
	# 开始冷却
	_start_cooldown()
	
	skill_activated.emit()
	
	# 残影持续时间
	await get_tree().create_timer(echo_duration).timeout
	
	# 移除残影
	_remove_echo()
	
	is_active = false
	skill_completed.emit()
	
	return true

## 创建残影
func _create_echo(player: CharacterBody2D) -> void:
	# 创建残影节点
	echo_instance = Node2D.new()
	echo_instance.global_position = player.global_position
	
	# 添加精灵
	var sprite = Sprite2D.new()
	sprite.texture = player.get_node("Sprite2D").texture
	sprite.flip_h = player.get_node("Sprite2D").flip_h
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)  # 半透明灰色
	echo_instance.add_child(sprite)
	
	# 添加碰撞体
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 48)
	collision.shape = shape
	echo_instance.add_child(collision)
	
	# 添加到场景
	get_tree().current_scene.add_child(echo_instance)
	
	# 添加粒子效果
	_add_echo_particles(echo_instance)

## 添加残影粒子效果
func _add_echo_particles(echo: Node2D) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 16
	particles.lifetime = 0.5
	particles.process_material = _create_particle_material()
	echo.add_child(particles)

## 创建粒子材质
func _create_particle_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 50.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.color = Color(0.4, 0.4, 0.4, 0.6)
	return material

## 移除残影
func _remove_echo() -> void:
	if echo_instance and is_instance_valid(echo_instance):
		# 添加消失动画
		var tween = echo_instance.create_tween()
		tween.tween_property(echo_instance, "modulate:a", 0.0, 0.3)
		tween.tween_callback(echo_instance.queue_free)
		echo_instance = null

## 开始冷却
func _start_cooldown() -> void:
	is_ready = false
	current_cooldown = cooldown

## 冷却完成
func _on_cooldown_timeout() -> void:
	is_ready = true

## 获取冷却进度
func get_cooldown_progress() -> float:
	if is_ready:
		return 1.0
	return 1.0 - (current_cooldown / cooldown)

## 是否就绪
func is_skill_ready() -> bool:
	return is_ready
