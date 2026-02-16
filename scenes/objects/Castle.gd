extends Node3D

# Dimensiones del castillo — proporciones del HTML de referencia
# En el HTML: size=20, entonces el castillo es 40x40 (±20)
# Para nuestro juego: castle_half = 20, castillo de 40x40m
var castle_half: float = 20.0
var wall_height: float = 6.0
var wall_depth: float = 2.0
var tower_radius: float = 3.0
var tower_height: float = 10.0
var gate_width: float = 6.0
var gate_height: float = 5.0
var keep_size: Vector3 = Vector3(10, 15, 10)

var stone_texture: ImageTexture = null

func _ready():
	if TextureGenerator:
		stone_texture = TextureGenerator.generate_stone_wall()
	_build_all()

func _get_stone_mat(uv_x: float, uv_y: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if stone_texture:
		mat.albedo_texture = stone_texture
		mat.albedo_color = Color.WHITE
		mat.uv1_scale = Vector3(uv_x, uv_y, 1.0)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		mat.albedo_color = Color(0.45, 0.45, 0.45)
	mat.roughness = 0.9
	return mat

func _build_all():
	_build_towers()
	_build_walls()
	_build_keep()
	print("Castillo construido en posición: ", global_position)

func _add_box_wall(pos: Vector3, size: Vector3):
	var body = StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var face_w = max(size.x, size.z)
	mesh.set_surface_override_material(0, _get_stone_mat(face_w / 4.0, size.y / 4.0))
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func _build_towers():
	var h = castle_half
	var corners = [
		Vector3(h, 0, h),
		Vector3(-h, 0, h),
		Vector3(h, 0, -h),
		Vector3(-h, 0, -h)
	]
	for corner in corners:
		# Torre cilíndrica
		var body = StaticBody3D.new()
		body.position = Vector3(corner.x, tower_height / 2.0, corner.z)
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)

		var mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = tower_radius
		cyl.bottom_radius = tower_radius
		cyl.height = tower_height
		cyl.radial_segments = 16
		mesh.mesh = cyl
		mesh.set_surface_override_material(0, _get_stone_mat(3.0, 2.0))
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		body.add_child(mesh)

		var col = CollisionShape3D.new()
		var cyl_shape = CylinderShape3D.new()
		cyl_shape.radius = tower_radius
		cyl_shape.height = tower_height
		col.shape = cyl_shape
		body.add_child(col)

		# Techo cónico
		var roof = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.1
		cone.bottom_radius = tower_radius + 1.0
		cone.height = 4.0
		cone.radial_segments = 16
		roof.mesh = cone
		roof.position = Vector3(corner.x, tower_height + 2.0, corner.z)
		var roof_mat = StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.35, 0.18, 0.12)
		roof_mat.roughness = 0.85
		roof.set_surface_override_material(0, roof_mat)
		roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(roof)

func _build_walls():
	var h = castle_half
	var wh = wall_height
	var wd = wall_depth

	# Muro trasero — completo
	_add_box_wall(Vector3(0, wh / 2.0, -h), Vector3(h * 2.0, wh, wd))

	# Muro derecho — completo
	_add_box_wall(Vector3(h, wh / 2.0, 0), Vector3(wd, wh, h * 2.0))

	# Muro izquierdo — completo
	_add_box_wall(Vector3(-h, wh / 2.0, 0), Vector3(wd, wh, h * 2.0))

	# Muro frontal — dos segmentos con hueco para puerta
	var seg_w = (h * 2.0 - gate_width) / 2.0
	_add_box_wall(
		Vector3(-(seg_w / 2.0 + gate_width / 2.0), wh / 2.0, h),
		Vector3(seg_w, wh, wd)
	)
	_add_box_wall(
		Vector3((seg_w / 2.0 + gate_width / 2.0), wh / 2.0, h),
		Vector3(seg_w, wh, wd)
	)

	# Dintel sobre la puerta
	var lintel_h = wh - gate_height
	if lintel_h > 0:
		_add_box_wall(
			Vector3(0, gate_height + lintel_h / 2.0, h),
			Vector3(gate_width + 0.5, lintel_h, wd + 0.1)
		)

	# Almenas en los 4 muros
	_add_battlements_line(Vector3(-h, wh, 0), Vector3(h, wh, 0), -h)  # Trasero
	_add_battlements_line(Vector3(-h, wh, 0), Vector3(h, wh, 0), h)   # Frontal
	_add_battlements_side(Vector3(0, wh, -h), Vector3(0, wh, h), h)   # Derecho
	_add_battlements_side(Vector3(0, wh, -h), Vector3(0, wh, h), -h)  # Izquierdo

func _add_battlements_line(from_v: Vector3, to_v: Vector3, z_pos: float):
	var spacing = 2.2
	var count = int(castle_half * 2.0 / spacing)
	var batt_mat = _get_stone_mat(0.5, 0.5)
	for i in range(count):
		var x = -castle_half + spacing * 0.5 + i * spacing
		# Saltar hueco de puerta en muro frontal
		if z_pos > 0 and abs(x) < gate_width / 2.0 + 1.5:
			continue
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.0, 1.0, wall_depth + 0.3)
		mesh.mesh = box
		mesh.position = Vector3(x, wall_height + 0.5, z_pos)
		mesh.set_surface_override_material(0, batt_mat)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mesh)

func _add_battlements_side(from_v: Vector3, to_v: Vector3, x_pos: float):
	var spacing = 2.2
	var count = int(castle_half * 2.0 / spacing)
	var batt_mat = _get_stone_mat(0.5, 0.5)
	for i in range(count):
		var z = -castle_half + spacing * 0.5 + i * spacing
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(wall_depth + 0.3, 1.0, 1.0)
		mesh.mesh = box
		mesh.position = Vector3(x_pos, wall_height + 0.5, z)
		mesh.set_surface_override_material(0, batt_mat)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mesh)

func _build_keep():
	_add_box_wall(Vector3(0, keep_size.y / 2.0, 0), keep_size)

	# Almenas del keep
	var batt_mat = _get_stone_mat(0.5, 0.5)
	var spacing = 2.0
	var kw = keep_size.x / 2.0
	var kd = keep_size.z / 2.0
	var y = keep_size.y + 0.5

	for i in range(int(keep_size.x / spacing)):
		var x = -kw + spacing * 0.5 + i * spacing
		for z_side in [kd, -kd]:
			var m = MeshInstance3D.new()
			var b = BoxMesh.new()
			b.size = Vector3(0.8, 1.0, 0.6)
			m.mesh = b
			m.position = Vector3(x, y, z_side)
			m.set_surface_override_material(0, batt_mat)
			add_child(m)

	for i in range(int(keep_size.z / spacing)):
		var z = -kd + spacing * 0.5 + i * spacing
		for x_side in [kw, -kw]:
			var m = MeshInstance3D.new()
			var b = BoxMesh.new()
			b.size = Vector3(0.6, 1.0, 0.8)
			m.mesh = b
			m.position = Vector3(x_side, y, z)
			m.set_surface_override_material(0, batt_mat)
			add_child(m)
