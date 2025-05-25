extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func strike():
    # Play the strike animation
    animation_player.play("strike")