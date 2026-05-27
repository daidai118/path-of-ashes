# Goal: 灰烬之路 - 完整游戏设计 + 素材提示词库

## 任务目标
一次性完成以下4个模块的所有待填充内容，全部做完，不要中途停下询问。

1. 世界观与剧情 (`world/lore.md`)
2. 技能系统详细设计 (`systems/skills.md`)
3. 战斗系统详细设计 (`systems/combat.md`)
4. 素材提示词库补完 (`assets-prompts/` 目录下所有素材)

---

## 项目背景

### 基本信息
- **游戏名称:** 灰烬之路 (Path of Ashes)
- **类型:** 2D像素风动作RPG / Souls-like
- **引擎:** Godot 4.x
- **视角:** 2D横版
- **风格:** Dark fantasy pixel art, 16-bit retro, gloomy medieval atmosphere

### 核心卖点
**"每个技能都是一把钥匙和一把剑"**
- 每个技能同时服务战斗与探索
- 技能组合产生隐藏效果
- 技能决定你能到达的区域

### 技能系统架构
```
组合层: 3个主动技能槽 + 3个被动技能槽（玩家自由搭配）
升级层: 每个技能3条分支（战斗/探索/特殊）
来源层: 装备提供基础技能（每件装备自带1主动+1被动）
```

### 区域结构
```
初始墓地(教程) → 腐朽森林/沉没教堂/灰烬矿坑(三选一)
    → 灰烬主城(枢纽) → 王城废墟/深渊回廊/火焰神殿(三选一)
    → 灰烬之心(最终)
```

### 风格关键词
```
Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere,
muted desaturated colors with warm accent lighting (amber/orange from fire),
high contrast shadows, hand-crafted pixel detail
```

### 灵感来源
- Dark Souls: 战斗手感、关卡互联、氛围叙事
- Hollow Knight: 技能驱动探索、隐藏区域
- Dead Cells: 技能组合、Build多样性
- Blasphemous: 哥特像素美学、宗教意象

---

## 模块一：世界观与剧情

### 需要填充的文件
`/root/ai/token/game-design/world/lore.md`

### 需要完成的内容

**1. 世界背景 (3-5段)**
- 世界名称
- 灰烬的起源、性质、对世界的影响
- 当前世界状态

**2. 核心谜团**
- 1个主线谜团（玩家最终要解答的问题）
- 3-5个支线谜团（串联起来揭示主线）

**3. 历史时间线**
- 至少5个关键历史时期
- 每个时期的核心事件
- 事件如何导致当前状态

**4. 核心主题**
- 2-3个深层主题（牺牲、记忆、轮回等）
- 贯穿整个游戏

**5. 阵营与势力**
- 至少3个主要势力
- 各自立场、理念、代表NPC

**6. 视觉意象**
- 反复出现的视觉符号及其含义

**设计约束:**
- 碎片化叙事，环境叙事为主
- 世界观要能解释技能系统的存在
- 保持神秘感，不要解释太多

---

## 模块二：技能系统详细设计

### 需要填充的文件
`/root/ai/token/game-design/systems/skills.md`

### 需要完成的内容

**1. 主动技能完整列表 (至少12个)**

每个技能格式：
```
#### [技能名称]
**来源:** [区域/装备]
**消耗:** [专注值]
**冷却:** [秒数]

**战斗效果:** [详细描述]
**探索效果:** [详细描述]

**升级分支:**
- 战斗线：[效果]
- 探索线：[效果]
- 特殊线：[效果]

**视觉效果:** [动画/特效描述]
```

需要包含：
- 3个基础技能（初始获得）：翻滚、钩索、基础攻击
- 6个区域技能（每区域一个）：灰烬回响、圣光术、震地击、血誓之刃、暗影步、火焰印记
- 3个高级/隐藏技能

**2. 被动技能完整列表 (至少8个)**

格式：
```
#### [被动名称]
**来源:** [装备/升级]
**触发条件:** [条件]
**效果:** [具体效果]
```

**3. 隐藏组合效果 (至少8组)**

| 技能A | 技能B | 组合名称 | 效果 | 发现难度 |
|-------|-------|---------|------|---------|

**4. 专注值系统数值**
- 基础最大值、恢复速度、成长曲线

**5. 技能槽位规则**
- 解锁条件、是否可重复

---

## 模块三：战斗系统详细设计

### 需要填充的文件
`/root/ai/token/game-design/systems/combat.md`

### 需要完成的内容

**1. 完整数值系统**

玩家基础属性表：
| 属性 | 基础值 | 每点收益 | 说明 |
|------|--------|---------|------|

伤害计算完整公式：
```
最终伤害 = [完整公式，包含所有因素]
```

体力系统：各操作消耗、恢复速度、耗尽惩罚

**2. 敌人设计 (至少6种)**

每种敌人格式：
```
#### [敌人名称]
**类型:** 普通/精英
**HP/伤害/防御:** [数值]

**攻击模式:**
| 模式 | 动作 | 伤害 | 前摇 | 后摇 | 应对方式 |
|------|------|------|------|------|---------|

**弱点/掉落/出现区域**
```

必须包含：
1. 骷髅兵（基础近战）
2. 骷髅弓手（远程）
3. 骷髅骑士（精英近战）
4. 腐化村民（基础，不同攻击模式）
5. 暗影猎手（精英，高速）
6. 灰烬亡灵（特殊机制）

**3. Boss战详细设计 (至少3个)**

每个Boss格式：
```
#### [Boss名称]
**所在区域/HP/测试技能**

##### 第一阶段 (100%-70%)
| 攻击模式 | 动作 | 伤害 | 前摇 | 应对 |

##### 第二阶段 (70%-30%)
| 新增攻击 | 动作 | 伤害 | 前摇 | 应对 |

##### 第三阶段 (30%-0%)
| 狂暴模式 | 动作 | 伤害 | 前摇 | 应对 |

**战斗场地/掉落物/设计意图**
```

必须详细设计：
1. 墓地守卫（教学Boss，测试翻滚）
2. 腐朽之母（测试灰烬回响）
3. 堕落主教（硬核战斗）

**4. 战斗手感参数**

| 参数 | 帧数/数值 | 说明 |
|------|----------|------|
| 翻滚无敌帧 | | |
| 翻滚冷却 | | |
| 格挡减伤 | | |
| 弹反窗口 | | |
| 受击无敌 | | |

**5. 状态异常详细设计**

| 异常 | 触发 | 效果 | 持续 | 恢复 |
|------|------|------|------|------|
| 流血 | | | | |
| 中毒 | | | | |
| 诅咒 | | | | |
| 燃烧 | | | | |

---

## 模块四：素材提示词库补完

### 需要创建的文件
在 `/root/ai/token/assets-prompts/` 目录下创建以下文件

### 提示词文件模板

每个 `.md` 文件格式：
```markdown
# [素材名称]

## 基本信息
- **类型**: character / environment / ui / item / vfx
- **用途**: [具体描述]
- **尺寸**: [像素尺寸]
- **动画帧数**: [帧数或静态]
- **输出格式**: PNG, sprite sheet / 单帧

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词
```
[详细生成提示词]
```

### 负向提示词
```
[需要避免的元素]
```

## 参考说明
- [视觉参考]

## 备注
- [特殊要求]
```

### 需要创建的素材文件列表

**玩家角色动画 (7个文件):**
- `characters/player/player-idle.md` ✅ 已有
- `characters/player/player-run.md` [新建]
- `characters/player/player-attack-light.md` [新建]
- `characters/player/player-attack-heavy.md` [新建]
- `characters/player/player-dodge.md` [新建]
- `characters/player/player-hurt.md` [新建]
- `characters/player/player-death.md` [新建]

**敌人：骷髅战士 (5个文件):**
- `characters/enemies/skeleton-warrior/skeleton-idle.md` ✅ 已有
- `characters/enemies/skeleton-warrior/skeleton-walk.md` [新建]
- `characters/enemies/skeleton-warrior/skeleton-attack.md` [新建]
- `characters/enemies/skeleton-warrior/skeleton-hurt.md` [新建]
- `characters/enemies/skeleton-warrior/skeleton-death.md` [新建]

**Boss：墓地守卫 (6个文件):**
- `characters/bosses/grave-warden/grave-warden-idle.md` [新建]
- `characters/bosses/grave-warden/grave-warden-attack1.md` [新建]
- `characters/bosses/grave-warden/grave-warden-attack2.md` [新建]
- `characters/bosses/grave-warden/grave-warden-phase2.md` [新建]
- `characters/bosses/grave-warden/grave-warden-hurt.md` [新建]
- `characters/bosses/grave-warden/grave-warden-death.md` [新建]

**NPC (2个文件):**
- `characters/npcs/blacksmith.md` [新建]
- `characters/npcs/merchant.md` [新建]

**环境瓦片 - 初始墓地 (4个文件):**
- `environment/tilesets/graveyard-ground.md` [新建]
- `environment/tilesets/graveyard-wall.md` [新建]
- `environment/tilesets/graveyard-platform.md` [新建]
- `environment/tilesets/graveyard-background.md` [新建]

**环境道具 (5个文件):**
- `environment/props/bonfire.md` ✅ 已有
- `environment/props/gravestone.md` [新建]
- `environment/props/iron-gate.md` [新建]
- `environment/props/dead-tree.md` [新建]
- `environment/props/chain.md` [新建]

**UI元素 (6个文件):**
- `ui/health-bar.md` ✅ 已有
- `ui/stamina-bar.md` [新建]
- `ui/focus-bar.md` [新建]
- `ui/skill-slot.md` [新建]
- `ui/item-slot.md` [新建]
- `ui/dialog-box.md` [新建]

**武器图标 (3个文件):**
- `items/weapons/sword-rusty.md` ✅ 已有
- `items/weapons/sword-holy.md` [新建]
- `items/weapons/axe-bleed.md` [新建]

**消耗品图标 (2个文件):**
- `items/consumables/estus-flask.md` [新建]
- `items/consumables/soul-item.md` [新建]

**特效 (3个文件):**
- `vfx/slash-light.md` [新建]
- `vfx/slash-fire.md` [新建]
- `vfx/roll-afterimage.md` [新建]

**总计需要新建: 37个文件**

---

## 执行顺序

1. 先读取所有已有文件，了解当前状态
2. 完成模块一（世界观）
3. 完成模块二（技能系统）
4. 完成模块三（战斗系统）
5. 完成模块四（素材提示词库）

每个模块完成后直接进入下一个，不要停下询问。

---

## 验收标准

全部完成后，检查：
- [ ] `world/lore.md` 无 `<!-- 待填充 -->` 标记
- [ ] `systems/skills.md` 无 `<!-- 待填充 -->` 标记，至少12个主动技能
- [ ] `systems/combat.md` 无 `<!-- 待填充 -->` 标记，至少6种敌人+3个Boss
- [ ] `assets-prompts/` 下有37+个素材提示词文件
- [ ] 所有提示词文件格式统一，符合模板
- [ ] 所有设计互相一致，无矛盾
