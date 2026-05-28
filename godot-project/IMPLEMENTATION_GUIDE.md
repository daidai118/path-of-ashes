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

## 四、验收标准

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
