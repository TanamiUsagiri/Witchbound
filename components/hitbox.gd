extends Area2D

@export var dmg = 10

@onready var colision = $CollisionShape2D
@onready var DisableTimer = $DisableHitBoxTimer

func _ready() -> void:
	add_to_group("attack")

func tempDisable():
	colision.call_deferred("set", "disabled", true)
	DisableTimer.start()

func _on_disable_hit_box_timer_timeout() -> void:
	colision.call_deferred("set", "disabled", false)
