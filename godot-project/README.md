# 灰烬之路 - Godot 项目

## 快速开始

1. 用 Godot 4.2+ 打开此项目
2. 主场景: `scenes/ui/main_menu.tscn` (待创建)
3. 玩家场景: `scenes/player/player.tscn` (待创建)

## 项目结构

```
godot-project/
├── project.godot           # 项目配置
├── scenes/                 # 场景文件
│   ├── player/            # 玩家场景
│   ├── enemies/           # 敌人场景
│   ├── bosses/            # Boss场景
│   ├── npcs/              # NPC场景
│   ├── ui/                # UI场景
│   └── levels/            # 关卡场景
├── scripts/                # GDScript脚本
│   ├── player/            # 玩家脚本
│   ├── enemies/           # 敌人脚本
│   ├── bosses/            # Boss脚本
│   ├── npcs/              # NPC脚本
│   ├── ui/                # UI脚本
│   ├── systems/           # 系统脚本
│   └── autoload/          # 自动加载脚本
├── assets/                 # 游戏素材
│   ├── characters/        # 角色素材
│   ├── environment/       # 环境素材
│   ├── ui/                # UI素材
│   ├── items/             # 物品素材
│   ├── vfx/               # 特效素材
│   └── audio/             # 音频素材
└── resources/              # Godot资源
    ├── items/             # 物品资源
    ├── skills/            # 技能资源
    └── enemies/           # 敌人资源
```

## 操作按键

| 按键 | 功能 |
|------|------|
| A/D 或 左/右 | 移动 |
| Space 或 上 | 跳跃 |
| Shift | 翻滚 |
| 鼠标左键 | 轻攻击 |
| 鼠标右键 | 重攻击 |
| Q/E/R | 技能1/2/3 |
| F | 使用道具 |
| E | 交互 |
| ESC | 暂停 |

## 已实现系统

- [x] 玩家基础移动
- [x] 翻滚/无敌帧
- [x] 基础攻击系统
- [x] 敌人AI基类
- [x] 游戏管理器
- [x] 音频管理器
- [x] 存档系统框架

## 待实现系统

- [ ] 技能系统
- [ ] 装备系统
- [ ] 物品系统
- [ ] NPC对话系统
- [ ] 商店系统
- [ ] Boss战系统
- [ ] 篝火系统
- [ ] 关卡系统

## 设计文档

详见 `game-design/` 目录

## 素材来源

- PNG素材: `assets/` 目录
- 素材提示词: `assets-prompts/` 目录
- 如需生成更多素材，使用提示词库
