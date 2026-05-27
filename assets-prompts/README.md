# 魂系像素风游戏 - AI素材生成提示词库

## 项目概述
本项目是一个魂系(Souls-like)像素风动作RPG游戏的AI美术素材生成系统。
每个 `.md` 文件对应一个素材，包含标准化的提示词，可供Codex/AI Agent批量执行生成任务。

## 统一风格标准

### 核心风格关键词
```
Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, 
muted desaturated colors with warm accent lighting (amber/orange from fire), 
high contrast shadows, hand-crafted pixel detail
```

### 色彩方案
- **主色调**: 深灰、暗褐、冷蓝（压抑、阴暗）
- **强调色**: 琥珀色、橙色（火光、篝暖）
- **点缀色**: 暗红（血迹、危险）、幽绿（毒/魔法）

### 参考游戏风格
- Blasphemous（亵渎）- 哥特式阴暗
- Dead Cells - 流畅动作 + 像素
- Hollow Knight - 氛围感 + 精细像素
- Salt and Sanctuary - 魂系像素化

## 文件结构

### 目录说明
```
characters/     角色素材（玩家、敌人、NPC）
├── player/     玩家角色动画
├── enemies/    敌人动画（按敌人类型分子目录）
└── npcs/       NPC立绘

environment/    环境素材
├── tilesets/   地形瓦片（可平铺）
├── props/      场景道具
└── backgrounds/ 背景图

ui/             UI素材
├── 血条、体力条
├── 菜单界面
├── 图标
└── 对话框

items/          物品素材
├── weapons/    武器图标/立绘
└── consumables/ 消耗品图标

vfx/            特效素材
├── 攻击特效
├── 魔法特效
└── 环境特效
```

### 命名规范
- 英文小写 + 连字符分隔
- 格式: `{对象}-{状态/类型}.md`
- 示例: `player-idle.md`, `skeleton-attack.md`, `dungeon-stone.md`

## 每个提示词文件的标准格式

```markdown
# [素材名称]

## 基本信息
- **类型**: character / environment / ui / item / vfx
- **用途**: [具体描述]
- **尺寸**: 像素尺寸
- **动画帧数**: 帧数或"静态"
- **输出格式**: PNG, sprite sheet 或 单帧

## 风格标准
> [从上面的核心风格关键词复制，可针对具体素材微调]

## 提示词 (Prompt)

### 正向提示词
```
[生成内容的详细描述]
```

### 负向提示词
```
[需要避免的元素]
```

## 参考说明
- [视觉参考描述]

## 备注
- [特殊要求]
```

## 使用方法

### Codex / AI Agent 批量生成
1. 读取指定目录下的所有 `.md` 文件
2. 提取正向提示词和负向提示词
3. 调用图像生成API（Midjourney/DALL-E/Stable Diffusion）
4. 将生成结果保存到对应的 `/output` 目录

### 单个素材生成
直接打开对应的 `.md` 文件，复制提示词使用。

## 待完成
- [ ] 玩家角色全套动画
- [ ] 基础敌人（骷髅、亡灵、骑士）
- [ ] Boss设计
- [ ] 地牢环境瓦片
- [ ] 城堡环境瓦片
- [ ] UI全套
- [ ] 武器图标
- [ ] 特效系统
