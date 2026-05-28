## 商店系统
## 管理物品买卖、价格、库存
class_name ShopSystem
extends Node

# ============================================================
# 信号
# ============================================================
signal shop_opened(shop_id: String)
signal shop_closed
signal item_bought(item_id: String, price: int)
signal item_sold(item_id: String, price: int)
signal insufficient_funds(item_id: String, price: int, current_souls: int)

# ============================================================
# 导出变量
# ============================================================
@export_group("Shop Info")
@export var shop_id: String = ""
@export var shop_name: String = ""
@export var shop_type: String = "general"  # general, weapons, consumables

@export_group("Settings")
@export var buy_price_multiplier: float = 1.0
@export var sell_price_multiplier: float = 0.5
@export var infinite_stock: bool = false

# ============================================================
# 节点引用
# ============================================================
@onready var shop_ui: Control = $ShopUI if has_node("ShopUI") else null
@onready var item_list: ItemList = $ShopUI/ItemList if has_node("ShopUI/ItemList") else null
@onready var item_details: Control = $ShopUI/ItemDetails if has_node("ShopUI/ItemDetails") else null
@onready var souls_label: Label = $ShopUI/SoulsLabel if has_node("ShopUI/SoulsLabel") else null
@onready var buy_button: Button = $ShopUI/BuyButton if has_node("ShopUI/BuyButton") else null
@onready var sell_button: Button = $ShopUI/SellButton if has_node("ShopUI/SellButton") else null

# ============================================================
# 商品数据
# ============================================================
var shop_inventory: Array[Dictionary] = []  # 商店库存
var player_inventory: Array[Dictionary] = []  # 玩家背包（用于出售）

# 商品数据结构:
# {
#   "id": "potion_hp",
#   "name": "生命药水",
#   "description": "恢复100点生命",
#   "icon": Texture2D,
#   "base_price": 100,
#   "stock": 10,  # -1表示无限
#   "type": "consumable",  # weapon, amulet, consumable, material
#   "stats": {}  # 物品属性
# }

# ============================================================
# 状态
# ============================================================
var is_open: bool = false
var selected_item: Dictionary = {}
var current_tab: String = "buy"  # buy, sell

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_hide_shop()
	_connect_signals()

func _connect_signals() -> void:
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if item_list:
		item_list.item_selected.connect(_on_item_selected)

# ============================================================
# 商店操作
# ============================================================
## 打开商店
func open_shop() -> void:
	if is_open:
		return
	
	is_open = true
	_show_shop()
	_refresh_inventory()
	_update_souls_display()
	
	# 暂停游戏
	if GameManager:
		GameManager.change_state(GameManager.GameState.DIALOG)
	
	shop_opened.emit(shop_id)
	EventBus.shop_opened.emit(shop_id)

## 关闭商店
func close_shop() -> void:
	if not is_open:
		return
	
	is_open = false
	_hide_shop()
	
	# 恢复游戏
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)
	
	shop_closed.emit()
	EventBus.shop_closed.emit()

## 刷新库存
func _refresh_inventory() -> void:
	if not item_list:
		return
	
	item_list.clear()
	
	var items = shop_inventory if current_tab == "buy" else player_inventory
	
	for item in items:
		var stock_text = ""
		if current_tab == "buy":
			var stock = item.get("stock", -1)
			if stock >= 0:
				stock_text = " (x%d)" % stock
		
		item_list.add_item(item.get("name", "") + stock_text)

# ============================================================
# 购买
# ============================================================
func _on_buy_pressed() -> void:
	if selected_item.is_empty():
		return
	
	buy_item(selected_item.get("id", ""))

## 购买物品
func buy_item(item_id: String) -> bool:
	var item = _find_shop_item(item_id)
	if item.is_empty():
		return false
	
	# 检查库存
	var stock = item.get("stock", -1)
	if stock == 0:
		return false
	
	# 计算价格
	var price = _calculate_buy_price(item)
	
	# 检查灵魂
	if GameManager:
		if GameManager.player_stats.souls < price:
			insufficient_funds.emit(item_id, price, GameManager.player_stats.souls)
			return false
		
		# 扣除灵魂
		GameManager.player_stats.souls -= price
		
		# 减少库存
		if stock > 0:
			item["stock"] = stock - 1
		
		# 添加到玩家背包
		_add_to_player_inventory(item)
		
		# 更新显示
		_refresh_inventory()
		_update_souls_display()
		
		item_bought.emit(item_id, price)
		EventBus.item_acquired.emit(item_id, 1)
		
		return true
	
	return false

## 计算购买价格
func _calculate_buy_price(item: Dictionary) -> int:
	var base_price = item.get("base_price", 0)
	return int(base_price * buy_price_multiplier)

# ============================================================
# 出售
# ============================================================
func _on_sell_pressed() -> void:
	if selected_item.is_empty():
		return
	
	sell_item(selected_item.get("id", ""))

## 出售物品
func sell_item(item_id: String) -> bool:
	var item = _find_player_item(item_id)
	if item.is_empty():
		return false
	
	# 计算价格
	var price = _calculate_sell_price(item)
	
	# 添加灵魂
	if GameManager:
		GameManager.player_stats.souls += price
		
		# 从玩家背包移除
		_remove_from_player_inventory(item_id)
		
		# 更新显示
		_refresh_inventory()
		_update_souls_display()
		
		item_sold.emit(item_id, price)
		return true
	
	return false

## 计算出售价格
func _calculate_sell_price(item: Dictionary) -> int:
	var base_price = item.get("base_price", 0)
	return int(base_price * sell_price_multiplier)

# ============================================================
# 库存管理
# ============================================================
func _find_shop_item(item_id: String) -> Dictionary:
	for item in shop_inventory:
		if item.get("id", "") == item_id:
			return item
	return {}

func _find_player_item(item_id: String) -> Dictionary:
	for item in player_inventory:
		if item.get("id", "") == item_id:
			return item
	return {}

func _add_to_player_inventory(item: Dictionary) -> void:
	# 检查是否已存在
	for existing_item in player_inventory:
		if existing_item.get("id", "") == item.get("id", ""):
			existing_item["quantity"] = existing_item.get("quantity", 1) + 1
			return
	
	# 添加新物品
	var new_item = item.duplicate()
	new_item["quantity"] = 1
	player_inventory.append(new_item)

func _remove_from_player_inventory(item_id: String) -> void:
	for i in range(player_inventory.size()):
		var item = player_inventory[i]
		if item.get("id", "") == item_id:
			var quantity = item.get("quantity", 1)
			if quantity > 1:
				item["quantity"] = quantity - 1
			else:
				player_inventory.remove_at(i)
			return

## 添加商品到商店
func add_shop_item(item: Dictionary) -> void:
	shop_inventory.append(item)

## 移除商品
func remove_shop_item(item_id: String) -> void:
	for i in range(shop_inventory.size()):
		if shop_inventory[i].get("id", "") == item_id:
			shop_inventory.remove_at(i)
			return

## 设置商店库存
func set_shop_inventory(items: Array[Dictionary]) -> void:
	shop_inventory = items

## 设置玩家库存
func set_player_inventory(items: Array[Dictionary]) -> void:
	player_inventory = items

# ============================================================
# UI控制
# ============================================================
func _show_shop() -> void:
	if shop_ui:
		shop_ui.visible = true

func _hide_shop() -> void:
	if shop_ui:
		shop_ui.visible = false

func _update_souls_display() -> void:
	if souls_label and GameManager:
		souls_label.text = "灰烬精华: %d" % GameManager.player_stats.souls

func _on_item_selected(index: int) -> void:
	var items = shop_inventory if current_tab == "buy" else player_inventory
	if index >= 0 and index < items.size():
		selected_item = items[index]
		_update_item_details(selected_item)

func _update_item_details(item: Dictionary) -> void:
	# 子类可重写以显示物品详情
	pass

# ============================================================
# 查询
# ============================================================
func get_shop_info() -> Dictionary:
	return {
		"id": shop_id,
		"name": shop_name,
		"type": shop_type,
		"items": shop_inventory.size(),
		"is_open": is_open,
	}

func can_afford(item_id: String) -> bool:
	var item = _find_shop_item(item_id)
	if item.is_empty():
		return false
	
	var price = _calculate_buy_price(item)
	return GameManager and GameManager.player_stats.souls >= price
