# 专注条 (Focus Bar)

## 基本信息
- **类型**: ui
- **用途**: 玩家HUD专注值条，显示在体力条下方
- **尺寸**: 外框 256x32 / 填充条 240x20
- **动画帧数**: 静态（外框）+ 动态填充（代码实现）
- **输出格式**: PNG, 外框图 + 填充贴图

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词 - 外框
```
Dark fantasy pixel art UI focus bar frame, 16-bit retro style, 256x32 pixel, ornate dark iron bar frame with subtle arcane or magical rune decorations, medieval dark souls style UI element, dark muted metal colors, weathered look, transparent center for focus fill, game HUD element, pixel perfect, clean readable design, slightly mystical appearance
```

### 正向提示词 - 专注填充（参考色）
```
Dark fantasy pixel art focus bar fill, 16-bit retro style, 240x20 pixel, muted blue to dark blue gradient, subtle magical glow effect, dark souls FP bar style, arcane blue color, readable but not bright, game HUD element, pixel perfect
```

### 负向提示词
```
blurry, smooth, realistic, 3D render, bright neon colors, cartoon style, sci-fi UI, modern sleek design, low detail, anti-aliasing, gradient, photo, watermark, text, signature, clean futuristic
```

## 参考说明
- 风格参考: Dark Souls的FP条
- 设计要点: 蓝色调，比血条和体力条更神秘
- 外框可以有轻微的符文装饰

## 备注
- 专注条填充由代码控制
- 使用技能时应有消耗动画
- 放置在体力条正下方
