extends CharacterBody2D

@export var movement_speed := 50.0
@export var hp := 50
@export var player_reference: CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction : Vector2
var speed : float = 75

var enemy_type : EnemyType:
	set(value):
		enemy_type = value
		# Chỉ apply nếu node đã trong scene tree
		if is_inside_tree():
			apply_type()

func _ready():
	apply_type()
	animated_sprite.play("default")

func apply_type():
	if enemy_type == null:
		return
	
	# Kiểm tra animated_sprite có tồn tại không
	if animated_sprite == null:
		return
	
	animated_sprite.frames = enemy_type.sprite_frames
	animated_sprite.play("default")

func _physics_process(delta) -> void:
	velocity = (player_reference.position - position).normalized() * speed
	move_and_collide(velocity * delta)	
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _on_hurtbox_hurt(dmg: Variant) -> void:
	hp -= dmg
	if hp < 0:
		queue_free()