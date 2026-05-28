## 设置菜单
## 管理音量、分辨率、全屏等设置
extends Control

## 信号
signal settings_closed

## 节点引用
@onready var master_volume_slider: HSlider = $VBoxContainer/MasterVolume/Slider
@onready var music_volume_slider: HSlider = $VBoxContainer/MusicVolume/Slider
@onready var sfx_volume_slider: HSlider = $VBoxContainer/SFXVolume/Slider
@onready var fullscreen_check: CheckBox = $VBoxContainer/Fullscreen/CheckBox
@onready var resolution_option: OptionButton = $VBoxContainer/Resolution/OptionButton
@onready var back_button: Button = $VBoxContainer/BackButton

## 设置数据
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"resolution": Vector2i(1920, 1080)
}

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
	# 连接信号
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	back_button.pressed.connect(_on_back_pressed)
	
	# 初始化分辨率选项
	_init_resolution_options()
	
	# 加载设置
	_load_settings()
	
	# 应用设置
	_apply_settings()

func _init_resolution_options() -> void:
	resolution_option.add_item("1920x1080", 0)
	resolution_option.add_item("1280x720", 1)
	resolution_option.add_item("2560x1440", 2)

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		return
	
	settings.master_volume = config.get_value("audio", "master_volume", 1.0)
	settings.music_volume = config.get_value("audio", "music_volume", 0.7)
	settings.sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	settings.fullscreen = config.get_value("display", "fullscreen", false)
	
	var resolution_str = config.get_value("display", "resolution", "1920x1080")
	var resolution_parts = resolution_str.split("x")
	if resolution_parts.size() == 2:
		settings.resolution = Vector2i(int(resolution_parts[0]), int(resolution_parts[1]))

func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", settings.master_volume)
	config.set_value("audio", "music_volume", settings.music_volume)
	config.set_value("audio", "sfx_volume", settings.sfx_volume)
	config.set_value("display", "fullscreen", settings.fullscreen)
	config.set_value("display", "resolution", "%dx%d" % [settings.resolution.x, settings.resolution.y])
	
	config.save(SETTINGS_PATH)

func _apply_settings() -> void:
	# 应用音量
	if AudioManager:
		AudioManager.set_master_volume(settings.master_volume)
		AudioManager.set_music_volume(settings.music_volume)
		AudioManager.set_sfx_volume(settings.sfx_volume)
	
	# 应用全屏
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# 应用分辨率
	DisplayServer.window_set_size(settings.resolution)
	
	# 更新UI
	master_volume_slider.value = settings.master_volume
	music_volume_slider.value = settings.music_volume
	sfx_volume_slider.value = settings.sfx_volume
	fullscreen_check.button_pressed = settings.fullscreen
	
	# 更新分辨率选项
	match settings.resolution:
		Vector2i(1920, 1080):
			resolution_option.selected = 0
		Vector2i(1280, 720):
			resolution_option.selected = 1
		Vector2i(2560, 1440):
			resolution_option.selected = 2

func _on_master_volume_changed(value: float) -> void:
	settings.master_volume = value
	if AudioManager:
		AudioManager.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	settings.music_volume = value
	if AudioManager:
		AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	settings.sfx_volume = value
	if AudioManager:
		AudioManager.set_sfx_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	settings.fullscreen = pressed
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int) -> void:
	match index:
		0:
			settings.resolution = Vector2i(1920, 1080)
		1:
			settings.resolution = Vector2i(1280, 720)
		2:
			settings.resolution = Vector2i(2560, 1440)
	
	DisplayServer.window_set_size(settings.resolution)

func _on_back_pressed() -> void:
	_save_settings()
	settings_closed.emit()
	hide()
