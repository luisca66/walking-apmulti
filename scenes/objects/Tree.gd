extends StaticBody3D

# Parámetros exportados para variedad
@export var trunk_height: float = 5.0       # Más alto
@export var trunk_radius: float = 0.5       # Más grueso
@export var canopy_radius: float = 4.5      # Copa más grande
@export var tree_scale_variation: float = 0.3  # ±30% variación de tamaño

func _ready():
	# Configurar capas de colisión
	collision_layer = 1  # Bit 1 - para que el CharacterBody3D del jugador choque
	collision_mask = 0   # El árbol no necesita detectar nada

	# Variación aleatoria para que cada árbol sea único
	var scale_factor = 1.0 + randf_range(-tree_scale_variation, tree_scale_variation)
	var t_height = trunk_height * scale_factor
	var t_radius = trunk_radius * scale_factor
	var c_radius = canopy_radius * scale_factor

	# Rotación aleatoria en Y para variedad visual
	rotation.y = randf() * TAU

	_build_trunk(t_height, t_radius)
	_build_canopy(t_height, c_radius, scale_factor)
	_build_collision(t_height, t_radius, c_radius)

func _build_trunk(height: float, radius: float):
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius * 0.7  # Más delgado arriba
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	trunk.mesh = mesh
	trunk.position.y = height / 2.0

	# Material del tronco — corteza marrón oscura con variación
	var mat = StandardMaterial3D.new()
	var bark_base = randf_range(0.15, 0.25)
	mat.albedo_color = Color(bark_base + 0.1, bark_base + 0.04, bark_base)
	mat.roughness = 0.95
	trunk.set_surface_override_material(0, mat)
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(trunk)

func _build_canopy(trunk_height: float, radius: float, scale_factor: float):
	# Cinco esferas superpuestas para copa más densa y voluminosa
	var positions = [
		Vector3(0, trunk_height + radius * 0.5, 0),                          # Centro arriba
		Vector3(radius * 0.4, trunk_height + radius * 0.1, radius * 0.3),    # Derecha-adelante bajo
		Vector3(-radius * 0.35, trunk_height + radius * 0.25, -radius * 0.3),# Izquierda-atrás medio
		Vector3(radius * 0.15, trunk_height + radius * 0.7, -radius * 0.15), # Arriba-atrás
		Vector3(-radius * 0.2, trunk_height + radius * 0.0, radius * 0.35)   # Izquierda-adelante bajo
	]

	var radii = [
		radius,              # Principal
		radius * 0.85,       # Grande
		radius * 0.75,       # Mediana
		radius * 0.7,        # Superior
		radius * 0.8         # Frontal
	]

	for i in range(5):
		var node = MeshInstance3D.new()
		node.name = "Canopy%d" % (i + 1)
		var sphere = SphereMesh.new()
		sphere.radius = radii[i]
		sphere.height = radii[i] * 1.8  # Más alta para más volumen
		sphere.radial_segments = 12
		sphere.rings = 8
		node.mesh = sphere
		node.position = positions[i]

		# Material de hojas — variaciones de verde por esfera
		var mat = StandardMaterial3D.new()
		var green_variation = randf_range(-0.05, 0.05)
		var base_green = randf_range(0.28, 0.45)
		mat.albedo_color = Color(
			0.08 + green_variation,
			base_green + green_variation,
			0.06 + green_variation * 0.5
		)
		mat.roughness = 0.9
		mat.metallic = 0.0
		node.set_surface_override_material(0, mat)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(node)

func _build_collision(trunk_height: float, trunk_radius: float, canopy_radius: float):
	# Colisión del tronco — cilindro simplificado como cápsula
	var col_trunk = CollisionShape3D.new()
	col_trunk.name = "CollisionTrunk"
	var capsule = CapsuleShape3D.new()
	capsule.radius = trunk_radius + 0.15  # Ajustado para tronco más grueso
	capsule.height = trunk_height + 0.5
	col_trunk.shape = capsule
	col_trunk.position.y = trunk_height / 2.0
	add_child(col_trunk)

	# Colisión de la copa — esfera grande simplificada
	var col_canopy = CollisionShape3D.new()
	col_canopy.name = "CollisionCanopy"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = canopy_radius * 0.7  # Ajustado para copa más grande
	col_canopy.shape = sphere_shape
	col_canopy.position.y = trunk_height + canopy_radius * 0.35
	add_child(col_canopy)
