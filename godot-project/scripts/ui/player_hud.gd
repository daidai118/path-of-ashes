## 玩家HUD
## 显示血条、体力条、专注值、技能栏、道具栏
extends CanvasLayer

## 节点引用
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var focus_bar: ProgressBar = $MarginContainer/VBoxContainer/FocusBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/Label
@onready var stamina_label: Label = $MarginContainer/VBoxContainer/StaminaBar/Label
@onready var focus_label: Label = $MarginContainer/VBoxContainer/FocusBar/Label
@onready var souls_label: Label = $MarginContainer/SoulsLabel
@onready var estus_label: Label = $MarginContainer/EstusLabel

## 技能栏
@onready var skill_slots: HBoxContainer = $MarginContainer/SkillSlots
@onready var skill_1_texture: TextureRect = $MarginContainer/SkillSlots/Skill1/TextureRect
@onready var skill_2_texture: TextureRect = $MarginContainer/SkillSlots/Skill2/TextureRect
@onready var skill_3_texture: TextureRect = $MarginContainer/SkillSlots/Skill3/TextureRect
@onready var skill_1_cooldown: ProgressBar = $MarginContainer/SkillSlots/Skill1/Cooldown
@onready var skill_2_cooldown: ProgressBar = $MarginContainer/SkillSlots/Skill2/Cooldown
@onready var skill_3_cooldown: ProgressBar = $MarginContainer/SkillSlots/Skill3/Cooldown

## 道具栏
@onready var item_slot: HBoxContainer = $MarginContainer/ItemSlot
@onready var item_texture: TextureRect = $MarginContainer/ItemSlot/TextureRect
@onready var item_count: Label = $MarginContainer/ItemSlot/Count

## 玩家引用
var player: CharacterBody2D = null

func _ready() -> void:
	# 等待一帧确保玩家已加载
	await get_tree().process_frame
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if player:
		# 连接玩家信号
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("focus_changed"):
			player.focus_changed.connect(_on_focus_changed)
		if player.has_signal("souls_changed"):
			player.souls_changed.connect(_on_souls_changed)
		
		# 初始化显示
		_on_health_changed(player.current_hp, player.max_hp)
		_on_stamina_changed(player.current_stamina, player.max_stamina)
		_on_focus_changed(player.current_focus, player.max_focus)
	
	# 连接GameManager信号
	if GameManager:
		GameManager.bonfire_rest.connect(_on_bonfire_rest)
	
	# 初始化原素瓶显示
	_update_estus_display()

func _on_health_changed(new_hp: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = new_hp
	if health_label:
		health_label.text = "%d/%d" % [new_hp, max_hp]

func _on_stamina_changed(new_stamina: float, max_stamina: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = new_stamina
	if stamina_label:
		stamina_label.text = "%d/%d" % [int(new_stamina), int(max_stamina)]

func _on_focus_changed(new_focus: float, max_focus: float) -> void:
	if focus_bar:
		focus_bar.max_value = max_focus
		focus_bar.value = new_focus
	if focus_label:
		focus_label.text = "%d/%d" % [int(new_focus), int(max_focus)]

func _on_souls_changed(new_souls: int) -> void:
	if souls_label:
		souls_label.text = "灰烬精华: %d" % new_souls

func _on_bonfire_rest(_bonfire_id: String) -> void:
	_update_estus_display()

func _update_estus_display() -> void:
	if estus_label and GameManager:
		var charges = GameManager.player_stats.estus_charges
		var max_charges = GameManager.player_stats.max_estus
		estus_label.text = "原素瓶: %d/%d" % [charges, max_charges]

func _process(_delta: float) -> void:
	# 更新灰烬精华显示
	if souls_label and GameManager:
		souls_label.text = "灰烬精华: %d" % GameManager.player_stats.souls
