## 铁门/机关门
## 可通过拉杆打开/关闭
extends StaticBody2D

## 导出变量
@export var gate_id: String = ""
@export var is_open: bool = false
@export var auto_close: bool = false
@export var auto_close_delay: float = 5.0

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 计时器
var auto_close_timer: Timer

func _ready() -> void:
	# 初始化状态
	_update_state()
	
	# 创建自动关闭计时器
	if auto_close:
		auto_close_timer = Timer.new()
		auto_close_timer.one_shot = true
		auto_close_timer.wait_time = auto_close_delay
		auto_close_timer.timeout.connect(_on_auto_close_timeout)
		add_child(auto_close_timer)

## 打开门
func activate() -> void:
	if is_open:
		return
	
	is_open = true
	_update_state()
	
	# 播放动画
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	
	# 启动自动关闭计时器
	if auto_close and auto_close_timer:
		auto_close_timer.start()

## 关闭门
func deactivate() -> void:
	if not is_open:
		return
	
	is_open = false
	_update_state()
	
	# 播放动画
	if animation_player and animation_player.has_animation("close"):
		animation_player.play("close")

## 更新状态
func _update_state() -> void:
	# 禁用/启用碰撞
	if collision:
		collision.disabled = is_open
	
	# 更新视觉
	if sprite:
		if is_open:
			sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)  # 半透明
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 不透明

## 自动关闭超时
func _on_auto_close_timeout() -> void:
	deactivate()

## 获取状态
func get_is_open() -> bool:
	return is_open
