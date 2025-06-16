extends Node

var game_results: Array[Dictionary] = []
var current_cases: Array[Case] = []
var player_decisions: Array[Dictionary] = []

func set_game_results(results: Array[Dictionary]) -> void:
	game_results = results.duplicate(true) # Deep copy to avoid reference issues

func get_game_results() -> Array[Dictionary]:
	return game_results

func set_cases(cases: Array[Case]) -> void:
	current_cases = cases.duplicate(true)

func get_cases() -> Array[Case]:
	return current_cases

func get_decisions() -> Array[Dictionary]:
	return player_decisions

func set_decisions(decisions: Array[Dictionary]) -> void:
	player_decisions = decisions.duplicate(true)

func clear_data() -> void:
	game_results.clear()
	current_cases.clear()
	player_decisions.clear()

func get_summary_stats() -> Dictionary:
	if game_results.is_empty():
		return {}
	
	var correct_count = 0
	for result in game_results:
		if result.was_correct:
			correct_count += 1
	
	return {
		"total_cases": game_results.size(),
		"correct_answers": correct_count,
		"accuracy_percentage": (float(correct_count) / float(game_results.size())) * 100.0
	}
