class_name PaperDocument
extends TextureRect

# Text content
var full_text: String = ""
var pages: Array[String] = []
var current_page: int = 0
@export var characters_per_page: int = 700

@export var case: Case

@onready var text_content: RichTextLabel = $TextContainer/TextContent
@onready var next_btn: Button = $ButtonContainer/NextPageButton
@onready var prev_btn: Button = $ButtonContainer/PrevPageButton
@onready var page_indicator: RichTextLabel = $PageText
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	print("Paper document ready")
	if case:
		set_document_text(format_case_to_rich_text(case))
	else:
		set_document_text("No document text set.")
	
	prev_btn.pressed.connect(go_to_previous_page)
	next_btn.pressed.connect(go_to_next_page)

func set_document_text(text: String):
	full_text = text
	split_into_pages()
	display_current_page()
	update_buttons()

func split_into_pages():
	pages.clear()
	
	# Text processing variables
	var remaining_text = full_text
	var page_break_char = "|" # Configurable special character for page breaks
	
	while remaining_text.length() > 0:
		var break_point = -1
		
		# Look for the special character
		break_point = remaining_text.find(page_break_char)
		
		# If no special character is found, use the entire remaining text
		if break_point == -1:
			break_point = remaining_text.length()
		
		# Ensure we're making progress (min 1 character)
		break_point = max(1, break_point)
		break_point = min(break_point, remaining_text.length())
		
		# Add page and update remaining text
		pages.append(remaining_text.substr(0, break_point))
		remaining_text = remaining_text.substr(break_point + 1 if break_point < remaining_text.length() else break_point)
	
	# Update total pages
	update_page_indicator()

func display_current_page():
	audio_player.play()

	if pages.size() > 0 and current_page < pages.size():
		text_content.text = pages[current_page]
	else:
		text_content.text = ""

func go_to_next_page():
	if current_page < pages.size() - 1:
		current_page += 1
		display_current_page()
		update_buttons()
		update_page_indicator()

func go_to_previous_page():
	if current_page > 0:
		current_page -= 1
		display_current_page()
		update_buttons()
		update_page_indicator()

func update_buttons():
	prev_btn.visible = current_page > 0
	next_btn.visible = current_page < pages.size() - 1

func update_page_indicator():
	page_indicator.text = str(current_page + 1) + "/" + str(pages.size())


func format_case_to_rich_text(case_data: Case, proposed_verdict: Dictionary = {}) -> String:
	var formatted_text = ""
	
	# Format title - centered with large font
	formatted_text += "[center][font_size=36]" + case_data.title + "[/font_size][/center]\n\n"
	
	# Format description section
	formatted_text += "[font_size=24]Description[/font_size]\n"
	formatted_text += case_data.description + "\n\n"
	
	# Format verdict section
	formatted_text += "[font_size=24]Proposed Verdict[/font_size]\n"
	formatted_text += proposed_verdict.get("text", case_data.correct_verdict) + "\n\n"

	return formatted_text

func load_case(case_data: Case, proposed_verdict: Dictionary = {}):
	# Clear existing text
	full_text = ""
	pages.clear()
	current_page = 0
	
	# Set the case and format the text
	case = case_data
	set_document_text(format_case_to_rich_text(case, proposed_verdict))
	
	# Reset page state
	display_current_page()
	update_buttons()
	update_page_indicator()

func load_results(results: Array[Dictionary]) -> void:
	# Clear existing text
	full_text = ""
	pages.clear()
	current_page = 0
	
	# Format results into rich text
	var formatted_text = format_results_to_rich_text(results)
	set_document_text(formatted_text)
	
	# Reset page state
	display_current_page()
	update_buttons()
	update_page_indicator()

func format_results_to_rich_text(results: Array[Dictionary]) -> String:
	var formatted_text = ""
	
	# Title
	formatted_text += "[center][font_size=42][color=#8B4513]JUDGMENT RESULTS[/color][/font_size][/center]\n\n"
	
	# Calculate summary statistics
	var correct_count = 0
	var total_cases = results.size()
	for result in results:
		if result.was_correct:
			correct_count += 1
	
	var accuracy = (float(correct_count) / float(total_cases)) * 100.0 if total_cases > 0 else 0.0
	
	# Summary section
	formatted_text += "[center][font_size=28]SUMMARY[/font_size][/center]\n"
	formatted_text += "[center]Cases Judged: %d[/center]\n" % total_cases
	formatted_text += "[center]Correct Decisions: %d[/center]\n" % correct_count
	formatted_text += "[center][color=%s]Accuracy: %.1f%%[/color][/center]\n\n" % [
		get_accuracy_color(accuracy),
		accuracy
	]
	
	# Performance assessment
	var performance_text = get_performance_assessment(accuracy)
	formatted_text += "[center][font_size=20]%s[/font_size][/center]\n\n" % performance_text
	
	# Separator PAGE BREAK
	formatted_text += "[center]═══════════════════════════════[/center]|\n\n"
	
	# Individual case results
	for i in range(results.size()):
		var result = results[i]
		formatted_text += format_individual_case_result(result, i + 1)
		
		# Add page break suggestion after each case (except the last)
		if i < results.size() - 1:
			# PAGE BREAK
			formatted_text += "\n[center]───────────────────[/center]|\n\n"
	
	return formatted_text

func format_individual_case_result(result: Dictionary, case_number: int) -> String:
	var case_text = ""
	var case_data = result.case
	var decision = result.player_decision
	
	# Case header with result status
	var status_color = "#2D5016" if result.was_correct else "#8B0000"
	var status_text = "✓ CORRECT" if result.was_correct else "✗ INCORRECT"
	
	case_text += "[font_size=24]CASE %d: %s[/font_size]\n" % [case_number, case_data.title]
	case_text += "[color=%s][font_size=20]%s[/font_size][/color]\n\n" % [status_color, status_text]
	
	# Case description (abbreviated)
	var description_preview = case_data.description
	if description_preview.length() > 200:
		description_preview = description_preview.substr(0, 200) + "..."
	case_text += "[font_size=16]%s[/font_size]\n\n" % description_preview
	
	# Presented verdict and player decision
	#PAGE BREAK
	case_text += "|[font_size=18][color=#B8860B]Presented Verdict:[/color][/font_size]\n"
	case_text += "%s\n\n" % decision["presented_verdict_text"]
	
	case_text += "[font_size=18][color=#4682B4]Your Decision:[/color][/font_size]\n"
	case_text += "Scale Position: [font_size=16]%s[/font_size]\n" % decision["player_choice"].to_upper()
	case_text += "Verdict Type: [font_size=16]%s[/font_size]\n\n" % decision["presented_verdict_type"].to_upper()
	
	# Correct information
	case_text += "[font_size=18][color=#2D5016]Correct Verdict:[/color][/font_size]\n"
	case_text += "%s\n\n" % case_data.correct_verdict
	
	# Explanation if available
	if not case_data.explanation.is_empty():
		# PAGE BREAK
		case_text += "|[font_size=18][color=#CD853F]Legal Explanation:[/color][/font_size]\n"
		case_text += "%s\n\n" % case_data.explanation
	
	# Decision analysis
	# PAGE BREAK
	case_text += "|[font_size=16][color=#696969]Analysis:[/color][/font_size]\n"
	case_text += get_decision_analysis(decision["presented_verdict_type"], decision["player_choice"], result.was_correct)
	
	return case_text

func get_accuracy_color(accuracy: float) -> String:
	if accuracy >= 80.0:
		return "#2D5016" # Dark green
	elif accuracy >= 60.0:
		return "#B8860B" # Dark goldenrod
	elif accuracy >= 40.0:
		return "#CD853F" # Peru/brown
	else:
		return "#8B0000" # Dark red

func get_performance_assessment(accuracy: float) -> String:
	if accuracy >= 90.0:
		return "Outstanding judicial wisdom! You have the makings of a Supreme Court Justice."
	elif accuracy >= 80.0:
		return "Excellent judgment! Your decisions show strong legal reasoning."
	elif accuracy >= 70.0:
		return "Good performance. You demonstrate solid understanding of justice."
	elif accuracy >= 60.0:
		return "Fair judgment. Consider reviewing legal principles for improvement."
	elif accuracy >= 50.0:
		return "Below average. More study of legal precedents is recommended."
	else:
		return "Concerning performance. Extensive legal training is strongly advised."

func get_decision_analysis(verdict_type: String, player_choice: String, was_correct: bool) -> String:
	var analysis = ""
	
	if was_correct:
		match verdict_type:
			"correct":
				analysis = "You correctly identified this as an appropriate verdict. Well done!"
			"lenient":
				analysis = "You correctly identified this verdict as too lenient and chose a harsher stance."
			"harsh":
				analysis = "You correctly identified this verdict as too harsh and chose a more lenient stance."
	else:
		match verdict_type:
			"correct":
				if player_choice == "left":
					analysis = "This was actually an appropriate verdict, but you deemed it too harsh."
				else:
					analysis = "This was actually an appropriate verdict, but you deemed it too lenient."
			"lenient":
				if player_choice == "center":
					analysis = "This verdict was too lenient, but you considered it appropriate."
				else:
					analysis = "This verdict was too lenient, but you made it even more lenient."
			"harsh":
				if player_choice == "center":
					analysis = "This verdict was too harsh, but you considered it appropriate."
				else:
					analysis = "This verdict was too harsh, but you made it even harsher."
	
	return analysis + "\n"
