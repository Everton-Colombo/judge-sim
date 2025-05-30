class_name GameManager

extends Node

signal case_completed(case_index: int, player_decision: String)
signal all_cases_completed()

@export var cases_folder_path: String = "res://assets/cases/"

var cases: Array[Case] = []
var current_case_index: int = 0
var total_cases: int = 5

@onready var paper_document: PaperDocument = $UILayer/UI/MarginContainer/PaperDocument
@onready var mallot: Mallot = $ContentLayer/Mallot
@onready var scale: Scale = $ContentLayer/Scale

@onready var ui: UI = $UILayer/UI

var results_scene: PackedScene = preload("res://scenes/screens/ResultsScreen.tscn")

func _ready():
	mallot.struck.connect(on_mallot_struck)
	
	GameData.clear_data()
	
	load_all_cases()
	display_current_case()

# Displays the current case
func display_current_case():
	var current_case = get_current_case()
	if current_case == null:
		push_error("No current case available.")
		return
	
	# Every time the current case is displayed, update verdict info
	record_case_data()

	var verdict_info: Dictionary = {
		"text": null,
		"type": null
	}
	var current_decisions: Dictionary = GameData.get_decisions()[current_case_index]
	
	verdict_info["text"] = current_decisions["presented_verdict_text"]
	verdict_info["type"] = current_decisions["presented_verdict_type"]
	
	paper_document.load_case(current_case, verdict_info)

func on_mallot_struck():
	var current_case = get_current_case()
	if current_case == null:
		push_error("No current case available.")
		return
	
	record_player_decision(scale.scale_position)
	await get_tree().create_timer(0.75).timeout
	await ui.play_splash_animation(scale.scale_position)
	if not next_case():
		# Store results in singleton before changing scenes
		GameData.set_game_results(get_results())
		get_tree().change_scene_to_packed(results_scene)
	else:
		display_current_case()

## Loads all Case resource files from the specified folder
func load_all_cases() -> void:
	cases.clear()
	
	var dir = DirAccess.open(cases_folder_path)
	if dir == null:
		push_error("Failed to open cases directory: " + cases_folder_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var file_path = cases_folder_path + file_name
			var case_resource = load(file_path) as Case
			
			if case_resource != null:
				cases.append(case_resource)
				print("Loaded case: ", case_resource.title)
			else:
				push_warning("Failed to load case from: " + file_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	cases.shuffle()
	if cases.size() > total_cases:
		cases = cases.slice(0, total_cases)
	
	print("Loaded ", cases.size(), " cases")
	GameData.set_cases(cases)

func get_current_case() -> Case:
	if current_case_index < cases.size():
		return cases[current_case_index]
	return null

# Get random case verdict
func get_current_case_verdict() -> Dictionary:
	var current_case = get_current_case()
	if current_case == null:
		return {}
	
	var verdict_types = ["correct", "lenient", "harsh"]
	var selected_type = verdict_types[randi() % verdict_types.size()]
	
	var verdict_text: String
	match selected_type:
		"correct":
			verdict_text = current_case.correct_verdict
		"lenient":
			verdict_text = current_case.lenient_verdict
		"harsh":
			verdict_text = current_case.harsh_verdict
	
	return {
		"type": selected_type,
		"text": verdict_text
	}

# Records the current case data
func record_case_data() -> void:
	# Chooses the proposed verdict for this case
	var presented_verdict: Dictionary = get_current_case_verdict()

	var case_data = {
		"case_index": current_case_index,
		"case_title": get_current_case().title,
		"presented_verdict_type": presented_verdict["type"],
		"presented_verdict_text": presented_verdict["text"],
		"timestamp": 0,
		"player_choice": null
	}
	
	GameData.get_decisions().append(case_data)

# Records the player's decision
func record_player_decision(scale_position: String) -> void:
	# Gets the current dictionary of player decisions
	var current_decisions: Dictionary = GameData.get_decisions()[current_case_index]
	
	# Updates the dict with the player decision
	current_decisions["player_choice"] = scale_position
	current_decisions["timestamp"] = Time.get_unix_time_from_system()
	
	case_completed.emit(current_case_index, scale_position)
	print("Recorded decision for case: ", current_decisions["case_title"], " - Player chose: ", scale_position)

# Checks if there is a next case
func next_case() -> bool:
	current_case_index += 1
	
	if current_case_index >= cases.size():
		all_cases_completed.emit()
		return false
	
	return true

# Matches the player choice with the decision
func is_decision_correct(player_choice: String, verdict_type: String) -> bool:
	match verdict_type:
		"correct":
			return player_choice == "center"
		"lenient":
			return player_choice == "right" # too lenient, should be harsher
		"harsh":
			return player_choice == "left" # too harsh, should be more lenient
	
	return false

# Returns the final results for each case
func get_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for i in range(GameData.get_decisions().size()):
		var decision = GameData.get_decisions()[i]
		var case_data = cases[decision.case_index]
		
		var is_correct = is_decision_correct(
			decision["player_choice"],
			decision["presented_verdict_type"]
		)
		
		var result = {
			"case": case_data,
			"player_decision": decision,
			"was_correct": is_correct,
			"correct_verdict": case_data.correct_verdict,
			"explanation": case_data.explanation
		}
		
		results.append(result)
	
	return results

func reset_game() -> void:
	current_case_index = 0
	GameData.get_decisions().clear()
	load_all_cases()

func get_progress() -> Dictionary:
	return {
		"current": current_case_index + 1,
		"total": min(cases.size(), total_cases)
	}
