## 敌人基类
## 所有敌人继承此类
extends CharacterBody2D

## 导出变量
@export var max_hp: int = 100
@export var damage: int = 20
@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar

## 状态
enum EnemyState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: EnemyState = EnemyState.IDLE
var current_hp: int
var player_ref: CharacterBody2D = null
var facing_right: bool = true

## 掉落
@export var soul_drop: int = 10
@export var drop_items: Array[String] = []

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.visible = false
	
	# 连接信号
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 状态处理
	match current_state:
		EnemyState.IDLE:
			_idle_state(delta)
		EnemyState.PATROL:
			_patrol_state(delta)
		EnemyState.CHASE:
			_chase_state(delta)
		EnemyState.ATTACK:
			_attack_state(delta)
		EnemyState.HURT:
			pass
	
	move_and_slide()
	_update_facing()

## 空闲状态
func _idle_state(delta: float) -> void:
	velocity.x = 0
	# TODO: 巡逻逻辑

## 巡逻状态
func _patrol_state(delta: float) -> void:
	# TODO: 实现巡逻
	pass

## 追击状态
func _chase_state(delta: float) -> void:
	if player_ref == null:
		change_state(EnemyState.IDLE)
		return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	
	# 检查攻击距离
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= attack_range:
		change_state(EnemyState.ATTACK)

## 攻击状态
func _attack_state(delta: float) -> void:
	velocity.x = 0
	
	# 播放攻击动画
	animation_player.play("attack")
	await animation_player.animation_finished
	
	# 检查是否还在攻击范围
	if player_ref and global_position.distance_to(player_ref.global_position) <= attack_range:
		# 造成伤害
		_deal_damage()
	else:
		change_state(EnemyState.CHASE)

## 造成伤害
func _deal_damage() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		var knockback_dir = (player_ref.global_position - global_position).normalized()
		player_ref.take_damage(damage, knockback_dir)

## 受到伤害
func take_damage(damage: int) -> void:
	current_hp -= damage
	health_bar.value = current_hp
	health_bar.visible = true
	
	if current_hp <= 0:
		_die()
	else:
		change_state(EnemyState.HURT)
		animation_player.play("hurt")
		await animation_player.animation_finished
		change_state(EnemyState.CHASE)

## 死亡
func _die() -> void:
	change_state(EnemyState.DEAD)
	animation_player.play("death")
	
	# 掉落灵魂
	GameManager.player_stats.souls += soul_drop
	
	# TODO: 掉落物品
	
	await animation_player.animation_finished
	queue_free()

## 切换状态
func change_state(new_state: EnemyState) -> void:
	current_state = new_state

## 玩家进入检测范围
func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		change_state(EnemyState.CHASE)

## 玩家离开检测范围
func _on_player_lost(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		change_state(EnemyState.IDLE)

## 更新朝向
func _update_facing() -> void:
	if velocity.x > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
	elif velocity.x < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true
