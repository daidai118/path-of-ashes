## 音频管理器 - 全局自动加载
## 管理背景音乐和音效
extends Node

## 音频播放器
var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var sfx_players: Array[AudioStreamPlayer] = []

## 音量设置
var music_volume: float = 0.8
var sfx_volume: float = 1.0

func _ready() -> void:
	add_child(music_player)
	music_player.bus = "Music"
	
	# 创建音效播放器池
	for i in 8:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = "SFX"
		sfx_players.append(player)

## 播放背景音乐
func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
	if music_player.stream == stream:
		return
	
	if music_player.playing and fade_time > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40, fade_time / 2)
		await tween.finished
	
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume)
	music_player.play()

## 停止背景音乐
func stop_music(fade_time: float = 1.0) -> void:
	if fade_time > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40, fade_time)
		await tween.finished
	music_player.stop()

## 播放音效
func play_sfx(stream: AudioStream, volume_offset: float = 0.0) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume) + volume_offset
			player.play()
			return
	
	# 如果所有播放器都在使用，用第一个
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = linear_to_db(sfx_volume) + volume_offset
	sfx_players[0].play()

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
