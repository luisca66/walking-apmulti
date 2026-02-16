extends Area3D

signal player_crossed_gate
var is_active: bool = false

func _ready():
	collision_layer = 0
	collision_mask = 1  # Detectar al jugador
	body_entered.connect(_on_body_entered)

func activate():
	is_active = true

func _on_body_entered(body: Node3D):
	if not is_active:
		return
	if body is CharacterBody3D:
		is_active = false
		player_crossed_gate.emit()
