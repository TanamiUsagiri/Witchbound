extends CharacterBody2D

@export var movement_speed = 20.0
@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("walk")
func _physics_process(_delta) -> void:
	var direction = global_position .direction_to(player.global_position)
	velocity = direction*movement_speed
	move_and_slide()

	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
