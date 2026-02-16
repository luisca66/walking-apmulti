extends Node3D

@export var rock_count: int = 52  # Era 40
var rock_scene: PackedScene = preload("res://scenes/objects/Rock.tscn")
var spawned_rocks: Array = []

func spawn_rocks():
	for rock in spawned_rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	spawned_rocks.clear()

	var arena_size = GameManager.ARENA_SIZE
	var spawn_area = arena_size - 20.0
	var min_dist_from_center = 12.0
	var min_dist_between_rocks = 14.0
	var min_dist_from_trees = 8.0  # No encimar con árboles

	# Obtener posiciones de árboles si existen
	var tree_positions: Array[Vector3] = []
	var tree_spawner = get_parent().get_node_or_null("TreeSpawner")
	if tree_spawner and tree_spawner.has_method("get") and "spawned_trees" in tree_spawner:
		for tree in tree_spawner.spawned_trees:
			if is_instance_valid(tree):
				tree_positions.append(tree.position)

	var placed = 0
	var max_attempts = 2000
	var attempts = 0

	while placed < rock_count and attempts < max_attempts:
		attempts += 1

		var x = randf_range(-spawn_area / 2.0, spawn_area / 2.0)
		var z = randf_range(-spawn_area / 2.0, spawn_area / 2.0)

		if abs(x) < min_dist_from_center and abs(z) < min_dist_from_center:
			continue

		# No spawnear dentro del castillo
		if x > -24.0 and x < 24.0 and z > -64.0 and z < -16.0:
			continue

		# No spawnear dentro del laberinto
		if x > 32.0 and x < 88.0 and z > 22.0 and z < 78.0:
			continue

		# No cerca de la puerta
		if abs(x) < 5.0 and z < -(spawn_area / 2.0 - 10.0):
			continue

		var candidate_pos = Vector3(x, 0, z)

		# Distancia mínima entre rocas
		var too_close = false
		for existing in spawned_rocks:
			if candidate_pos.distance_to(existing.position) < min_dist_between_rocks:
				too_close = true
				break
		if too_close:
			continue

		# Distancia mínima de árboles
		for tree_pos in tree_positions:
			if candidate_pos.distance_to(tree_pos) < min_dist_from_trees:
				too_close = true
				break
		if too_close:
			continue

		var rock = rock_scene.instantiate()
		rock.position = candidate_pos
		add_child(rock)
		spawned_rocks.append(rock)
		placed += 1

	print("Rocas colocadas: ", placed)
