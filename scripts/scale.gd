class_name Scale

extends Node2D

var max_rotation_angle: float = 30.0
var current_rotation: float = 0.0
var mouse_scale_mode: bool = false # For moving the scale with the mouse

@onready var not_arduino_readings: RichTextLabel = $"../Not Arduino Readings"
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

func _process(delta: float) -> void:
	if mouse_scale_mode and not ArduinoConn.IsConnected():
		var mouse_x = get_viewport().get_mouse_position().x
		var viewport_center_x = get_viewport().size.x / 2
		var angle = (mouse_x - viewport_center_x) / 4.0
		rotate_arms(angle)
		# Update RichTextLabel with formatted string
		not_arduino_readings.text = "Mouse Scale Mode: On\nMouse X: %.2f\nAngle: %.2f°" % [mouse_x, angle]
	else:
		# Display when mouse scale mode is off
		not_arduino_readings.text = "Mouse Scale Mode: Off"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			mouse_scale_mode = not mouse_scale_mode
			# Update label to reflect mode change
	
		
