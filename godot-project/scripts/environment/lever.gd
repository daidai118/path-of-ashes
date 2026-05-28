## 机关拉杆
## 可通过钩索拉动，触发机关
extends Area2D

## 信号
signal lever_activated
signal lever_deactivated

## 导出变量
@export var lever_id: String = ""
@export var is_active: bool = false
@export var is_toggle: bool = true  # 是否可切换

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 连接的机关
var connected_objects: Array[Node2D] = []

func _ready() -> void:
	# 初始化状态
	_update_visual()

## 激活拉杆
func activate() -> void:
	if is_toggle:
		is_active = !is_active
	else:
		is_active = true
	
	_update_visual()
	
	# 通知连接的机关
	for obj in connected_objects:
		if is_active and obj.has_method("activate"):
			obj.activate()
		elif not is_active and obj.has_method("deactivate"):
			obj.deactivate()
	
	# 发送信号
	if is_active:
		lever_activated.emit()
	else:
		lever_deactivated.emit()
	
	# 播放动画
	if animation_player:
		if is_active and animation_player.has_animation("activate"):
			animation_player.play("activate")
		elif not is_active and animation_player.has_animation("deactivate"):
			animation_player.play("deactivate")

## 更新视觉
func _update_visual() -> void:
	if sprite:
		# 可以根据状态改变颜色或纹理
		if is_active:
			sprite.modulate = Color(0.5, 1.0, 0.5)  # 绿色
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0)  # 白色

## 连接机关
func connect_object(obj: Node2D) -> void:
	if not connected_objects.has(obj):
		connected_objects.append(obj)

## 断开机关
func disconnect_object(obj: Node2D) -> void:
	connected_objects.erase(obj)

## 获取状态
func get_is_active() -> bool:
	return is_active
