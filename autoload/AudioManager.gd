extends Node

# Ruta base para los samples de audio
var base_path: String = "res://assets/samples/"

# Sistema de música de fondo
var music_player: AudioStreamPlayer
var music_playlist: Array[String] = []
var current_track_index: int = 0


func _ready() -> void:
	print("AudioManager initialized")

	# Construir playlist de jazz
	for i in range(1, 11):
		var filename = "res://assets/music/jazz-%02d.mp3" % i
		music_playlist.append(filename)

	# Crear player de música
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -10.0
	music_player.finished.connect(_on_music_track_finished)

	# Mezclar el orden aleatoriamente para variedad
	music_playlist.shuffle()


func get_sample_path(instrument: String, note_index: int, octave: int) -> String:
	var note_name: String = GameManager.NOTES[note_index]
	var full_path: String = "%s%s/%s%d.mp3" % [base_path, instrument, note_name, octave]
	return full_path


func play_note(instrument: String, note_index: int, octave: int) -> void:
	var sample_path: String = get_sample_path(instrument, note_index, octave)
	if not ResourceLoader.exists(sample_path):
		print("⚠️  Audio file not found: ", sample_path)
		return

	var audio_stream = ResourceLoader.load(sample_path)
	if audio_stream == null:
		print("❌ Failed to load audio: ", sample_path)
		return

	var player = AudioStreamPlayer.new()
	player.bus = &"Master"
	add_child(player)
	player.stream = audio_stream
	player.play()
	player.finished.connect(player.queue_free)
	print("🎵 Playing: ", sample_path)


func play_correct() -> void:
	_play_sfx("res://assets/samples/acierto.mp3")


func play_wrong() -> void:
	_play_sfx("res://assets/samples/error.mp3")


func _play_sfx(path: String) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	var stream = load(path)
	if stream:
		player.stream = stream
		player.volume_db = 0.0
		player.play()
		player.finished.connect(player.queue_free)
	else:
		push_warning("AudioManager: No se encontró el archivo: " + path)
		player.queue_free()


func start_music() -> void:
	current_track_index = 0
	_play_current_track()


func _play_current_track() -> void:
	if music_playlist.is_empty():
		return
	var path = music_playlist[current_track_index]
	var stream = load(path)
	if stream:
		stream.loop = false  # NO hacer loop individual, queremos pasar a la siguiente
		music_player.stream = stream
		music_player.play()
	else:
		push_warning("AudioManager: No se encontró: " + path)
		_on_music_track_finished()  # Saltar al siguiente


func _on_music_track_finished() -> void:
	current_track_index += 1
	if current_track_index >= music_playlist.size():
		current_track_index = 0
		music_playlist.shuffle()  # Re-mezclar cuando termina la playlist completa
	_play_current_track()


func stop_music() -> void:
	music_player.stop()


func set_music_volume(value: float) -> void:
	# value va de 0.0 a 1.0
	# Convertir a dB: 0.0 = silencio (-80 dB), 1.0 = máximo (0 dB)
	if value <= 0.01:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(value)
