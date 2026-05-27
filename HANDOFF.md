# 项目交接文档 - 灰烬之路 (Path of Ashes)

> **更新时间:** 2026-05-27
> **项目状态:** 设计完成，准备开始Godot开发

---

## 一、项目概述

**灰烬之路**是一款2D像素风魂系动作RPG，使用Godot 4.x引擎开发。

**核心卖点：**
- 每个技能同时服务战斗与探索（技能双用）
- 技能组合产生隐藏效果
- 技能决定你能到达的区域

---

## 二、当前项目状态

### ✅ 已完成

| 类别 | 文件数 | 位置 |
|------|--------|------|
| 游戏设计文档 | 16个 | `game-design/` |
| 素材提示词库 | 196个 | `assets-prompts/` |
| 已生成PNG素材 | 198个 | `assets/` |
| 交接文档 | 1个 | `HANDOFF.md` |

### ❌ 待完成

| 类别 | 说明 |
|------|------|
| Godot项目 | 需要创建 |
| 游戏代码 | 需要实现 |
| 音效/音乐 | 需要添加 |
| 真实像素画 | 当前是占位图，需要替换 |

---

## 三、目录结构

```
/root/ai/token/
├── game-design/              # 游戏设计文档
│   ├── GDD.md               # 主文档
│   ├── world/               # 世界观/区域/角色
│   ├── systems/             # 技能/战斗/进度/物品
│   ├── art/                 # 美术风格指南
│   ├── dev/                 # 开发路线图
│   └── goals/               # AI生成任务
│
├── assets-prompts/           # 素材生成提示词库
│   ├── characters/          # 角色提示词
│   ├── environment/         # 环境提示词
│   ├── ui/                  # UI提示词
│   ├── items/               # 物品提示词
│   └── vfx/                 # 特效提示词
│
├── assets/                   # 已生成素材
│   ├── characters/          # 角色PNG
│   ├── environment/         # 环境PNG
│   ├── ui/                  # UI PNG
│   ├── items/               # 物品PNG
│   └── vfx/                 # 特效PNG
│
└── godot-project/            # Godot项目（待创建）
```

---

## 四、关键设计文档索引

### 必读文档

| 文档 | 路径 | 内容 |
|------|------|------|
| 游戏设计文档 | `game-design/GDD.md` | 项目总览 |
| 世界观 | `game-design/world/lore.md` | 世界背景、剧情 |
| 区域设计 | `game-design/world/regions.md` | 9个区域详细设计 |
| 角色设定 | `game-design/world/characters.md` | NPC、Boss设定 |
| 技能系统 | `game-design/systems/skills.md` | 12个主动技能、9个被动 |
| 战斗系统 | `game-design/systems/combat.md` | 6种敌人、3个Boss |
| 进度系统 | `game-design/systems/progression.md` | 升级、篝火、死亡 |
| 物品系统 | `game-design/systems/items.md` | 武器、护符、消耗品 |
| 垂直切片 | `game-design/dev/vertical-slice.md` | 初始墓地详细设计 |

---

## 五、开发计划

### 阶段一：垂直切片（初始墓地）- 2周

**目标：** 验证核心玩法

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 创建Godot项目结构 | P0 | 1天 |
| 实现玩家移动/跳跃 | P0 | 2天 |
| 实现翻滚/无敌帧 | P0 | 1天 |
| 实现基础攻击系统 | P0 | 2天 |
| 实现钩索技能 | P0 | 2天 |
| 实现骷髅战士AI | P0 | 2天 |
| 实现墓地守卫Boss | P0 | 2天 |
| 实现篝火系统 | P0 | 1天 |
| 实现基础UI | P0 | 1天 |
| 实现初始墓地关卡 | P0 | 2天 |

### 阶段二：核心系统 - 3周

**目标：** 完成核心系统

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 实现技能系统 | P0 | 3天 |
| 实现装备系统 | P0 | 2天 |
| 实现升级系统 | P0 | 2天 |
| 实现物品系统 | P0 | 2天 |
| 实现存档系统 | P0 | 2天 |
| 实现NPC对话系统 | P1 | 2天 |
| 实现商店系统 | P1 | 1天 |
| 集成所有UI | P1 | 2天 |

### 阶段三：内容扩展 - 4周

**目标：** 完成所有区域

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 实现腐朽森林区域 | P1 | 1周 |
| 实现沉没教堂区域 | P1 | 1周 |
| 实现灰烬矿坑区域 | P1 | 1周 |
| 实现灰烬主城区域 | P1 | 3天 |
| 实现其他区域 | P2 | 1周 |

### 阶段四：打磨发布 - 2周

**目标：** 准备发布

| 任务 | 优先级 | 预计时间 |
|------|--------|---------|
| 平衡性调整 | P1 | 3天 |
| Bug修复 | P1 | 3天 |
| 性能优化 | P1 | 2天 |
| 音效集成 | P2 | 2天 |
| 发布准备 | P2 | 2天 |

---

## 六、Godot项目启动指南

### 1. 创建项目

```bash
# 在Godot中创建新项目
# 项目名: PathOfAshes
# 路径: /root/ai/token/godot-project
# 渲染器: Compatibility (2D)
```

### 2. 目录结构建议

```
godot-project/
├── project.godot
├── scenes/
│   ├── player/           # 玩家场景
│   ├── enemies/          # 敌人场景
│   ├── bosses/           # Boss场景
│   ├── npcs/             # NPC场景
│   ├── ui/               # UI场景
│   └── levels/           # 关卡场景
├── scripts/
│   ├── player/           # 玩家脚本
│   ├── enemies/          # 敌人脚本
│   ├── bosses/           # Boss脚本
│   ├── npcs/             # NPC脚本
│   ├── ui/               # UI脚本
│   ├── systems/          # 系统脚本
│   └── autoload/         # 自动加载脚本
├── assets/
│   ├── characters/       # 角色素材
│   ├── environment/      # 环境素材
│   ├── ui/               # UI素材
│   ├── items/            # 物品素材
│   ├── vfx/              # 特效素材
│   └── audio/            # 音频素材
└── resources/
    ├── items/            # 物品资源
    ├── skills/           # 技能资源
    └── enemies/          # 敌人资源
```

### 3. 核心系统实现顺序

1. **玩家控制器** - 移动、跳跃、翻滚
2. **战斗系统** - 攻击、受击、伤害计算
3. **技能系统** - 主动技能、被动技能
4. **敌人AI** - 状态机、攻击模式
5. **Boss系统** - 多阶段、特殊机制
6. **篝火系统** - 存档、回复、传送
7. **UI系统** - 血条、技能栏、菜单
8. **物品系统** - 武器、消耗品、护符
9. **NPC系统** - 对话、商店
10. **关卡系统** - 瓦片地图、机关

---

## 七、素材使用说明

### PNG素材

所有PNG素材存放在 `assets/` 目录，按类别组织：

- **角色动画:** `assets/characters/player/`, `assets/characters/enemies/`, `assets/characters/bosses/`
- **环境瓦片:** `assets/environment/tilesets/{region}/`
- **道具:** `assets/environment/props/`
- **UI:** `assets/ui/`
- **物品:** `assets/items/`
- **特效:** `assets/vfx/`

### 提示词库

如需生成更多素材，使用 `assets-prompts/` 中的提示词：

1. 找到对应的 `.md` 文件
2. 复制正向提示词
3. 使用AI图像生成工具生成
4. 保存到对应的 `assets/` 目录

---

## 八、注意事项

### 占位素材

当前PNG素材是占位图（带文字标签），需要替换为真实像素画：
- 使用 `assets-prompts/` 中的提示词生成
- 或者找像素画师绘制
- 保持相同的文件名和目录结构

### 设计文档

所有设计决策都有文档支持，开发前请先阅读相关文档：
- 实现技能前读 `systems/skills.md`
- 实现敌人前读 `systems/combat.md`
- 实现关卡前读 `world/regions.md`

### 代码规范

建议遵循：
- GDScript 代码规范
- 信号驱动架构
- 组合优于继承
- 每个场景独立，减少耦合

---

## 九、联系方式

如有问题，请参考：
- GitHub仓库: https://github.com/daidai118/path-of-ashes
- 设计文档: `game-design/` 目录

---

**祝开发顺利！🎮**
