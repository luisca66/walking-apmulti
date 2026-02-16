extends CanvasLayer

@onready var panel: ColorRect = $Panel
@onready var title: Label = $Panel/Center/Title
@onready var stats: Label = $Panel/Center/Stats
@onready var restart_button: Button = $Panel/Center/RestartButton

func _ready():
	visible = false
	restart_button.pressed.connect(_on_restart)

func show_victory(score: int):
	visible = true
	title.text = "¡NIVEL COMPLETADO!"
	stats.text = "Aciertos totales: %d\n¡Felicidades!" % score

	# Fade in del fondo
	panel.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(panel, "color", Color(0, 0, 0, 0.85), 1.0)

	get_tree().paused = true

func _on_restart():
	get_tree().paused = false
	visible = false
	GameManager.reset_level_state()
	get_tree().reload_current_scene()
