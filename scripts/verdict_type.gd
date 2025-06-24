extends RichTextLabel
@onready var judge_scale: Scale = $"../../ContentLayer/Scale"

func _ready() -> void:
	# Ativa o uso de formatação
	set_use_bbcode(true)
	
func _process(_delta: float) -> void:
	var temp_text: String = "PLACHEHOLDER"
	# Muda o texto conforme a posição da balança
	match judge_scale.scale_position:
		"left":
			temp_text = "MAIS LENIENTE!"
		"right":
			temp_text = "MAIS RÍGIDO!"
		"center":
			temp_text = "APROPRIADO!"
			
	text = "[center]%s[/center]" %temp_text
