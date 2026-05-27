# 血条 (Health Bar)

## 基本信息
- **类型**: ui
- **用途**: 玩家HUD生命值条，显示在屏幕左上角或左下角
- **尺寸**: 外框 256x32 / 填充条 240x20
- **动画帧数**: 静态（外框）+ 动态填充（代码实现）
- **输出格式**: PNG, 外框图 + 填充贴图

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词 - 外框
```
Dark fantasy pixel art UI health bar frame, 16-bit retro style, 256x32 pixel, ornate dark iron bar frame with subtle skull or gothic decorations at corners, medieval dark souls style UI element, dark muted metal colors, weathered and battle-worn look, transparent center for health fill, game HUD element, pixel perfect, clean readable design, dark background with subtle border details
```

### 正向提示词 - 血量填充（参考色）
```
Dark fantasy pixel art health bar fill, 16-bit retro style, 240x20 pixel, deep crimson red to dark red gradient, subtle animated pulse glow effect reference, dark souls health bar style, muted blood red color, saturated enough to read at a glance but not bright or cartoonish, game HUD element, pixel perfect
```

### 负向提示词
```
blurry, smooth, realistic, 3D render, bright neon colors, cartoon style, sci-fi UI, modern sleek design, hearts instead of bar, low detail, anti-aliasing, gradient, photo, watermark, text, signature, clean futuristic
```

## 参考说明
- 风格参考: Dark Souls的血条、Hollow Knight的生命值面具
- 设计要点: 简洁但有质感，不抢游戏画面注意力
- 色彩: 暗红（正常）→ 深红闪烁（低血量警告）

## 备注
- 血条填充由代码控制，只需提供外框素材
- 需要配套的：体力条（绿色调）、魔力条（蓝色调）
- 受伤时血条需要做短暂闪烁动画（代码实现）
- 可选：血条旁加一个小型玩家头像/状态图标
