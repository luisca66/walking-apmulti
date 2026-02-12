extends Node3D

# Variables exportadas
@export var cube_count: int = 20
@export var area_size: float = 250.0
@export var min_distance_from_center: float = 30.0
@export var min_distance_between_cubes: float = 25.0

# Variables internas
var note_cube_scene: PackedScene = preload("res://scenes/objects/NoteCube.tscn")
var spawned_cubes: Array[Area3D] = []


func is_too_close_to_other_cubes(new_pos: Vector3) -> bool:
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			var distance = new_pos.distance_to(cube.position)
			if distance < min_distance_between_cubes:
				return true
	return false


func spawn_cubes() -> void:
	# Limpiar cubos anteriores
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	spawned_cubes.clear()

	var placed = 0
	var max_attempts = 500  # safety limit (increased due to spacing constraints)
	var attempts = 0

	while placed < cube_count and attempts < max_attempts:
		attempts += 1
		if GameManager.selected_notes.is_empty():
			print("No selected notes")
			return

		# Seleccionar nota aleatoria de las seleccionadas
		var note_data = GameManager.selected_notes[randi() % GameManager.selected_notes.size()]

		# Generar posición aleatoria
		var x = randf_range(-area_size / 2.0, area_size / 2.0)
		var z = randf_range(-area_size / 2.0, area_size / 2.0)

		# Excluir zona central donde está el jugador
		if abs(x) < min_distance_from_center and abs(z) < min_distance_from_center:
			continue

		var new_position = Vector3(x, 1.5, z)

		# Verificar distancia mínima con otros cubos
		if is_too_close_to_other_cubes(new_position):
			continue

		# Instanciar y configurar el cubo
		var cube = note_cube_scene.instantiate()
		cube.position = new_position
		cube.note_index = note_data["note_index"]
		cube.octave = note_data["octave"]
		add_child(cube)
		spawned_cubes.append(cube)
		placed += 1


func reset_all_cubes() -> void:
	spawn_cubes()
