class_name Mallot
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_sound_effect: AudioStreamPlayer = $"Hit Sound Effect"

signal struck()

func _ready() -> void:
	ArduinoConn.KnockDetected.connect(strike)

func strike(knock: int = 0) -> void:
	# Emit the struck signal
	struck.emit()

	# Play the strike animation
	animation_player.play("strike")

# Called when input
func _input(event: InputEvent) -> void:
	if ArduinoConn.IsConnected():
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_X:
			strike()
