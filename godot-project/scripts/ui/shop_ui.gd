## 商店UI
## 显示商品列表、购买/出售功能
extends Control

## 信号
signal shop_closed

## 节点引用
@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var item_details: VBoxContainer = $VBoxContainer/ItemDetails
@onready var item_name_label: Label = $VBoxContainer/ItemDetails/NameLabel
@onready var item_desc_label: Label = $VBoxContainer/ItemDetails/DescLabel
@onready var item_price_label: Label = $VBoxContainer/ItemDetails/PriceLabel
@onready var buy_button: Button = $VBoxContainer/ItemDetails/BuyButton
@onready var sell_button: Button = $VBoxContainer/ItemDetails/SellButton
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var souls_label: Label = $VBoxContainer/SoulsLabel
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer

## 商店数据
var shop_items: Array[Dictionary] = []
var player_items: Array[Dictionary] = []
var selected_item: Dictionary = {}
var current_tab: String = "buy"

func _ready() -> void:
	# 连接信号
	item_list.item_selected.connect(_on_item_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# 初始化
	hide()
	item_details.visible = false

## 打开商店
func open_shop(items: Array[Dictionary]) -> void:
	shop_items = items
	_refresh_item_list()
	_update_souls_display()
	show()

## 关闭商店
func close_shop() -> void:
	hide()
	shop_closed.emit()

## 刷新物品列表
func _refresh_item_list() -> void:
	item_list.clear()
	
	var items = shop_items if current_tab == "buy" else player_items
	
	for item in items:
		var index = item_list.add_item(item.get("name", ""))
		item_list.set_item_metadata(index, item)

## 更新灵魂显示
func _update_souls_display() -> void:
	if souls_label and GameManager:
		souls_label.text = "灰烬精华: %d" % GameManager.player_stats.souls

## 选择物品
func _on_item_selected(index: int) -> void:
	selected_item = item_list.get_item_metadata(index)
	_show_item_details(selected_item)

## 显示物品详情
func _show_item_details(item: Dictionary) -> void:
	item_name_label.text = item.get("name", "")
	item_desc_label.text = item.get("description", "")
	item_price_label.text = "价格: %d" % item.get("price", 0)
	
	item_details.visible = true
	
	# 更新按钮状态
	if current_tab == "buy":
		buy_button.visible = true
		sell_button.visible = false
		buy_button.disabled = not _can_afford(item)
	else:
		buy_button.visible = false
		sell_button.visible = true

## 检查是否买得起
func _can_afford(item: Dictionary) -> bool:
	if not GameManager:
		return false
	return GameManager.player_stats.souls >= item.get("price", 0)

## 购买物品
func _on_buy_pressed() -> void:
	if selected_item.is_empty():
		return
	
	var price = selected_item.get("price", 0)
	if GameManager and GameManager.player_stats.souls >= price:
		GameManager.player_stats.souls -= price
		
		# 添加到玩家背包
		_add_to_inventory(selected_item)
		
		_update_souls_display()
		_refresh_item_list()

## 出售物品
func _on_sell_pressed() -> void:
	if selected_item.is_empty():
		return
	
	var price = selected_item.get("price", 0)
	if GameManager:
		GameManager.player_stats.souls += int(price * 0.5)  # 卖出价格是买入的一半
		
		# 从玩家背包移除
		_remove_from_inventory(selected_item)
		
		_update_souls_display()
		_refresh_item_list()

## 添加到背包
func _add_to_inventory(item: Dictionary) -> void:
	# TODO: 实现背包系统集成
	pass

## 从背包移除
func _remove_from_inventory(item: Dictionary) -> void:
	# TODO: 实现背包系统集成
	pass

## 关闭商店
func _on_close_pressed() -> void:
	close_shop()
