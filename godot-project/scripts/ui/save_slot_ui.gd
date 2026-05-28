## 存档槽UI
## 显示存档槽位、存档信息、保存/加载功能
extends Control

## 信号
signal save_completed
signal load_completed
signal save_ui_closed

## 节点引用
@onready var slot_container: VBoxContainer = $VBoxContainer/SlotContainer
@onready var slot_buttons: Array[Button] = []
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var delete_button: Button = $VBoxContainer/DeleteButton
@onready var close_button: Button = $VBoxContainer/CloseButton

## 状态
var selected_slot: int = -1
var mode: String = "save"  # "save" or "load"

func _ready() -> void:
	# 创建存档槽按钮
	for i in range(3):
		var button = Button.new()
		button.text = "存档槽 %d" % (i + 1)
		button.pressed.connect(_on_slot_selected.bind(i))
		slot_container.add_child(button)
		slot_buttons.append(button)
	
	# 连接信号
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# 初始化
	hide()
	_update_buttons()

## 打开存档UI
func open_save_ui(save_mode: String = "save") -> void:
	mode = save_mode
	selected_slot = -1
	_refresh_slots()
	_update_buttons()
	show()

## 刷新存档槽显示
func _refresh_slots() -> void:
	for i in range(3):
		var button = slot_buttons[i]
		var meta = SaveManager.get_save_meta(i)
		
		if meta.is_empty():
			button.text = "存档槽 %d - 空" % (i + 1)
		else:
			var time = Time.get_datetime_string_from_unix_time(meta.get("timestamp", 0))
			var level = meta.get("level", 1)
			var area = meta.get("area", "graveyard")
			button.text = "存档槽 %d - Lv.%d %s (%s)" % [i + 1, level, area, time]

## 选择存档槽
func _on_slot_selected(slot: int) -> void:
	selected_slot = slot
	_update_buttons()
	
	# 高亮选中的按钮
	for i in range(3):
		slot_buttons[i].button_pressed = (i == slot)

## 更新按钮状态
func _update_buttons() -> void:
	var has_selection = selected_slot >= 0
	
	if mode == "save":
		save_button.visible = true
		load_button.visible = false
		save_button.disabled = not has_selection
	else:
		save_button.visible = false
		load_button.visible = true
		load_button.disabled = not has_selection
	
	delete_button.disabled = not has_selection or SaveManager.get_save_meta(selected_slot).is_empty()

## 保存游戏
func _on_save_pressed() -> void:
	if selected_slot < 0:
		return
	
	var success = SaveManager.save_game(selected_slot)
	if success:
		_refresh_slots()
		save_completed.emit()

## 加载游戏
func _on_load_pressed() -> void:
	if selected_slot < 0:
		return
	
	var success = SaveManager.load_game(selected_slot)
	if success:
		load_completed.emit()
		hide()

## 删除存档
func _on_delete_pressed() -> void:
	if selected_slot < 0:
		return
	
	SaveManager.delete_save(selected_slot)
	_refresh_slots()
	_update_buttons()

## 关闭UI
func _on_close_pressed() -> void:
	hide()
	save_ui_closed.emit()
