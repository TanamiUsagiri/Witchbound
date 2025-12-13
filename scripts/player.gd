extends CharacterBody2D


const SPEED := 100
const MAX_HP := 100
const WATER_SHURIKEN_SCENE = preload("res://bullets/water_shuriken.tscn")
const INPUT_ACTIONS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
}

var hp := MAX_HP
var is_attacking := false
var is_dead := false
var is_hurt := false
var water_shuriken_spawned := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_setup_wasd_input()
	animated_sprite.play("idle")

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	
	if is_attacking or is_hurt:
		return
	
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving := input_vector.length_squared() > 0.0

	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * SPEED
	_update_animation(is_moving, input_vector)
	move_and_slide()
	
	# Check for attack input (Space key)
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_attack()


func _setup_wasd_input() -> void:
	for action in INPUT_ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = INPUT_ACTIONS[action]

		# Remove existing bindings so WASD becomes the sole scheme.
		for event in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, event)

		InputMap.action_add_event(action, key_event)


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
	if is_dead:
		return
	
	hp -= amount
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

