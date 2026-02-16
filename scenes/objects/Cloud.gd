extends Node3D

var drift_speed: float = 0.0
var drift_direction: Vector3 = Vector3.ZERO
var bob_speed: float = 0.0
var bob_offset: float = 0.0
var bob_amount: float = 0.0
var base_y: float = 0.0
var arena_limit: float = 0.0

func _ready():
	# Parámetros únicos por nube
	drift_speed = randf_range(1.0, 3.5)
	# Dirección predominante con ligera variación
	var angle = randf_range(-0.3, 0.3)  # Casi todas van en la misma dirección
	drift_direction = Vector3(cos(angle), 0, sin(angle)).normalized()
	bob_speed = randf_range(0.3, 0.8)
	bob_offset = randf() * TAU
	bob_amount = randf_range(0.3, 1.0)
	base_y = position.y
	arena_limit = GameManager.ARENA_SIZE * 0.8

	_build_cloud()

func _build_cloud():
	# Escala general aleatoria de la nube
	var cloud_scale = randf_range(0.7, 1.5)

	# Configuración de cada "puff" (bola de algodón)
	var configs = [
		# [offset_x, offset_y, offset_z, radius, squash_y]
		[0.0, 0.0, 0.0, 5.0, 0.45],              # Centro grande
		[-3.5, 0.5, 1.0, 4.0, 0.5],               # Izquierda arriba
		[3.0, 0.3, -0.5, 3.5, 0.5],               # Derecha
		[-1.5, -0.3, -1.5, 3.0, 0.55],             # Atrás izquierda abajo
		[1.5, 0.6, 1.5, 3.5, 0.4],                # Adelante derecha arriba
	]

	for i in range(5):
		var cfg = configs[i]

		var puff = MeshInstance3D.new()
		puff.name = "Puff%d" % (i + 1)

		var sphere = SphereMesh.new()
		sphere.radius = cfg[3] * cloud_scale
		sphere.height = cfg[3] * 2.0 * cfg[4] * cloud_scale  # Achatada
		sphere.radial_segments = 10
		sphere.rings = 6
		puff.mesh = sphere

		puff.position = Vector3(
			cfg[0] * cloud_scale + randf_range(-0.5, 0.5),
			cfg[1] * cloud_scale,
			cfg[2] * cloud_scale + randf_range(-0.5, 0.5)
		)

		# Material blanco suave, ligeramente transparente
		var mat = StandardMaterial3D.new()
		var brightness = randf_range(0.9, 1.0)
		mat.albedo_color = Color(brightness, brightness, brightness, randf_range(0.75, 0.9))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 1.0
		mat.metallic = 0.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Sin sombras propias, siempre brillante
		puff.set_surface_override_material(0, mat)

		# Las nubes NO proyectan sombra al suelo (se vería raro)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)

func _process(delta: float):
	var time = Time.get_ticks_msec() * 0.001

	# --- DERIVA horizontal lenta ---
	position += drift_direction * drift_speed * delta

	# --- BOBBING vertical suave ---
	position.y = base_y + sin(time * bob_speed + bob_offset) * bob_amount

	# --- WRAP: cuando sale del área, reaparece del otro lado ---
	if position.x > arena_limit:
		position.x = -arena_limit
	elif position.x < -arena_limit:
		position.x = arena_limit

	if position.z > arena_limit:
		position.z = -arena_limit
	elif position.z < -arena_limit:
		position.z = arena_limit
