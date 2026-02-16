extends Node3D

var cutscene_manager: Node = null
var gate_trigger: Area3D = null
var level_complete_screen: CanvasLayer = null

func _ready() -> void:
	# Aplicar textura de pasto procedural al suelo
	_apply_grass_texture()

	# Configurar iluminación mejorada
	_setup_lighting()

	# Instanciar castillo medieval
	var castle_scene = preload("res://scenes/objects/Castle.tscn")
	var castle = castle_scene.instantiate()
	castle.position = Vector3(0, 0, -40)
	add_child(castle)

	# Instanciar laberinto de setos
	var maze_scene = preload("res://scenes/objects/HedgeMaze.tscn")
	var maze = maze_scene.instantiate()
	maze.position = Vector3(60, 0, 50)  # En una esquina del área, lejos del castillo y del spawn
	add_child(maze)

	# Configurar notas seleccionadas (C3, F#3, C4)
	GameManager.selected_notes = [
		{"note_index": 0, "octave": 3},   # C3
		{"note_index": 6, "octave": 3},   # F#3
		{"note_index": 0, "octave": 4}    # C4
	]

	# Configurar instrumento seleccionado
	GameManager.selected_instrument = "Piano"

	# Generar árboles primero
	$TreeSpawner.spawn_trees()

	# Generar rocas después de los árboles (para evitar overlap)
	$RockSpawner.spawn_rocks()

	# Generar los cubos de notas al final (para evitar spawn sobre obstáculos)
	$NoteSpawner.spawn_cubes()

	# Generar mariposas (decoración animada)
	$ButterflySpawner.spawn_butterflies()

	# Generar nubes (decoración cielo)
	$CloudSpawner.spawn_clouds()

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

	# Gate trigger — posicionar en el hueco de la puerta del muro perimetral
	var trigger_scene = preload("res://scenes/objects/GateTrigger.tscn")
	gate_trigger = trigger_scene.instantiate()
	var arena_half = GameManager.ARENA_SIZE / 2.0
	gate_trigger.position = Vector3(0, 3.0, -arena_half)  # En la puerta del muro norte
	add_child(gate_trigger)

	# Level complete screen
	var lc_scene = preload("res://scenes/ui/LevelComplete.tscn")
	level_complete_screen = lc_scene.instantiate()
	add_child(level_complete_screen)

	# Cutscene manager
	cutscene_manager = Node.new()
	cutscene_manager.set_script(preload("res://scenes/objects/CutsceneManager.gd"))
	add_child(cutscene_manager)
	cutscene_manager.setup($Player, $Arena, gate_trigger)
	cutscene_manager.level_completed.connect(_on_level_completed)

	# Conectar la señal de gate_unlocked para disparar la cutscene
	GameManager.gate_unlocked.connect(_on_gate_unlocked)


func _on_gate_unlocked():
	cutscene_manager.play_gate_cutscene()


func _on_level_completed():
	level_complete_screen.show_victory(GameManager.score)


func _on_player_hit_cube(note_index: int, octave: int, cube: Area3D) -> void:
	print("Hit note: ", GameManager.NOTES[note_index], octave)


func _on_level_reset() -> void:
	# Resetear todos los cubos
	$NoteSpawner.reset_all_cubes()

	# Los árboles NO se regeneran (decoración permanente)

	# Resetear estado de colisión del jugador
	if $Player.has_method("reset_collision_state"):
		$Player.reset_collision_state()

	# Reposicionar jugador al centro
	$Player.position = Vector3(0, 0, 0)
	$Player.velocity = Vector3.ZERO


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


func _setup_lighting():
	# Configurar luz ambiente más alta
	var env = $WorldEnvironment.environment
	if env:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.6, 0.65, 0.7)
		env.ambient_light_energy = 0.7

	# Fill light desde dirección opuesta
	var fill_light = DirectionalLight3D.new()
	fill_light.light_color = Color(0.8, 0.85, 0.9)
	fill_light.light_energy = 0.4
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(-30, 180, 0)
	add_child(fill_light)

	# Luz lateral para iluminar paredes Este/Oeste
	var side_light = DirectionalLight3D.new()
	side_light.light_color = Color(0.75, 0.8, 0.85)
	side_light.light_energy = 0.3
	side_light.shadow_enabled = false
	side_light.rotation_degrees = Vector3(-20, 90, 0)
	add_child(side_light)
