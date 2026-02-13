extends Node3D


func _ready() -> void:
	# Aplicar textura de pasto procedural al suelo
	_apply_grass_texture()

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

func _apply_grass_texture():
	var ground = $Ground
	if ground:
		var grass_tex = TextureGenerator.generate_grass()
		var grass_mat = StandardMaterial3D.new()
		grass_mat.albedo_texture = grass_tex
		grass_mat.uv1_scale = Vector3(50.0, 50.0, 1.0)
		grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		grass_mat.roughness = 0.95
		ground.set_surface_override_material(0, grass_mat)
		print("Grass texture applied to ground")


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
