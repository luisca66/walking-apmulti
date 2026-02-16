extends Node3D

# Variables exportadas
@export var cube_count: int = 20
@export var min_distance_from_center: float = 15.0

# Variables internas
var note_cube_scene: PackedScene = preload("res://scenes/objects/NoteCube.tscn")
var spawned_cubes: Array[Area3D] = []


func spawn_cubes() -> void:
	var spawn_area = GameManager.ARENA_SIZE - 30.0  # Margen de 15 metros por lado

	# Limpiar cubos anteriores
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	spawned_cubes.clear()

	var placed = 0
	var max_attempts = 2000  # Más intentos por el área más grande
	var attempts = 0
	var min_distance_between_cubes = 25.0  # Separación entre cubos aumentada para forzar más caminata

	# Elegir UN color aleatorio para todos los cubos de esta ronda
	var cube_color = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))

	while placed < 20 and attempts < max_attempts:
		attempts += 1
		if GameManager.selected_notes.is_empty():
			print("No selected notes")
			return

		var note_data = GameManager.selected_notes[randi() % GameManager.selected_notes.size()]
		var x = randf_range(-spawn_area / 2.0, spawn_area / 2.0)
		var z = randf_range(-spawn_area / 2.0, spawn_area / 2.0)

		if abs(x) < min_distance_from_center and abs(z) < min_distance_from_center:
			continue

		# No spawnear dentro del torreón central del castillo
		var keep_center = Vector3(0, 0, -40)
		if abs(x - keep_center.x) < 7.0 and abs(z - keep_center.z) < 7.0:
			continue

		var too_close = false
		var candidate_pos = Vector3(x, 1.5, z)
		for existing_cube in spawned_cubes:
			if candidate_pos.distance_to(existing_cube.position) < min_distance_between_cubes:
				too_close = true
				break
		if too_close:
			continue

		# --- Verificar que no esté encima de un árbol ---
		var tree_spawner = get_parent().get_node_or_null("TreeSpawner")
		if tree_spawner and "spawned_trees" in tree_spawner:
			var near_tree = false
			for tree in tree_spawner.spawned_trees:
				if is_instance_valid(tree):
					if candidate_pos.distance_to(tree.position) < 8.0:
						near_tree = true
						break
			if near_tree:
				continue

		# --- Verificar que no esté encima de una roca ---
		var rock_spawner = get_parent().get_node_or_null("RockSpawner")
		if rock_spawner and "spawned_rocks" in rock_spawner:
			var near_rock = false
			for rock in rock_spawner.spawned_rocks:
				if is_instance_valid(rock):
					if candidate_pos.distance_to(rock.position) < 6.0:
						near_rock = true
						break
			if near_rock:
				continue

		var cube = note_cube_scene.instantiate()
		cube.position = candidate_pos
		cube.note_index = note_data["note_index"]
		cube.octave = note_data["octave"]
		cube.override_color = cube_color
		cube.note_triggered.connect(_on_note_triggered)
		add_child(cube)
		spawned_cubes.append(cube)
		placed += 1

	print("Cubos colocados: ", placed, " en ", attempts, " intentos")


func _on_note_triggered(note_index: int, octave: int, cube: Area3D) -> void:
	pass


func reset_all_cubes() -> void:
	spawn_cubes()


func get_cube_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			positions.append(cube.position)
	return positions
