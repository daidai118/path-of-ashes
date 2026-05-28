## 墓地守卫Boss
## 教学Boss，教会玩家翻滚和攻击节奏
extends CharacterBody2D

## 信号
signal boss_defeated(boss_name: String)
signal health_changed(new_hp: int, max_hp: int)
signal phase_changed(phase: int)

## 导出变量
@export_group("Stats")
@export var max_hp: int = 1500
@export var damage_phase1: int = 50
@export var damage_phase2: int = 70
@export var damage_phase3: int = 80
@export var defense: int = 20
@export var souls_reward: int = 200

@export_group("Movement")
@export var move_speed: float = 200.0
@export var gravity: float = 1200.0

@export_group("Combat")
@export var attack_range: float = 80.0
@export var detection_range: float = 300.0
@export var phase1_threshold: float = 0.7  # 70% HP
@export var phase2_threshold: float = 0.3  # 30% HP

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var phase_timer: Timer = $PhaseTimer

## 状态枚举
enum BossState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	PHASE_TRANSITION,
	DEAD
}

## 攻击模式枚举
enum AttackPattern {
	SWEEP,      # 横扫
	THRUST,     # 突刺
	JUMP_SLASH, # 跳劈
	COMBO,      # 连续横扫
	DASH,       # 冲刺
	SHOCKWAVE,  # 地面冲击波
	FRENZY      # 狂暴连斩
}

## 当前状态
var current_state: BossState = BossState.IDLE
var current_hp: int
var current_phase: int = 1
var facing_direction: int = 1

## 战斗相关
var player_ref: CharacterBody2D = null
var can_attack: bool = true
var is_attacking: bool = false
var current_attack: AttackPattern = AttackPattern.SWEEP
var attack_queue: Array[AttackPattern] = []

## 受击相关
var is_staggered: bool = false
var stagger_duration: float = 0.5
var stagger_timer: float = 0.0

## 阶段转换
var is_transitioning: bool = false
var transition_duration: float = 1.5

## 攻击模式列表（按阶段）
var phase1_patterns: Array[AttackPattern] = [
	AttackPattern.SWEEP,
	AttackPattern.THRUST,
	AttackPattern.JUMP_SLASH
]

var phase2_patterns: Array[AttackPattern] = [
	AttackPattern.SWEEP,
	AttackPattern.THRUST,
	AttackPattern.JUMP_SLASH,
	AttackPattern.COMBO,
	AttackPattern.DASH
]

var phase3_patterns: Array[AttackPattern] = [
	AttackPattern.FRENZY,
	AttackPattern.SHOCKWAVE,
	AttackPattern.COMBO,
	AttackPattern.DASH
]

func _ready() -> void:
	current_hp = max_hp
	
	# 连接信号
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	# 设置计时器
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	phase_timer.one_shot = true

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
		current_state = BossState.CHASE

func _process_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var direction = (player_ref.global_position - global_position).normalized()
	
	# 在攻击范围内
	if distance_to_player <= attack_range:
		current_state = BossState.ATTACK
		return
	
	# 追击玩家
	velocity.x = direction.x * move_speed
	
	# 玩家离开检测范围
	if distance_to_player > detection_range * 1.5:
		player_ref = null
		current_state = BossState.IDLE

func _process_attack(_delta: float) -> void:
	velocity.x = 0
	
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# 玩家离开攻击范围
	if distance_to_player > attack_range * 2:
		current_state = BossState.CHASE
		return
	
	# 执行攻击
	if can_attack and not is_attacking:
		_choose_attack_pattern()
		_perform_attack()

func _choose_attack_pattern() -> void:
	var patterns: Array[AttackPattern]
	
	match current_phase:
		1:
			patterns = phase1_patterns
		2:
			patterns = phase2_patterns
		3:
			patterns = phase3_patterns
	
	# 随机选择攻击模式
	current_attack = patterns[randi() % patterns.size()]

func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	
	# 根据攻击模式执行
	match current_attack:
		AttackPattern.SWEEP:
			_attack_sweep()
		AttackPattern.THRUST:
			_attack_thrust()
		AttackPattern.JUMP_SLASH:
			_attack_jump_slash()
		AttackPattern.COMBO:
			_attack_combo()
		AttackPattern.DASH:
			_attack_dash()
		AttackPattern.SHOCKWAVE:
			_attack_shockwave()
		AttackPattern.FRENZY:
			_attack_frenzy()

func _attack_sweep() -> void:
	# 横扫攻击
	if animation_player.has_animation("attack1"):
		animation_player.play("attack1")
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.0)

func _attack_thrust() -> void:
	# 突刺攻击
	if animation_player.has_animation("attack2"):
		animation_player.play("attack2")
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.2)

func _attack_jump_slash() -> void:
	# 跳劈攻击
	if animation_player.has_animation("attack_jump"):
		animation_player.play("attack_jump")
	
	# 跳跃
	velocity.y = -400
	
	await get_tree().create_timer(0.3).timeout
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.5)

func _attack_combo() -> void:
	# 连续横扫（2-3次）
	var combo_count = 2 if current_phase < 3 else 3
	
	for i in combo_count:
		if animation_player.has_animation("attack1"):
			animation_player.play("attack1")
		
		_enable_hitbox()
		await animation_player.animation_finished
		_disable_hitbox()
		
		if i < combo_count - 1:
			await get_tree().create_timer(0.3).timeout
	
	_end_attack(1.5)

func _attack_dash() -> void:
	# 冲刺攻击
	var direction = (player_ref.global_position - global_position).normalized()
	
	# 冲刺
	velocity = direction * 500
	
	if animation_player.has_animation("attack_dash"):
		animation_player.play("attack_dash")
	
	await get_tree().create_timer(0.3).timeout
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.0)

func _attack_shockwave() -> void:
	# 地面冲击波（第三阶段）
	if animation_player.has_animation("attack_shockwave"):
		animation_player.play("attack_shockwave")
	
	# 跳跃
	velocity.y = -300
	
	await get_tree().create_timer(0.4).timeout
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.5)

func _attack_frenzy() -> void:
	# 狂暴连斩（第三阶段）
	var frenzy_count = 4
	
	for i in frenzy_count:
		if animation_player.has_animation("attack1"):
			animation_player.play("attack1")
		
		_enable_hitbox()
		await animation_player.animation_finished
		_disable_hitbox()
		
		if i < frenzy_count - 1:
			await get_tree().create_timer(0.2).timeout
	
	_end_attack(2.0)

func _end_attack(cooldown: float) -> void:
	is_attacking = false
	current_state = BossState.CHASE
	
	# 攻击冷却
	await get_tree().create_timer(cooldown).timeout
	can_attack = true

func _enable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = true
		hitbox.position.x = abs(hitbox.position.x) * facing_direction

func _disable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = false

func _update_animation() -> void:
	if is_staggered:
		if animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		return
	
	if is_attacking:
		return
	
	match current_state:
		BossState.IDLE:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
		BossState.CHASE:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
		BossState.PHASE_TRANSITION:
			if animation_player.has_animation("phase2"):
				animation_player.play("phase2")

func _update_facing() -> void:
	if is_attacking or is_staggered or is_transitioning:
		return
	
	if player_ref:
		facing_direction = 1 if player_ref.global_position.x > global_position.x else -1
	
	sprite.flip_h = facing_direction == -1

## 受到伤害
func take_damage(damage_amount: int, damage_position: Vector2, element: String = "physical") -> void:
	if current_state == BossState.DEAD or is_transitioning:
		return
	
	# 计算实际伤害
	var actual_damage = damage_amount - defense
	if actual_damage < 1:
		actual_damage = 1
	
	# 属性克制
	if element == "holy":
		actual_damage = int(actual_damage * 1.5)
	
	# 扣血
	current_hp -= actual_damage
	health_changed.emit(current_hp, max_hp)
	
	# 受击效果
	_apply_stagger()
	
	# 击退效果
	var knockback_dir = (global_position - damage_position).normalized()
	velocity = knockback_dir * 100
	
	# 检查阶段转换
	_check_phase_transition()
	
	# 检查死亡
	if current_hp <= 0:
		_die()

func _apply_stagger() -> void:
	is_staggered = true
	stagger_timer = stagger_duration
	current_state = BossState.STAGGER
	is_attacking = false
	_disable_hitbox()

func _check_phase_transition() -> void:
	var hp_percentage = float(current_hp) / float(max_hp)
	
	# 阶段2转换
	if current_phase == 1 and hp_percentage <= phase1_threshold:
		_start_phase_transition(2)
	
	# 阶段3转换
	elif current_phase == 2 and hp_percentage <= phase2_threshold:
		_start_phase_transition(3)

func _start_phase_transition(new_phase: int) -> void:
	current_phase = new_phase
	is_transitioning = true
	current_state = BossState.PHASE_TRANSITION
	
	phase_changed.emit(current_phase)
	
	# 播放转换动画
	if animation_player.has_animation("phase_transition"):
		animation_player.play("phase_transition")
	
	# 等待转换完成
	await get_tree().create_timer(transition_duration).timeout
	
	is_transitioning = false
	current_state = BossState.CHASE
	
	# 阶段3增加攻击力
	if current_phase == 3:
		move_speed *= 1.2

func _process_phase_transition(_delta: float) -> void:
	velocity.x = 0

func _die() -> void:
	current_state = BossState.DEAD
	
	# 播放死亡动画
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	# 发送击败信号
	boss_defeated.emit("墓地守卫")
	
	# 通知GameManager
	if GameManager:
		GameManager.player_stats.souls += souls_reward
		GameManager.boss_defeated.emit("墓地守卫")
		if not "grave_warden" in GameManager.game_data.defeated_bosses:
			GameManager.game_data.defeated_bosses.append("grave_warden")
	
	# 禁用碰撞
	set_physics_process(false)
	if hurtbox:
		hurtbox.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	# 延迟后销毁
	await get_tree().create_timer(5.0).timeout
	queue_free()

## 检测区域进入
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body

## 检测区域退出
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 延迟后丢失玩家
		await get_tree().create_timer(3.0).timeout
		if player_ref == body:
			player_ref = null

## 受伤区域碰撞
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		var current_damage = damage_phase1 if current_phase == 1 else (damage_phase2 if current_phase == 2 else damage_phase3)
		body.take_damage(current_damage, knockback_dir * 400)

func _on_attack_timer_timeout() -> void:
	can_attack = true
