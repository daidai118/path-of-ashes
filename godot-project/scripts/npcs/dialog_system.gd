## 对话系统
## 管理对话的播放、分支、选择
class_name DialogSystem
extends Node

# ============================================================
# 信号
# ============================================================
signal dialog_started(dialog_id: String)
signal dialog_line_shown(line: Dictionary)
signal dialog_choice_presented(choices: Array[Dictionary])
signal dialog_choice_made(choice_id: String)
signal dialog_ended

# ============================================================
# 导出变量
# ============================================================
@export_group("Settings")
@export var text_speed: float = 0.05  # 每个字符的显示时间
@export var auto_advance_delay: float = 3.0  # 自动推进延迟
@export var can_skip: bool = true

# ============================================================
# 节点引用
# ============================================================
@onready var dialog_box: Control = $DialogBox if has_node("DialogBox") else null
@onready var name_label: Label = $DialogBox/NameLabel if has_node("DialogBox/NameLabel") else null
@onready var text_label: Label = $DialogBox/TextLabel if has_node("DialogBox/TextLabel") else null
@onready var portrait_texture: TextureRect = $DialogBox/Portrait if has_node("DialogBox/Portrait") else null
@onready var choices_container: VBoxContainer = $DialogBox/Choices if has_node("DialogBox/Choices") else null
@onready var continue_indicator: Control = $DialogBox/ContinueIndicator if has_node("DialogBox/ContinueIndicator") else null

# ============================================================
# 状态
# ============================================================
enum DialogState { INACTIVE, TYPING, WAITING_FOR_INPUT, WAITING_FOR_CHOICE }
var current_state: DialogState = DialogState.INACTIVE

# ============================================================
# 对话数据
# ============================================================
var current_dialog: Dictionary = {}
var current_line_index: int = 0
var current_lines: Array = []
var current_speaker: String = ""
var current_portrait: Texture2D = null

# ============================================================
# 对话树缓存
# ============================================================
var dialog_trees: Dictionary = {}  # dialog_id -> dialog_data
var dialog_variables: Dictionary = {}  # 对话中使用的变量

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_hide_dialog_box()
	_connect_signals()

func _connect_signals() -> void:
	if EventBus:
		EventBus.dialog_started.connect(_on_dialog_started)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == DialogState.INACTIVE:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("attack_light"):
		if can_skip:
			_advance_dialog()

# ============================================================
# 对话控制
# ============================================================
## 开始对话
func start_dialog(dialog_id: String) -> void:
	if current_state != DialogState.INACTIVE:
		return
	
	# 加载对话数据
	var dialog_data = _load_dialog(dialog_id)
	if dialog_data.is_empty():
		push_error("对话数据不存在: " + dialog_id)
		return
	
	current_dialog = dialog_data
	current_lines = dialog_data.get("lines", [])
	current_line_index = 0
	
	if current_lines.is_empty():
		return
	
	# 显示对话框
	_show_dialog_box()
	current_state = DialogState.TYPING
	
	# 暂停游戏
	if GameManager:
		GameManager.change_state(GameManager.GameState.DIALOG)
	
	# 发送信号
	dialog_started.emit(dialog_id)
	EventBus.dialog_started.emit(dialog_id)
	
	# 显示第一行
	_show_current_line()

## 推进对话
func _advance_dialog() -> void:
	match current_state:
		DialogState.TYPING:
			# 立即显示完整文本
			if text_label:
				text_label.visible_characters = -1
			current_state = DialogState.WAITING_FOR_INPUT
		
		DialogState.WAITING_FOR_INPUT:
			# 下一行
			current_line_index += 1
			if current_line_index < current_lines.size():
				_show_current_line()
			else:
				_end_dialog()
		
		DialogState.WAITING_FOR_CHOICE:
			# 等待玩家选择
			pass

## 显示当前行
func _show_current_line() -> void:
	if current_line_index >= current_lines.size():
		_end_dialog()
		return
	
	var line = current_lines[current_line_index]
	
	# 更新说话者
	current_speaker = line.get("speaker", "")
	if name_label:
		name_label.text = current_speaker
	
	# 更新头像
	current_portrait = line.get("portrait", null)
	if portrait_texture:
		if current_portrait:
			portrait_texture.texture = current_portrait
			portrait_texture.visible = true
		else:
			portrait_texture.visible = false
	
	# 更新文本
	var text = line.get("text", "")
	if text_label:
		text_label.text = text
		text_label.visible_characters = 0
	
	# 检查是否有选项
	var choices = line.get("choices", [])
	if not choices.is_empty():
		current_state = DialogState.WAITING_FOR_CHOICE
		_show_choices(choices)
	else:
		current_state = DialogState.TYPING
		_start_typing_animation(text)
	
	# 发送信号
	dialog_line_shown.emit(line)

## 开始打字动画
func _start_typing_animation(text: String) -> void:
	if not text_label:
		return
	
	var tween = create_tween()
	tween.tween_property(text_label, "visible_characters", text.length(), text.length() * text_speed)
	tween.tween_callback(func(): current_state = DialogState.WAITING_FOR_INPUT)

## 显示选项
func _show_choices(choices: Array) -> void:
	if not choices_container:
		return
	
	# 清空选项容器
	for child in choices_container.get_children():
		child.queue_free()
	
	# 创建选项按钮
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = choice.get("text", "")
		button.pressed.connect(_on_choice_selected.bind(choice))
		choices_container.add_child(button)
	
	# 显示选项容器
	choices_container.visible = true
	
	# 发送信号
	dialog_choice_presented.emit(choices)

## 选择选项
func _on_choice_selected(choice: Dictionary) -> void:
	var choice_id = choice.get("id", "")
	dialog_choice_made.emit(choice_id)
	EventBus.dialog_choice_made.emit(choice_id)
	
	# 隐藏选项
	if choices_container:
		choices_container.visible = false
	
	# 处理选择结果
	var next_dialog = choice.get("next_dialog", "")
	var next_line = choice.get("next_line", -1)
	
	if not next_dialog.is_empty():
		# 跳转到另一个对话
		start_dialog(next_dialog)
	elif next_line >= 0:
		# 跳转到指定行
		current_line_index = next_line
		_show_current_line()
	else:
		# 继续下一行
		current_state = DialogState.WAITING_FOR_INPUT
		_advance_dialog()

## 结束对话
func _end_dialog() -> void:
	current_state = DialogState.INACTIVE
	_hide_dialog_box()
	
	# 恢复游戏
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)
	
	# 发送信号
	dialog_ended.emit()
	EventBus.dialog_ended.emit()
	
	# 清理
	current_dialog = {}
	current_lines = []
	current_line_index = 0

# ============================================================
# UI控制
# ============================================================
func _show_dialog_box() -> void:
	if dialog_box:
		dialog_box.visible = true

func _hide_dialog_box() -> void:
	if dialog_box:
		dialog_box.visible = false
	if choices_container:
		choices_container.visible = false
	if continue_indicator:
		continue_indicator.visible = false

# ============================================================
# 对话数据加载
# ============================================================
func _load_dialog(dialog_id: String) -> Dictionary:
	# 检查缓存
	if dialog_trees.has(dialog_id):
		return dialog_trees[dialog_id]
	
	# 从文件加载
	var dialog_path = "res://resources/dialog/dialog_trees/" + dialog_id + ".json"
	if not FileAccess.file_exists(dialog_path):
		push_error("对话文件不存在: " + dialog_path)
		return {}
	
	var file = FileAccess.open(dialog_path, FileAccess.READ)
	if not file:
		return {}
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("对话文件格式错误: " + dialog_path)
		return {}
	
	var dialog_data = json.data
	dialog_trees[dialog_id] = dialog_data
	return dialog_data

# ============================================================
# 变量系统
# ============================================================
## 设置对话变量
func set_variable(key: String, value: Variant) -> void:
	dialog_variables[key] = value

## 获取对话变量
func get_variable(key: String, default_value: Variant = null) -> Variant:
	return dialog_variables.get(key, default_value)

# ============================================================
# 信号回调
# ============================================================
func _on_dialog_started(dialog_id: String) -> void:
	# 如果是外部触发的对话
	if current_state == DialogState.INACTIVE:
		start_dialog(dialog_id)

# ============================================================
# 查询
# ============================================================
func is_active() -> bool:
	return current_state != DialogState.INACTIVE

func get_current_speaker() -> String:
	return current_speaker
