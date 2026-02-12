extends Node3D


func _ready() -> void:
	# Configurar notas seleccionadas (C3, F#3, C4)
	GameManager.selected_notes = [
		{"note_index": 0, "octave": 3},   # C3
		{"note_index": 6, "octave": 3},   # F#3
		{"note_index": 0, "octave": 4}    # C4
	]

	# Configurar instrumento seleccionado
	GameManager.selected_instrument = "Piano"

	# Generar los cubos de notas
	$NoteSpawner.spawn_cubes()

	# Generar teclado DESPUÉS de configurar las notas
	$HUD.refresh_keyboard()

	# Conectar señal del jugador con el HUD
	var player = $Player
	var hud = $HUD
	player.player_hit_cube.connect(func(note_index, octave, cube): hud.set_challenge(note_index, octave, cube))

	# Conectar señal de reset de nivel
	GameManager.level_reset.connect(_on_level_reset)

	# Mantener conexión para debug
	$Player.player_hit_cube.connect(_on_player_hit_cube)

	# Iniciar música de fondo
	AudioManager.start_music()


func _on_player_hit_cube(note_index: int, octave: int, cube: Area3D) -> void:
	print("Hit note: ", GameManager.NOTES[note_index], octave)


func _on_level_reset() -> void:
	# Resetear todos los cubos
	$NoteSpawner.reset_all_cubes()

	# Resetear estado de colisión del jugador
	if $Player.has_method("reset_collision_state"):
		$Player.reset_collision_state()

	# Reposicionar jugador al centro
	$Player.position = Vector3(0, 0, 0)
	$Player.velocity = Vector3.ZERO
