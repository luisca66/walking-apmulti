extends Node3D

@onready var player = $Player
@onready var note_spawner = $NoteSpawner
@onready var hud = $HUD
@onready var exit_gate = $ExitGate
@onready var level_complete = $LevelComplete

func _ready():
	# Aplicar textura de pasto procedural al suelo
	_apply_grass_texture()

	GameManager.selected_notes = GameManager.get_current_level_notes()
	GameManager.selected_instrument = "Piano"
	GameManager.reset_level_state()

	note_spawner.spawn_cubes()
	hud.refresh_keyboard()

	# Conectar señales
	player.player_hit_cube.connect(func(note_index, octave, cube):
		hud.set_challenge(note_index, octave, cube)
	)

	GameManager.level_reset.connect(_on_level_reset)

	exit_gate.gate_crossed.connect(_on_gate_crossed)

	if not AudioManager.music_player.playing:
		AudioManager.start_music()

func _apply_grass_texture():
	var ground = get_node_or_null("Ground")
	if ground:
		var grass_tex = TextureGenerator.generate_grass()
		var grass_mat = StandardMaterial3D.new()
		grass_mat.albedo_texture = grass_tex
		grass_mat.uv1_scale = Vector3(50.0, 50.0, 1.0)
		grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		grass_mat.roughness = 0.95
		ground.set_surface_override_material(0, grass_mat)
		print("Grass texture applied to ground")

func _on_level_reset():
	note_spawner.reset_all_cubes()
	if player.has_method("reset_collision_state"):
		player.reset_collision_state()
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO

func _on_gate_crossed():
	var level_name = GameManager.level_names.get(GameManager.current_level, "")
	level_complete.show_screen(GameManager.current_level, level_name, GameManager.score)
