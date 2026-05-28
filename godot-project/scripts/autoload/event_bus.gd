## 事件总线 - 全局自动加载
## 解耦系统间通信，所有全局事件在此定义
extends Node

# ============================================================
# 玩家事件
# ============================================================
signal player_died
signal player_respawned
signal player_health_changed(new_hp: int, max_hp: int)
signal player_stamina_changed(new_stamina: float, max_stamina: float)
signal player_focus_changed(new_focus: float, max_focus: float)
signal player_souls_changed(new_souls: int)
signal player_leveled_up(new_level: int)

# ============================================================
# 战斗事件
# ============================================================
signal enemy_died(enemy_id: String, souls: int)
signal boss_defeated(boss_id: String)
signal damage_dealt(target: Node2D, damage: int, element: String)
signal damage_taken(source: Node2D, damage: int)
signal critical_hit(target: Node2D, damage: int)

# ============================================================
# 技能事件
# ============================================================
signal skill_used(skill_id: String)
signal skill_equipped(slot: int, skill_id: String)
signal skill_cooldown_started(skill_id: String, duration: float)
signal skill_cooldown_ended(skill_id: String)
signal skill_unlocked(skill_id: String)

# ============================================================
# 进度事件
# ============================================================
signal area_discovered(area_id: String)
signal bonfire_rest(bonfire_id: String)
signal bonfire_lit(bonfire_id: String)
signal item_acquired(item_id: String, quantity: int)
signal item_used(item_id: String)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)

# ============================================================
# UI事件
# ============================================================
signal dialog_started(dialog_id: String)
signal dialog_ended
signal dialog_choice_made(choice_id: String)
signal shop_opened(shop_id: String)
signal shop_closed
signal menu_opened
signal menu_closed
signal notification_requested(message: String, type: String)

# ============================================================
# 游戏状态事件
# ============================================================
signal game_state_changed(old_state: int, new_state: int)
signal game_saved
signal game_loaded
signal game_paused
signal game_resumed
signal scene_transition_started(target_scene: String)
signal scene_transition_completed

# ============================================================
# 音频事件
# ============================================================
signal music_requested(music_path: String, fade_time: float)
signal sfx_requested(sfx_path: String, volume_offset: float)
signal ambient_requested(ambient_path: String)
