extends Node

# Variables de estado del juego
var current_level: int = 1
var score: int = 0
var streak: int = 0
var max_streak_to_unlock: int = 20
var selected_notes: Array = []
var selected_instrument: String = "Piano"
var is_playing: bool = false

# Constantes
const NOTES: PackedStringArray = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const NOTE_COLORS: Array[Color] = [
	Color.RED,
	Color("#ff4500"),
	Color.ORANGE,
	Color("#ffd700"),
	Color.YELLOW,
	Color("#9acd32"),
	Color.GREEN,
	Color("#00ced1"),
	Color.BLUE,
	Color("#8a2be2"),
	Color("#ee82ee"),
	Color("#c71585")
]

# Señales
signal streak_updated(new_streak: int)
signal gate_unlocked
signal score_updated(new_score: int)
signal level_reset


func _ready() -> void:
	print("GameManager initialized")


func check_answer(guessed_index: int, challenge: Dictionary) -> bool:
	if guessed_index == challenge["note_index"]:
		streak += 1
		score += 1
		streak_updated.emit(streak)
		score_updated.emit(score)
		if streak >= max_streak_to_unlock:
			gate_unlocked.emit()
		print("✅ Correct! Streak: ", streak, " | Score: ", score)
		return true
	else:
		streak = 0
		score = 0
		streak_updated.emit(streak)
		score_updated.emit(score)
		level_reset.emit()
		print("❌ Wrong! Level reset - all cubes respawned.")
		return false


func reset_level_state() -> void:
	score = 0
	streak = 0
	print("Level state reset")


func load_next_level() -> void:
	current_level += 1
	reset_level_state()
	var level_path: String = "res://scenes/levels/Level%02d.tscn" % current_level
	print("Loading level: ", level_path)
	get_tree().change_scene_to_file(level_path)


func set_selected_notes(notes: Array) -> void:
	selected_notes = notes
	print("Selected notes: ", selected_notes)


func get_note_color(note_index: int) -> Color:
	if note_index >= 0 and note_index < NOTE_COLORS.size():
		return NOTE_COLORS[note_index]
	return Color.WHITE
