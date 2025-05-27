extends Node2D

@onready var paper_document: PaperDocument = $UILayer/UI/MarginContainer/PaperDocument

func _ready() -> void:
	var game_results = GameData.get_game_results()
	if game_results.is_empty():
		push_error("No game results found!")
		return
	
	# Load results into the paper document
	paper_document.load_results(game_results)
