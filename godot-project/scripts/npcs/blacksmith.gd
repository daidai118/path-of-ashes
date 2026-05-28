## 铁匠NPC
## 提供武器强化和修理服务
extends CharacterBody2D

## 信号
signal interaction_started
signal interaction_ended

## 导出变量
@export_group("NPC Info")
@export var npc_name: String = "铁匠"
@export var dialog_id: String = "blacksmith_intro"

@export_group("Interaction")
@export var interaction_range: float = 50.0

## 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel
@onready var dialog_indicator: Sprite2D = $DialogIndicator

## 状态
var player_nearby: bool = false
var is_interacting: bool = false

func _ready() -> void:
	# 连接信号
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	# 设置名称
	if name_label:
		name_label.text = npc_name
	
	# 隐藏对话指示器
	if dialog_indicator:
		dialog_indicator.visible = false

func _process(_delta: float) -> void:
	# 检测玩家输入
	if player_nearby and Input.is_action_just_pressed("interact"):
		if not is_interacting:
			_start_interaction()
	
	# 更新对话指示器
	if dialog_indicator:
		dialog_indicator.visible = player_nearby and not is_interacting

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false

func _start_interaction() -> void:
	is_interacting = true
	interaction_started.emit()
	
	# 面向玩家
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = player.global_position - global_position
		if sprite:
			sprite.flip_h = direction.x < 0
	
	# 开始对话
	if EventBus:
		EventBus.dialog_started.emit(dialog_id)
	
	# 播放动画
	if animation_player and animation_player.has_animation("talk"):
		animation_player.play("talk")

func _end_interaction() -> void:
	is_interacting = false
	interaction_ended.emit()
	
	# 恢复动画
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

## 对话结束回调
func _on_dialog_ended() -> void:
	if is_interacting:
		_end_interaction()
