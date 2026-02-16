extends Node3D

var stone_texture: ImageTexture
var wood_texture: ImageTexture
var left_door: Node3D = null
var right_door: Node3D = null
var gate_position: Vector3 = Vector3.ZERO
var is_gate_open: bool = false

func _ready():
	# Generar texturas procedurales
	stone_texture = TextureGenerator.generate_stone_wall()
	wood_texture = TextureGenerator.generate_wood_door()
	print("Procedural textures generated")

	var size = GameManager.ARENA_SIZE
	var half = size / 2.0
	var h = GameManager.WALL_HEIGHT
	var t = GameManager.WALL_THICKNESS
	var gate_width = 5.0  # Ancho del hueco de la puerta

	# Pared Sur (Z positivo) — pared completa
	_create_wall(Vector3(0, h / 2.0, half), Vector3(size, h, t))

	# Pared Este (X positivo) — pared completa
	_create_wall(Vector3(half, h / 2.0, 0), Vector3(t, h, size))

	# Pared Oeste (X negativo) — pared completa
	_create_wall(Vector3(-half, h / 2.0, 0), Vector3(t, h, size))

	# Pared Norte (Z negativo) — DOS segmentos con hueco en el centro para la puerta
	var segment_width = (size - gate_width) / 2.0
	# Segmento izquierdo
	_create_wall(
		Vector3(-(segment_width / 2.0 + gate_width / 2.0), h / 2.0, -half),
		Vector3(segment_width, h, t)
	)
	# Segmento derecho
	_create_wall(
		Vector3((segment_width / 2.0 + gate_width / 2.0), h / 2.0, -half),
		Vector3(segment_width, h, t)
	)

	# Guardar posición de la puerta
	gate_position = Vector3(0, 0, -half)

	# Crear dos hojas de puerta separadas
	var door_panel_width = gate_width / 2.0 - 0.3
	left_door = _create_door_panel(Vector3(-gate_width / 4.0, h / 2.0, -half), Vector3(door_panel_width, h, t * 0.8))
	right_door = _create_door_panel(Vector3(gate_width / 4.0, h / 2.0, -half), Vector3(door_panel_width, h, t * 0.8))


func _create_wall(pos: Vector3, wall_size: Vector3):
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)

	# Visual
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = wall_size
	mesh_inst.mesh = box_mesh

	# Material con textura de piedra procedural
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = stone_texture
	mat.albedo_color = Color.WHITE
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	# Calcular UV scale correctamente según la orientación del muro
	# La cara visible más grande determina el tiling
	var face_width = max(wall_size.x, wall_size.z)  # La dimensión horizontal del muro
	var face_height = wall_size.y                    # Siempre la altura
	var tile_size = 4.0                              # Repetir textura cada 4 metros
	mat.uv1_scale = Vector3(face_width / tile_size, face_height / tile_size, 1.0)
	mat.roughness = 0.9

	mesh_inst.set_surface_override_material(0, mat)
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh_inst)

	# Colision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = wall_size
	col.shape = shape
	body.add_child(col)


func _create_door_panel(pos: Vector3, door_size: Vector3) -> Node3D:
	var body = StaticBody3D.new()
	body.position = pos
	add_child(body)

	# Visual
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = door_size
	mesh_inst.mesh = box_mesh

	# Material con textura de madera procedural
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = wood_texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.roughness = 0.7

	mesh_inst.set_surface_override_material(0, mat)
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh_inst)

	# Colision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = door_size
	col.shape = shape
	body.add_child(col)

	return body

func open_gate():
	if is_gate_open:
		return
	is_gate_open = true

	if left_door:
		var tween_l = create_tween()
		tween_l.tween_property(left_door, "rotation:y", -1.3, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if right_door:
		var tween_r = create_tween()
		tween_r.tween_property(right_door, "rotation:y", 1.3, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
