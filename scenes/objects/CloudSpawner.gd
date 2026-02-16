extends Node3D

@export var cloud_count: int = 12
var cloud_scene: PackedScene = preload("res://scenes/objects/Cloud.tscn")

func spawn_clouds():
	var arena_size = GameManager.ARENA_SIZE
	var spread = arena_size * 0.8

	for i in range(cloud_count):
		var cloud = cloud_scene.instantiate()

		# Posición aleatoria en el cielo
		var x = randf_range(-spread, spread)
		var z = randf_range(-spread, spread)
		# Altura variada: entre 25 y 45 metros (bien arriba de los muros)
		var y = randf_range(25.0, 45.0)

		cloud.position = Vector3(x, y, z)
		add_child(cloud)

	print("Nubes spawneadas: ", cloud_count)
