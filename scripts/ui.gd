class_name UI

extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var splash_decision_label: Label = $SplashLabelContainer/VBoxContainer/DecisionLabel

func play_splash_animation(decision: String) -> void:
    splash_decision_label.text = decision.to_upper()
    animation_player.play("splash")
    await animation_player.animation_finished