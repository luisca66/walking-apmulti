extends Node3D

@export var tree_count: int = 90  # Era 70
var tree_scene: PackedScene = preload("res://scenes/objects/Tree.tscn")
var spawned_trees: Array = []

func spawn_trees():
	# Limpiar anteriores
	for tree in spawned_trees:
		if is_instance_valid(tree):
			tree.queue_free()
	spawned_trees.clear()

	var arena_size = GameManager.ARENA_SIZE
	var spawn_area = arena_size - 20.0  # Margen de 10m por lado (lejos de muros)
	var min_dist_from_center = 10.0      # Espacio libre para el jugador al inicio
	var min_dist_between_trees = 14.0    # Ligeramente más separados
	var min_dist_from_cubes = 6.0        # No tapar completamente los cubos

	var placed = 0
	var max_attempts = 2000              # Aumentado para área más grande
	var attempts = 0

	while placed < tree_count and attempts < max_attempts:
		attempts += 1

		var x = randf_range(-spawn_area / 2.0, spawn_area / 2.0)
		var z = randf_range(-spawn_area / 2.0, spawn_area / 2.0)

		# No muy cerca del centro (spawn del jugador)
		if abs(x) < min_dist_from_center and abs(z) < min_dist_from_center:
			continue

		# No spawnear dentro del castillo
		if x > -24.0 and x < 24.0 and z > -64.0 and z < -16.0:
			continue

		# No spawnear dentro del laberinto
		if x > 32.0 and x < 88.0 and z > 22.0 and z < 78.0:
			continue

		# No muy cerca de la puerta (pared norte centro)
		if abs(x) < 5.0 and z < -(spawn_area / 2.0 - 10.0):
			continue

		var candidate_pos = Vector3(x, 0, z)

		# Distancia mínima entre árboles
		var too_close = false
		for existing in spawned_trees:
			if candidate_pos.distance_to(existing.position) < min_dist_between_trees:
				too_close = true
				break
		if too_close:
			continue

		# Verificar distancia a cubos de notas (si ya fueron spawneados)
		var note_spawner = get_node_or_null("../NoteSpawner")
		if note_spawner and note_spawner.has_method("get_cube_positions"):
			var cube_positions = note_spawner.get_cube_positions()
			for cube_pos in cube_positions:
				if candidate_pos.distance_to(cube_pos) < min_dist_from_cubes:
					too_close = true
					break
		if too_close:
			continue

		var tree = tree_scene.instantiate()
		tree.position = candidate_pos
		add_child(tree)
		spawned_trees.append(tree)
		placed += 1

	print("Árboles colocados: ", placed)
