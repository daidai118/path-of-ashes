# 灰烬之路 (Path of Ashes) - 实现指南

> **版本:** 1.0
> **最后更新:** 2026-05-28
> **目的:** 为每个任务提供具体实现步骤和代码示例

---

## 一、玩家系统实现

### T-1.1.1: 实现水平移动基础

**实现步骤:**

1. 打开 `scripts/player/player_controller.gd`
2. 添加导出变量:
```gdscript
@export var move_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
```

3. 在 `_physics_process` 中添加移动逻辑:
```gdscript
func _handle_movement(delta: float) -> void:
    var input_dir = Input.get_axis("move_left", "move_right")
    
    if input_dir != 0:
        # 加速
        velocity.x = move_toward(velocity.x, input_dir * move_speed, acceleration * delta)
    else:
        # 减速
        velocity.x = move_toward(velocity.x, 0, friction * delta)
```

4. 验证:
   - 运行游戏
   - 按A/D移动
   - 观察是否有加速过程

---

### T-1.1.2: 实现跳跃基础

**实现步骤:**

1. 添加导出变量:
```gdscript
@export var jump_force: float = -400.0
@export var gravity: float = 980.0
```

2. 添加跳跃逻辑:
```gdscript
func _handle_jump(delta: float) -> void:
    # 应用重力
    if not is_on_floor():
        velocity.y += gravity * delta
    
    # 跳跃
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
```

3. 验证:
   - 按空格跳跃
   - 测量跳跃高度
   - 落地后再次跳跃

---

### T-1.1.3: 实现土狼时间

**实现步骤:**

1. 添加变量:
```gdscript
@export var coyote_time: float = 0.1
var coyote_timer: float = 0.0
var was_on_floor: bool = false
```

2. 修改跳跃逻辑:
```gdscript
func _handle_jump(delta: float) -> void:
    # 更新土狼计时器
    if is_on_floor():
        coyote_timer = coyote_time
    else:
        coyote_timer -= delta
    
    # 跳跃（允许土狼时间内跳跃）
    if Input.is_action_just_pressed("jump") and coyote_timer > 0:
        velocity.y = jump_force
        coyote_timer = 0
```

3. 验证:
   - 走到平台边缘
   - 离开后0.1秒内按空格
   - 测试是否可以跳跃

---

### T-1.1.5: 实现翻滚

**实现步骤:**

1. 添加导出变量:
```gdscript
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.5
@export var dodge_stamina_cost: float = 25.0
```

2. 添加翻滚函数:
```gdscript
func _start_dodge() -> void:
    if not can_dodge or current_stamina < dodge_stamina_cost:
        return
    
    can_dodge = false
    is_invincible = true
    current_stamina -= dodge_stamina_cost
    
    # 翻滚方向
    var dodge_dir = 1.0 if facing_right else -1.0
    if Input.is_action_pressed("move_left"):
        dodge_dir = -1.0
    elif Input.is_action_pressed("move_right"):
        dodge_dir = 1.0
    
    velocity.x = dodge_speed * dodge_dir
    velocity.y = 0
    
    # 播放动画
    animation_player.play("dodge")
    
    # 翻滚结束
    await get_tree().create_timer(dodge_duration).timeout
    is_invincible = false
    
    # 冷却
    await get_tree().create_timer(dodge_cooldown).timeout
    can_dodge = true
```

3. 验证:
   - 按Shift翻滚
   - 测量翻滚距离
   - 翻滚期间测试无敌

---

### T-1.2.1: 实现轻攻击

**实现步骤:**

1. 添加变量:
```gdscript
@export var light_attack_stamina_cost: float = 15.0
var is_attacking: bool = false
var attack_combo: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.8
```

2. 添加攻击函数:
```gdscript
func _start_attack(type: String) -> void:
    if is_attacking:
        return
    
    var stamina_cost = light_attack_stamina_cost if type == "light" else heavy_attack_stamina_cost
    if current_stamina < stamina_cost:
        return
    
    current_stamina -= stamina_cost
    is_attacking = true
    
    # 连击逻辑
    if type == "light":
        if combo_timer > 0:
            attack_combo = min(attack_combo + 1, 2)
        else:
            attack_combo = 0
        combo_timer = COMBO_WINDOW
    
    # 播放动画
    animation_player.play("attack_" + type + "_" + str(attack_combo))
    
    # 启用Hitbox
    _enable_hitbox()
    
    # 等待动画结束
    await animation_player.animation_finished
    
    _disable_hitbox()
    is_attacking = false
```

3. 验证:
   - 点击左键攻击
   - 观察动画播放
   - 观察体力消耗

---

### T-1.3.2: 实现钩索技能基础

**实现步骤:**

1. 创建 `scripts/skills/grapple_skill.gd`:
```gdscript
extends Node2D

@export var focus_cost: float = 20.0
@export var cooldown: float = 1.0
@export var max_range: float = 300.0
@export var pull_speed: float = 800.0

var current_cooldown: float = 0.0
var is_ready: bool = true
var is_active: bool = false

func activate(caster: Node2D, direction: Vector2) -> bool:
    if not is_ready:
        return false
    
    # 检查专注值
    if caster.has_method("consume_focus"):
        if not caster.consume_focus(focus_cost):
            return false
    
    # 发射钩索
    is_active = true
    _shoot_grapple(caster, direction)
    
    # 开始冷却
    _start_cooldown()
    
    return true

func _shoot_grapple(caster: Node2D, direction: Vector2) -> void:
    # TODO: 实现钩索发射逻辑
    pass

func _start_cooldown() -> void:
    is_ready = false
    current_cooldown = cooldown
```

2. 在玩家控制器中添加钩索使用:
```gdscript
func _use_skill(slot: int) -> void:
    var skill_id = GameManager.player_stats.equipped_skills[slot]
    if skill_id == "grapple" and grapple_skill:
        if grapple_skill.is_ready():
            var direction = Vector2(1 if facing_right else -1, 0)
            grapple_skill.activate(self, direction)
```

3. 验证:
   - 按Q发射钩索
   - 观察钩索飞行
   - 测试命中效果

---

### T-2.1.1: 实现敌人基类状态机

**实现步骤:**

1. 创建 `scripts/enemies/enemy_base.gd`:
```gdscript
class_name EnemyBase
extends CharacterBody2D

enum EnemyState { IDLE, PATROL, CHASE, ATTACK, STAGGER, DEAD }
var current_state: EnemyState = EnemyState.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        EnemyState.IDLE:
            _process_idle(delta)
        EnemyState.PATROL:
            _process_patrol(delta)
        EnemyState.CHASE:
            _process_chase(delta)
        EnemyState.ATTACK:
            _process_attack(delta)
        EnemyState.STAGGER:
            _process_stagger(delta)
        EnemyState.DEAD:
            _process_dead(delta)

func _process_idle(_delta: float) -> void:
    velocity.x = 0

func _process_patrol(_delta: float) -> void:
    # 子类实现
    pass

func _process_chase(_delta: float) -> void:
    # 子类实现
    pass

func _process_attack(_delta: float) -> void:
    # 子类实现
    pass

func _process_stagger(_delta: float) -> void:
    # 子类实现
    pass

func _process_dead(_delta: float) -> void:
    velocity.x = 0

func change_state(new_state: EnemyState) -> void:
    current_state = new_state
```

2. 验证:
   - 代码审查
   - 继承测试

---

### T-3.1.4: 实现篝火系统

**实现步骤:**

1. 创建 `scripts/systems/bonfire.gd`:
```gdscript
extends Area2D

signal bonfire_rest(bonfire_id: String)

@export var bonfire_id: String = ""
@export var bonfire_name: String = ""

var player_nearby: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    if player_nearby and Input.is_action_just_pressed("interact"):
        _rest_at_bonfire()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_nearby = true

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_nearby = false

func _rest_at_bonfire() -> void:
    # 恢复状态
    GameManager.player_stats.current_hp = GameManager.player_stats.max_hp
    GameManager.player_stats.current_fp = GameManager.player_stats.max_fp
    GameManager.player_stats.current_stamina = GameManager.player_stats.max_stamina
    GameManager.player_stats.estus_charges = GameManager.player_stats.max_estus
    
    # 保存存档
    SaveManager.save_game()
    
    # 重置敌人
    EventBus.bonfire_rest.emit(bonfire_id)
```

2. 验证:
   - 靠近篝火
   - 按E休息
   - 观察状态恢复

---

## 二、UI系统实现

### T-4.1.1: 实现血条显示

**实现步骤:**

1. 创建 `scenes/ui/player_hud.tscn`:
```
PlayerHUD (CanvasLayer)
└── MarginContainer
    └── VBoxContainer
        ├── HealthBar (ProgressBar)
        │   └── Label
        ├── StaminaBar (ProgressBar)
        │   └── Label
        └── FocusBar (ProgressBar)
            └── Label
```

2. 创建 `scripts/ui/player_hud.gd`:
```gdscript
extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/Label

func _ready() -> void:
    EventBus.player_health_changed.connect(_on_health_changed)

func _on_health_changed(new_hp: int, max_hp: int) -> void:
    health_bar.max_value = max_hp
    health_bar.value = new_hp
    health_label.text = "%d/%d" % [new_hp, max_hp]
```

3. 验证:
   - 受伤观察血条变化
   - 观察数字显示

---

## 三、系统功能实现

### T-5.1.2: 实现存档功能

**实现步骤:**

1. 创建 `scripts/autoload/save_manager.gd`:
```gdscript
extends Node

const SAVE_PATH = "user://save_game.json"

func save_game() -> bool:
    var save_data = {
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system(),
        "player_stats": _serialize_player_stats(),
        "game_data": _serialize_game_data(),
    }
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("无法创建存档文件")
        return false
    
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    
    EventBus.game_saved.emit()
    return true

func _serialize_player_stats() -> Dictionary:
    return {
        "level": GameManager.player_stats.level,
        "souls": GameManager.player_stats.souls,
        "max_hp": GameManager.player_stats.max_hp,
        "current_hp": GameManager.player_stats.current_hp,
        # ... 其他属性
    }

func _serialize_game_data() -> Dictionary:
    return {
        "current_area": GameManager.game_data.current_area,
        "last_bonfire": GameManager.game_data.last_bonfire,
        "defeated_bosses": GameManager.game_data.defeated_bosses,
    }
```

2. 验证:
   - 保存游戏
   - 检查文件内容
   - 验证数据正确

---

### T-6.2.1: 实现拉杆

**实现步骤:**

1. 创建 `scripts/environment/lever.gd`:
```gdscript
extends Area2D

signal lever_activated

@export var lever_id: String = ""
var is_active: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        activate()

func activate() -> void:
    if is_active:
        return
    
    is_active = true
    lever_activated.emit()
    
    # 视觉反馈
    _update_visual()

func _update_visual() -> void:
    # 改变颜色或动画
    modulate = Color(0.5, 1.0, 0.5)
```

2. 验证:
   - 靠近拉杆
   - 按E激活
   - 观察信号触发

---

## 四、玩家系统补充实现

### T-1.1.4: 实现跳跃缓冲

**实现步骤:**

1. 添加变量:
```gdscript
@export var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0
```

2. 修改跳跃逻辑:
```gdscript
func _handle_jump(delta: float) -> void:
    # 更新跳跃缓冲计时器
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = jump_buffer_time
    else:
        jump_buffer_timer -= delta
    
    # 跳跃（允许缓冲时间内跳跃）
    if jump_buffer_timer > 0 and is_on_floor():
        velocity.y = jump_force
        jump_buffer_timer = 0
```

3. 验证:
   - 跳跃中提前按空格
   - 观察落地后是否自动跳跃

---

### T-1.1.6: 实现朝向切换

**实现步骤:**

1. 添加变量:
```gdscript
var facing_right: bool = true
```

2. 在移动逻辑中更新朝向:
```gdscript
func _update_facing() -> void:
    if velocity.x > 0 and not facing_right:
        facing_right = true
        sprite.flip_h = false
    elif velocity.x < 0 and facing_right:
        facing_right = false
        sprite.flip_h = true
```

3. 验证:
   - 左右移动观察精灵方向

---

### T-1.1.7: 实现动画状态机

**实现步骤:**

1. 在 `_process` 中更新动画:
```gdscript
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
        PlayerState.DODGE:
            animation_player.play("dodge")
        PlayerState.ATTACK:
            pass  # 攻击动画在攻击函数中播放
```

2. 验证:
   - 执行各种动作观察动画

---

### T-1.2.2: 实现3连击系统

**实现步骤:**

1. 修改攻击函数:
```gdscript
func _start_attack(type: String) -> void:
    if is_attacking:
        return
    
    is_attacking = true
    
    # 连击逻辑
    if type == "light":
        if combo_timer > 0:
            attack_combo = min(attack_combo + 1, 2)
        else:
            attack_combo = 0
        combo_timer = COMBO_WINDOW
    
    # 播放动画
    animation_player.play("attack_" + type + "_" + str(attack_combo))
    
    # 等待动画结束
    await animation_player.animation_finished
    
    is_attacking = false
```

2. 验证:
   - 快速连续点击3次
   - 观察是否3连击
   - 延迟后点击测试重置

---

### T-1.2.3: 实现重攻击

**实现步骤:**

1. 添加变量:
```gdscript
@export var heavy_attack_stamina_cost: float = 30.0
@export var heavy_attack_multiplier: float = 1.5
```

2. 修改攻击函数:
```gdscript
func _start_attack(type: String) -> void:
    var stamina_cost = heavy_attack_stamina_cost if type == "heavy" else light_attack_stamina_cost
    if current_stamina < stamina_cost:
        return
    
    current_stamina -= stamina_cost
    # ... 其余逻辑
```

3. 验证:
   - 右键攻击
   - 观察体力消耗
   - 比较伤害数值

---

### T-1.2.5: 实现受击判定(Hurtbox)

**实现步骤:**

1. 创建Hurtbox区域:
```
Hurtbox (Area2D)
└── CollisionShape2D
```

2. 连接信号:
```gdscript
func _ready() -> void:
    hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _on_hurtbox_body_entered(body: Node2D) -> void:
    if body.has_method("get_damage"):
        take_damage(body.get_damage())
```

3. 验证:
   - 让敌人攻击玩家
   - 观察是否扣血
   - 观察无敌时间

---

### T-1.2.6: 实现体力系统

**实现步骤:**

1. 添加变量:
```gdscript
@export var max_stamina: float = 100.0
var current_stamina: float = 100.0
@export var stamina_recovery_rate: float = 30.0
@export var stamina_recovery_rate_combat: float = 15.0
var is_in_combat: bool = false
```

2. 添加恢复逻辑:
```gdscript
func _recover_stamina(delta: float) -> void:
    if current_stamina < max_stamina:
        var recovery_rate = stamina_recovery_rate_combat if is_in_combat else stamina_recovery_rate
        current_stamina = min(current_stamina + recovery_rate * delta, max_stamina)
```

3. 验证:
   - 连续攻击观察体力消耗
   - 等待观察恢复速度

---

### T-1.2.7: 实现伤害计算

**实现步骤:**

1. 创建伤害计算函数:
```gdscript
func calculate_damage(attacker: Dictionary, defender: Dictionary) -> int:
    var base_damage = attacker.base_damage * (1 + attacker.strength * 0.03)
    var defense_reduction = defender.defense / (defender.defense + 100.0)
    var final_damage = base_damage * (1 - defense_reduction)
    return int(final_damage)
```

2. 验证:
   - 打印伤害计算过程
   - 验证公式正确性

---

### T-1.3.1: 实现技能基类

**实现步骤:**

1. 创建 `scripts/skills/skill_base.gd`:
```gdscript
class_name SkillBase
extends Node

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var focus_cost: float = 0.0
@export var cooldown: float = 1.0

var current_cooldown: float = 0.0
var is_ready: bool = true

func activate(caster: Node2D, direction: Vector2) -> bool:
    if not is_ready:
        return false
    if not _check_resources(caster):
        return false
    
    _consume_resources(caster)
    _execute(caster, direction)
    _start_cooldown()
    return true

func _check_resources(caster: Node2D) -> bool:
    if caster.has_method("get_focus"):
        return caster.get_focus() >= focus_cost
    return false

func _consume_resources(caster: Node2D) -> void:
    if caster.has_method("consume_focus"):
        caster.consume_focus(focus_cost)

func _execute(caster: Node2D, direction: Vector2) -> void:
    pass  # 子类实现

func _start_cooldown() -> void:
    is_ready = false
    current_cooldown = cooldown
```

2. 验证:
   - 代码审查
   - 实例化测试

---

### T-1.3.3: 实现钩索战斗效果

**实现步骤:**

1. 在钩索脚本中添加:
```gdscript
func _on_hook_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies"):
        var enemy_size = _get_enemy_size(body)
        if enemy_size == "small":
            # 拉向玩家
            _pull_target_to_player(body)
            body.apply_stagger(0.5)
        else:
            # 拉向敌人
            _pull_player_to_target(body)
```

2. 验证:
   - 对小型敌人使用钩索
   - 对大型敌人使用钩索
   - 观察硬直效果

---

### T-1.3.4: 实现钩索探索效果

**实现步骤:**

1. 添加钩环点检测:
```gdscript
func _on_hook_body_entered(body: Node2D) -> void:
    if body.is_in_group("grapple_points"):
        # 拉向钩环
        _pull_player_to_target(body)
    elif body.is_in_group("levers"):
        # 激活机关
        body.activate()
```

2. 验证:
   - 对钩环点使用钩索
   - 测试到达隐藏区域
   - 测试激活拉杆

---

### T-1.3.5: 实现技能槽系统

**实现步骤:**

1. 添加变量:
```gdscript
var equipped_skills: Array[String] = ["dodge", "grapple", ""]
var active_skill_slot: int = 0
```

2. 添加切换逻辑:
```gdscript
func _handle_skill_input() -> void:
    if Input.is_action_just_pressed("skill_1"):
        _use_skill(0)
    elif Input.is_action_just_pressed("skill_2"):
        _use_skill(1)
    elif Input.is_action_just_pressed("skill_3"):
        _use_skill(2)
```

3. 验证:
   - 装备不同技能
   - 按Q/E/R使用

---

### T-1.3.6: 实现专注值系统

**实现步骤:**

1. 添加变量:
```gdscript
@export var max_focus: float = 100.0
var current_focus: float = 100.0
@export var focus_recovery_rate: float = 5.0
@export var focus_recovery_rate_combat: float = 2.0
@export var focus_recovery_on_hit: float = 8.0
```

2. 添加恢复逻辑:
```gdscript
func _recover_focus(delta: float) -> void:
    if current_focus < max_focus:
        var recovery_rate = focus_recovery_rate_combat if is_in_combat else focus_recovery_rate
        current_focus = min(current_focus + recovery_rate * delta, max_focus)
```

3. 验证:
   - 使用技能观察专注值
   - 等待观察恢复

---

## 五、敌人系统实现

### T-2.1.2: 实现敌人检测区域

**实现步骤:**

1. 创建检测区域:
```
DetectionArea (Area2D)
└── CollisionShape2D (CircleShape2D, radius=200)
```

2. 连接信号:
```gdscript
func _ready() -> void:
    detection_area.body_entered.connect(_on_detection_area_body_entered)
    detection_area.body_exited.connect(_on_detection_area_body_exited)

func _on_detection_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_ref = body
        change_state(EnemyState.CHASE)

func _on_detection_area_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_ref = null
        change_state(EnemyState.IDLE)
```

3. 验证:
   - 玩家进入范围观察状态变化
   - 玩家离开范围观察状态变化

---

### T-2.1.3: 实现敌人受击系统

**实现步骤:**

1. 创建Hurtbox:
```
Hurtbox (Area2D)
└── CollisionShape2D
```

2. 添加受击函数:
```gdscript
func take_damage(damage: int, knockback_dir: Vector2) -> void:
    current_hp -= damage
    velocity = knockback_dir * 200
    
    if current_hp <= 0:
        _die()
    else:
        _apply_stagger()
```

3. 验证:
   - 攻击敌人观察扣血
   - 观察受击动画

---

### T-2.1.4: 实现敌人死亡系统

**实现步骤:**

1. 添加死亡函数:
```gdscript
func _die() -> void:
    change_state(EnemyState.DEAD)
    animation_player.play("death")
    await animation_player.animation_finished
    
    # 掉落灵魂
    EventBus.enemy_died.emit(enemy_id, souls_reward)
    
    # 禁用碰撞
    set_physics_process(false)
    
    # 延迟销毁
    await get_tree().create_timer(3.0).timeout
    queue_free()
```

2. 验证:
   - 击杀敌人观察死亡
   - 观察灵魂掉落

---

### T-2.2.1: 实现骷髅战士巡逻

**实现步骤:**

1. 添加巡逻逻辑:
```gdscript
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
@export var patrol_speed: float = 100.0

func _process_patrol(_delta: float) -> void:
    if patrol_points.is_empty():
        return
    
    var target = patrol_points[current_patrol_index]
    var direction = (target - global_position).normalized()
    velocity.x = direction.x * patrol_speed
    
    if global_position.distance_to(target) < 10:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
```

2. 验证:
   - 观察敌人巡逻路径
   - 测量移动速度

---

### T-2.2.2: 实现骷髅战士追击

**实现步骤:**

1. 添加追击逻辑:
```gdscript
@export var chase_speed: float = 180.0

func _process_chase(_delta: float) -> void:
    if not player_ref:
        return
    
    var direction = (player_ref.global_position - global_position).normalized()
    velocity.x = direction.x * chase_speed
    
    if global_position.distance_to(player_ref.global_position) < attack_range:
        change_state(EnemyState.ATTACK)
```

2. 验证:
   - 玩家进入范围观察追击
   - 测量追击速度

---

### T-2.2.3: 实现骷髅战士攻击

**实现步骤:**

1. 添加攻击逻辑:
```gdscript
@export var attack_range: float = 50.0
@export var attack_damage: int = 30
@export var attack_cooldown: float = 1.5
var can_attack: bool = true

func _process_attack(_delta: float) -> void:
    velocity.x = 0
    
    if not player_ref:
        change_state(EnemyState.IDLE)
        return
    
    if global_position.distance_to(player_ref.global_position) > attack_range * 1.5:
        change_state(EnemyState.CHASE)
        return
    
    if can_attack:
        _perform_attack()

func _perform_attack() -> void:
    can_attack = false
    animation_player.play("attack")
    await animation_player.animation_finished
    
    # 检测命中
    if hitbox.monitoring:
        var bodies = hitbox.get_overlapping_bodies()
        for body in bodies:
            if body.has_method("take_damage"):
                body.take_damage(attack_damage)
    
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
```

2. 验证:
   - 观察攻击动画
   - 测量攻击间隔
   - 验证伤害数值

---

### T-2.3.1: 实现Boss阶段1攻击

**实现步骤:**

1. 添加攻击模式:
```gdscript
enum AttackPattern { SWEEP, THRUST, JUMP_SLASH }
var phase1_patterns: Array[AttackPattern] = [
    AttackPattern.SWEEP,
    AttackPattern.THRUST,
    AttackPattern.JUMP_SLASH
]

func _choose_attack() -> void:
    var pattern = phase1_patterns[randi() % phase1_patterns.size()]
    match pattern:
        AttackPattern.SWEEP:
            _attack_sweep()
        AttackPattern.THRUST:
            _attack_thrust()
        AttackPattern.JUMP_SLASH:
            _attack_jump_slash()
```

2. 验证:
   - 观察3种攻击动画
   - 测量伤害数值

---

### T-2.3.2: 实现Boss阶段2攻击

**实现步骤:**

1. 添加阶段2逻辑:
```gdscript
func _check_phase_transition() -> void:
    var hp_percentage = float(current_hp) / float(max_hp)
    if current_phase == 1 and hp_percentage <= 0.7:
        _start_phase_transition(2)

func _start_phase_transition(new_phase: int) -> void:
    current_phase = new_phase
    is_transitioning = true
    animation_player.play("phase_transition")
    await animation_player.animation_finished
    is_transitioning = false
```

2. 验证:
   - 打到70%HP观察阶段转换
   - 测试新攻击模式

---

### T-2.3.3: 实现Boss阶段3攻击

**实现步骤:**

1. 添加阶段3逻辑:
```gdscript
func _check_phase_transition() -> void:
    var hp_percentage = float(current_hp) / float(max_hp)
    if current_phase == 2 and hp_percentage <= 0.3:
        _start_phase_transition(3)
```

2. 验证:
   - 打到30%HP观察阶段转换
   - 测试新攻击模式

---

### T-2.3.4: 实现Boss阶段转换

**实现步骤:**

1. 添加转换动画:
```gdscript
func _start_phase_transition(new_phase: int) -> void:
    current_phase = new_phase
    is_transitioning = true
    
    # 禁用碰撞
    hurtbox.monitoring = false
    
    # 播放动画
    animation_player.play("phase_transition")
    await animation_player.animation_finished
    
    # 启用碰撞
    hurtbox.monitoring = true
    is_transitioning = false
```

2. 验证:
   - 观察阶段转换动画
   - 测试转换期间无敌

---

### T-2.3.5: 实现Boss掉落

**实现步骤:**

1. 在死亡函数中添加掉落:
```gdscript
func _die() -> void:
    # ... 死亡逻辑
    
    # 掉落灵魂
    EventBus.enemy_died.emit(boss_id, souls_reward)
    
    # 掉落物品
    EventBus.item_acquired.emit("grave_warden_key", 1)
    
    # 随机掉落武器
    if randf() < 0.1:
        EventBus.item_acquired.emit("grave_warden_sword", 1)
```

2. 验证:
   - 击败Boss观察掉落

---

## 六、关卡系统实现

### T-3.1.1: 实现关卡地面

**实现步骤:**

1. 创建场景:
```
Ground (StaticBody2D)
├── Sprite2D
└── CollisionShape2D (RectangleShape2D, size=Vector2(1920, 100))
```

2. 设置碰撞层:
```gdscript
collision_layer = 4  # Environment
collision_mask = 0
```

3. 验证:
   - 玩家可以站立在地面上
   - 不会穿透地面

---

### T-3.1.2: 实现平台系统

**实现步骤:**

1. 复制地面场景
2. 调整位置和大小
3. 验证:
   - 跳跃到平台上
   - 观察平台位置

---

### T-3.1.3: 实现敌人放置

**实现步骤:**

1. 在关卡中实例化敌人
2. 设置巡逻点
3. 验证:
   - 观察敌人巡逻
   - 测试战斗

---

### T-3.1.5: 实现钩环点

**实现步骤:**

1. 创建场景:
```
GrapplePoint (Area2D)
├── Sprite2D
└── CollisionShape2D (CircleShape2D, radius=15)
```

2. 添加到组:
```gdscript
# 在场景设置中添加到 "grapple_points" 组
```

3. 验证:
   - 对钩环使用钩索
   - 观察移动效果

---

### T-3.1.6: 实现机关谜题

**实现步骤:**

1. 创建拉杆场景
2. 创建铁门场景
3. 连接信号:
```gdscript
lever.lever_activated.connect(gate.activate)
```

4. 验证:
   - 激活拉杆
   - 观察铁门打开

---

### T-3.1.7: 实现隐藏区域

**实现步骤:**

1. 创建高处平台
2. 添加钩环点
3. 添加奖励
4. 验证:
   - 使用钩索到达隐藏区域
   - 获取奖励

---

### T-3.1.8: 实现Boss区域

**实现步骤:**

1. 创建Boss房
2. 添加Boss
3. 添加触发器
4. 验证:
   - 进入Boss房
   - 观察Boss出现

---

## 七、UI系统实现

### T-4.1.2: 实现体力条显示

**实现步骤:**

1. 在HUD中添加ProgressBar
2. 连接信号:
```gdscript
EventBus.player_stamina_changed.connect(_on_stamina_changed)

func _on_stamina_changed(new_stamina: float, max_stamina: float) -> void:
    stamina_bar.max_value = max_stamina
    stamina_bar.value = new_stamina
    stamina_label.text = "%d/%d" % [int(new_stamina), int(max_stamina)]
```

3. 验证:
   - 使用技能观察体力条
   - 等待观察恢复

---

### T-4.1.3: 实现专注值显示

**实现步骤:**

1. 在HUD中添加ProgressBar
2. 连接信号:
```gdscript
EventBus.player_focus_changed.connect(_on_focus_changed)

func _on_focus_changed(new_focus: float, max_focus: float) -> void:
    focus_bar.max_value = max_focus
    focus_bar.value = new_focus
    focus_label.text = "%d/%d" % [int(new_focus), int(max_focus)]
```

3. 验证:
   - 使用技能观察专注条
   - 等待观察恢复

---

### T-4.1.4: 实现原素瓶显示

**实现步骤:**

1. 在HUD中添加Label
2. 更新逻辑:
```gdscript
func _update_estus_display() -> void:
    if estus_label and GameManager:
        var charges = GameManager.player_stats.estus_charges
        var max_charges = GameManager.player_stats.max_estus
        estus_label.text = "原素瓶: %d/%d" % [charges, max_charges]
```

3. 验证:
   - 使用原素瓶观察数量
   - 篝火休息观察恢复

---

### T-4.1.5: 实现技能栏显示

**实现步骤:**

1. 创建技能栏UI
2. 显示技能图标
3. 显示冷却进度
4. 验证:
   - 装备技能观察显示
   - 使用技能观察冷却

---

### T-4.1.6: 实现灰烬精华显示

**实现步骤:**

1. 在HUD中添加Label
2. 更新逻辑:
```gdscript
func _process(_delta: float) -> void:
    if souls_label and GameManager:
        souls_label.text = "灰烬精华: %d" % GameManager.player_stats.souls
```

3. 验证:
   - 击杀敌人观察数量变化

---

### T-4.2.1: 实现主菜单

**实现步骤:**

1. 创建场景:
```
MainMenu (Control)
├── Background (ColorRect)
├── TitleLabel (Label)
├── VBoxContainer
│   ├── NewGameButton (Button)
│   ├── ContinueButton (Button)
│   ├── SettingsButton (Button)
│   └── QuitButton (Button)
└── VersionLabel (Label)
```

2. 连接按钮信号
3. 验证:
   - 点击各按钮测试功能

---

### T-4.2.2: 实现暂停菜单

**实现步骤:**

1. 创建暂停菜单场景
2. 添加ESC键检测
3. 暂停/恢复游戏
4. 验证:
   - 按ESC暂停
   - 点击各按钮测试

---

### T-4.2.3: 实现设置菜单

**实现步骤:**

1. 创建设置菜单场景
2. 添加音量滑块
3. 添加分辨率选择
4. 验证:
   - 调节音量测试
   - 切换分辨率测试

---

### T-4.2.4: 实现存档UI

**实现步骤:**

1. 创建存档UI场景
2. 显示存档槽
3. 显示存档信息
4. 验证:
   - 保存游戏
   - 加载游戏
   - 删除存档

---

## 八、系统功能实现

### T-5.1.1: 实现存档数据结构

**实现步骤:**

1. 定义数据结构:
```gdscript
var save_data = {
    "version": "1.0",
    "timestamp": Time.get_unix_time_from_system(),
    "player_stats": {
        "level": 1,
        "souls": 0,
        "max_hp": 500,
        "current_hp": 500,
        # ... 其他属性
    },
    "game_data": {
        "current_area": "graveyard",
        "last_bonfire": "graveyard_start",
        "defeated_bosses": [],
    }
}
```

2. 验证:
   - 代码审查
   - 序列化测试

---

### T-5.1.3: 实现读档功能

**实现步骤:**

1. 添加加载函数:
```gdscript
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    file.close()
    
    var save_data = json.data
    _apply_save_data(save_data)
    return true
```

2. 验证:
   - 加载游戏
   - 验证状态恢复

---

### T-5.1.4: 实现存档槽管理

**实现步骤:**

1. 支持多存档槽:
```gdscript
const SAVE_DIR = "user://saves/"
const MAX_SAVE_SLOTS = 3

func save_game(slot: int) -> bool:
    var save_path = SAVE_DIR + "save_" + str(slot) + ".json"
    # ... 保存逻辑
```

2. 验证:
   - 多槽位保存测试
   - 删除存档测试

---

### T-5.2.1: 实现背景音乐播放

**实现步骤:**

1. 添加播放函数:
```gdscript
func play_music(music_path: String, fade_time: float = 1.0) -> void:
    var music_player = AudioStreamPlayer.new()
    music_player.stream = load(music_path)
    music_player.bus = "Music"
    add_child(music_player)
    
    # 淡入
    music_player.volume_db = -80
    music_player.play()
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_time)
```

2. 验证:
   - 播放音乐测试
   - 调节音量测试

---

### T-5.2.2: 实现音效播放

**实现步骤:**

1. 添加播放函数:
```gdscript
func play_sfx(sfx_path: String, volume_offset: float = 0.0) -> void:
    var player = _get_available_sfx_player()
    player.stream = load(sfx_path)
    player.volume_db = linear_to_db(sfx_volume) + volume_offset
    player.play()
```

2. 验证:
   - 播放多个音效测试
   - 调节音量测试

---

### T-5.2.3: 实现环境音效

**实现步骤:**

1. 添加环境音效播放
2. 支持切换
3. 验证:
   - 切换场景观察环境音

---

### T-5.2.4: 实现音量控制

**实现步骤:**

1. 添加音量设置:
```gdscript
func set_master_volume(volume: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func set_music_volume(volume: float) -> void:
    music_volume = volume
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume))

func set_sfx_volume(volume: float) -> void:
    sfx_volume = volume
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(volume))
```

2. 验证:
   - 调节各种音量
   - 重启后验证保存

---

## 九、环境系统实现

### T-6.1.1: 实现篝火基础

**实现步骤:**

1. 创建篝火场景:
```
Bonfire (Area2D)
├── Sprite2D
├── CollisionShape2D
├── PointLight2D
└── AnimationPlayer
```

2. 添加交互逻辑:
```gdscript
var player_nearby: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    if player_nearby and Input.is_action_just_pressed("interact"):
        _rest_at_bonfire()
```

3. 验证:
   - 靠近篝火观察提示
   - 按E交互

---

### T-6.1.2: 实现篝火休息

**实现步骤:**

1. 添加休息函数:
```gdscript
func _rest_at_bonfire() -> void:
    # 恢复状态
    GameManager.player_stats.current_hp = GameManager.player_stats.max_hp
    GameManager.player_stats.current_fp = GameManager.player_stats.max_fp
    GameManager.player_stats.current_stamina = GameManager.player_stats.max_stamina
    GameManager.player_stats.estus_charges = GameManager.player_stats.max_estus
    
    # 重置敌人
    EventBus.bonfire_rest.emit(bonfire_id)
```

2. 验证:
   - 受伤后休息
   - 观察状态恢复
   - 观察敌人重置

---

### T-6.1.3: 实现篝火存档

**实现步骤:**

1. 在休息函数中添加存档:
```gdscript
func _rest_at_bonfire() -> void:
    # ... 恢复逻辑
    
    # 自动存档
    SaveManager.save_game()
```

2. 验证:
   - 休息后退出
   - 重新加载验证

---

### T-6.1.4: 实现篝火传送

**实现步骤:**

1. 添加传送UI
2. 显示已激活篝火
3. 传送到目标
4. 验证:
   - 选择篝火传送
   - 验证位置正确

---

### T-6.2.2: 实现铁门

**实现步骤:**

1. 创建铁门场景:
```
Gate (StaticBody2D)
├── Sprite2D
├── CollisionShape2D
└── AnimationPlayer
```

2. 添加激活函数:
```gdscript
func activate() -> void:
    is_open = true
    collision.disabled = true
    animation_player.play("open")
```

3. 验证:
   - 激活拉杆观察铁门打开

---

### T-6.2.3: 实现钩环点

**实现步骤:**

1. 创建钩环点场景
2. 添加到"grapple_points"组
3. 验证:
   - 对钩环使用钩索
   - 观察移动效果

---

## 十、验收标准

### 功能验收

每个任务完成后，必须通过以下验收：

1. **功能完整** - 所有需求都已实现
2. **无明显bug** - 基本功能正常工作
3. **代码规范** - 符合项目代码规范
4. **性能达标** - 不影响游戏性能
5. **文档更新** - 更新相关文档

### 验收流程

1. 开发者完成功能
2. 运行游戏测试
3. 填写验收清单
4. 提交代码
5. 代码审查

---

**附注:** 本文档为实现指南，提供具体实现步骤和代码示例。开发者可以直接按照指南实现功能。
