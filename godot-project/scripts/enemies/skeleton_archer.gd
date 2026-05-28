## 骷髅弓手AI
## 远程敌人，保持距离射击
extends CharacterBody2D

## 信号
signal enemy_died(souls: int)
signal health_changed(new_hp: int, max_hp: int)

## 导出变量
@export_group("Stats")
@export var max_hp: int = 100
@export var damage: int = 25
@export var defense: int = 5
@export var souls_reward: int = 12

@export_group("Movement")
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var gravity: float = 1200.0
@export var keep_distance: float = 150.0  # 保持距离

@export_group("Combat")
@export var attack_range: float = 200.0
@export var detection_range: float = 250.0
@export var attack_cooldown: float = 1.2
@export var stagger_duration: float = 0.3

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer

## 状态枚举
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETREAT,
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

## 攻击相关
var can_attack: bool = true
var is_attacking: bool = false

## 受击相关
var is_staggered: bool = false
var stagger_timer: float = 0.0

## 弱点
var weakness_element: String = "fire"
var weakness_multiplier: float = 1.5

## 投射物场景
var arrow_scene: PackedScene = null

func _ready() -> void:
	current_hp = max_hp
	
	# 设置巡逻点
	var start_pos = global_position
	patrol_points = [
		start_pos,
		start_pos + Vector2(80, 0),
		start_pos + Vector2(80, 0),
		start_pos
	]
	
	# 连接信号
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
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
		EnemyState.RETREAT:
			_process_retreat(delta)
	
	# 移动
	move_and_slide()
	
	# 更新动画
	_update_animation()
	
	# 更新朝向
	_update_facing()

func _process_idle(_delta: float) -> void:
	velocity.x = 0
	
	if player_ref:
		current_state = EnemyState.CHASE

func _process_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		current_state = EnemyState.IDLE
		return
	
	var target = patrol_points[current_patrol_index]
	var direction = (target - global_position).normalized()
	
	velocity.x = direction.x * patrol_speed
	
	if global_position.distance_to(target) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		current_state = EnemyState.IDLE

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
	
	# 太近了，后退
	if distance_to_player < keep_distance:
		current_state = EnemyState.RETREAT
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
	if distance_to_player > attack_range * 1.2:
		current_state = EnemyState.CHASE
		return
	
	# 执行攻击
	if can_attack and not is_attacking:
		_perform_attack()

func _process_retreat(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = EnemyState.IDLE
		return
	
	var direction = (global_position - player_ref.global_position).normalized()
	velocity.x = direction.x * chase_speed
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player >= keep_distance:
		current_state = EnemyState.ATTACK

func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	
	# 播放攻击动画
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# 等待动画播放到关键帧
	await get_tree().create_timer(0.3).timeout
	
	# 发射箭矢
	_shoot_arrow()
	
	# 等待动画结束
	await animation_player.animation_finished
	
	is_attacking = false
	
	# 启动攻击冷却
	attack_timer.start()

func _shoot_arrow() -> void:
	if not player_ref:
		return
	
	# 创建箭矢
	var arrow = _create_arrow()
	if arrow:
		get_parent().add_child(arrow)
		arrow.global_position = global_position + Vector2(0, -10)
		
		# 计算方向
		var direction = (player_ref.global_position - global_position).normalized()
		arrow.set_direction(direction)

func _create_arrow() -> Node2D:
	# 创建简单的箭矢
	var arrow = Area2D.new()
	arrow.collision_layer = 0
	arrow.collision_mask = 1  # 检测玩家
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 4)
	collision.shape = shape
	arrow.add_child(collision)
	
	var sprite = Sprite2D.new()
	# 使用简单颜色代替纹理
	sprite.modulate = Color(0.6, 0.3, 0.1)
	arrow.add_child(sprite)
	
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 300.0
var damage: int = 25
var lifetime: float = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	
func _process(delta):
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func set_direction(dir: Vector2):
	direction = dir
	rotation = dir.angle()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, direction * 100)
		queue_free()
"""
	script.reload()
	arrow.set_script(script)
	
	return arrow

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
		EnemyState.RETREAT:
			if animation_player.has_animation("run"):
				animation_player.play("run")
		EnemyState.ATTACK:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")

func _update_facing() -> void:
	if is_attacking or is_staggered:
		return
	
	if player_ref:
		facing_direction = 1 if player_ref.global_position.x > global_position.x else -1
	
	sprite.flip_h = facing_direction == -1

func take_damage(damage_amount: int, damage_position: Vector2, element: String = "physical") -> void:
	if current_state == EnemyState.DEAD:
		return
	
	var actual_damage = max(1, damage_amount - defense)
	
	if element == weakness_element:
		actual_damage = int(actual_damage * weakness_multiplier)
	
	current_hp -= actual_damage
	health_changed.emit(current_hp, max_hp)
	
	_apply_stagger()
	
	var knockback_dir = (global_position - damage_position).normalized()
	velocity = knockback_dir * 200
	
	if current_hp <= 0:
		_die()

func _apply_stagger() -> void:
	is_staggered = true
	stagger_timer = stagger_duration
	current_state = EnemyState.STAGGER
	is_attacking = false

func _die() -> void:
	current_state = EnemyState.DEAD
	
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	enemy_died.emit(souls_reward)
	if GameManager:
		GameManager.player_stats.souls += souls_reward
	
	set_physics_process(false)
	if hurtbox:
		hurtbox.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(2.0).timeout
		if player_ref == body:
			player_ref = null

func _on_hurtbox_body_entered(body: Node2D) -> void:
	# 弓手近战伤害较低
	if body.has_method("take_damage") and body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(15, knockback_dir * 200)

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
