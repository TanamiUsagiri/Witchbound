extends Node2D

var player: Node2D

func _ready() -> void:
	# Lưu reference player; tạm thời không spawn mob nào.
	player = $Player

