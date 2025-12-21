extends Area2D

var direction : Vector2 = Vector2.RIGHT
var speed : float = 200
var damage : float = 1

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    if animated_sprite:
        animated_sprite.play("default")

func _process(delta: float) -> void:
    position += direction * speed * delta

    if direction != Vector2.ZERO:
        rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage)
        body.knockback = direction * 75


func _on_screen_exited() -> void:
    queue_free()

func setup(dir: Vector2, spd: float, dmg: float, sprite_frames: SpriteFrames = null):
    direction = dir
    speed = spd
    damage = dmg

    if sprite_frames and animated_sprite:
        animated_sprite.sprite_frames = sprite_frames
        animated_sprite.play("default")
    
    if direction != Vector2.ZERO:
        rotation = direction.angle()