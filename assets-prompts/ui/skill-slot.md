# 技能槽 (Skill Slot)

## 基本信息
- **类型**: ui
- **用途**: 玩家HUD技能图标槽位，显示当前装备的技能
- **尺寸**: 48x48
- **动画帧数**: 静态（空槽）/ 静态（技能图标）
- **输出格式**: PNG, 单帧, transparent background

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词 - 空槽
```
Dark fantasy pixel art UI skill slot, 16-bit retro style, 48x48 pixel, empty skill icon frame, ornate dark iron border with subtle rune engravings, dark souls style UI element, dark muted metal colors, weathered and battle-worn look, hollow center for skill icon, game HUD element, pixel perfect, clean readable design
```

### 正向提示词 - 技能图标示例（钩索）
```
Dark fantasy pixel art UI skill icon, 16-bit retro style, 48x48 pixel, rusty grappling hook icon, dark souls style skill icon, muted metal colors with orange rust detail, simple clear silhouette, game HUD element, pixel perfect, skill icon design
```

### 负向提示词
```
blurry, smooth, realistic, 3D render, bright neon colors, cartoon style, sci-fi UI, modern sleek design, complex detailed icon, low detail, anti-aliasing, gradient, photo, watermark, text, signature, clean futuristic
```

## 参考说明
- 风格参考: Dark Souls的技能/道具图标
- 设计要点: 简洁、清晰、一目了然
- 图标应能在小尺寸下辨识

## 备注
- 需要3个槽位（Q/E/R）
- 空槽应有明显的边框
- 技能冷却时应有遮罩效果（代码实现）
