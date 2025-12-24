extends Node2D

@onready var sprite : Sprite2D = $Sprite2D
@export var rustle_area : Area2D

func _ready() -> void:
    z_index = 0
    y_sort_enabled = true

    # Tạo Area2D để detect player
    rustle_area = Area2D.new()
    add_child(rustle_area)

    var shape = CircleShape2D.new()
    shape.radius = 20
    var collision = CollisionShape2D.new()
    collision.shape = shape
    rustle_area.add_child(collision)

    # Set layer/mask
    rustle_area.collision_layer = 0
    rustle_area.collision_mask = 2  # Detect Player layer

    rustle_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.name == "Player":
        # Tween nhẹ khi player đi qua
        var tween = create_tween()
        tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
        tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func _process(_delta: float) -> void:
    z_index = int(global_position.y)