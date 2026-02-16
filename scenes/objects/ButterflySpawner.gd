extends Node3D

@export var butterfly_count: int = 15
var butterfly_scene: PackedScene = preload("res://scenes/objects/Butterfly.tscn")

func spawn_butterflies():
	var arena_size = GameManager.ARENA_SIZE
	var spawn_area = arena_size - 30.0

	for i in range(butterfly_count):
		var butterfly = butterfly_scene.instantiate()

		# Posición inicial aleatoria
		var x = randf_range(-spawn_area / 2.0, spawn_area / 2.0)
		var z = randf_range(-spawn_area / 2.0, spawn_area / 2.0)
		var y = randf_range(2.0, 6.0)

		butterfly.position = Vector3(x, y, z)

		# Centro de vuelo cerca de donde aparece
		butterfly.fly_center = Vector3(
			x + randf_range(-10, 10),
			0,
			z + randf_range(-10, 10)
		)

		add_child(butterfly)

	print("Mariposas spawneadas: ", butterfly_count)
