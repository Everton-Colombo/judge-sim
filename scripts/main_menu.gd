extends Control

@onready var start_button: Button = $ButtonContainer/Start
@onready var quit_button: Button = $ButtonContainer/Quit
@onready var music_button: Button = $ButtonContainer/Music

func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	music_button.pressed.connect(_on_music_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_music_pressed() -> void:
	if Music.playing:
		Music.stop()
	else:
		Music.play()


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/TutorialScreen.tscn")
