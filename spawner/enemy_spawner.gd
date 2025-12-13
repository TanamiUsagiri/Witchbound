extends Node2D


@export var enemy_scene : PackedScene
@export var spawn_radius := 600.0
@export var spawn_interval := 2.0

@onready var player := get_tree().get_first_node_in_group("player")
@onready var enemies := get_parent().get_node("enemies")
func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(spawn_enemy)
	add_child(timer)

func spawn_enemy():
	if player == null:
		return
	var angle = randf() * TAU
	var dir = Vector2(cos(angle), sin(angle))
	var spawn_pos = player.global_position + dir * spawn_radius

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	enemies.add_child(enemy)
