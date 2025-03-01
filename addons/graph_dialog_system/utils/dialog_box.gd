@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogBox
extends Panel

## -----------------------------------------------------------------------------
## Dialog Box to display dialogues
## -----------------------------------------------------------------------------

## Signal to continue the dialog tree when the player press the continue button.
signal continue_dialog

## Max number of characters to display in the dialog box.[br][br]
## The dialog will be split according to this limit and displayed in parts.
@export var max_characters_to_display: int = 0
## Time between typing dialog characters, controls the [b]speed[/b] of text display.
## [br][br][i]The higher the value, the slower the text is displayed.[/i]
@export var type_time: float = 0.05

@export_category("Input Actions")
## Input action to continue dialogue.[br][br]
## (For default press [kbd]enter[/kbd] or [kbd]space[/kbd] key).
@export var continue_input_action: StringName = "ui_accept"
## Input action to skip dialogue animation. [br][br]
## (For default press [kbd]enter[/kbd] or [kbd]space[/kbd] key).
@export var skip_input_action: StringName = "ui_accept"

@export_category("Dialog Box Components")
## [RichTextLabel] where character name will be displayed.
@export var name_display: RichTextLabel
## [RichTextLabel] where dialogue will be displayed.
@export var dialog_display: RichTextLabel
## Visual indicator to indicate press for continue the dialogue (like an arrow).
@export var continue_indicator: Control

## Timer to control the typing speed of the dialog.
@onready var type_timer: Timer = Timer.new()

## Flag to control if the dialog is completed.
var _display_completed: bool = false
## Array to store the dialog sentences.
var _sentences: Array[String] = []
## Index of the current sentence being displayed.
var _current_sentence: int = 0

## Dialog player to play the dialog.
var _dialog_player: DialogPlayer


func _ready() -> void:
	# Set up timer to control the typing speed of the dialog
	add_child(type_timer)
	type_timer.wait_time = type_time
	type_timer.connect("timeout", _on_type_timer_timeout)
	
	# Set up dialog box settings
	dialog_display.bbcode_enabled = true
	continue_indicator.visible = false
	hide()


func _input(event: InputEvent) -> void:
	# Handle input events to continue or skip dialog
	if _dialog_player and _dialog_player.is_running():
		# Skip dialog animation and show the entire text
		if (not _display_completed
			and Input.is_action_just_pressed(skip_input_action)):
			dialog_display.visible_characters = dialog_display.text.length()
			type_timer.stop()
			_on_display_completed()
		# Continue dialog when the player press the continue button
		elif _display_completed and Input.is_action_just_pressed(continue_input_action):
				if _current_sentence < _sentences.size() - 1: # Display next sentence
					_current_sentence += 1
					_display_new_sentence(_sentences[_current_sentence])
				else: # Continue with the next dialog node
					continue_dialog.emit()


## Play a dialog on dialog box
func play_dialog(char: String, dialog: String, player: DialogPlayer) -> void:
	if not visible: # Start a new dialog
		_dialog_player = player
		# Connect dialog ended signal to close the dialog box
		if not _dialog_player.is_connected("dialog_ended", _on_dialog_ended):
			_dialog_player.connect("dialog_ended", _on_dialog_ended)
		
		# TODO: Allow to open dialog box with an animation
		show()
	
	name_display.text = char
	dialog_display.text = dialog
	print(char + " : " + dialog)
	
	# Display dialog by characters limit
	_sentences = []
	_current_sentence = 0
	_display_completed = false
	_sentences = _split_dialog(dialog)
	_display_new_sentence(_sentences[_current_sentence])


## End the dialog and close the dialog box
func end_dialog() -> void:
	# TODO: Allow to close dialog box with an animation
	_display_completed = false
	_current_sentence = 0
	_sentences = []
	hide()


## Split dialog by characters limit
func _split_dialog(dialog: String) -> Array[String]:
	if max_characters_to_display == 0:
		return [dialog]
	
	if dialog.length() > max_characters_to_display:
		var words: Array = dialog.split(" ")
		var sentences: Array[String] = []
		var clean_sentence: String = ""
		var sentence: String = ""
		var opened_tags = []
		var next_sentence_tags = []
		
		# Regex to get bbcodes tags from text
		var regex_tags = RegEx.new()
		regex_tags.compile("\\[.*?\\]")
		
		for word in words:
			# Add each word without bbcode tags to count the characters
			var clean_word = regex_tags.sub(word, "", true)
			var aux_sentence = clean_sentence + " " + clean_word

			# When not reach the limit, add the word to the sentence -----------
			if aux_sentence.length() < max_characters_to_display:
				sentence += " " + word
				clean_sentence += "" + clean_word
			
				# Get opened bbcode tags from the word and add to the list -----
				var tags = regex_tags.search_all(word).map(
					func(tag): return tag.get_string()
				)
				for tag in tags:
					if tag.begins_with("[/"): # Tag is a closing tag
						var tag_begin = tag.replace("[/", "[").replace("]", "")
						# Find the opening tag to remove from the list
						var open_tag_index = opened_tags.find(
							func(open_tag): return open_tag.begins_with(tag_begin)
						)
						if open_tag_index: # Remove the opening tag
							print("\nClosing tag: " + tag)
							print("Remove tag: " + opened_tags[open_tag_index])
							opened_tags.erase(opened_tags[open_tag_index])
							print("Opened tags: " + str(opened_tags))
						
					else: # Add the opening tag to the list
						opened_tags.append(tag)
						print("\nAdd opening tag: " + tag)
						print("Opened tags: " + str(opened_tags))
			
			else: # When reach the limit, add the sentence to the list ---------
				# Add opened tags from previous sentence on the beginning
				sentence = _add_tags_to_sentence(sentence, next_sentence_tags)
				next_sentence_tags = opened_tags.duplicate()
				print("\nAdd sentence: " + sentence)
				print("\nNext sentence tags: " + str(next_sentence_tags))

				# Add the sentence to the list
				sentences.append(sentence)
				clean_sentence = ""
				sentence = ""
		
		# Add the last sentence to the list -----------------------------------
		if sentence != "":
			sentence = _add_tags_to_sentence(sentence, next_sentence_tags)
			print("\nAdd last sentence: " + sentence)
			sentences.append(sentence)
		return sentences
	return [dialog]

## Add tags to the beginning of the sentence
func _add_tags_to_sentence(sentence: String, tags: Array) -> String:
	var tags_string = ""
	for tag in tags:
		tags_string += tag
	sentence = tags_string + sentence
	return sentence

## Display a new sentence
func _display_new_sentence(sentence: String) -> void:
	dialog_display.text = sentence
	dialog_display.visible_characters = 0
	continue_indicator.visible = false
	_display_completed = false
	type_timer.start()


## Timer to type the dialog characters
func _on_type_timer_timeout() -> void:
	if dialog_display.visible_characters < dialog_display.text.length():
		dialog_display.visible_characters += 1
	else:
		type_timer.stop()
		_on_display_completed()


## When the dialog finishes displaying a text
func _on_display_completed() -> void:
	continue_indicator.visible = true
	_display_completed = true


## When the dialog ends, close the dialog box
func _on_dialog_ended() -> void:
	end_dialog()
