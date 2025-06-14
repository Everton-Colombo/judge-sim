class_name Scale

extends Node2D

var max_rotation_angle: float = 30.0
var current_rotation: float = 0.0
var mouse_scale_mode: bool = false # For moving the scale with the mouse
var angle: float = 0.0

# Thresholds for scale position detection
@export var left_threshold: float = -10.0 # Degrees - anything below this is "left"
@export var right_threshold: float = 10.0 # Degrees - anything above this is "right"

@onready var left_basket: Sprite2D = $Arms/leftMarker/LeftBasket
@onready var right_basket: Sprite2D = $Arms/rightMarker/RightBasket

## Gets the current scale position as a string
var scale_position: String:
	get:
		if current_rotation <= left_threshold:
			return "left"
		elif current_rotation >= right_threshold:
			return "right"
		else:
			return "center"

func _ready():
	# Ensure baskets are initially positioned correctly
	update_basket_rotations(0)
	rotate_arms(30)

	ArduinoConn.ReadingsUpdated.connect(handle_readings)

func handle_readings(f_scale, knock):
	# Map from range [200, 490] to [-30, 30]
	var scale_mapped = -30 + (f_scale - 200) * 60.0 / 290.0
	rotate_arms(scale_mapped)

func rotate_arms(f_angle: float):
	# Limit the rotation to the max angle
	f_angle = clamp(f_angle, -max_rotation_angle, max_rotation_angle)
	$Arms.rotation_degrees = f_angle
	current_rotation = f_angle
	
	# Update baskets to maintain downward orientation
	update_basket_rotations(f_angle)

func update_basket_rotations(arm_angle: float):
	# Counter-rotate baskets to maintain absolute 0 rotation
	# The basket needs to rotate by the negative of the arm's rotation
	if left_basket:
		left_basket.rotation_degrees = - arm_angle
	
	if right_basket:
		right_basket.rotation_degrees = - arm_angle

func _process(_delta: float) -> void:
	if ArduinoConn.IsConnected():
		return

	if mouse_scale_mode:
		var mouse_x = get_viewport().get_mouse_position().x
		var viewport_center_x = get_viewport().size.x / 2
		angle = (mouse_x - viewport_center_x) / 4.0
		
	rotate_arms(angle)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			mouse_scale_mode = not mouse_scale_mode
