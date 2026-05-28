## 背包系统
## 管理玩家的物品、装备、消耗品
class_name InventorySystem
extends Node

# ============================================================
# 信号
# ============================================================
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal item_used(item_id: String)
signal inventory_full
signal slot_changed(slot_type: String, slot_index: int)

# ============================================================
# 导出变量
# ============================================================
@export_group("Settings")
@export var max_inventory_size: int = 50
@export var max_consumable_slots: int = 5
@export var max_weapon_slots: int = 3
@export var max_amulet_slots: int = 2

# ============================================================
# 物品类型
# ============================================================
enum ItemType { WEAPON, AMULET, CONSUMABLE, MATERIAL, KEY_ITEM }

# ============================================================
# 物品数据结构
# ============================================================
# {
#   "id": "potion_hp",
#   "name": "生命药水",
#   "description": "恢复100点生命",
#   "icon": Texture2D,
#   "type": ItemType.CONSUMABLE,
#   "quantity": 1,
#   "max_quantity": 99,
#   "stackable": true,
#   "usable": true,
#   "equipable": false,
#   "stats": {},
#   "effects": []
# }

# ============================================================
# 背包数据
# ============================================================
var items: Array[Dictionary] = []  # 所有物品
var equipped_weapon: Dictionary = {}
var equipped_amulets: Array[Dictionary] = [{}]
var equipped_consumables: Array[Dictionary] = []

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_init_inventory()

func _init_inventory() -> void:
	# 初始化装备槽
	equipped_consumables.resize(max_consumable_slots)
	equipped_amulets.resize(max_amulet_slots)

# ============================================================
# 物品管理
# ============================================================
## 添加物品
func add_item(item_data: Dictionary, quantity: int = 1) -> bool:
	var item_id = item_data.get("id", "")
	
	# 检查是否可堆叠
	if item_data.get("stackable", false):
		# 查找现有物品
		var existing_item = _find_item(item_id)
		if not existing_item.is_empty():
			var current_quantity = existing_item.get("quantity", 1)
			var max_quantity = existing_item.get("max_quantity", 99)
			
			if current_quantity + quantity <= max_quantity:
				existing_item["quantity"] = current_quantity + quantity
				item_added.emit(item_id, quantity)
				return true
			else:
				# 部分添加
				var can_add = max_quantity - current_quantity
				if can_add > 0:
					existing_item["quantity"] = max_quantity
					item_added.emit(item_id, can_add)
					# 剩余的需要新槽位
					quantity -= can_add
	
	# 检查背包是否已满
	if items.size() >= max_inventory_size:
		inventory_full.emit()
		return false
	
	# 添加新物品
	var new_item = item_data.duplicate()
	new_item["quantity"] = quantity
	items.append(new_item)
	item_added.emit(item_id, quantity)
	
	return true

## 移除物品
func remove_item(item_id: String, quantity: int = 1) -> bool:
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	
	var current_quantity = item.get("quantity", 1)
	if current_quantity < quantity:
		return false
	
	if current_quantity == quantity:
		# 移除整个物品
		items.erase(item)
	else:
		# 减少数量
		item["quantity"] = current_quantity - quantity
	
	item_removed.emit(item_id, quantity)
	return true

## 使用物品
func use_item(item_id: String) -> bool:
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	
	if not item.get("usable", false):
		return false
	
	# 应用效果
	var effects = item.get("effects", [])
	for effect in effects:
		_apply_effect(effect)
	
	# 减少数量
	remove_item(item_id, 1)
	item_used.emit(item_id)
	
	return true

## 使用装备的消耗品
func use_equipped_consumable(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= max_consumable_slots:
		return false
	
	var item = equipped_consumables[slot_index]
	if item.is_empty():
		return false
	
	return use_item(item.get("id", ""))

# ============================================================
# 装备系统
# ============================================================
## 装备武器
func equip_weapon(item_id: String) -> bool:
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	
	if item.get("type") != ItemType.WEAPON:
		return false
	
	# 卸下当前武器
	if not equipped_weapon.is_empty():
		unequip_weapon()
	
	# 装备新武器
	equipped_weapon = item.duplicate()
	remove_item(item_id, 1)
	
	slot_changed.emit("weapon", 0)
	return true

## 卸下武器
func unequip_weapon() -> bool:
	if equipped_weapon.is_empty():
		return false
	
	# 添加回背包
	add_item(equipped_weapon)
	equipped_weapon = {}
	
	slot_changed.emit("weapon", 0)
	return true

## 装备护符
func equip_amulet(item_id: String, slot_index: int = 0) -> bool:
	if slot_index < 0 or slot_index >= max_amulet_slots:
		return false
	
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	
	if item.get("type") != ItemType.AMULET:
		return false
	
	# 卸下当前护符
	if not equipped_amulets[slot_index].is_empty():
		unequip_amulet(slot_index)
	
	# 装备新护符
	equipped_amulets[slot_index] = item.duplicate()
	remove_item(item_id, 1)
	
	slot_changed.emit("amulet", slot_index)
	return true

## 卸下护符
func unequip_amulet(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= max_amulet_slots:
		return false
	
	if equipped_amulets[slot_index].is_empty():
		return false
	
	# 添加回背包
	add_item(equipped_amulets[slot_index])
	equipped_amulets[slot_index] = {}
	
	slot_changed.emit("amulet", slot_index)
	return true

## 装备消耗品
func equip_consumable(item_id: String, slot_index: int = 0) -> bool:
	if slot_index < 0 or slot_index >= max_consumable_slots:
		return false
	
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	
	if item.get("type") != ItemType.CONSUMABLE:
		return false
	
	# 卸下当前消耗品
	if not equipped_consumables[slot_index].is_empty():
		unequip_consumable(slot_index)
	
	# 装备新消耗品
	equipped_consumables[slot_index] = item.duplicate()
	remove_item(item_id, 1)
	
	slot_changed.emit("consumable", slot_index)
	return true

## 卸下消耗品
func unequip_consumable(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= max_consumable_slots:
		return false
	
	if equipped_consumables[slot_index].is_empty():
		return false
	
	# 添加回背包
	add_item(equipped_consumables[slot_index])
	equipped_consumables[slot_index] = {}
	
	slot_changed.emit("consumable", slot_index)
	return true

# ============================================================
# 效果应用
# ============================================================
func _apply_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0)
	
	match effect_type:
		"heal_hp":
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal"):
				player.heal(value)
		"heal_fp":
			if GameManager:
				GameManager.player_stats.current_fp = min(
					GameManager.player_stats.current_fp + value,
					GameManager.player_stats.max_fp
				)
		"heal_stamina":
			if GameManager:
				GameManager.player_stats.current_stamina = min(
					GameManager.player_stats.current_stamina + value,
					GameManager.player_stats.max_stamina
				)
		"cure_status":
			# TODO: 清除状态异常
			pass
		_:
			push_warning("未知的效果类型: " + effect_type)

# ============================================================
# 查询
# ============================================================
func _find_item(item_id: String) -> Dictionary:
	for item in items:
		if item.get("id", "") == item_id:
			return item
	return {}

func has_item(item_id: String, quantity: int = 1) -> bool:
	var item = _find_item(item_id)
	if item.is_empty():
		return false
	return item.get("quantity", 0) >= quantity

func get_item_count(item_id: String) -> int:
	var item = _find_item(item_id)
	if item.is_empty():
		return 0
	return item.get("quantity", 0)

func get_inventory_size() -> int:
	return items.size()

func is_inventory_full() -> bool:
	return items.size() >= max_inventory_size

func get_all_items() -> Array[Dictionary]:
	return items

func get_items_by_type(type: ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if item.get("type") == type:
			result.append(item)
	return result

func get_equipped_weapon() -> Dictionary:
	return equipped_weapon

func get_equipped_amulet(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= max_amulet_slots:
		return {}
	return equipped_amulets[slot_index]

func get_equipped_consumable(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= max_consumable_slots:
		return {}
	return equipped_consumables[slot_index]

# ============================================================
# 序列化
# ============================================================
func to_dict() -> Dictionary:
	return {
		"items": items,
		"equipped_weapon": equipped_weapon,
		"equipped_amulets": equipped_amulets,
		"equipped_consumables": equipped_consumables,
	}

func from_dict(data: Dictionary) -> void:
	items = data.get("items", [])
	equipped_weapon = data.get("equipped_weapon", {})
	equipped_amulets = data.get("equipped_amulets", [])
	equipped_consumables = data.get("equipped_consumables", [])
