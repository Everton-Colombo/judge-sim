extends Button

# Scale factors
var original_scale = Vector2(1, 1)
@export var hover_scale = Vector2(1.1, 1.1) # 10% larger when hovered
@export var tween_duration = 0.2

func _ready():
	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Store original scale
	original_scale = scale
	
	# Set pivot to center of button
	pivot_offset = size / 2

func _on_mouse_entered():
	# Create tween to scale up
	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, tween_duration)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	# Create tween to scale back down
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, tween_duration)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
