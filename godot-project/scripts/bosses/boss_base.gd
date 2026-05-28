## Boss基类
## 所有Boss继承此类，提供通用的Boss行为框架
class_name BossBase
extends CharacterBody2D

# ============================================================
# 信号
# ============================================================
signal boss_defeated(boss_id: String)
signal health_changed(new_hp: int, max_hp: int)
signal phase_changed(new_phase: int)

# ============================================================
# 导出变量
# ============================================================
@export_group("Boss Info")
@export var boss_id: String = ""
@export var boss_name: String = ""
@export var boss_title: String = ""

@export_group("Stats")
@export var max_hp: int = 1000
@export var defense: int = 20
@export var souls_reward: int = 500

@export_group("Movement")
@export var move_speed: float = 150.0
@export var gravity: float = 1200.0

@export_group("Phases")
@export var phase_thresholds: Array[float] = [0.7, 0.3]  # 阶段转换阈值

# ============================================================
# 节点引用
# ============================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea

# ============================================================
# 状态
# ============================================================
enum BossState { IDLE, CHASE, ATTACK, STAGGER, PHASE_TRANSITION, DEAD }
var current_state: BossState = BossState.IDLE
var current_hp: int
var current_phase: int = 1
var facing_direction: int = 1

# ============================================================
# 战斗相关
# ============================================================
var player_ref: CharacterBody2D = null
var can_attack: bool = true
var is_attacking: bool = false
var is_staggered: bool = false
var stagger_timer: float = 0.0
var is_transitioning: bool = false

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	current_hp = max_hp
	_init_boss()
	_connect_signals()

func _init_boss() -> void:
	# 子类可重写此方法进行初始化
	pass

func _connect_signals() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == BossState.DEAD:
		return
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 更新受击状态
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0:
			is_staggered = false
			current_state = BossState.IDLE
		move_and_slide()
		return
	
	# 根据状态处理逻辑
	match current_state:
		BossState.IDLE:
			_process_idle(delta)
		BossState.CHASE:
			_process_chase(delta)
		BossState.ATTACK:
			_process_attack(delta)
		BossState.PHASE_TRANSITION:
			_process_phase_transition(delta)
	
	move_and_slide()
	_update_animation()
	_update_facing()

# ============================================================
# 状态处理（子类重写）
# ============================================================
func _process_idle(_delta: float) -> void:
	velocity.x = 0
	if player_ref:
		current_state = BossState.CHASE

func _process_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	var direction = (player_ref.global_position - global_position).normalized()
	
	if distance <= get_attack_range():
		current_state = BossState.ATTACK
		return
	
	velocity.x = direction.x * move_speed

func _process_attack(_delta: float) -> void:
	velocity.x = 0
	
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	if can_attack and not is_attacking:
		_choose_and_execute_attack()

func _process_phase_transition(_delta: float) -> void:
	velocity.x = 0

# ============================================================
# 攻击逻辑（子类重写）
# ============================================================
func get_attack_range() -> float:
	return 80.0

func _choose_and_execute_attack() -> void:
	# 子类实现具体的攻击选择逻辑
	pass

func _execute_attack(attack_name: String) -> void:
	is_attacking = true
	can_attack = false
	
	# 播放攻击动画
	if animation_player.has_animation(attack_name):
		animation_player.play(attack_name)
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	is_attacking = false
	current_state = BossState.CHASE
	
	# 攻击冷却
	await get_tree().create_timer(get_attack_cooldown()).timeout
	can_attack = true

func get_attack_cooldown() -> float:
	return 1.5

func _enable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = true
		hitbox.position.x = abs(hitbox.position.x) * facing_direction

func _disable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = false

# ============================================================
# 伤害处理
# ============================================================
func take_damage(damage: int, damage_position: Vector2, element: String = "physical") -> void:
	if current_state == BossState.DEAD or is_transitioning:
		return
	
	# 计算实际伤害
	var actual_damage = max(1, damage - defense)
	
	# 属性克制
	actual_damage = _apply_element_multiplier(actual_damage, element)
	
	# 扣血
	current_hp = max(0, current_hp - actual_damage)
	health_changed.emit(current_hp, max_hp)
	
	# 受击效果
	_apply_stagger()
	
	# 击退
	var knockback_dir = (global_position - damage_position).normalized()
	velocity = knockback_dir * 100
	
	# 检查阶段转换
	_check_phase_transition()
	
	# 检查死亡
	if current_hp <= 0:
		_die()

func _apply_element_multiplier(damage: int, element: String) -> int:
	# 子类可重写以实现属性克制
	return damage

func _apply_stagger(duration: float = 0.5) -> void:
	is_staggered = true
	stagger_timer = duration
	current_state = BossState.STAGGER
	is_attacking = false
	_disable_hitbox()

# ============================================================
# 阶段管理
# ============================================================
func _check_phase_transition() -> void:
	var hp_percentage = float(current_hp) / float(max_hp)
	
	for i in range(phase_thresholds.size()):
		var threshold = phase_thresholds[i]
		if current_phase <= i and hp_percentage <= threshold:
			_start_phase_transition(i + 2)  # 阶段从1开始
			break

func _start_phase_transition(new_phase: int) -> void:
	current_phase = new_phase
	is_transitioning = true
	current_state = BossState.PHASE_TRANSITION
	
	phase_changed.emit(current_phase)
	
	# 播放转换动画
	if animation_player.has_animation("phase_transition"):
		animation_player.play("phase_transition")
		await animation_player.animation_finished
	
	is_transitioning = false
	current_state = BossState.CHASE

# ============================================================
# 死亡处理
# ============================================================
func _die() -> void:
	current_state = BossState.DEAD
	
	# 播放死亡动画
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	# 发送击败信号
	boss_defeated.emit(boss_id)
	
	# 通知GameManager
	if GameManager:
		GameManager.player_stats.souls += souls_reward
		if not boss_id in GameManager.game_data.defeated_bosses:
			GameManager.game_data.defeated_bosses.append(boss_id)
	
	# 禁用碰撞
	set_physics_process(false)
	if hurtbox:
		hurtbox.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	# 延迟后销毁
	await get_tree().create_timer(5.0).timeout
	queue_free()

# ============================================================
# 动画和朝向
# ============================================================
func _update_animation() -> void:
	if is_staggered:
		if animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		return
	
	if is_attacking or is_transitioning:
		return
	
	match current_state:
		BossState.IDLE:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
		BossState.CHASE:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")

func _update_facing() -> void:
	if is_attacking or is_staggered or is_transitioning:
		return
	
	if player_ref:
		facing_direction = 1 if player_ref.global_position.x > global_position.x else -1
	
	if sprite:
		sprite.flip_h = facing_direction == -1

# ============================================================
# 信号回调
# ============================================================
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(3.0).timeout
		if player_ref == body:
			player_ref = null

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(get_contact_damage(), knockback_dir * 300)

func get_contact_damage() -> int:
	return 30
