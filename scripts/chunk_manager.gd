extends Node2D

# === SETTINGS ===
@export_group("Player Reference")
@export var player : CharacterBody2D

@export_group("Chunk Settings")
@export var chunk_size : int = 1024
@export var view_distance : int = 3  # Tăng từ 2 → 3 để gen xa hơn
@export var preload_distance : int = 3  # Gen thêm 1 vòng ngoài view_distance

@export_group("Ground")
@export var ground_layer : TileMapLayer

@export_group("Obstacles - Solid (có collision)")
@export var tree_scenes : Array[PackedScene] = []
@export var rock_scenes : Array[PackedScene] = []
@export var pond_scenes : Array[PackedScene] = []

@export_group("Decorations (không collision)")
@export var grass_scenes : Array[PackedScene] = []
@export var bush_scenes : Array[PackedScene] = []

@export_group("Spawn Rates")
@export_range(0.0, 1.0) var tree_density : float = 0.08
@export_range(0.0, 1.0) var rock_density : float = 0.04
@export_range(0.0, 1.0) var pond_density : float = 0.02
@export_range(0.0, 1.0) var grass_density : float = 0.15
@export_range(0.0, 1.0) var bush_density : float = 0.06

# === INTERNAL ===
var chunks : Dictionary = {}
var ground_chunks : Dictionary = {}
var noise : FastNoiseLite
var pond_noise : FastNoiseLite
var last_player_chunk : Vector2i = Vector2i(-999, -999)  # Track vị trí chunk trước
var chunk_queue: Array[Vector2i] = []
var is_generating := false

# Ground tiles
var ground_tiles = [Vector2i(1,5), Vector2i(2,5), Vector2i(1,6), Vector2i(2,6)]

func _ready():
	setup_noise()
	# Gen ngay lập tức khi start
	call_deferred("generate_initial_chunks")

func setup_noise():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 28042004
	noise.frequency = 0.05
	
	pond_noise = FastNoiseLite.new()
	pond_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	pond_noise.seed = 20042804
	pond_noise.frequency = 0.03

func _physics_process(_delta):
	if not player:
		return

	var current_chunk = get_chunk_position(player.global_position)
	if current_chunk != last_player_chunk:
		last_player_chunk = current_chunk
		update_chunks()

func generate_initial_chunks():
	if not player:
		return
	
	var player_chunk = get_chunk_position(player.global_position)
	last_player_chunk = player_chunk

	# DEBUG
	print("Player chunk: ", player_chunk)
	print("Active obstacle chunks: ", chunks.keys().size())
	print("Active ground chunks: ", ground_chunks.keys().size())
	
	# Gen với bán kính lớn hơn để đảm bảo đầy đủ
	var initial_distance = view_distance + preload_distance
	
	for x in range(-initial_distance, initial_distance + 1):
		for y in range(-initial_distance, initial_distance + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			generate_ground_chunk(chunk_pos)
			generate_chunk(chunk_pos)

func process_chunk_queue():
	is_generating = true

	if chunk_queue.is_empty():
		is_generating = false
		return

	var chunk_pos = chunk_queue.pop_front()

	if not ground_chunks.has(chunk_pos):
		generate_ground_chunk(chunk_pos)

	if not chunks.has(chunk_pos):
		generate_chunk(chunk_pos)

	call_deferred("process_chunk_queue")

func update_chunks():
	var player_chunk = get_chunk_position(player.global_position)
	var total_distance = view_distance + preload_distance

	for x in range(-total_distance, total_distance + 1):
		for y in range(-total_distance, total_distance + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not chunks.has(chunk_pos):
				chunk_queue.append(chunk_pos)

	if not is_generating:
		process_chunk_queue()
	
	# Xóa chunks xa (xa hơn total_distance + buffer)
	var remove_distance = total_distance + 2
	
	var to_remove = []
	for chunk_pos in chunks.keys():
		if player_chunk.distance_to(chunk_pos) > remove_distance:
			to_remove.append(chunk_pos)
	
	for chunk_pos in to_remove:
		chunks[chunk_pos].queue_free()
		chunks.erase(chunk_pos)
	
	var ground_to_remove = []
	for chunk_pos in ground_chunks.keys():
		if player_chunk.distance_to(chunk_pos) > remove_distance:
			ground_to_remove.append(chunk_pos)
	
	for chunk_pos in ground_to_remove:
		clear_ground_chunk(chunk_pos)
		ground_chunks.erase(chunk_pos)

func get_chunk_position(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / chunk_size),
		floori(world_pos.y / chunk_size)
	)

# === GROUND GENERATION ===
func generate_ground_chunk(chunk_pos: Vector2i):
	if ground_chunks.has(chunk_pos) or not ground_layer:
		return
	
	var tile_size = 32
	var tiles_per_chunk = chunk_size / tile_size
	
	var start_x = chunk_pos.x * tiles_per_chunk
	var start_y = chunk_pos.y * tiles_per_chunk
	
	for x in range(tiles_per_chunk):
		for y in range(tiles_per_chunk):
			var tile_x = start_x + x
			var tile_y = start_y + y
			
			var idx = (abs(tile_x) % 2) * 2 + (abs(tile_y) % 2)
			ground_layer.set_cell(Vector2i(tile_x, tile_y), 0, ground_tiles[idx])
	
	ground_chunks[chunk_pos] = true

func clear_ground_chunk(chunk_pos: Vector2i):
	if not ground_layer:
		return
	
	var tile_size = 32
	var tiles_per_chunk = chunk_size / tile_size
	
	var start_x = chunk_pos.x * tiles_per_chunk
	var start_y = chunk_pos.y * tiles_per_chunk
	
	for x in range(tiles_per_chunk):
		for y in range(tiles_per_chunk):
			ground_layer.erase_cell(Vector2i(start_x + x, start_y + y))

# === OBSTACLE GENERATION ===
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
	var grid_size = 64  # Tăng từ 32 → 64 để giảm số obstacles, tăng performance
	var spawns_per_chunk = chunk_size / grid_size
	
	for x in range(spawns_per_chunk):
		for y in range(spawns_per_chunk):
			var world_x = chunk_pos.x * chunk_size / grid_size + x
			var world_y = chunk_pos.y * chunk_size / grid_size + y
			
			var terrain_noise = noise.get_noise_2d(world_x, world_y)
			var water_noise = pond_noise.get_noise_2d(world_x, world_y)
			
			var local_pos = Vector2(x * grid_size + grid_size/2, y * grid_size + grid_size/2)
			
			seed(hash(Vector2i(world_x, world_y)))
			
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

