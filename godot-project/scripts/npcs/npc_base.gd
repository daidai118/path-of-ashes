## NPC基类
## 所有NPC继承此类，提供通用的NPC行为框架
class_name NPCBase
extends CharacterBody2D

# ============================================================
# 信号
# ============================================================
signal dialog_started(dialog_id: String)
signal dialog_ended
signal interaction_started
signal interaction_ended

# ============================================================
# 导出变量
# ============================================================
@export_group("NPC Info")
@export var npc_id: String = ""
@export var npc_name: String = ""
@export var npc_title: String = ""
@export var npc_description: String = ""

@export_group("Interaction")
@export var interaction_range: float = 50.0
@export var interaction_prompt: String = "按 E 对话"
@export var can_interact: bool = true

@export_group("Dialog")
@export var dialog_tree_id: String = ""
@export var default_dialog_id: String = ""

@export_group("Movement")
@export var can_move: bool = false
@export var patrol_points: Array[Vector2] = []
@export var move_speed: float = 50.0

# ============================================================
# 节点引用
# ============================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var dialog_indicator: Sprite2D = $DialogIndicator if has_node("DialogIndicator") else null
@onready var name_label: Label = $NameLabel if has_node("NameLabel") else null

# ============================================================
# 状态
# ============================================================
enum NPCState { IDLE, TALKING, WALKING, WORKING }
var current_state: NPCState = NPCState.IDLE
var player_nearby: bool = false
var is_interacting: bool = false
var facing_direction: int = 1

# ============================================================
# 对话
# ============================================================
var current_dialog_id: String = ""
var dialog_completed: Dictionary = {}  # 记录已完成的对话

# ============================================================
# 生命周期
# ============================================================
func _ready() -> void:
	_init_npc()
	_connect_signals()
	_update_visual()

func _init_npc() -> void:
	# 子类可重写以进行初始化
	pass

func _connect_signals() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	# 连接对话系统信号
	if EventBus:
		EventBus.dialog_ended.connect(_on_dialog_ended)

func _process(_delta: float) -> void:
	# 检测玩家输入
	if player_nearby and Input.is_action_just_pressed("interact"):
		if can_interact and not is_interacting:
			_start_interaction()
	
	# 更新对话指示器
	_update_dialog_indicator()

# ============================================================
# 交互
# ============================================================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		_show_interaction_prompt()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		_hide_interaction_prompt()

func _start_interaction() -> void:
	is_interacting = true
	interaction_started.emit()
	
	# 确定要播放的对话
	var dialog_id = _get_dialog_id()
	if dialog_id.is_empty():
		_end_interaction()
		return
	
	# 开始对话
	current_dialog_id = dialog_id
	dialog_started.emit(dialog_id)
	EventBus.dialog_started.emit(dialog_id)
	
	# 子类可重写以添加额外逻辑
	_on_interaction_start()

func _end_interaction() -> void:
	is_interacting = false
	current_dialog_id = ""
	interaction_ended.emit()
	
	# 子类可重写以添加额外逻辑
	_on_interaction_end()

## 获取要播放的对话ID（子类重写）
func _get_dialog_id() -> String:
	# 默认返回默认对话
	return default_dialog_id

## 交互开始时调用（子类重写）
func _on_interaction_start() -> void:
	pass

## 交互结束时调用（子类重写）
func _on_interaction_end() -> void:
	pass

# ============================================================
# 对话回调
# ============================================================
func _on_dialog_ended() -> void:
	if is_interacting:
		# 标记对话完成
		if not current_dialog_id.is_empty():
			dialog_completed[current_dialog_id] = true
		
		_end_interaction()

## 标记对话完成
func mark_dialog_completed(dialog_id: String) -> void:
	dialog_completed[dialog_id] = true

## 检查对话是否已完成
func is_dialog_completed(dialog_id: String) -> bool:
	return dialog_completed.has(dialog_id)

# ============================================================
# 视觉更新
# ============================================================
func _update_visual() -> void:
	if name_label:
		name_label.text = npc_name
	
	_update_animation()

func _update_animation() -> void:
	if not animation_player:
		return
	
	match current_state:
		NPCState.IDLE:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
		NPCState.TALKING:
			if animation_player.has_animation("talk"):
				animation_player.play("talk")
		NPCState.WALKING:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")

func _update_dialog_indicator() -> void:
	if dialog_indicator:
		# 显示/隐藏对话指示器
		var has_new_dialog = not _get_dialog_id().is_empty() and not is_dialog_completed(_get_dialog_id())
		dialog_indicator.visible = player_nearby and has_new_dialog

func _show_interaction_prompt() -> void:
	# 子类可重写以显示交互提示
	pass

func _hide_interaction_prompt() -> void:
	# 子类可重写以隐藏交互提示
	pass

# ============================================================
# 朝向
# ============================================================
func _update_facing() -> void:
	if sprite:
		sprite.flip_h = facing_direction == -1

func face_toward(target_position: Vector2) -> void:
	facing_direction = 1 if target_position.x > global_position.x else -1
	_update_facing()

func face_toward_player() -> void:
	if player_nearby:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			face_toward(player.global_position)

# ============================================================
# 查询
# ============================================================
func get_npc_info() -> Dictionary:
	return {
		"id": npc_id,
		"name": npc_name,
		"title": npc_title,
		"description": npc_description,
		"can_interact": can_interact,
		"current_state": current_state,
	}
