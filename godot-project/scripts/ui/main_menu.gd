## 主菜单
extends Control

## 节点引用
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel

## 场景路径
const GAME_SCENE_PATH = "res://scenes/levels/graveyard_01.tscn"

func _ready() -> void:
	# 设置按钮焦点
	new_game_button.grab_focus()
	
	# 连接按钮信号
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 检查是否有存档
	_update_continue_button()
	
	# 设置版本号
	if version_label:
		version_label.text = "v0.1.0 - Alpha"

func _update_continue_button() -> void:
	if continue_button:
		var has_save = FileAccess.file_exists("user://save_game.json")
		continue_button.disabled = not has_save

func _on_new_game_pressed() -> void:
	# 创建新游戏
	if GameManager:
		GameManager.change_state(GameManager.GameState.PLAYING)
	
	# 加载游戏场景
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_continue_pressed() -> void:
	# 加载存档
	if GameManager:
		var success = GameManager.load_game()
		if success:
			GameManager.change_state(GameManager.GameState.PLAYING)
			get_tree().change_scene_to_file(GAME_SCENE_PATH)
		else:
			# 显示错误信息
			_show_error("无法加载存档")

func _on_settings_pressed() -> void:
	# TODO: 打开设置菜单
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()

func _show_error(message: String) -> void:
	# TODO: 显示错误对话框
	push_error(message)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# 在主菜单按ESC退出
		get_tree().quit()
