extends CanvasLayer

# Referencias a nodos UI
@onready var score_value: Label = $TopPanel/VBoxContainer/ScoreBoard/HBoxContainer/ScoreValue
@onready var streak_value: Label = $TopPanel/VBoxContainer/ScoreBoard/HBoxContainer/StreakValue
@onready var feedback_label: Label = $TopPanel/VBoxContainer/FeedbackLabel
@onready var keyboard_container: HBoxContainer = $BottomPanel/KeyboardContainer
@onready var controls_hint: Label = $ControlsHint
@onready var music_slider: HSlider = $MusicVolumePanel/HBoxContainer/MusicSlider

# Estado
var current_challenge: Dictionary = {}  # vacío = no hay reto activo
var feedback_tween: Tween = null


func _ready() -> void:
	# NO generar teclado aquí - se hace desde TestScene después de configurar las notas

	# Conectar señales del GameManager
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.streak_updated.connect(_on_streak_updated)
	GameManager.gate_unlocked.connect(_on_gate_unlocked)
	GameManager.level_reset.connect(_on_level_reset)

	# Configurar slider de volumen de música
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_slider.value = 0.3  # volumen inicial


func _generate_keyboard() -> void:
	print("=== GENERATING KEYBOARD ===")
	print("Selected notes: ", GameManager.selected_notes)
	print("Keyboard container: ", keyboard_container)
	print("Keyboard container child count before: ", keyboard_container.get_child_count())

	# Limpiar botones previos
	for child in keyboard_container.get_children():
		child.queue_free()

	# Obtener las notas únicas del nivel (solo note_index, sin duplicados)
	var unique_note_indices: Array[int] = []
	for note_data in GameManager.selected_notes:
		var idx = note_data["note_index"]
		if idx not in unique_note_indices:
			unique_note_indices.append(idx)

	# Ordenar para que aparezcan en orden cromático
	unique_note_indices.sort()
	print("Unique note indices: ", unique_note_indices)

	# Crear un botón por cada nota única
	for note_idx in unique_note_indices:
		var btn = Button.new()
		btn.text = GameManager.NOTES[note_idx]
		btn.custom_minimum_size = Vector2(70, 55)

		# Estilo normal
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color("#1e293b")
		stylebox.border_color = Color("#475569")
		stylebox.border_width_bottom = 4
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", stylebox)

		# Estilo hover
		var stylebox_hover = StyleBoxFlat.new()
		stylebox_hover.bg_color = Color("#334155")
		stylebox_hover.border_color = Color("#475569")
		stylebox_hover.border_width_bottom = 4
		stylebox_hover.corner_radius_top_left = 8
		stylebox_hover.corner_radius_top_right = 8
		stylebox_hover.corner_radius_bottom_left = 8
		stylebox_hover.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("hover", stylebox_hover)

		# Estilo pressed
		var stylebox_pressed = StyleBoxFlat.new()
		stylebox_pressed.bg_color = Color("#475569")
		stylebox_pressed.border_color = Color("#475569")
		stylebox_pressed.border_width_bottom = 1
		stylebox_pressed.corner_radius_top_left = 8
		stylebox_pressed.corner_radius_top_right = 8
		stylebox_pressed.corner_radius_bottom_left = 8
		stylebox_pressed.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("pressed", stylebox_pressed)

		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color.WHITE)

		var index = note_idx
		btn.pressed.connect(func(): _on_note_button_pressed(index))
		keyboard_container.add_child(btn)

	print("Keyboard buttons generated: ", keyboard_container.get_child_count())


func set_challenge(note_index: int, octave: int, cube: Area3D) -> void:
	current_challenge = {"note_index": note_index, "octave": octave, "cube": cube}
	_show_feedback("¿Qué nota es?", Color.WHITE)


func _on_note_button_pressed(guessed_index: int) -> void:
	# Verificar si hay un reto activo
	if current_challenge.is_empty():
		_show_feedback("¡Busca un cubo!", Color("#fbbf24"))
		return

	# Verificar respuesta
	var is_correct = GameManager.check_answer(guessed_index, current_challenge)

	# Encontrar el botón correspondiente al note_index presionado
	var btn: Button = null
	for child in keyboard_container.get_children():
		if child is Button and child.text == GameManager.NOTES[guessed_index]:
			btn = child
			break

	if is_correct:
		_show_feedback("¡Correcto! " + GameManager.NOTES[guessed_index], Color("#4ade80"))
		AudioManager.play_correct()
		if btn:
			_flash_button(btn, Color("#22c55e"))

		# Marcar cubo como resuelto si tiene el método
		if current_challenge.has("cube") and current_challenge.cube != null:
			if current_challenge.cube.has_method("mark_solved"):
				current_challenge.cube.mark_solved()

		# Limpiar reto
		current_challenge = {}
	else:
		_show_feedback("Intenta de nuevo", Color("#f87171"))
		AudioManager.play_wrong()
		if btn:
			_flash_button(btn, Color("#ef4444"))


func _flash_button(btn: Button, color: Color) -> void:
	# Crear estilo temporal con el color de feedback
	var flash_style = StyleBoxFlat.new()
	flash_style.bg_color = color
	flash_style.corner_radius_top_left = 8
	flash_style.corner_radius_top_right = 8
	flash_style.corner_radius_bottom_left = 8
	flash_style.corner_radius_bottom_right = 8
	flash_style.border_width_bottom = 4
	flash_style.border_color = color.darkened(0.5)
	btn.add_theme_stylebox_override("normal", flash_style)

	# Restaurar estilo después de 0.4 segundos
	var t = create_tween()
	t.tween_callback(func():
		if is_instance_valid(btn):
			_restore_button_style(btn)
	).set_delay(0.4)


func _restore_button_style(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	# Recrear estilo normal original
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#1e293b")
	style_normal.border_color = Color("#475569")
	style_normal.border_width_bottom = 4
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style_normal)


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color

	# Matar tween anterior si existe
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	# Hacer visible el feedback
	feedback_label.modulate.a = 1.0

	# Crear tween para desvanecer después de 1.5 segundos
	feedback_tween = create_tween()
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 3.0).set_delay(1.5)


func _on_score_updated(new_score: int) -> void:
	score_value.text = str(new_score)


func _on_streak_updated(new_streak: int) -> void:
	streak_value.text = str(new_streak) + "/" + str(GameManager.max_streak_to_unlock)

	# Cambiar color según racha
	if new_streak > 0:
		streak_value.modulate = Color("#4ade80")  # Verde
	else:
		streak_value.modulate = Color("#fbbf24")  # Amber


func _on_gate_unlocked() -> void:
	_show_feedback("¡PUERTA DESBLOQUEADA! ¡Búscala!", Color("#fbbf24"))

	# Matar el tween para que el feedback no se desvanezca
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()


func _on_level_reset() -> void:
	current_challenge = {}
	_show_feedback("¡Error! Cubos reseteados. Inténtalo de nuevo.", Color("#f87171"))
	refresh_keyboard()


func refresh_keyboard() -> void:
	_generate_keyboard()


func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
