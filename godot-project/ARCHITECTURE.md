# 灰烬之路 (Path of Ashes) - Godot 技术架构文档

> **版本:** 1.0
> **最后更新:** 2026-05-28
> **状态:** 架构设计完成

---

## 一、技术栈

| 项目 | 选择 | 说明 |
|------|------|------|
| 引擎 | Godot 4.2+ | 最新稳定版 |
| 脚本语言 | GDScript | 主要开发语言 |
| 渲染器 | Compatibility | 2D游戏，兼容性好 |
| 物理引擎 | Godot内置 | 2D物理 |
| 音频 | Godot内置 | 支持多音频总线 |
| 版本控制 | Git + GitHub | 代码版本管理 |
| 素材管理 | PNG/OGG | 标准格式 |

---

## 二、项目结构

```
godot-project/
├── project.godot                    # 项目配置
├── ARCHITECTURE.md                  # 本文档
├── README.md                        # 项目说明
│
├── scenes/                          # 场景文件
│   ├── player/                      # 玩家场景
│   │   └── player.tscn             # 玩家主场景
│   ├── enemies/                     # 敌人场景
│   │   ├── skeleton_warrior.tscn   # 骷髅战士
│   │   ├── skeleton_archer.tscn    # 骷髅弓手
│   │   └── enemy_base.tscn         # 敌人基类场景
│   ├── bosses/                      # Boss场景
│   │   ├── grave_warden.tscn       # 墓地守卫
│   │   ├── decay_mother.tscn       # 腐朽之母
│   │   └── boss_base.tscn          # Boss基类场景
│   ├── npcs/                        # NPC场景
│   │   ├── blacksmith.tscn         # 铁匠
│   │   ├── merchant.tscn           # 商人
│   │   └── prophet.tscn            # 先知
│   ├── ui/                          # UI场景
│   │   ├── main_menu.tscn          # 主菜单
│   │   ├── pause_menu.tscn         # 暂停菜单
│   │   ├── player_hud.tscn         # 玩家HUD
│   │   ├── bonfire_menu.tscn       # 篝火菜单
│   │   ├── dialog_box.tscn         # 对话框
│   │   └── inventory.tscn          # 背包界面
│   ├── levels/                      # 关卡场景
│   │   ├── graveyard_01.tscn       # 初始墓地
│   │   ├── decay_forest.tscn       # 腐朽森林
│   │   ├── sunken_cathedral.tscn   # 沉没教堂
│   │   └── level_base.tscn         # 关卡基类场景
│   ├── skills/                      # 技能场景
│   │   ├── grapple_skill.tscn      # 钩索技能
│   │   ├── echo_skill.tscn         # 灰烬回响
│   │   └── skill_base.tscn         # 技能基类场景
│   └── environment/                 # 环境场景
│       ├── bonfire.tscn            # 篝火
│       ├── grapple_point.tscn      # 钩环点
│       ├── lever.tscn              # 机关拉杆
│       ├── gate.tscn               # 铁门
│       └── checkpoint.tscn         # 存档点
│
├── scripts/                         # 脚本文件
│   ├── autoload/                    # 自动加载脚本
│   │   ├── game_manager.gd         # 游戏状态管理
│   │   ├── audio_manager.gd        # 音频管理
│   │   ├── event_bus.gd            # 事件总线
│   │   └── save_manager.gd         # 存档管理
│   ├── player/                      # 玩家脚本
│   │   ├── player_controller.gd    # 玩家控制器
│   │   ├── player_stats.gd         # 玩家属性
│   │   └── player_animations.gd    # 动画控制
│   ├── enemies/                     # 敌人脚本
│   │   ├── enemy_base.gd           # 敌人基类
│   │   ├── skeleton_warrior.gd     # 骷髅战士
│   │   ├── skeleton_archer.gd      # 骷髅弓手
│   │   └── states/                 # 敌人状态机
│   │       ├── idle_state.gd
│   │       ├── patrol_state.gd
│   │       ├── chase_state.gd
│   │       ├── attack_state.gd
│   │       └── stagger_state.gd
│   ├── bosses/                      # Boss脚本
│   │   ├── boss_base.gd            # Boss基类
│   │   ├── grave_warden.gd         # 墓地守卫
│   │   └── phases/                 # Boss阶段
│   │       ├── phase_1.gd
│   │       ├── phase_2.gd
│   │       └── phase_3.gd
│   ├── npcs/                        # NPC脚本
│   │   ├── npc_base.gd             # NPC基类
│   │   ├── dialog_system.gd        # 对话系统
│   │   └── shop_system.gd          # 商店系统
│   ├── skills/                      # 技能脚本
│   │   ├── skill_base.gd           # 技能基类
│   │   ├── grapple_skill.gd        # 钩索技能
│   │   ├── echo_skill.gd           # 灰烬回响
│   │   └── skill_manager.gd        # 技能管理器
│   ├── systems/                     # 系统脚本
│   │   ├── combat_system.gd        # 战斗系统
│   │   ├── damage_system.gd        # 伤害计算
│   │   ├── progression_system.gd   # 进度系统
│   │   ├── inventory_system.gd     # 背包系统
│   │   ├── equipment_system.gd     # 装备系统
│   │   └── bonfire_system.gd       # 篝火系统
│   ├── ui/                          # UI脚本
│   │   ├── main_menu.gd            # 主菜单
│   │   ├── pause_menu.gd           # 暂停菜单
│   │   ├── player_hud.gd           # 玩家HUD
│   │   ├── bonfire_menu.gd         # 篝火菜单
│   │   ├── dialog_box.gd           # 对话框
│   │   └── inventory_ui.gd         # 背包UI
│   ├── levels/                      # 关卡脚本
│   │   ├── level_base.gd           # 关卡基类
│   │   ├── graveyard_level.gd      # 初始墓地
│   │   └── level_manager.gd        # 关卡管理器
│   └── environment/                 # 环境脚本
│       ├── bonfire.gd              # 篝火
│       ├── lever.gd                # 机关拉杆
│       ├── gate.gd                 # 铁门
│       └── checkpoint.gd           # 存档点
│
├── resources/                       # 资源文件
│   ├── items/                       # 物品资源
│   │   ├── weapons/                # 武器
│   │   ├── amulets/                # 护符
│   │   └── consumables/            # 消耗品
│   ├── skills/                      # 技能资源
│   │   ├── active_skills/          # 主动技能
│   │   └── passive_skills/         # 被动技能
│   ├── enemies/                     # 敌人资源
│   │   └── enemy_data/             # 敌人数据
│   └── dialog/                      # 对话资源
│       └── dialog_trees/           # 对话树
│
├── assets/                          # 素材文件
│   ├── characters/                  # 角色素材
│   │   ├── player/                 # 玩家
│   │   ├── enemies/                # 敌人
│   │   ├── bosses/                 # Boss
│   │   └── npcs/                   # NPC
│   ├── environment/                 # 环境素材
│   │   ├── tilesets/               # 瓦片集
│   │   ├── props/                  # 道具
│   │   └── backgrounds/            # 背景
│   ├── ui/                          # UI素材
│   │   ├── icons/                  # 图标
│   │   ├── frames/                 # 框架
│   │   └── fonts/                  # 字体
│   ├── vfx/                         # 特效素材
│   │   ├── particles/              # 粒子
│   │   └── animations/             # 动画
│   └── audio/                       # 音频素材
│       ├── music/                  # 音乐
│       ├── sfx/                    # 音效
│       └── ambient/                # 环境音
│
└── addons/                          # 插件
    ├── debug_tools/                 # 调试工具
    └── level_editor/                # 关卡编辑器
```

---

## 三、核心架构模式

### 3.1 自动加载单例 (Autoloads)

| 单例名 | 脚本 | 职责 |
|--------|------|------|
| `GameManager` | `game_manager.gd` | 游戏状态、玩家数据、全局逻辑 |
| `AudioManager` | `audio_manager.gd` | 音乐、音效播放管理 |
| `EventBus` | `event_bus.gd` | 全局事件总线，解耦系统间通信 |
| `SaveManager` | `save_manager.gd` | 存档/读档、数据序列化 |

**project.godot 配置：**
```ini
[autoload]
GameManager="*res://scripts/autoload/game_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
EventBus="*res://scripts/autoload/event_bus.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
```

### 3.2 信号驱动架构 (Signal-Driven)

```
┌─────────────┐    Signal    ┌─────────────┐
│   System A   │ ──────────→ │   System B   │
└─────────────┘              └─────────────┘
       │                            │
       ↓                            ↓
┌─────────────┐    Signal    ┌─────────────┐
│   EventBus   │ ←──────────→ │   EventBus   │
└─────────────┘              └─────────────┘
```

**EventBus 示例：**
```gdscript
# scripts/autoload/event_bus.gd
extends Node

# 玩家事件
signal player_died
signal player_respawned
signal player_health_changed(new_hp, max_hp)
signal player_stamina_changed(new_stamina, max_stamina)
signal player_focus_changed(new_focus, max_focus)

# 战斗事件
signal enemy_died(enemy_id, souls)
signal boss_defeated(boss_id)
signal damage_dealt(target, damage, element)
signal damage_taken(source, damage)

# 技能事件
signal skill_used(skill_id)
signal skill_cooldown_started(skill_id, duration)
signal skill_cooldown_ended(skill_id)

# 进度事件
signal area_discovered(area_id)
signal bonfire_rest(bonfire_id)
signal bonfire_lit(bonfire_id)
signal item_acquired(item_id, quantity)
signal level_up(new_level)

# UI事件
signal dialog_started(dialog_id)
signal dialog_ended
signal shop_opened(shop_id)
signal shop_closed
signal menu_opened
signal menu_closed
```

### 3.3 状态机模式 (State Machine)

**敌人状态机：**
```
┌─────────────────────────────────────────────────┐
│                 EnemyStateMachine                │
├─────────────────────────────────────────────────┤
│  States:                                        │
│  ┌─────┐  ┌─────────┐  ┌───────┐  ┌─────────┐  │
│  │ IDLE │→│ PATROL  │→│ CHASE │→│ ATTACK  │  │
│  └─────┘  └─────────┘  └───────┘  └─────────┘  │
│     ↑          ↑           ↑          ↓         │
│     └──────────┴───────────┴────←────┘         │
│                    ↓                            │
│              ┌─────────┐                        │
│              │ STAGGER │                        │
│              └─────────┘                        │
└─────────────────────────────────────────────────┘
```

**实现示例：**
```gdscript
# scripts/enemies/enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

# 状态枚举
enum EnemyState { IDLE, PATROL, CHASE, ATTACK, STAGGER, DEAD }
var current_state: EnemyState = EnemyState.IDLE

# 状态处理函数映射
var state_handlers: Dictionary = {}

func _ready() -> void:
    _init_states()

func _init_states() -> void:
    state_handlers = {
        EnemyState.IDLE: _process_idle,
        EnemyState.PATROL: _process_patrol,
        EnemyState.CHASE: _process_chase,
        EnemyState.ATTACK: _process_attack,
        EnemyState.STAGGER: _process_stagger,
        EnemyState.DEAD: _process_dead,
    }

func _physics_process(delta: float) -> void:
    if state_handlers.has(current_state):
        state_handlers[current_state].call(delta)

func change_state(new_state: EnemyState) -> void:
    var old_state = current_state
    current_state = new_state
    _on_state_changed(old_state, new_state)

func _on_state_changed(old_state: EnemyState, new_state: EnemyState) -> void:
    # 状态切换时的清理和初始化
    pass
```

### 3.4 组合优于继承 (Composition over Inheritance)

**技能系统示例：**
```gdscript
# scripts/skills/skill_base.gd
class_name SkillBase
extends Node

@export var skill_id: String
@export var skill_name: String
@export var focus_cost: float
@export var cooldown: float
@export var description: String

var current_cooldown: float = 0.0
var is_ready: bool = true

func activate(caster: Node2D, direction: Vector2) -> bool:
    if not is_ready:
        return false
    if not _consume_resource(caster):
        return false
    _execute(caster, direction)
    _start_cooldown()
    return true

func _execute(caster: Node2D, direction: Vector2) -> void:
    # 子类实现
    pass

func _consume_resource(caster: Node2D) -> bool:
    if caster.has_method("consume_focus"):
        return caster.consume_focus(focus_cost)
    return false

func _start_cooldown() -> void:
    is_ready = false
    current_cooldown = cooldown
```

---

## 四、系统模块设计

### 4.1 游戏管理器 (GameManager)

```gdscript
# scripts/autoload/game_manager.gd
extends Node

# 游戏状态
enum GameState { MENU, PLAYING, PAUSED, DEAD, DIALOG, CUTSCENE, LOADING }
var current_state: GameState = GameState.MENU

# 玩家数据
var player_stats: PlayerStats = PlayerStats.new()
var game_data: GameData = GameData.new()

# 状态管理
func change_state(new_state: GameState) -> void:
    var old_state = current_state
    current_state = new_state
    
    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.PLAYING:
            get_tree().paused = false
        GameState.DEAD:
            EventBus.player_died.emit()
    
    EventBus.game_state_changed.emit(old_state, new_state)
```

### 4.2 战斗系统 (Combat System)

```gdscript
# scripts/systems/combat_system.gd
class_name CombatSystem
extends Node

# 伤害计算
static func calculate_damage(
    attacker: Dictionary,
    defender: Dictionary,
    skill_multiplier: float = 1.0,
    element: String = "physical"
) -> DamageResult:
    
    # 基础伤害
    var base_damage = attacker.base_damage * (1 + attacker.strength_bonus)
    
    # 技能倍率
    var skill_damage = base_damage * skill_multiplier
    
    # 属性克制
    var element_multiplier = _get_element_multiplier(element, defender.element)
    
    # 防御减伤
    var defense_reduction = defender.defense / (defender.defense + 100.0)
    
    # 最终伤害
    var final_damage = skill_damage * element_multiplier * (1 - defense_reduction)
    
    # 暴击检测
    var is_critical = randf() < attacker.crit_chance
    if is_critical:
        final_damage *= 1.5
    
    return DamageResult.new(final_damage, is_critical, element)

static func _get_element_multiplier(attack_element: String, defend_element: String) -> float:
    var element_table = {
        "fire": {"nature": 1.5, "ice": 1.5},
        "holy": {"shadow": 1.5, "undead": 1.5},
        "shadow": {"holy": 1.3},
    }
    
    if element_table.has(attack_element):
        if element_table[attack_element].has(defend_element):
            return element_table[attack_element][defend_element]
    
    return 1.0
```

### 4.3 技能系统 (Skill System)

```gdscript
# scripts/skills/skill_manager.gd
class_name SkillManager
extends Node

# 技能槽
var active_skills: Array[SkillBase] = [null, null, null]
var passive_skills: Array[PassiveSkill] = [null, null, null]

# 技能冷却
var cooldowns: Dictionary = {}

# 装备技能
func equip_skill(slot: int, skill: SkillBase) -> void:
    if slot < 0 or slot >= 3:
        return
    active_skills[slot] = skill
    EventBus.skill_equipped.emit(slot, skill.skill_id)

# 使用技能
func use_skill(slot: int, caster: Node2D, direction: Vector2) -> bool:
    if slot < 0 or slot >= 3:
        return false
    
    var skill = active_skills[slot]
    if skill == null:
        return false
    
    if not skill.is_ready:
        return false
    
    var success = skill.activate(caster, direction)
    if success:
        EventBus.skill_used.emit(skill.skill_id)
    
    return success

# 更新冷却
func _process(delta: float) -> void:
    for skill in active_skills:
        if skill != null and not skill.is_ready:
            skill.current_cooldown -= delta
            if skill.current_cooldown <= 0:
                skill.is_ready = true
                EventBus.skill_cooldown_ended.emit(skill.skill_id)
```

### 4.4 存档系统 (Save System)

```gdscript
# scripts/autoload/save_manager.gd
extends Node

const SAVE_PATH = "user://save_game.json"

# 保存游戏
func save_game() -> bool:
    var save_data = {
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system(),
        "player_stats": _serialize_player_stats(),
        "game_data": _serialize_game_data(),
        "world_state": _serialize_world_state(),
    }
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("无法创建存档文件")
        return false
    
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    
    EventBus.game_saved.emit()
    return true

# 加载游戏
func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    
    var json = JSON.new()
    var error = json.parse(file.get_as_text())
    file.close()
    
    if error != OK:
        push_error("存档文件格式错误")
        return false
    
    var save_data = json.data
    _deserialize_player_stats(save_data.player_stats)
    _deserialize_game_data(save_data.game_data)
    _deserialize_world_state(save_data.world_state)
    
    EventBus.game_loaded.emit()
    return true
```

---

## 五、场景层级设计

### 5.1 关卡场景结构

```
Level (Node2D)
├── Background (Sprite2D)
├── TileMap (TileMap)
├── Platforms (Node2D)
│   ├── Platform1 (StaticBody2D)
│   └── Platform2 (StaticBody2D)
├── Player (CharacterBody2D) [instance]
├── Enemies (Node2D)
│   ├── Skeleton1 (CharacterBody2D) [instance]
│   └── Skeleton2 (CharacterBody2D) [instance]
├── Bosses (Node2D)
│   └── GraveWarden (CharacterBody2D) [instance]
├── Bonfires (Node2D)
│   └── Bonfire1 (Area2D) [instance]
├── Puzzles (Node2D)
│   ├── Lever1 (Area2D) [instance]
│   └── Gate1 (StaticBody2D) [instance]
├── Collectibles (Node2D)
│   └── Soul1 (Area2D) [instance]
├── Triggers (Node2D)
│   └── Trigger1 (Area2D) [instance]
├── UI (CanvasLayer)
│   ├── PlayerHUD (Control) [instance]
│   └── PauseMenu (Control) [instance]
└── Camera (Camera2D)
```

### 5.2 玩家场景结构

```
Player (CharacterBody2D)
├── Sprite2D (Sprite2D)
├── CollisionShape2D (CollisionShape2D)
├── Hitbox (Area2D)
│   └── CollisionShape2D
├── Hurtbox (Area2D)
│   └── CollisionShape2D
├── AnimationPlayer (AnimationPlayer)
├── StateMachine (Node)
│   ├── IdleState (Node)
│   ├── RunState (Node)
│   ├── JumpState (Node)
│   ├── FallState (Node)
│   ├── DodgeState (Node)
│   ├── AttackState (Node)
│   └── GrappleState (Node)
├── Skills (Node)
│   └── GrappleSkill (Node2D) [instance]
└── Timers (Node)
    ├── CoyoteTimer (Timer)
    ├── DodgeTimer (Timer)
    ├── AttackTimer (Timer)
    └── InvincibilityTimer (Timer)
```

---

## 六、输入映射

```ini
# project.godot [input] 配置

# 移动
move_left = A, Left
move_right = D, Right
move_up = W, Up
move_down = S, Down

# 动作
jump = Space
dodge = Shift
attack_light = Mouse Left
attack_heavy = Mouse Right
interact = E

# 技能
skill_1 = Q
skill_2 = E
skill_3 = R

# 道具
use_item = F
item_prev = Z
item_next = C

# 菜单
pause = Escape
inventory = Tab
map = M
```

---

## 七、物理层配置

```ini
# project.godot [layer_names] 配置

2d_physics/layer_1 = "Player"      # 玩家
2d_physics/layer_2 = "Enemies"     # 敌人
2d_physics/layer_3 = "Environment" # 环境（地面、墙壁）
2d_physics/layer_4 = "Items"       # 物品
2d_physics/layer_5 = "Projectiles" # 投射物
2d_physics/layer_6 = "Triggers"    # 触发器
2d_physics/layer_7 = "Hitbox"      # 攻击判定
2d_physics/layer_8 = "Hurtbox"     # 受击判定
```

---

## 八、音频总线配置

```
Master
├── Music        # 背景音乐
├── SFX          # 音效
├── Ambient      # 环境音
└── UI           # UI音效
```

---

## 九、性能优化策略

### 9.1 对象池
- 敌人对象池（避免频繁创建/销毁）
- 特效对象池（粒子、动画）
- 投射物对象池

### 9.2 资源管理
- 延迟加载（按需加载关卡资源）
- 资源预加载（常用资源提前加载）
- 内存管理（及时释放不用的资源）

### 9.3 渲染优化
- 视口裁剪（只渲染可见区域）
- 精灵批处理（减少Draw Call）
- 粒子系统优化（限制粒子数量）

---

## 十、开发工具

### 10.1 调试工具
- 性能监控面板
- 碰撞体可视化
- 状态机可视化
- 伤害数字显示

### 10.2 关卡编辑器
- 瓦片地图编辑
- 敌人放置
- 触发器设置
- 预览功能

---

## 附录：待定义列表

- [ ] 详细的资源命名规范
- [ ] 动画命名规范
- [ ] 音效命名规范
- [ ] 测试用例设计
- [ ] CI/CD 配置
