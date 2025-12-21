extends CharacterBody2D

@export var player_reference: CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var damage_popup_node = preload("res://components/damage.tscn")
var direction : Vector2
var speed : float = 75
var dmg : float
var knockback : Vector2
var separation : float

var health : float:
	set(value):
		health = value
		if health <= 0:
			queue_free()

var elite : bool = false:
	set(value):
		elite = value
		if value:
			$AnimatedSprite2D.material = load("res://Shader/Rainbow.tres")
			scale = Vector2(1.5, 1.5)

var enemy_type : EnemyType:
	set(value):
		enemy_type = value
		# Chỉ apply nếu node đã trong scene tree
		if is_inside_tree():
			apply_type()
		dmg = value.dmg
		health = value.health

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

func _physics_process(_delta) -> void:
	check_separation(_delta)
	knockback_update(_delta)

func check_separation(_delta):
	separation = (player_reference.position - position).length()
	if separation >= 500 and not elite:
		queue_free()

	if separation < player_reference.nearest_enemy_distance:
		player_reference.nearest_enemy = self

func knockback_update(delta):
	velocity = (player_reference.position - position).normalized() * speed
	knockback = knockback.move_toward(Vector2.ZERO, 1)
	velocity += knockback
	var collider = move_and_collide(velocity * delta)
	if collider:
		collider.get_collider().knockback = (collider.get_collider().global_position - global_position).normalized() * 50
	
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func damage_popup(amount):
	var popup = damage_popup_node.instantiate()
	popup.text = str(int(amount))
	popup.position = position + Vector2(-50, -25)
	get_tree().current_scene.add_child(popup)

func take_damage(amount):
	var tween =get_tree().create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(3, 0.25, 0.25), 0.2)
	tween.chain().tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1), 0.2)
	tween.bind_node(self)

	damage_popup(amount)
	health -= amount
