extends CharacterBody3D

# Variables de movimiento
@export var move_speed: float = 5.0
@export var turn_speed: float = 3.0
var gravity: float = 9.8

# Referencias a nodos
@onready var player_model: Node3D = $PlayerModel
@onready var body_mesh: MeshInstance3D = $PlayerModel/Body
@onready var left_foot: Node3D = $PlayerModel/LeftFoot
@onready var right_foot: Node3D = $PlayerModel/RightFoot
@onready var left_hand: MeshInstance3D = $PlayerModel/LeftHand
@onready var right_hand: MeshInstance3D = $PlayerModel/RightHand
@onready var camera_pivot: Node3D = $CameraPivot
@onready var detection_area: Area3D = $DetectionArea

# Estado
var is_moving: bool = false
var last_collided_cube: Area3D = null
var steps_player: AudioStreamPlayer

# Animación
var walk_time: float = 0.0
var anim_speed: float = 8.0
var stride_length: float = 0.6

# Señales
signal player_hit_cube(note_index: int, octave: int, cube: Area3D)


func _ready() -> void:
	detection_area.area_entered.connect(_on_area_entered)

	# Configurar sonido de pasos
	steps_player = AudioStreamPlayer.new()
	add_child(steps_player)
	var steps_stream = load("res://assets/samples/steps.mp3")
	if steps_stream:
		steps_stream.loop = true
		steps_player.stream = steps_stream
		steps_player.volume_db = -6.0


func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Leer input para movimiento adelante/atrás
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1

	# Rotación con A/D
	if Input.is_action_pressed("move_left"):
		player_model.rotation.y += turn_speed * delta
	if Input.is_action_pressed("move_right"):
		player_model.rotation.y -= turn_speed * delta

	# Calcular dirección forward basada en la rotación del modelo
	var forward: Vector3 = -player_model.transform.basis.z
	velocity.x = forward.x * input_dir.y * move_speed
	velocity.z = forward.z * input_dir.y * move_speed

	# Actualizar estado de movimiento
	is_moving = input_dir.y != 0

	# Control de sonido de pasos
	if is_moving:
		if not steps_player.playing:
			steps_player.play()
	else:
		if steps_player.playing:
			steps_player.stop()

	# Aplicar movimiento
	move_and_slide()

	# Animar extremidades
	_animate_limbs(delta)

	# Cámara: seguir rotación del modelo
	camera_pivot.rotation.y = player_model.rotation.y
	var cam = $CameraPivot/CameraBoom/Camera3D
	cam.look_at(global_position + Vector3(0, 1.8, 0), Vector3.UP)


func _animate_limbs(delta: float) -> void:
	if is_moving:
		walk_time += anim_speed * delta
	else:
		# Cuando no se mueve, resetear suavemente walk_time hacia un múltiplo de TAU
		# para que los pies vuelvan a posición neutral
		var target = round(walk_time / TAU) * TAU
		walk_time = lerp(walk_time, target, 5.0 * delta)

	var t = walk_time

	# --- PIES ---
	var foot_base_y = 0.3

	# Pie izquierdo
	var lf_lift = max(0.0, sin(t))  # Solo sube cuando sin > 0
	var lf_z = cos(t) * stride_length  # Adelante/atrás
	left_foot.position = Vector3(-0.6, foot_base_y + lf_lift * 0.5, lf_z)
	left_foot.rotation.x = -lf_lift * 0.5  # Inclinación al levantar

	# Pie derecho (desfase PI)
	var rf_lift = max(0.0, sin(t + PI))
	var rf_z = cos(t + PI) * stride_length
	right_foot.position = Vector3(0.6, foot_base_y + rf_lift * 0.5, rf_z)
	right_foot.rotation.x = -rf_lift * 0.5

	# --- MANOS (balanceo opuesto a los pies) ---
	var hand_base_y = 1.5
	left_hand.position = Vector3(-1.1, hand_base_y + cos(t) * 0.2, sin(t) * 0.4)
	right_hand.position = Vector3(1.1, hand_base_y + cos(t + PI) * 0.2, sin(t + PI) * 0.4)

	# --- BODY BOBBING (rebote al caminar) ---
	if is_moving:
		body_mesh.position.y = 1.5 + abs(sin(t)) * 0.1
	else:
		body_mesh.position.y = lerp(body_mesh.position.y, 1.5, 5.0 * delta)

	# --- SQUASH AND STRETCH del cuerpo (sutil) ---
	if is_moving:
		var squash = 1.0 + abs(sin(t)) * 0.05
		var stretch = 1.0 - abs(sin(t)) * 0.03
		body_mesh.scale = body_mesh.scale.lerp(Vector3(stretch, squash, stretch), 10.0 * delta)
	else:
		body_mesh.scale = body_mesh.scale.lerp(Vector3(1.0, 1.0, 1.0), 5.0 * delta)


func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("note_cube"):
		return
	if area == last_collided_cube:
		return
	if area.solved:
		return

	last_collided_cube = area

	# Reproducir nota
	AudioManager.play_note(GameManager.selected_instrument, area.note_index, area.octave)

	# Animación de bounce en el cubo
	var tween = create_tween()
	tween.tween_property(area, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tween.tween_property(area, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

	# Emitir señal
	player_hit_cube.emit(area.note_index, area.octave, area)


func reset_collision_state() -> void:
	last_collided_cube = null