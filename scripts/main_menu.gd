extends Control

var music_playing: bool = true

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_music_pressed() -> void:
	if music_playing:
		Music.stop()
	else:
		Music.play()
	music_playing = not music_playing
