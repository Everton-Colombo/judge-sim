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


func format_case_to_rich_text(case_data: Case) -> String:
	var formatted_text = ""
	
	# Format title - centered with large font
	formatted_text += "[center][font_size=36]" + case_data.title + "[/font_size][/center]\n\n"
	
	# Format description section
	formatted_text += "[font_size=24]Description[/font_size]\n"
	formatted_text += case_data.description + "\n\n"
	
	# Format verdict section
	formatted_text += "[font_size=24]Proposed Verdict[/font_size]\n"
	formatted_text += case_data.correct_verdict + "\n\n"
	
	return formatted_text
