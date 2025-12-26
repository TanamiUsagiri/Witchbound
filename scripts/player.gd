extends CharacterBody2D

var speed: float = 120
var hp: float = 100:
	set(value):
			hp = value
			%Health.value = value
var knockback : Vector2 = Vector2.ZERO
var nearest_enemy : CharacterBody2D
var nearest_enemy_distance : float = INF
var is_attacking := false
var is_dead := false
var is_hurt := false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

	
func _ready() -> void:
	animated_sprite.play("idle")

func _physics_process(_delta: float) -> void:
	if is_instance_valid(nearest_enemy):
		nearest_enemy_distance = nearest_enemy.separation
	else:
		nearest_enemy_distance = INF

	var input_vector := Input.get_vector("left", "right", "up", "down")
	var len_sq := input_vector.length_squared()
	if len_sq > 1.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()
	_update_animation(len_sq > 0.0, input_vector)

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_attack()

func _update_animation(is_moving: bool, direction: Vector2) -> void:
	if is_dead or is_attacking or is_hurt:
		return
	
	var target_anim := "idle"
	if is_moving:
		target_anim = "run"

	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)

	if is_moving and direction.x != 0.0:
		animated_sprite.flip_h = direction.x < 0.0

func _attack() -> void:
	if is_attacking or is_dead:
		return
	
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	is_attacking = false

func take_damage(amount: int) -> void:
	hp -= amount
	print(amount)
	if hp <= 0:
		hp = 0
		die()
		return
	
	is_hurt = true
	velocity = Vector2.ZERO
	animated_sprite.play("hurt")
	await animated_sprite.animation_finished
	is_hurt = false

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	# Optionally handle death logic here

func _on_self_dmg_body_entered(body: Node2D) -> void:
	take_damage(body.dmg)


func _on_timer_timeout() -> void:
	%Collision.set_deferred("disable", true)
	%Collision.set_deferred("disable", false)
