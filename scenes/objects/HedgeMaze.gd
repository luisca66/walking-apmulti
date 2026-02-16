extends Node3D

var hedge_height: float = 1.5  # Era 4.0, ahora un tercio
var hedge_thickness: float = 1.5
var maze_size: float = 50.0  # El laberinto ocupa 50x50 metros

func _ready():
	_build_maze()
	print("Laberinto de setos construido en posición: ", global_position)

func _get_hedge_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	var green = randf_range(0.15, 0.25)
	mat.albedo_color = Color(green * 0.6, green + randf_range(-0.02, 0.02), green * 0.4)
	mat.roughness = 0.95
	mat.metallic = 0.0
	return mat

func _add_hedge_wall(pos: Vector3, size: Vector3):
	var body = StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	# Visual: caja con borde redondeado simulado usando múltiples meshes
	# Cuerpo principal del seto
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.set_surface_override_material(0, _get_hedge_material())
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh)

	# Tope redondeado: cilindro horizontal a lo largo del seto
	var top = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	# Determinar orientación: si el seto es más largo en X, el cilindro va en X
	if size.x > size.z:
		cyl.height = size.x
		cyl.top_radius = hedge_thickness / 2.0
		cyl.bottom_radius = hedge_thickness / 2.0
		cyl.radial_segments = 8
		top.mesh = cyl
		top.rotation.z = PI / 2.0  # Cilindro horizontal en X
	else:
		cyl.height = size.z
		cyl.top_radius = hedge_thickness / 2.0
		cyl.bottom_radius = hedge_thickness / 2.0
		cyl.radial_segments = 8
		top.mesh = cyl
		top.rotation.x = PI / 2.0  # Cilindro horizontal en Z
	top.position.y = size.y / 2.0
	top.set_surface_override_material(0, _get_hedge_material())
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(top)

	# Colisión
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(size.x, size.y + hedge_thickness * 0.5, size.z)
	col.shape = shape
	col.position.y = hedge_thickness * 0.15
	body.add_child(col)

func _build_maze():
	var h = hedge_height
	var t = hedge_thickness
	var half = maze_size / 2.0
	var cell = 8.0  # Tamaño de cada celda del laberinto
	var passage = 3.5  # Ancho del pasillo (Glub mide ~2m de ancho)

	# --- PERÍMETRO del laberinto con entrada y salida ---

	# Pared norte — con hueco de entrada a la derecha
	_add_hedge_wall(Vector3(-cell, h / 2.0, -half), Vector3(maze_size - cell * 2.0, h, t))

	# Pared sur — con hueco de salida a la izquierda
	_add_hedge_wall(Vector3(cell, h / 2.0, half), Vector3(maze_size - cell * 2.0, h, t))

	# Pared este — completa
	_add_hedge_wall(Vector3(half, h / 2.0, 0), Vector3(t, h, maze_size))

	# Pared oeste — completa
	_add_hedge_wall(Vector3(-half, h / 2.0, 0), Vector3(t, h, maze_size))

	# --- MUROS INTERNOS del laberinto ---
	# Diseño de laberinto fijo que crea caminos sinuosos
	# El laberinto tiene ~6x6 celdas de 8m cada una

	# Fila 1 (desde el norte): muros horizontales
	_add_hedge_wall(Vector3(-10, h / 2.0, -17), Vector3(16.0, h, t))
	_add_hedge_wall(Vector3(14, h / 2.0, -17), Vector3(12.0, h, t))

	# Fila 1: muros verticales
	_add_hedge_wall(Vector3(-17, h / 2.0, -13), Vector3(t, h, 10.0))
	_add_hedge_wall(Vector3(6, h / 2.0, -15), Vector3(t, h, 14.0))

	# Fila 2: muros horizontales
	_add_hedge_wall(Vector3(-6, h / 2.0, -9), Vector3(20.0, h, t))
	_add_hedge_wall(Vector3(17, h / 2.0, -9), Vector3(6.0, h, t))

	# Fila 2: muros verticales
	_add_hedge_wall(Vector3(-10, h / 2.0, -5), Vector3(t, h, 10.0))
	_add_hedge_wall(Vector3(14, h / 2.0, -3), Vector3(t, h, 14.0))

	# Fila 3: muros horizontales (centro)
	_add_hedge_wall(Vector3(-17, h / 2.0, -1), Vector3(12.0, h, t))
	_add_hedge_wall(Vector3(4, h / 2.0, -1), Vector3(16.0, h, t))

	# Fila 3: muros verticales
	_add_hedge_wall(Vector3(-4, h / 2.0, 3), Vector3(t, h, 10.0))
	_add_hedge_wall(Vector3(20, h / 2.0, 3), Vector3(t, h, 10.0))

	# Fila 4: muros horizontales
	_add_hedge_wall(Vector3(-14, h / 2.0, 7), Vector3(16.0, h, t))
	_add_hedge_wall(Vector3(8, h / 2.0, 7), Vector3(10.0, h, t))

	# Fila 4: muros verticales
	_add_hedge_wall(Vector3(-20, h / 2.0, 11), Vector3(t, h, 10.0))
	_add_hedge_wall(Vector3(0, h / 2.0, 13), Vector3(t, h, 14.0))

	# Fila 5: muros horizontales
	_add_hedge_wall(Vector3(-8, h / 2.0, 15), Vector3(20.0, h, t))
	_add_hedge_wall(Vector3(16, h / 2.0, 15), Vector3(8.0, h, t))

	# Fila 5: muros verticales
	_add_hedge_wall(Vector3(10, h / 2.0, 19), Vector3(t, h, 10.0))
	_add_hedge_wall(Vector3(-14, h / 2.0, 19), Vector3(t, h, 8.0))

	# Algunos muros cortos adicionales para crear callejones sin salida
	_add_hedge_wall(Vector3(-20, h / 2.0, -5), Vector3(6.0, h, t))
	_add_hedge_wall(Vector3(20, h / 2.0, -5), Vector3(6.0, h, t))
	_add_hedge_wall(Vector3(-8, h / 2.0, 21), Vector3(t, h, 6.0))
	_add_hedge_wall(Vector3(6, h / 2.0, 11), Vector3(t, h, 6.0))
