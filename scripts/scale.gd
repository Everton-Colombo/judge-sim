class_name Scale

extends Node2D

var max_rotation_angle: float = 30.0
var current_rotation: float = 0.0

@export var left_basket: Sprite2D
@export var right_basket: Sprite2D

func _ready():
    # Ensure baskets are initially positioned correctly
    update_basket_rotations(0)
    rotate_arms(30)

func rotate_arms(angle: float):
    # Limit the rotation to the max angle
    angle = clamp(angle, -max_rotation_angle, max_rotation_angle)
    $Arms.rotation_degrees = angle
    current_rotation = angle
    
    # Update baskets to maintain downward orientation
    update_basket_rotations(angle)

func update_basket_rotations(arm_angle: float):
    # Counter-rotate baskets to maintain absolute 0 rotation
    # The basket needs to rotate by the negative of the arm's rotation
    if left_basket:
        left_basket.rotation_degrees = -arm_angle
    
    if right_basket:
        right_basket.rotation_degrees = -arm_angle
