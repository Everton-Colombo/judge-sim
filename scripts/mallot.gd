extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_sound_effect: AudioStreamPlayer = $"Hit Sound Effect"

func strike():
	# Play the strike animation
	animation_player.play("strike")

# Called when input
func _input(event: InputEvent) -> void:
	# Calls the strike animation if the x key is pressed
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and not ArduinoConn.IsConnected():
		if event.keycode == KEY_X:
			strike()
