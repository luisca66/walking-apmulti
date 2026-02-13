extends Node3D

var stone_texture: ImageTexture
var wood_texture: ImageTexture

func _ready():
	# Generar texturas procedurales
	stone_texture = TextureGenerator.generate_stone_wall()
	wood_texture = TextureGenerator.generate_wood_door()
	print("Procedural textures generated")

# Crear un muro con textura de piedra
func _create_wall(position: Vector3, size: Vector3) -> StaticBody3D:
	var wall = StaticBody3D.new()
	wall.position = position

	# Mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	# Material con textura de piedra
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = stone_texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(size.x / 4.0, size.y / 4.0, 1.0)
	mat.roughness = 0.8

	mesh_instance.set_surface_override_material(0, mat)
	wall.add_child(mesh_instance)

	# Colisión
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)

	return wall

# Crear una puerta con textura de madera
func _create_door(position: Vector3, size: Vector3 = Vector3(2.0, 3.0, 0.2)) -> StaticBody3D:
	var door = StaticBody3D.new()
	door.position = position

	# Mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	# Material con textura de madera
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = wood_texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)  # La textura ya tiene el tamaño correcto
	mat.roughness = 0.7

	mesh_instance.set_surface_override_material(0, mat)
	door.add_child(mesh_instance)

	# Colisión
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	door.add_child(collision)

	return door

# Ejemplo de uso: crear un recinto simple
func create_simple_arena():
	# Muro norte
	var wall_n = _create_wall(Vector3(0, 2, -20), Vector3(40, 4, 0.5))
	add_child(wall_n)

	# Muro sur
	var wall_s = _create_wall(Vector3(0, 2, 20), Vector3(40, 4, 0.5))
	add_child(wall_s)

	# Muro este
	var wall_e = _create_wall(Vector3(20, 2, 0), Vector3(0.5, 4, 40))
	add_child(wall_e)

	# Muro oeste
	var wall_w = _create_wall(Vector3(-20, 2, 0), Vector3(0.5, 4, 40))
	add_child(wall_w)

	# Puerta en el muro sur
	var door = _create_door(Vector3(0, 1.5, 20))
	add_child(door)
