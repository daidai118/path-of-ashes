## 骷髅战士AI
## 基础近战敌人，用于垂直切片
extends CharacterBody2D

## 信号
signal enemy_died(souls: int)
signal health_changed(new_hp: int, max_hp: int)

## 导出变量
@export_group("Stats")
@export var max_hp: int = 150
@export var damage: int = 30
@export var defense: int = 10
@export var souls_reward: int = 15

@export_group("Movement")
@export var patrol_speed: float = 100.0
@export var chase_speed: float = 180.0
@export var gravity: float = 1200.0

@export_group("Combat")
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 1.5
@export var stagger_duration: float = 0.3

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var patrol_timer: Timer = $PatrolTimer
@onready var attack_timer: Timer = $AttackTimer

## 状态枚举
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	STAGGER,
	DEAD
}

## 当前状态
var current_state: EnemyState = EnemyState.IDLE
var current_hp: int
var facing_direction: int = 1

## 巡逻相关
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 2.0

## 追击相关
var player_ref: CharacterBody2D = null
var last_known_player_position: Vector2 = Vector2.ZERO

## 攻击相关
var can_attack: bool = true
var is_attacking: bool = false

## 受击相关
var is_staggered: bool = false
var stagger_timer: float = 0.0

## 弱点
var weakness_element: String = "holy"
var weakness_multiplier: float = 1.5

func _ready() -> void:
	current_hp = max_hp
	
	# 设置巡逻点（默认在初始位置附近巡逻）
	var start_pos = global_position
	patrol_points = [
		start_pos,
		start_pos + Vector2(100, 0),
		start_pos + Vector2(100, 0),
		start_pos
	]
	
	# 连接信号
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	# 启动巡逻计时器
	patrol_timer.wait_time = patrol_wait_time
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	
	# 设置攻击计时器
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 更新受击状态
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0:
			is_staggered = false
			current_state = EnemyState.IDLE
		move_and_slide()
		return
	
	# 根据状态处理逻辑
	match current_state:
		EnemyState.IDLE:
			_process_idle(delta)
		EnemyState.PATROL:
			_process_patrol(delta)
		EnemyState.CHASE:
			_process_chase(delta)
		EnemyState.ATTACK:
			_process_attack(delta)
	
	# 移动
	move_and_slide()
	
	# 更新动画
	_update_animation()
	
	# 更新朝向
	_update_facing()

func _process_idle(_delta: float) -> void:
	velocity.x = 0
	
	# 检测玩家
	if player_ref:
		current_state = EnemyState.CHASE
		return
	
	# 开始巡逻
	if patrol_timer.is_stopped():
		patrol_timer.start()

func _process_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		current_state = EnemyState.IDLE
		return
	
	var target = patrol_points[current_patrol_index]
	var direction = (target - global_position).normalized()
	
	velocity.x = direction.x * patrol_speed
	
	# 到达巡逻点
	if global_position.distance_to(target) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		current_state = EnemyState.IDLE
		patrol_timer.start()

func _process_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = null
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var direction = (player_ref.global_position - global_position).normalized()
	
	# 在攻击范围内
	if distance_to_player <= attack_range:
		current_state = EnemyState.ATTACK
		return
	
	# 追击玩家
	velocity.x = direction.x * chase_speed
	
	# 玩家离开检测范围
	if distance_to_player > detection_range * 1.5:
		player_ref = null
		current_state = EnemyState.IDLE

func _process_attack(_delta: float) -> void:
	velocity.x = 0
	
	if not player_ref or not is_instance_valid(player_ref):
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# 玩家离开攻击范围
	if distance_to_player > attack_range * 1.5:
		current_state = EnemyState.CHASE
		return
	
	# 执行攻击
	if can_attack and not is_attacking:
		_perform_attack()

func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	
	# 播放攻击动画
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# 启用攻击判定
	_enable_hitbox()
	
	# 等待攻击动画结束
	await animation_player.animation_finished
	
	_disable_hitbox()
	is_attacking = false
	
	# 启动攻击冷却
	attack_timer.start()

func _enable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = true
		hitbox.position.x = abs(hitbox.position.x) * facing_direction

func _disable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = false

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _update_animation() -> void:
	if is_staggered:
		if animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		return
	
	if is_attacking:
		return
	
	match current_state:
		EnemyState.IDLE:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
		EnemyState.PATROL:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")
		EnemyState.CHASE:
			if animation_player.has_animation("run"):
				animation_player.play("run")
		EnemyState.DEAD:
			pass

func _update_facing() -> void:
	if is_attacking or is_staggered:
		return
	
	if current_state == EnemyState.CHASE and player_ref:
		facing_direction = 1 if player_ref.global_position.x > global_position.x else -1
	elif current_state == EnemyState.PATROL:
		var target = patrol_points[current_patrol_index]
		facing_direction = 1 if target.x > global_position.x else -1
	
	sprite.flip_h = facing_direction == -1

## 受到伤害
func take_damage(damage_amount: int, damage_position: Vector2, element: String = "physical") -> void:
	if current_state == EnemyState.DEAD:
		return
	
	# 计算实际伤害
	var actual_damage = damage_amount - defense
	if actual_damage < 1:
		actual_damage = 1
	
	# 属性克制
	if element == weakness_element:
		actual_damage = int(actual_damage * weakness_multiplier)
	
	# 扣血
	current_hp -= actual_damage
	health_changed.emit(current_hp, max_hp)
	
	# 受击效果
	_apply_stagger()
	
	# 击退效果
	var knockback_dir = (global_position - damage_position).normalized()
	velocity = knockback_dir * 200
	
	# 播放受击音效/特效
	_play_hit_effect()
	
	# 检查死亡
	if current_hp <= 0:
		_die()

func _apply_stagger() -> void:
	is_staggered = true
	stagger_timer = stagger_duration
	current_state = EnemyState.STAGGER
	is_attacking = false
	_disable_hitbox()

func _play_hit_effect() -> void:
	# TODO: 播放受击特效和音效
	pass

func _die() -> void:
	current_state = EnemyState.DEAD
	
	# 播放死亡动画
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	# 掉落灰烬精华
	enemy_died.emit(souls_reward)
	if GameManager:
		GameManager.player_stats.souls += souls_reward
	
	# 禁用碰撞
	set_physics_process(false)
	if hurtbox:
		hurtbox.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	# 延迟后销毁
	await get_tree().create_timer(3.0).timeout
	queue_free()

## 检测区域进入
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		last_known_player_position = body.global_position

## 检测区域退出
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		last_known_player_position = body.global_position
		# 延迟后丢失玩家
		await get_tree().create_timer(2.0).timeout
		if player_ref == body:
			player_ref = null

## 受伤区域碰撞
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(damage, knockback_dir * 300)

## 巡逻计时器超时
func _on_patrol_timer_timeout() -> void:
	if current_state == EnemyState.IDLE:
		current_state = EnemyState.PATROL

## 设置巡逻点
func set_patrol_points(points: Array[Vector2]) -> void:
	patrol_points = points
	current_patrol_index = 0

## 重置敌人（篝火休息时调用）
func reset() -> void:
	current_hp = max_hp
	current_state = EnemyState.IDLE
	is_staggered = false
	is_attacking = false
	can_attack = true
	position = patrol_points[0] if not patrol_points.is_empty() else global_position
	set_physics_process(true)
	if hurtbox:
		hurtbox.monitoring = true
	if detection_area:
		detection_area.monitoring = true
	show()
