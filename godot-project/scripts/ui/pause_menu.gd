## 暂停菜单
extends Control

## 节点引用
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 隐藏菜单
	visible = false

func _on_resume_pressed() -> void:
	hide_pause_menu()
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)

func _on_settings_pressed() -> void:
	# TODO: 打开设置菜单
	pass

func _on_quit_pressed() -> void:
	# 退出到主菜单
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func show_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

func hide_pause_menu() -> void:
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			hide_pause_menu()
			if GameManager:
				GameManager.change_state(GameManager.GameState.PLAYING)
		else:
			show_pause_menu()
			if GameManager:
				GameManager.change_state(GameManager.GameState.PAUSED)
