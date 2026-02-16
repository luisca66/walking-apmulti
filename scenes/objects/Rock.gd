extends StaticBody3D

@export var rock_height: float = 4.0
@export var rock_radius: float = 3.0
@export var scale_variation: float = 0.4

func _ready():
	collision_layer = 1
	collision_mask = 0

	var s = 1.0 + randf_range(-scale_variation, scale_variation)
	var h = rock_height * s
	var r = rock_radius * s

	rotation.y = randf() * TAU

	_build_rocks(h, r)
	_build_collision(h, r)

func _build_rocks(height: float, radius: float):
	# Cada roca es una esfera deformada (scale no uniforme) apilada
	var configs = [
		# [posición_y, radio, scale_x, scale_y, scale_z]
		[radius * 0.3, radius, 1.0, 0.6, 1.1],                      # Base: ancha y achatada
		[height * 0.4, radius * 0.75, 0.85, 0.8, 0.9],              # Media: más estrecha
		[height * 0.7, radius * 0.5, 0.7, 0.9, 0.65],               # Cima: puntiaguda
		[height * 0.2, radius * 0.5, 1.1, 0.5, 0.7],                # Detalle lateral 1
		[height * 0.15, radius * 0.4, 0.8, 0.55, 1.0]               # Detalle lateral 2
	]

	var offsets_xz = [
		Vector2(0, 0),                                                # Base centrada
		Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)),     # Media ligeramente desplazada
		Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)),     # Cima más desplazada
		Vector2(radius * 0.5, radius * 0.3),                         # Detalle a un lado
		Vector2(-radius * 0.4, radius * 0.4)                         # Detalle al otro lado
	]

	for i in range(5):
		var cfg = configs[i]

		var node = MeshInstance3D.new()
		node.name = ["Base", "Mid", "Top", "Detail1", "Detail2"][i]

		var sphere = SphereMesh.new()
		sphere.radius = cfg[1]
		sphere.height = cfg[1] * 2.0
		sphere.radial_segments = 10
		sphere.rings = 6
		node.mesh = sphere

		node.position = Vector3(offsets_xz[i].x, cfg[0], offsets_xz[i].y)
		node.scale = Vector3(cfg[2], cfg[3], cfg[4])

		# Material de piedra con variación por pieza
		var mat = StandardMaterial3D.new()
		var base_shade = randf_range(0.3, 0.5)
		var warm = randf_range(-0.03, 0.05)  # Ligera variación cálida/fría
		mat.albedo_color = Color(
			base_shade + warm + randf_range(-0.03, 0.03),
			base_shade + randf_range(-0.03, 0.03),
			base_shade - warm + randf_range(-0.03, 0.03)
		)
		mat.roughness = randf_range(0.85, 0.98)
		mat.metallic = 0.0
		node.set_surface_override_material(0, mat)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(node)

func _build_collision(height: float, radius: float):
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	# Usar una cápsula grande que cubra toda la formación
	var capsule = CapsuleShape3D.new()
	capsule.radius = radius * 0.8
	capsule.height = height * 0.9
	col.shape = capsule
	col.position.y = height * 0.35
	add_child(col)
