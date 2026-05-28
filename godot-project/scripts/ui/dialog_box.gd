## 对话框UI
## 显示对话文本、角色名称、选项
extends Control

## 信号
signal dialog_finished
signal choice_selected(choice_id: String)

## 节点引用
@onready var name_label: Label = $PanelContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $PanelContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer
@onready var continue_indicator: Label = $PanelContainer/VBoxContainer/ContinueIndicator

## 状态
var is_active: bool = false
var current_lines: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var typing_speed: float = 0.03

## 打字效果
var tween: Tween = null

func _ready() -> void:
	hide()
	continue_indicator.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("attack_light"):
		if is_typing:
			# 跳过打字效果
			_skip_typing()
		else:
			# 下一行
			_next_line()

## 开始对话
func start_dialog(lines: Array) -> void:
	current_lines = lines
	current_line_index = 0
	is_active = true
	
	show()
	_show_current_line()

## 显示当前行
func _show_current_line() -> void:
	if current_line_index >= current_lines.size():
		_end_dialog()
		return
	
	var line = current_lines[current_line_index]
	
	# 设置名称
	name_label.text = line.get("speaker", "")
	
	# 设置文本
	var text = line.get("text", "")
	text_label.text = text
	text_label.visible_characters = 0
	
	# 隐藏选项
	choices_container.visible = false
	continue_indicator.visible = false
	
	# 开始打字效果
	_start_typing(text)

## 开始打字效果
func _start_typing(text: String) -> void:
	is_typing = true
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(text_label, "visible_characters", text.length(), text.length() * typing_speed)
	tween.tween_callback(_on_typing_finished)

## 跳过打字效果
func _skip_typing() -> void:
	if tween:
		tween.kill()
	
	text_label.visible_characters = -1
	_on_typing_finished()

## 打字完成
func _on_typing_finished() -> void:
	is_typing = false
	
	# 检查是否有选项
	var line = current_lines[current_line_index]
	var choices = line.get("choices", [])
	
	if not choices.is_empty():
		_show_choices(choices)
	else:
		continue_indicator.visible = true

## 显示选项
func _show_choices(choices: Array) -> void:
	# 清空选项容器
	for child in choices_container.get_children():
		child.queue_free()
	
	# 创建选项按钮
	for choice in choices:
		var button = Button.new()
		button.text = choice.get("text", "")
		button.pressed.connect(_on_choice_pressed.bind(choice.get("id", "")))
		choices_container.add_child(button)
	
	choices_container.visible = true

## 选项被点击
func _on_choice_pressed(choice_id: String) -> void:
	choice_selected.emit(choice_id)
	
	# 检查是否有跳转
	var line = current_lines[current_line_index]
	var choices = line.get("choices", [])
	
	for choice in choices:
		if choice.get("id", "") == choice_id:
			var next_line = choice.get("next_line", -1)
			if next_line >= 0:
				current_line_index = next_line
				_show_current_line()
				return
	
	# 没有跳转，继续下一行
	_next_line()

## 下一行
func _next_line() -> void:
	current_line_index += 1
	_show_current_line()

## 结束对话
func _end_dialog() -> void:
	is_active = false
	hide()
	dialog_finished.emit()

## 取消对话
func cancel_dialog() -> void:
	if tween:
		tween.kill()
	
	is_active = false
	is_typing = false
	hide()
