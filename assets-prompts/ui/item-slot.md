# 道具槽 (Item Slot)

## 基本信息
- **类型**: ui
- **用途**: 玩家HUD道具图标槽位，显示当前选中的道具
- **尺寸**: 48x48
- **动画帧数**: 静态（空槽）/ 静态（道具图标）
- **输出格式**: PNG, 单帧, transparent background

## 风格标准
> Dark fantasy pixel art, 16-bit retro style, gloomy medieval atmosphere, muted desaturated colors with warm accent lighting (amber/orange from fire), high contrast shadows, hand-crafted pixel detail.

## 提示词 (Prompt)

### 正向提示词 - 空槽
```
Dark fantasy pixel art UI item slot, 16-bit retro style, 48x48 pixel, empty item icon frame, ornate dark iron border with subtle cross or medical motif, dark souls style UI element, dark muted metal colors, weathered look, hollow center for item icon, game HUD element, pixel perfect, clean readable design
```

### 正向提示词 - 道具图标示例（原素瓶）
```
Dark fantasy pixel art UI item icon, 16-bit retro style, 48x48 pixel, healing flask icon, dark souls estus flask style, amber glowing liquid in glass bottle, warm orange glow, simple clear silhouette, game HUD element, pixel perfect, consumable item icon
```

### 负向提示词
```
blurry, smooth, realistic, 3D render, bright neon colors, cartoon style, sci-fi UI, modern sleek design, complex detailed icon, low detail, anti-aliasing, gradient, photo, watermark, text, signature, clean futuristic
```

## 参考说明
- 风格参考: Dark Souls的道具栏
- 设计要点: 简洁、清晰、原素瓶的温暖光芒
- 道具数量应有数字显示

## 备注
- 需要显示道具数量（代码实现）
- 道具使用时应有消耗动画
- 放置在技能槽旁边
