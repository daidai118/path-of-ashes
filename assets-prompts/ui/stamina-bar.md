# 体力条 (Stamina Bar)

## 基本信息
- **类型**: ui
- **用途**: 玩家HUD体力值条，显示在血条下方
- **尺寸**: 外框 256x32 / 填充条 240x20
- **动画帧数**: 静态（外框）+ 动态填充（代码实现）
- **输出格式**: PNG, 外框图 + 填充贴图

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词 - 外框
```
Dark fantasy pixel art UI stamina bar frame, 16-bit retro style, 256x32 pixel, ornate dark iron bar frame with subtle vine or nature decorations, medieval dark souls style UI element, dark muted metal colors, weathered look, transparent center for stamina fill, game HUD element, pixel perfect, clean readable design, slightly smaller than health bar frame
```

### 正向提示词 - 体力填充（参考色）
```
Dark fantasy pixel art stamina bar fill, 16-bit retro style, 240x20 pixel, muted green to dark green gradient, subtle pulse when depleted, dark souls stamina bar style, forest green color, readable but not bright, game HUD element, pixel perfect
```

### 负向提示词
```
blurry, smooth, realistic, 3D render, bright neon colors, cartoon style, sci-fi UI, modern sleek design, low detail, anti-aliasing, gradient, photo, watermark, text, signature, clean futuristic
```

## 参考说明
- 风格参考: Dark Souls的体力条
- 设计要点: 比血条稍小，绿色调区分
- 与血条保持一致的外框风格

## 备注
- 体力条填充由代码控制
- 体力耗尽时应有闪烁效果
- 放置在血条正下方
