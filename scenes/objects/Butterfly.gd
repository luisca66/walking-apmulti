extends Node3D

# Parámetros de vuelo
var fly_speed: float = 0.0
var fly_center: Vector3 = Vector3.ZERO
var fly_radius: float = 0.0
var fly_angle: float = 0.0
var fly_height: float = 0.0
var fly_height_offset: float = 0.0
var vertical_wave_speed: float = 0.0
var wing_speed: float = 0.0
var direction_change_timer: float = 0.0
var direction_change_interval: float = 0.0
var target_angle_speed: float = 0.0
var current_angle_speed: float = 0.0
var wobble_offset: float = 0.0

var wing_color: Color = Color.WHITE

func _ready():
	# Cada mariposa tiene parámetros únicos
	fly_speed = randf_range(0.3, 0.8)
	fly_radius = randf_range(8.0, 25.0)
	fly_angle = randf() * TAU
	fly_height = randf_range(2.0, 6.0)
	fly_height_offset = randf() * TAU
	vertical_wave_speed = randf_range(0.5, 1.5)
	wing_speed = randf_range(8.0, 14.0)
	direction_change_interval = randf_range(3.0, 8.0)
	direction_change_timer = randf() * direction_change_interval
	target_angle_speed = fly_speed
	current_angle_speed = fly_speed
	wobble_offset = randf() * TAU

	_build_body()
	_build_wings()

func _build_body():
	var body_color = Color(0.294, 0.0, 0.51)  # Índigo oscuro
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body_mat.roughness = 0.5
	body_mat.metallic = 0.05

	# --- Cuerpo: cilindro delgado horizontal ---
	var body_mesh = MeshInstance3D.new()
	body_mesh.name = "BodyMesh"
	var body_cyl = CylinderMesh.new()
	body_cyl.top_radius = 0.03
	body_cyl.bottom_radius = 0.04
	body_cyl.height = 0.4
	body_cyl.radial_segments = 8
	body_mesh.mesh = body_cyl
	body_mesh.rotation.x = PI / 2.0  # Horizontal, apuntando hacia -Z
	body_mesh.set_surface_override_material(0, body_mat)
	add_child(body_mesh)

	# --- Cabeza: esfera ---
	var head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	var head_sphere = SphereMesh.new()
	head_sphere.radius = 0.05
	head_sphere.height = 0.1
	head_sphere.radial_segments = 10
	head_sphere.rings = 6
	head_mesh.mesh = head_sphere
	head_mesh.position = Vector3(0, 0, -0.22)  # Delante del cuerpo
	head_mesh.set_surface_override_material(0, body_mat)
	add_child(head_mesh)

	# --- Antena izquierda: cilindro delgado ---
	var ant_mat = StandardMaterial3D.new()
	ant_mat.albedo_color = body_color
	ant_mat.roughness = 0.5

	var ant_cyl = CylinderMesh.new()
	ant_cyl.top_radius = 0.008
	ant_cyl.bottom_radius = 0.01
	ant_cyl.height = 0.15
	ant_cyl.radial_segments = 4

	var antenna_l = MeshInstance3D.new()
	antenna_l.name = "AntennaL"
	antenna_l.mesh = ant_cyl
	antenna_l.position = Vector3(-0.03, 0.06, -0.24)
	antenna_l.rotation.z = 0.5   # Inclinada hacia afuera
	antenna_l.rotation.x = 0.4   # Inclinada hacia adelante
	antenna_l.set_surface_override_material(0, ant_mat)
	add_child(antenna_l)

	var antenna_r = MeshInstance3D.new()
	antenna_r.name = "AntennaR"
	antenna_r.mesh = ant_cyl
	antenna_r.position = Vector3(0.03, 0.06, -0.24)
	antenna_r.rotation.z = -0.5
	antenna_r.rotation.x = 0.4
	antenna_r.set_surface_override_material(0, ant_mat)
	add_child(antenna_r)

	# --- Puntas de antenas: esferitas ---
	var tip_sphere = SphereMesh.new()
	tip_sphere.radius = 0.015
	tip_sphere.height = 0.03
	tip_sphere.radial_segments = 6
	tip_sphere.rings = 4

	var antenna_l_tip = MeshInstance3D.new()
	antenna_l_tip.name = "AntennaLTip"
	antenna_l_tip.mesh = tip_sphere
	antenna_l_tip.position = Vector3(-0.06, 0.12, -0.28)
	antenna_l_tip.set_surface_override_material(0, ant_mat)
	add_child(antenna_l_tip)

	var antenna_r_tip = MeshInstance3D.new()
	antenna_r_tip.name = "AntennaRTip"
	antenna_r_tip.mesh = tip_sphere
	antenna_r_tip.position = Vector3(0.06, 0.12, -0.28)
	antenna_r_tip.set_surface_override_material(0, ant_mat)
	add_child(antenna_r_tip)

func _build_wings():
	# Colores posibles (mismos que antes)
	var colors = [
		Color(1.0, 0.41, 0.71),    # Rosa hot pink
		Color(0.2, 0.5, 0.95),     # Azul morpho
		Color(0.95, 0.85, 0.2),    # Amarillo
		Color(0.85, 0.2, 0.6),     # Magenta
		Color(0.95, 0.6, 0.1),     # Naranja monarca
		Color(0.6, 0.2, 0.85),     # Violeta
		Color(0.2, 0.8, 0.4),      # Verde esmeralda
		Color(0.9, 0.3, 0.3),      # Roja
	]
	wing_color = colors[randi() % colors.size()]

	# Crear pivots para las alas
	var left_wing_pivot = Node3D.new()
	left_wing_pivot.name = "LeftWingPivot"
	left_wing_pivot.position = Vector3(-0.02, 0.0, 0.0)
	add_child(left_wing_pivot)

	var right_wing_pivot = Node3D.new()
	right_wing_pivot.name = "RightWingPivot"
	right_wing_pivot.position = Vector3(0.02, 0.0, 0.0)
	add_child(right_wing_pivot)

	# Crear alas con forma orgánica
	var left_wing = MeshInstance3D.new()
	left_wing.name = "LeftWing"
	left_wing_pivot.add_child(left_wing)
	_create_wing_mesh(left_wing, 1.0)

	var right_wing = MeshInstance3D.new()
	right_wing.name = "RightWing"
	right_wing_pivot.add_child(right_wing)
	_create_wing_mesh(right_wing, -1.0)

func _create_wing_mesh(wing_node: MeshInstance3D, side: float):
	# Construir un ala de mariposa con forma orgánica usando ImmediateMesh
	# El ala tiene forma de gota/corazón vista de arriba

	var mesh = ImmediateMesh.new()
	wing_node.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = wing_color
	mat.emission_enabled = true
	mat.emission = wing_color
	mat.emission_energy_multiplier = 0.15
	mat.roughness = 0.3
	mat.metallic = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible de ambos lados
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	wing_node.set_surface_override_material(0, mat)

	# Generar la forma del ala como un abanico de triángulos
	# Puntos que definen el contorno del ala (forma de mariposa)
	var points: Array[Vector3] = []
	var segments = 16

	for i in range(segments + 1):
		var t = float(i) / float(segments)  # 0 a 1
		var angle = t * PI * 1.8 - PI * 0.1  # Barrido de casi 360 grados

		# Radio variable para forma de ala de mariposa
		var r = 0.0
		if t < 0.5:
			# Ala superior (más grande)
			r = 0.25 * sin(t * PI * 2.0) * (1.0 + 0.3 * sin(t * PI * 4.0))
		else:
			# Ala inferior (más pequeña)
			r = 0.18 * sin((t - 0.5) * PI * 2.0) * (1.0 + 0.2 * sin(t * PI * 3.0))

		r = abs(r)
		var px = side * r * cos(angle)
		var py = r * sin(angle) * 0.7  # Achatada verticalmente
		var pz = -t * 0.1  # Ligero barrido hacia atrás

		points.append(Vector3(px, py, pz))

	# Dibujar como abanico de triángulos desde el centro
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var center = Vector3(0, 0, 0)

	for i in range(points.size() - 1):
		# Triángulo: center -> point[i] -> point[i+1]
		mesh.surface_set_normal(Vector3(0, 0, 1))
		mesh.surface_add_vertex(center)
		mesh.surface_set_normal(Vector3(0, 0, 1))
		mesh.surface_add_vertex(points[i])
		mesh.surface_set_normal(Vector3(0, 0, 1))
		mesh.surface_add_vertex(points[i + 1])

	mesh.surface_end()

func _process(delta: float):
	var time = Time.get_ticks_msec() * 0.001

	# --- ALETEO (usando los pivots) ---
	var wing_angle = sin(time * wing_speed) * 1.1  # ±63 grados aprox
	var left_wing_pivot = get_node_or_null("LeftWingPivot")
	var right_wing_pivot = get_node_or_null("RightWingPivot")
	if left_wing_pivot:
		left_wing_pivot.rotation.z = wing_angle
	if right_wing_pivot:
		right_wing_pivot.rotation.z = -wing_angle

	# --- CAMBIO DE DIRECCIÓN periódico ---
	direction_change_timer += delta
	if direction_change_timer >= direction_change_interval:
		direction_change_timer = 0.0
		direction_change_interval = randf_range(3.0, 8.0)
		# Cambiar velocidad angular (puede invertir dirección)
		target_angle_speed = randf_range(-fly_speed, fly_speed)
		# Ocasionalmente cambiar radio
		fly_radius += randf_range(-3.0, 3.0)
		fly_radius = clampf(fly_radius, 5.0, 30.0)

	# Suavizar cambio de dirección
	current_angle_speed = lerp(current_angle_speed, target_angle_speed, 1.5 * delta)

	# --- MOVIMIENTO ORBITAL con deriva ---
	fly_angle += current_angle_speed * delta

	# Wobble lateral para que no sea un círculo perfecto
	var wobble_x = sin(time * 0.7 + wobble_offset) * 2.0
	var wobble_z = cos(time * 0.5 + wobble_offset) * 2.0

	var target_x = fly_center.x + cos(fly_angle) * fly_radius + wobble_x
	var target_z = fly_center.z + sin(fly_angle) * fly_radius + wobble_z

	# Ondulación vertical suave
	var target_y = fly_height + sin(time * vertical_wave_speed + fly_height_offset) * 1.5

	# Movimiento suave
	var target_pos = Vector3(target_x, target_y, target_z)

	# Limitar al área de la arena
	var arena_limit = GameManager.ARENA_SIZE / 2.0 - 5.0
	target_pos.x = clampf(target_pos.x, -arena_limit, arena_limit)
	target_pos.z = clampf(target_pos.z, -arena_limit, arena_limit)
	target_pos.y = clampf(target_pos.y, 1.5, 8.0)

	# Interpolar posición
	global_position = global_position.lerp(target_pos, 3.0 * delta)

	# --- ORIENTACIÓN: mirar hacia donde vuela ---
	var velocity_dir = target_pos - global_position
	if velocity_dir.length_squared() > 0.001:
		var look_target = global_position + velocity_dir.normalized()
		look_at(look_target, Vector3.UP)
		# Inclinar ligeramente al girar
		var bank_angle = -current_angle_speed * 0.3
		rotation.z = lerp(rotation.z, bank_angle, 3.0 * delta)
