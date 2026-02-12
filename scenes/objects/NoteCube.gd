extends Area3D

# Variables exportadas
@export var note_index: int = 0
@export var octave: int = 4

# Variables de estado
var solved: bool = false
var float_offset: float = 0.0
var rotation_speed: float = 0.015
var base_y: float = 1.5

# Referencias
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Señal
signal note_triggered(note_index: int, octave: int, cube: Area3D)


func _ready() -> void:
	# Inicializar valores aleatorios para animación
	float_offset = randf() * TAU
	rotation_speed = randf_range(0.01, 0.03)

	# Crear material con colores basados en la nota
	var material = StandardMaterial3D.new()
	material.albedo_color = GameManager.NOTE_COLORS[note_index]
	material.emission_enabled = true
	material.emission = GameManager.NOTE_COLORS[note_index]
	material.emission_energy_multiplier = 0.3
	mesh_instance.material_override = material

	# Agregar al grupo para detección
	add_to_group("note_cube")


func _process(delta: float) -> void:
	if solved:
		return

	# Animación de flotación
	position.y = base_y + sin(Time.get_ticks_msec() * 0.002 + float_offset) * 0.2

	# Animación de rotación
	rotate_x(rotation_speed * delta)
	rotate_y(rotation_speed * delta)


func setup(p_note_index: int, p_octave: int) -> void:
	note_index = p_note_index
	octave = p_octave


func mark_solved() -> void:
	solved = true
	var mat = mesh_instance.material_override
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.2
	mat.emission_energy_multiplier = 0.0
