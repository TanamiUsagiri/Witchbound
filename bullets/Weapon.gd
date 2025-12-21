extends Resource
class_name Weapon

@export var title : String
@export var sprite_frames : SpriteFrames

@export var damage : float
@export var cooldown : float
@export var speed : float

@export var projectile_node : PackedScene = preload("res://bullets/projectile.tscn")
func activate(_source, _target, _scene_tree):
    if projectile_node == null:
        push_error("projectile_node is null!")
        return

    if _target == null:
        return

    # Tạo instance từ PackedScene
    var projectile = projectile_node.instantiate()

    # Set vị trí xuất phát
    projectile.position = _source.global_position

    # Tính hướng bắn
    var direction = (_target.global_position - _source.global_position).normalized()

    # Setup projectile (nếu có hàm setup)
    if projectile.has_method("setup"):
        projectile.setup(direction, speed, damage, sprite_frames)
    else:
    # Hoặc set trực tiếp các thuộc tính
        projectile.direction = direction
        projectile.speed = speed
        projectile.damage = damage
    if projectile.has_node("AnimatedSprite2D"):
        projectile.get_node("AnimatedSprite2D").sprite_frames = sprite_frames

    # Thêm vào scene
    _scene_tree.current_scene.add_child(projectile)