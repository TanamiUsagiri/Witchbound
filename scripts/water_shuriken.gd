extends Area2D

const DAMAGE := 20.0
const ORBIT_RADIUS_X := 50.0  # Bán kính elipse theo trục X
const ORBIT_RADIUS_Y := 40.0  # Bán kính elipse theo trục Y
const ORBIT_SPEED := 3.0  # Tốc độ quay
const HIT_COOLDOWN := 0.5  # Cooldown giữa các lần hit cùng một enemy

var player: Node2D
var angle := 0.0
var hit_timers := {}  # Dictionary để track cooldown cho mỗi enemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	player = get_node("/root/main/Player")
	animated_sprite.play("default")
	
	# Kết nối signal để phát hiện va chạm
	body_entered.connect(_on_body_entered)
	
	# Enable monitoring để detect bodies
	monitoring = true
	monitorable = false
	
	# Set collision layers để detect CharacterBody2D (orc)
	collision_layer = 0
	collision_mask = 1  # Layer 1 cho enemies

func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		queue_free()
		return
	
	# Cập nhật góc quay
	angle += ORBIT_SPEED * delta
	
	# Tính toán vị trí theo hình elipse
	var x = cos(angle) * ORBIT_RADIUS_X
	var y = sin(angle) * ORBIT_RADIUS_Y
	
	# Đặt vị trí relative to player
	global_position = player.global_position + Vector2(x, y)
	
	# Update hit timers
	for enemy in hit_timers.keys():
		hit_timers[enemy] -= delta
		if hit_timers[enemy] <= 0.0:
			hit_timers.erase(enemy)
	
	# Check for overlapping bodies using space query (more reliable for CharacterBody2D)
	_check_collisions()

func _check_collisions() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = global_transform
	query.collision_mask = collision_mask
	
	var results = space_state.intersect_shape(query, 32)
	
	for result in results:
		var body = result.collider
		if body != null and body.has_method("take_damage") and body != player:
			if not body in hit_timers or hit_timers[body] <= 0.0:
				body.take_damage(DAMAGE)
				hit_timers[body] = HIT_COOLDOWN

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != player:
		if not body in hit_timers or hit_timers[body] <= 0.0:
			body.take_damage(DAMAGE)
			hit_timers[body] = HIT_COOLDOWN
