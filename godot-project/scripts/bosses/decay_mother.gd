## 腐朽之母Boss
## 第二个Boss，教会玩家使用残影分担压力
extends CharacterBody2D

## 信号
signal boss_defeated(boss_name: String)
signal health_changed(new_hp: int, max_hp: int)
signal phase_changed(phase: int)

## 导出变量
@export_group("Stats")
@export var max_hp: int = 2500
@export var damage_phase1: int = 40
@export var damage_phase2: int = 50
@export var damage_phase3: int = 60
@export var defense: int = 15
@export var souls_reward: int = 350

@export_group("Movement")
@export var move_speed: float = 120.0
@export var gravity: float = 1200.0

@export_group("Combat")
@export var attack_range: float = 100.0
@export var detection_range: float = 300.0
@export var phase1_threshold: float = 0.7
@export var phase2_threshold: float = 0.3

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer

## 状态枚举
enum BossState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	PHASE_TRANSITION,
	SUMMON,
	DEAD
}

## 攻击模式枚举
enum AttackPattern {
	VINE_WHIP,      # 藤蔓鞭打
	TOXIC_BREATH,   # 毒雾吐息
	SUMMON_MINIONS, # 召唤小虫
	GROUND_VINES,   # 地面藤蔓
	DECAY_BOMB,     # 腐朽之种
	DECAY_STORM     # 腐朽风暴
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
var current_attack: AttackPattern = AttackPattern.VINE_WHIP

## 受击相关
var is_staggered: bool = false
var stagger_duration: float = 0.5
var stagger_timer: float = 0.0

## 阶段转换
var is_transitioning: bool = false

## 攻击模式列表
var phase1_patterns: Array[AttackPattern] = [
	AttackPattern.VINE_WHIP,
	AttackPattern.TOXIC_BREATH,
	AttackPattern.SUMMON_MINIONS
]

var phase2_patterns: Array[AttackPattern] = [
	AttackPattern.VINE_WHIP,
	AttackPattern.TOXIC_BREATH,
	AttackPattern.SUMMON_MINIONS,
	AttackPattern.GROUND_VINES,
	AttackPattern.DECAY_BOMB
]

var phase3_patterns: Array[AttackPattern] = [
	AttackPattern.DECAY_STORM,
	AttackPattern.GROUND_VINES,
	AttackPattern.DECAY_BOMB,
	AttackPattern.SUMMON_MINIONS
]

## 召唤的小怪
var summoned_minions: Array[Node2D] = []

func _ready() -> void:
	current_hp = max_hp
	
	# 连接信号
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	# 设置攻击计时器
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

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
		BossState.SUMMON:
			_process_summon(delta)
	
	move_and_slide()
	_update_animation()
	_update_facing()

func _process_idle(_delta: float) -> void:
	velocity.x = 0
	
	if player_ref:
		current_state = BossState.CHASE

func _process_chase(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var direction = (player_ref.global_position - global_position).normalized()
	
	if distance_to_player <= attack_range:
		current_state = BossState.ATTACK
		return
	
	velocity.x = direction.x * move_speed

func _process_attack(_delta: float) -> void:
	velocity.x = 0
	
	if not player_ref or not is_instance_valid(player_ref):
		current_state = BossState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if distance_to_player > attack_range * 1.5:
		current_state = BossState.CHASE
		return
	
	if can_attack and not is_attacking:
		_choose_attack_pattern()
		_perform_attack()

func _process_phase_transition(_delta: float) -> void:
	velocity.x = 0

func _process_summon(_delta: float) -> void:
	velocity.x = 0

func _choose_attack_pattern() -> void:
	var patterns: Array[AttackPattern]
	
	match current_phase:
		1:
			patterns = phase1_patterns
		2:
			patterns = phase2_patterns
		3:
			patterns = phase3_patterns
	
	current_attack = patterns[randi() % patterns.size()]

func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	
	match current_attack:
		AttackPattern.VINE_WHIP:
			_attack_vine_whip()
		AttackPattern.TOXIC_BREATH:
			_attack_toxic_breath()
		AttackPattern.SUMMON_MINIONS:
			_attack_summon_minions()
		AttackPattern.GROUND_VINES:
			_attack_ground_vines()
		AttackPattern.DECAY_BOMB:
			_attack_decay_bomb()
		AttackPattern.DECAY_STORM:
			_attack_decay_storm()

func _attack_vine_whip() -> void:
	if animation_player.has_animation("attack1"):
		animation_player.play("attack1")
	
	_enable_hitbox()
	await animation_player.animation_finished
	_disable_hitbox()
	
	_end_attack(1.0)

func _attack_toxic_breath() -> void:
	if animation_player.has_animation("attack2"):
		animation_player.play("attack2")
	
	# 创建毒雾区域
	_create_toxic_cloud()
	
	await animation_player.animation_finished
	
	_end_attack(1.5)

func _attack_summon_minions() -> void:
	current_state = BossState.SUMMON
	
	if animation_player.has_animation("summon"):
		animation_player.play("summon")
	
	# 召唤小虫
	_spawn_minions(3)
	
	await animation_player.animation_finished
	
	current_state = BossState.CHASE
	_end_attack(2.0)

func _attack_ground_vines() -> void:
	if animation_player.has_animation("attack3"):
		animation_player.play("attack3")
	
	# 创建地面藤蔓
	_create_ground_vines()
	
	await animation_player.animation_finished
	
	_end_attack(1.5)

func _attack_decay_bomb() -> void:
	if animation_player.has_animation("attack4"):
		animation_player.play("attack4")
	
	# 投掷腐朽之种
	_throw_decay_bomb()
	
	await animation_player.animation_finished
	
	_end_attack(1.2)

func _attack_decay_storm() -> void:
	if animation_player.has_animation("ultimate"):
		animation_player.play("ultimate")
	
	# 创建腐朽风暴
	_create_decay_storm()
	
	await animation_player.animation_finished
	
	_end_attack(2.0)

func _create_toxic_cloud() -> void:
	# 创建毒雾区域
	var cloud = Area2D.new()
	cloud.collision_layer = 0
	cloud.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60.0
	collision.shape = shape
	cloud.add_child(collision)
	
	# 添加视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(120, 120)
	visual.position = Vector2(-60, -60)
	visual.color = Color(0.2, 0.5, 0.2, 0.3)
	cloud.add_child(visual)
	
	cloud.global_position = global_position + Vector2(facing_direction * 80, 0)
	get_parent().add_child(cloud)
	
	# 3秒后消失
	var tween = cloud.create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(cloud.queue_free)

func _spawn_minions(count: int) -> void:
	for i in count:
		var minion = _create_minion()
		minion.global_position = global_position + Vector2(randf_range(-100, 100), -50)
		get_parent().add_child(minion)
		summoned_minions.append(minion)

func _create_minion() -> Node2D:
	var minion = CharacterBody2D.new()
	minion.collision_layer = 2
	minion.collision_mask = 5
	
	# 添加精灵
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.4, 0.6, 0.3)
	minion.add_child(sprite)
	
	# 添加碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision.shape = shape
	minion.add_child(collision)
	
	# 添加简单AI脚本
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D

var hp: int = 30
var speed: float = 100.0
var damage: int = 20
var player_ref: Node2D = null

func _ready():
	add_to_group("enemies")

func _physics_process(delta):
	if player_ref and is_instance_valid(player_ref):
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount, _pos, _elem):
	hp -= amount
	if hp <= 0:
		queue_free()
"""
	script.reload()
	minion.set_script(script)
	
	return minion

func _create_ground_vines() -> void:
	# 创建地面藤蔓
	for i in 5:
		var vine = Area2D.new()
		vine.collision_layer = 0
		vine.collision_mask = 1
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 60)
		collision.shape = shape
		collision.position.y = -30
		vine.add_child(collision)
		
		# 添加视觉效果
		var visual = ColorRect.new()
		visual.size = Vector2(30, 60)
		visual.position = Vector2(-15, -60)
		visual.color = Color(0.3, 0.5, 0.2, 0.7)
		vine.add_child(visual)
		
		vine.global_position = global_position + Vector2(randf_range(-200, 200), 0)
		get_parent().add_child(vine)
		
		# 延迟后消失
		var tween = vine.create_tween()
		tween.tween_interval(2.0)
		tween.tween_callback(vine.queue_free)

func _throw_decay_bomb() -> void:
	if not player_ref:
		return
	
	# 创建腐朽之种
	var bomb = Area2D.new()
	bomb.collision_layer = 0
	bomb.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	bomb.add_child(collision)
	
	# 添加视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.5, 0.3, 0.5)
	bomb.add_child(visual)
	
	bomb.global_position = global_position
	get_parent().add_child(bomb)
	
	# 投掷到玩家位置
	var target_pos = player_ref.global_position
	var tween = bomb.create_tween()
	tween.tween_property(bomb, "global_position", target_pos, 0.5)
	tween.tween_callback(func(): _explode_bomb(bomb, target_pos))

func _explode_bomb(bomb: Area2D, pos: Vector2) -> void:
	# 爆炸效果
	var explosion = Area2D.new()
	explosion.collision_layer = 0
	explosion.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 80.0
	collision.shape = shape
	explosion.add_child(collision)
	
	# 添加视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(160, 160)
	visual.position = Vector2(-80, -80)
	visual.color = Color(0.6, 0.2, 0.6, 0.5)
	explosion.add_child(visual)
	
	explosion.global_position = pos
	get_parent().add_child(explosion)
	
	# 1秒后消失
	var tween = explosion.create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(explosion.queue_free)
	
	bomb.queue_free()

func _create_decay_storm() -> void:
	# 创建腐朽风暴
	var storm = Area2D.new()
	storm.collision_layer = 0
	storm.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 150.0
	collision.shape = shape
	storm.add_child(collision)
	
	# 添加视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(300, 300)
	visual.position = Vector2(-150, -150)
	visual.color = Color(0.3, 0.1, 0.3, 0.4)
	storm.add_child(visual)
	
	storm.global_position = global_position
	get_parent().add_child(storm)
	
	# 4秒后消失
	var tween = storm.create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(storm.queue_free)

func _end_attack(cooldown: float) -> void:
	is_attacking = false
	current_state = BossState.CHASE
	
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
	
	sprite.flip_h = facing_direction == -1

func take_damage(damage_amount: int, damage_position: Vector2, element: String = "physical") -> void:
	if current_state == BossState.DEAD or is_transitioning:
		return
	
	var actual_damage = max(1, damage_amount - defense)
	
	if element == "holy":
		actual_damage = int(actual_damage * 1.5)
	
	current_hp -= actual_damage
	health_changed.emit(current_hp, max_hp)
	
	_apply_stagger()
	
	var knockback_dir = (global_position - damage_position).normalized()
	velocity = knockback_dir * 80
	
	_check_phase_transition()
	
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
	
	if current_phase == 1 and hp_percentage <= phase1_threshold:
		_start_phase_transition(2)
	elif current_phase == 2 and hp_percentage <= phase2_threshold:
		_start_phase_transition(3)

func _start_phase_transition(new_phase: int) -> void:
	current_phase = new_phase
	is_transitioning = true
	current_state = BossState.PHASE_TRANSITION
	
	phase_changed.emit(current_phase)
	
	if animation_player.has_animation("phase_transition"):
		animation_player.play("phase_transition")
	
	await get_tree().create_timer(1.5).timeout
	
	is_transitioning = false
	current_state = BossState.CHASE
	
	if current_phase == 3:
		move_speed *= 1.2

func _die() -> void:
	current_state = BossState.DEAD
	
	# 清除召唤的小怪
	for minion in summoned_minions:
		if is_instance_valid(minion):
			minion.queue_free()
	summoned_minions.clear()
	
	if animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	boss_defeated.emit("腐朽之母")
	
	if GameManager:
		GameManager.player_stats.souls += souls_reward
		if not "decay_mother" in GameManager.game_data.defeated_bosses:
			GameManager.game_data.defeated_bosses.append("decay_mother")
	
	set_physics_process(false)
	if hurtbox:
		hurtbox.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

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
		var current_damage = damage_phase1 if current_phase == 1 else (damage_phase2 if current_phase == 2 else damage_phase3)
		body.take_damage(current_damage, knockback_dir * 300)

func _on_attack_timer_timeout() -> void:
	can_attack = true
