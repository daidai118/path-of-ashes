## 玩家控制器
## 处理移动、跳跃、翻滚、攻击
extends CharacterBody2D

## 导出变量
@export var move_speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 980.0
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.5

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var state_machine: Node = $StateMachine
@onready var grapple_skill: Node2D = $GrappleSkill

## 状态
enum PlayerState { IDLE, RUN, JUMP, FALL, DODGE, ATTACK, GRAPPLE, HURT, DEAD }
var current_state: PlayerState = PlayerState.IDLE
var is_invincible: bool = false
var can_dodge: bool = true
var facing_right: bool = true

## 连击系统
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.5

## 重力和移动
var was_on_floor: bool = false

func _ready() -> void:
	# 连接信号
	GameManager.player_respawned.connect(_on_respawned)
	
	# 连接钩索信号
	if grapple_skill:
		if grapple_skill.has_signal("grapple_started"):
			grapple_skill.grapple_started.connect(_on_grapple_started)
		if grapple_skill.has_signal("grapple_released"):
			grapple_skill.grapple_released.connect(_on_grapple_released)

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 状态处理
	match current_state:
		PlayerState.IDLE, PlayerState.RUN:
			_handle_movement(delta)
			_handle_actions()
		PlayerState.JUMP, PlayerState.FALL:
			_handle_air_movement(delta)
			_handle_actions()
		PlayerState.DODGE:
			_handle_dodge()
		PlayerState.ATTACK:
			_handle_attack(delta)
		PlayerState.GRAPPLE:
			_handle_grapple(delta)
		PlayerState.HURT:
			pass
		PlayerState.DEAD:
			pass
	
	# 移动
	move_and_slide()
	
	# 更新朝向
	_update_facing()
	
	# 更新动画
	_update_animation()
	
	# 检测落地
	if is_on_floor() and not was_on_floor:
		_on_landed()
	was_on_floor = is_on_floor()

## 处理移动
func _handle_movement(delta: float) -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		velocity.x = input_dir * move_speed
		if current_state != PlayerState.RUN:
			change_state(PlayerState.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 0.2)
		if current_state != PlayerState.IDLE and is_on_floor():
			change_state(PlayerState.IDLE)
	
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		change_state(PlayerState.JUMP)

## 处理空中移动
func _handle_air_movement(delta: float) -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * move_speed * 0.8  # 空中控制稍弱
	
	# 更新状态
	if velocity.y > 0 and current_state == PlayerState.JUMP:
		change_state(PlayerState.FALL)

## 处理动作输入
func _handle_actions() -> void:
	# 翻滚
	if Input.is_action_just_pressed("dodge") and can_dodge:
		_start_dodge()
	
	# 轻攻击
	if Input.is_action_just_pressed("attack_light"):
		_start_attack("light")
	
	# 重攻击
	if Input.is_action_just_pressed("attack_heavy"):
		_start_attack("heavy")
	
	# 技能
	if Input.is_action_just_pressed("skill_1"):
		_use_skill(0)
	if Input.is_action_just_pressed("skill_2"):
		_use_skill(1)
	if Input.is_action_just_pressed("skill_3"):
		_use_skill(2)

## 开始翻滚
func _start_dodge() -> void:
	change_state(PlayerState.DODGE)
	can_dodge = false
	is_invincible = true
	
	# 翻滚方向
	var dodge_dir = 1.0 if facing_right else -1.0
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1.0
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1.0
	
	velocity.x = dodge_speed * dodge_dir
	velocity.y = 0  # 翻滚时暂停重力
	
	# 翻滚结束
	await get_tree().create_timer(dodge_duration).timeout
	is_invincible = false
	change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)
	
	# 冷却
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

## 处理翻滚中
func _handle_dodge() -> void:
	# 翻滚中减速
	velocity.x = move_toward(velocity.x, 0, dodge_speed * 0.1)

## 开始攻击
func _start_attack(type: String) -> void:
	if current_state == PlayerState.ATTACK:
		# 连击检测
		if combo_timer > 0:
			combo_count = min(combo_count + 1, 2)
		else:
			combo_count = 0
	else:
		combo_count = 0
	
	change_state(PlayerState.ATTACK)
	combo_timer = COMBO_WINDOW
	
	# 触发动画
	animation_player.play("attack_" + type + "_" + str(combo_count))
	
	# 等待动画结束
	await animation_player.animation_finished
	
	if current_state == PlayerState.ATTACK:
		change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)

## 处理攻击中
func _handle_attack(delta: float) -> void:
	combo_timer -= delta
	velocity.x = move_toward(velocity.x, 0, move_speed * 0.3)  # 攻击时减速

## 使用技能
func _use_skill(slot: int) -> void:
	var skill_id = GameManager.player_stats.equipped_skills[slot]
	if skill_id.is_empty():
		return
	
	# 钩索技能
	if skill_id == "grapple" and grapple_skill:
		if grapple_skill.is_ready():
			var direction = Vector2(1 if facing_right else -1, 0)
			grapple_skill.activate(self, direction)
		return
	
	# TODO: 实现其他技能
	print("使用技能: ", skill_id)

## 处理钩索中
func _handle_grapple(delta: float) -> void:
	if grapple_skill and grapple_skill.get_state() == grapple_skill.GrappleState.PULLING:
		# 允许玩家控制移动
		var input_dir = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			velocity.x = move_toward(velocity.x, input_dir * move_speed * 0.3, move_speed * delta * 0.3)
	
	# 检查钩索是否结束
	if grapple_skill and not grapple_skill.is_active:
		change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)

## 钩索开始
func _on_grapple_started() -> void:
	change_state(PlayerState.GRAPPLE)

## 钩索释放
func _on_grapple_released() -> void:
	change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)

## 受到伤害
func take_damage(damage: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or current_state == PlayerState.DEAD:
		return
	
	# 计算实际伤害（考虑防御）
	var actual_damage = damage  # TODO: 考虑防御计算
	
	GameManager.player_stats.current_hp -= actual_damage
	
	# 击退
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 200
	
	# 检查死亡
	if GameManager.player_stats.current_hp <= 0:
		_die()
	else:
		change_state(PlayerState.HURT)
		is_invincible = true  # 受击无敌
		await get_tree().create_timer(0.5).timeout
		is_invincible = false
		change_state(PlayerState.IDLE)

## 死亡
func _die() -> void:
	change_state(PlayerState.DEAD)
	animation_player.play("death")
	await animation_player.animation_finished
	GameManager.on_player_death()

## 复活
func _on_respawned() -> void:
	change_state(PlayerState.IDLE)
	# 传送到篝火位置
	# TODO: 实现传送

## 落地
func _on_landed() -> void:
	if current_state == PlayerState.FALL:
		change_state(PlayerState.IDLE)

## 切换状态
func change_state(new_state: PlayerState) -> void:
	current_state = new_state

## 更新朝向
func _update_facing() -> void:
	if velocity.x > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
	elif velocity.x < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true

## 更新动画
func _update_animation() -> void:
	match current_state:
		PlayerState.IDLE:
			animation_player.play("idle")
		PlayerState.RUN:
			animation_player.play("run")
		PlayerState.JUMP:
			animation_player.play("jump")
		PlayerState.FALL:
			animation_player.play("fall")
		# 其他状态在各自函数中处理动画
