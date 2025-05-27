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
	
	# Get font metrics for better approximation
	var font = text_content.get_theme_font("normal_font")
	if font == null:
		font = text_content.get_theme_font("font")
	
	var font_size = text_content.get_theme_font_size("normal_font_size")
	if font_size <= 0:
		font_size = text_content.get_theme_font_size("font_size")
	if font_size <= 0:
		font_size = 16 # Default fallback
	
	# Calculate available space (if possible)
	var available_width = text_content.size.x - text_content.get_theme_constant("margin_left") - text_content.get_theme_constant("margin_right")
	
	# Approximate chars per line
	var avg_char_width = font_size * 0.6 # Rough estimate
	var chars_per_line = int(available_width / avg_char_width)
	
	# Use a more accurate chars per page calculation
	var chars_per_page = characters_per_page
	if chars_per_line > 0:
		# Adjust based on estimated line length
		chars_per_page = chars_per_line * (characters_per_page / 80) # Assuming default was based on 80 chars per line
	
	while remaining_text.length() > 0:
		var target_length = min(chars_per_page, remaining_text.length())
		var break_point = target_length
		
		# Try to find natural break points if we're not at the end
		if target_length < remaining_text.length():
			# Look for paragraph breaks (double newline)
			var paragraph_break = -1
			for i in range(target_length - 1, int(target_length * 0.7), -1):
				if i >= 0 and i < remaining_text.length() - 1 and remaining_text[i] == "\n" and remaining_text[i + 1] == "\n":
					paragraph_break = i
					break
			
			# Look for single newlines
			var newline_break = -1
			if paragraph_break < 0:
				for i in range(target_length - 1, int(target_length * 0.8), -1):
					if i >= 0 and remaining_text[i] == "\n":
						newline_break = i
						break
			
			# Look for sentence breaks (period followed by space)
			var sentence_break = -1
			if paragraph_break < 0 and newline_break < 0:
				for i in range(target_length - 1, int(target_length * 0.8), -1):
					if i >= 0 and i < remaining_text.length() - 1 and remaining_text[i] == "." and remaining_text[i + 1] == " ":
						sentence_break = i
						break
			
			# Look for word breaks (spaces)
			var word_break = -1
			if paragraph_break < 0 and newline_break < 0 and sentence_break < 0:
				word_break = remaining_text.rfind(" ", target_length)
				if word_break < int(target_length * 0.7):
					word_break = -1 # Too far back, don't use it
			
			# Choose the best break point
			if paragraph_break > 0:
				break_point = paragraph_break + 2 # Include the double newlines
			elif newline_break > 0:
				break_point = newline_break + 1 # Include the newline
			elif sentence_break > 0:
				break_point = sentence_break + 2 # Include period and space
			elif word_break > 0:
				break_point = word_break + 1 # Include the space
		
		# Ensure we're making progress (min 1 character)
		break_point = max(1, break_point)
		break_point = min(break_point, remaining_text.length())
		
		# Add page and update remaining text
		pages.append(remaining_text.substr(0, break_point))
		remaining_text = remaining_text.substr(break_point)
	
	# Update total pages
	update_page_indicator()

func display_current_page():
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
	
	# Separator
	formatted_text += "[center]═══════════════════════════════[/center]\n\n"
	
	# Individual case results
	for i in range(results.size()):
		var result = results[i]
		formatted_text += format_individual_case_result(result, i + 1)
		
		# Add page break suggestion after each case (except the last)
		if i < results.size() - 1:
			formatted_text += "\n[center]───────────────────[/center]\n\n"
	
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
	case_text += "[font_size=18][color=#B8860B]Presented Verdict:[/color][/font_size]\n"
	case_text += "%s\n\n" % decision.presented_verdict_text
	
	case_text += "[font_size=18][color=#4682B4]Your Decision:[/color][/font_size]\n"
	case_text += "Scale Position: [font_size=16]%s[/font_size]\n" % decision.player_choice.to_upper()
	case_text += "Verdict Type: [font_size=16]%s[/font_size]\n\n" % decision.presented_verdict_type.to_upper()
	
	# Correct information
	case_text += "[font_size=18][color=#2D5016]Correct Verdict:[/color][/font_size]\n"
	case_text += "%s\n\n" % case_data.correct_verdict
	
	# Explanation if available
	if not case_data.explanation.is_empty():
		case_text += "[font_size=18][color=#CD853F]Legal Explanation:[/color][/font_size]\n"
		case_text += "%s\n\n" % case_data.explanation
	
	# Decision analysis
	case_text += "[font_size=16][color=#696969]Analysis:[/color][/font_size]\n"
	case_text += get_decision_analysis(decision.presented_verdict_type, decision.player_choice, result.was_correct)
	
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