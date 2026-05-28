# 灰烬之路 (Path of Ashes) - 开发指南

> **版本:** 1.0
> **最后更新:** 2026-05-28

---

## 一、快速开始

### 1.1 环境要求

| 工具 | 版本 | 说明 |
|------|------|------|
| Godot | 4.2+ | 游戏引擎 |
| Git | 2.30+ | 版本控制 |
| VS Code | 最新 | 代码编辑器（推荐） |

### 1.2 克隆项目

```bash
git clone https://github.com/daidai118/path-of-ashes.git
cd path-of-ashes/godot-project
```

### 1.3 打开项目

1. 启动 Godot 4.2+
2. 点击 "导入" 或 "Import"
3. 选择 `godot-project/project.godot` 文件
4. 点击 "导入并编辑"

---

## 二、代码规范

### 2.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `PlayerController`, `EnemyBase` |
| 变量 | snake_case | `current_hp`, `move_speed` |
| 常量 | UPPER_SNAKE_CASE | `MAX_HP`, `GRAVITY` |
| 函数 | snake_case | `take_damage()`, `change_state()` |
| 信号 | snake_case | `player_died`, `health_changed` |
| 节点名 | PascalCase | `Sprite2D`, `CollisionShape2D` |
| 场景名 | snake_case | `player.tscn`, `skeleton_warrior.tscn` |

### 2.2 文件组织

```
scripts/
├── autoload/          # 全局单例
├── player/            # 玩家相关
├── enemies/           # 敌人相关
├── bosses/            # Boss相关
├── npcs/              # NPC相关
├── skills/            # 技能相关
├── systems/           # 系统相关
├── ui/                # UI相关
├── levels/            # 关卡相关
└── environment/       # 环境相关
```

### 2.3 注释规范

```gdscript
## 玩家控制器
## 处理玩家的移动、跳跃、攻击等核心操作
extends CharacterBody2D

## 信号
signal player_died
signal health_changed(new_hp: int, max_hp: int)

## 导出变量
@export var move_speed: float = 200.0
@export var jump_force: float = -400.0

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D

## 私有变量
var _current_hp: int = 100

## 公共方法
func take_damage(damage: int) -> void:
    ## 处理受伤逻辑
    pass

## 私有方法
func _update_animation() -> void:
    ## 更新动画状态
    pass
```

---

## 三、架构模式

### 3.1 自动加载单例

```gdscript
# 访问全局单例
GameManager.player_stats.current_hp -= 10
AudioManager.play_sfx(my_sfx)
EventBus.player_died.emit()
SaveManager.save_game()
```

### 3.2 信号驱动

```gdscript
# 定义信号
signal enemy_died(souls: int)

# 连接信号
enemy.enemy_died.connect(_on_enemy_died)

# 处理信号
func _on_enemy_died(souls: int) -> void:
    GameManager.player_stats.souls += souls
```

### 3.3 状态机

```gdscript
# 状态枚举
enum State { IDLE, RUN, JUMP, FALL, DODGE, ATTACK }

# 当前状态
var current_state: State = State.IDLE

# 状态处理
func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE:
            _process_idle(delta)
        State.RUN:
            _process_run(delta)
        # ...

# 切换状态
func change_state(new_state: State) -> void:
    current_state = new_state
```

---

## 四、常用代码片段

### 4.1 移动和跳跃

```gdscript
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 980.0

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y += gravity * delta
    
    # 移动
    var input_dir = Input.get_axis("move_left", "move_right")
    velocity.x = input_dir * move_speed
    
    # 跳跃
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
    
    move_and_slide()
```

### 4.2 翻滚（无敌帧）

```gdscript
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.5

var can_dodge: bool = true
var is_invincible: bool = false

func _start_dodge() -> void:
    if not can_dodge:
        return
    
    can_dodge = false
    is_invincible = true
    
    # 翻滚方向
    var dodge_dir = 1.0 if facing_right else -1.0
    velocity.x = dodge_speed * dodge_dir
    
    # 翻滚结束
    await get_tree().create_timer(dodge_duration).timeout
    is_invincible = false
    
    # 冷却
    await get_tree().create_timer(dodge_cooldown).timeout
    can_dodge = true
```

### 4.3 攻击判定

```gdscript
# Hitbox (攻击判定)
func _on_hitbox_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        var damage = calculate_damage()
        var knockback = (body.global_position - global_position).normalized()
        body.take_damage(damage, knockback)

# Hurtbox (受击判定)
func take_damage(damage: int, knockback_dir: Vector2) -> void:
    if is_invincible:
        return
    
    current_hp -= damage
    velocity = knockback_dir * 200
    
    if current_hp <= 0:
        _die()
```

### 4.4 敌人AI

```gdscript
# 检测玩家
func _on_detection_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_ref = body
        change_state(EnemyState.CHASE)

# 追击玩家
func _process_chase(delta: float) -> void:
    if not player_ref:
        return
    
    var direction = (player_ref.global_position - global_position).normalized()
    velocity.x = direction.x * chase_speed
    
    if global_position.distance_to(player_ref.global_position) < attack_range:
        change_state(EnemyState.ATTACK)
```

### 4.5 篝火系统

```gdscript
# 篝火休息
func rest_at_bonfire(bonfire_id: String) -> void:
    # 恢复状态
    GameManager.player_stats.current_hp = GameManager.player_stats.max_hp
    GameManager.player_stats.estus_charges = GameManager.player_stats.max_estus
    
    # 保存存档
    SaveManager.save_game()
    
    # 重置敌人
    EventBus.bonfire_rest.emit(bonfire_id)
```

---

## 五、调试技巧

### 5.1 打印调试

```gdscript
print("玩家HP: ", current_hp)
print("当前状态: ", State.keys()[current_state])
print("敌人数量: ", get_tree().get_nodes_in_group("enemies").size())
```

### 5.2 可视化调试

```gdscript
# 绘制碰撞体
func _draw() -> void:
    if OS.is_debug_build():
        draw_circle(Vector2.ZERO, detection_range, Color(1, 0, 0, 0.3))
```

### 5.3 性能监控

```gdscript
# 监控FPS
func _process(delta: float) -> void:
    if OS.is_debug_build():
        $FPSLabel.text = "FPS: " + str(Engine.get_frames_per_second())
```

---

## 六、常见问题

### Q: 如何添加新敌人？

1. 创建敌人场景（继承 `enemy_base.tscn`）
2. 创建敌人脚本（继承 `enemy_base.gd`）
3. 实现状态机逻辑
4. 添加到关卡场景的 `Enemies` 节点下

### Q: 如何添加新技能？

1. 创建技能场景（继承 `skill_base.tscn`）
2. 创建技能脚本（继承 `skill_base.gd`）
3. 实现 `_execute()` 方法
4. 在 `skill_manager.gd` 中注册技能

### Q: 如何添加新关卡？

1. 创建关卡场景（继承 `level_base.tscn`）
2. 创建关卡脚本（继承 `level_base.gd`）
3. 设计关卡布局
4. 放置敌人、篝火、道具
5. 在 `level_manager.gd` 中注册关卡

---

## 七、资源链接

| 资源 | 链接 | 说明 |
|------|------|------|
| Godot文档 | https://docs.godotengine.org/ | 官方文档 |
| GDScript参考 | https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/ | 语言参考 |
| Godot资产库 | https://godotengine.org/asset-library | 免费资源 |
| 像素艺术 | https://lospec.com/pixel-art-tool | 像素画工具 |

---

## 附录：快捷键

| 快捷键 | 功能 |
|--------|------|
| F5 | 运行游戏 |
| F6 | 运行当前场景 |
| F7 | 调试游戏 |
| F8 | 停止运行 |
| Ctrl+S | 保存场景 |
| Ctrl+Shift+S | 另存为 |
| Ctrl+Z | 撤销 |
| Ctrl+Y | 重做 |
