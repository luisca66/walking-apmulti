extends Node

var camera: Camera3D = null
var player: CharacterBody3D = null
var player_camera: Camera3D = null
var arena: Node3D = null
var gate_trigger: Area3D = null
var is_cutscene_playing: bool = false
var cutscene_player: AudioStreamPlayer = null

# Guardar posición original de la cámara del jugador
var original_cam_transform: Transform3D

signal cutscene_finished
signal level_completed

func setup(p_player: CharacterBody3D, p_arena: Node3D, p_gate_trigger: Area3D):
	player = p_player
	arena = p_arena
	gate_trigger = p_gate_trigger

	if gate_trigger:
		gate_trigger.player_crossed_gate.connect(_on_player_crossed_gate)

func play_gate_cutscene():
	if is_cutscene_playing:
		return
	is_cutscene_playing = true

	# Bajar volumen de música de fondo
	AudioManager.set_music_volume(0.1)

	# Reproducir música de cutscene
	cutscene_player = AudioStreamPlayer.new()
	add_child(cutscene_player)
	var stream = load("res://assets/music/abre_puerta_nivel_1.mp3")
	if stream:
		cutscene_player.stream = stream
		cutscene_player.volume_db = 0.0
		cutscene_player.play()

	# Desactivar control del jugador
	player.set_physics_process(false)

	# Encontrar la cámara actual del jugador
	player_camera = get_viewport().get_camera_3d()
	original_cam_transform = player_camera.global_transform

	# Crear cámara de cutscene
	camera = Camera3D.new()
	get_tree().root.add_child(camera)
	camera.global_transform = player_camera.global_transform
	camera.current = true

	# Posición objetivo: frente a la puerta, mirándola
	var gate_pos = arena.gate_position if arena else Vector3(0, 0, -GameManager.ARENA_SIZE / 2.0)
	var cam_target_pos = gate_pos + Vector3(0, 4.0, 12.0)  # Frente a la puerta, un poco arriba
	var look_target = gate_pos + Vector3(0, 3.0, 0)

	# Paso 1: Paneo de cámara hacia la puerta (2 segundos)
	var tween = create_tween()
	tween.tween_property(camera, "global_position", cam_target_pos, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		camera.look_at(look_target, Vector3.UP)
	)

	# Durante el paneo, ir rotando la cámara hacia la puerta
	var look_tween = create_tween()
	look_tween.tween_method(func(t: float):
		if is_instance_valid(camera):
			var current_look = original_cam_transform.origin + original_cam_transform.basis.z * -5.0
			var target_look = look_target
			var interp_look = current_look.lerp(target_look, t)
			camera.look_at(interp_look, Vector3.UP)
	, 0.0, 1.0, 2.0)

	# Paso 2: Esperar un momento, luego abrir la puerta (a los 2.5 segundos)
	await get_tree().create_timer(2.5).timeout

	if arena and arena.has_method("open_gate"):
		arena.open_gate()

	# Paso 3: Esperar que la puerta se abra (1.5 segundos de animación + 1 segundo de pausa)
	await get_tree().create_timer(2.5).timeout

	# Paso 4: Regresar cámara al jugador (1.5 segundos)
	var return_tween = create_tween()
	# Recalcular la posición actual de la cámara del jugador
	var player_cam_pos = player_camera.global_position
	return_tween.tween_property(camera, "global_position", player_cam_pos, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var return_look_tween = create_tween()
	var player_look = player.global_position + Vector3(0, 1.5, 0)
	return_look_tween.tween_method(func(t: float):
		if is_instance_valid(camera):
			var gate_look = gate_pos + Vector3(0, 3.0, 0)
			var interp = gate_look.lerp(player_look, t)
			camera.look_at(interp, Vector3.UP)
	, 0.0, 1.0, 1.5)

	await get_tree().create_timer(1.5).timeout

	# Paso 5: Devolver control
	player_camera.current = true
	if is_instance_valid(camera):
		camera.queue_free()
	camera = null

	player.set_physics_process(true)
	is_cutscene_playing = false

	# Activar el trigger de la puerta para que el jugador pueda cruzar
	if gate_trigger:
		gate_trigger.activate()

	cutscene_finished.emit()

	# Restaurar volumen de música de fondo
	AudioManager.set_music_volume(0.3)

	# Limpiar player de cutscene cuando termine
	if is_instance_valid(cutscene_player):
		cutscene_player.finished.connect(cutscene_player.queue_free)

func _on_player_crossed_gate():
	level_completed.emit()
