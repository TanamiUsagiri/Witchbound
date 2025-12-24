extends Node2D

# === SETTINGS ===
@export_group("Player Reference")
@export var player : CharacterBody2D

@export_group("Chunk Settings")
@export var chunk_size : int = 1024  # Kích thước 1 chunk (pixels)
@export var view_distance : int = 2  # Bán kính chunks xung quanh player

@export_group("Ground")
@export var ground_layer : TileMapLayer  # TileMapLayer cho nền cỏ

@export_group("Obstacles - Solid (có collision)")
@export var tree_scenes : Array[PackedScene] = []
@export var rock_scenes : Array[PackedScene] = []
@export var pond_scenes : Array[PackedScene] = []  # Hồ nhỏ

@export_group("Decorations (không collision)")
@export var grass_scenes : Array[PackedScene] = []  # Cỏ cao
@export var bush_scenes : Array[PackedScene] = []   # Bụi trang trí

@export_group("Spawn Rates")
@export_range(0.0, 1.0) var tree_density : float = 0.08
@export_range(0.0, 1.0) var rock_density : float = 0.04
@export_range(0.0, 1.0) var pond_density : float = 0.02
@export_range(0.0, 1.0) var grass_density : float = 0.15
@export_range(0.0, 1.0) var bush_density : float = 0.06

# === INTERNAL ===
var chunks : Dictionary = {}
var noise : FastNoiseLite
var pond_noise : FastNoiseLite

func _ready():
	setup_noise()
	if ground_layer:
		generate_ground_base()
	generate_initial_chunks()

func setup_noise():
	# Noise chính cho cây/đá
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 28042004
	noise.frequency = 0.05
	
	# Noise cho hồ nước
	pond_noise = FastNoiseLite.new()
	pond_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	pond_noise.seed = 20042804
	pond_noise.frequency = 0.03

func generate_ground_base():
	# Generate ground tiles cơ bản
	# Adjust theo tileset của bạn
	var tile_size = 32
	var world_tiles = 100
	
	for x in range(-world_tiles, world_tiles):
		for y in range(-world_tiles, world_tiles):
			# Sử dụng TileMapLayer API mới
			# source_id thường là 0, atlas_coords là vị trí tile trong atlas
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func _process(_delta):
	update_chunks()

func generate_initial_chunks():
	if not player:
		return
	
	var player_chunk = get_chunk_position(player.global_position)
	
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			generate_chunk(player_chunk + Vector2i(x, y))

func update_chunks():
	if not player:
		return
	
	var player_chunk = get_chunk_position(player.global_position)
	
	# Tạo chunks mới
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
	
	# Xóa chunks xa
	var to_remove = []
	for chunk_pos in chunks.keys():
		if player_chunk.distance_to(chunk_pos) > view_distance + 1:
			to_remove.append(chunk_pos)
	
	for chunk_pos in to_remove:
		chunks[chunk_pos].queue_free()
		chunks.erase(chunk_pos)

func get_chunk_position(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / chunk_size),
		floori(world_pos.y / chunk_size)
	)

func generate_chunk(chunk_pos: Vector2i):
	if chunks.has(chunk_pos):
		return
	
	var chunk = Node2D.new()
	chunk.position = Vector2(chunk_pos) * chunk_size
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.y_sort_enabled = true
	
	generate_chunk_content(chunk, chunk_pos)
	
	add_child(chunk)
	chunks[chunk_pos] = chunk

func generate_chunk_content(chunk: Node2D, chunk_pos: Vector2i):
	var grid_size = 32
	var spawns_per_chunk = chunk_size / grid_size
	
	for x in range(spawns_per_chunk):
		for y in range(spawns_per_chunk):
			var world_x = chunk_pos.x * spawns_per_chunk + x
			var world_y = chunk_pos.y * spawns_per_chunk + y
			
			var terrain_noise = noise.get_noise_2d(world_x, world_y)
			var water_noise = pond_noise.get_noise_2d(world_x, world_y)
			
			var local_pos = Vector2(x * grid_size + grid_size/2, y * grid_size + grid_size/2)
			
			seed(hash(Vector2i(world_x, world_y)))
			
			# SPAWN LOGIC
			
			# 1. PONDS
			if water_noise > 0.0 and not pond_scenes.is_empty():
				if randf() < pond_density:
					spawn_obstacle(chunk, local_pos, pond_scenes)
					continue
			
			# 2. DECORATIONS - Cỏ cao
			if terrain_noise < -0.2 and not grass_scenes.is_empty():
				if randf() < grass_density:
					spawn_obstacle(chunk, local_pos, grass_scenes)
			
			# 3. TREES
			if terrain_noise > 0.0 and not tree_scenes.is_empty():
				if randf() < tree_density:
					spawn_obstacle(chunk, local_pos, tree_scenes)
			
			# 4. ROCKS
			elif terrain_noise > 0.3 and terrain_noise < 0.6 and not rock_scenes.is_empty():
				if randf() < rock_density:
					spawn_obstacle(chunk, local_pos, rock_scenes)
			
			# 5. BUSHES
			elif terrain_noise > -0.2 and terrain_noise < 0.3 and not bush_scenes.is_empty():
				if randf() < bush_density:
					spawn_obstacle(chunk, local_pos, bush_scenes)

func spawn_obstacle(chunk: Node2D, pos: Vector2, scene_array: Array[PackedScene]):
	if scene_array.is_empty():
		return
	
	var random_scene = scene_array[randi() % scene_array.size()]
	var obstacle = random_scene.instantiate()
	
	obstacle.position = pos
	
	var scale_variation = randf_range(0.85, 1.15)
	obstacle.scale = Vector2(scale_variation, scale_variation)
	
	chunk.add_child(obstacle)