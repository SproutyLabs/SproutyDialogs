@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogBox
extends Panel

signal continue_dialog

## Max number of characters to display in the dialog box.
## The dialog will be split according to this limit and displayed in parts.
@export var max_characters_to_display : int = 0
## Time between typing dialog characters, controls the speed of text display.
## The higher the value, the slower the text is displayed.
@export var type_time : float = 0.05

@export_category("Input Actions")
## Input action to continue dialogue (for default press enter or space key).
@export var continue_input_action : StringName = "ui_accept"
## Input action to skip dialogue animation (for default press escape key).
@export var skip_input_action : StringName = "ui_accept"

@export_category("Dialog Box Components")
## Rich Text Label where character name will be displayed.
@export var name_display : RichTextLabel
## Rich Text Label where dialogue will be displayed.
@export var dialog_display : RichTextLabel
## Visual indicator to indicate press for continue the dialogue (like an arrow).
@export var continue_indicator : Control

@onready var type_timer : Timer = Timer.new()

var _display_completed : bool = false
var _sentences : Array[String] = []
var _current_sentence : int = 0

var _dialog_player : DialogPlayer

func _ready() -> void:
	add_child(type_timer)
	type_timer.wait_time = type_time
	type_timer.connect("timeout", _on_type_timer_timeout)
	
	dialog_display.bbcode_enabled = true
	continue_indicator.visible = false
	hide()

func _input(event: InputEvent) -> void:
	if _dialog_player and _dialog_player.is_running():
		if not _display_completed and Input.is_action_just_pressed(skip_input_action):
			# Skip dialog animation and show the entire text
			dialog_display.visible_characters = dialog_display.text.length()
			type_timer.stop()
			_on_display_completed()
		elif _display_completed and Input.is_action_just_pressed(continue_input_action):
				# Continue to the next dialog
				if _current_sentence < _sentences.size() - 1:
					# Display next sentence
					_current_sentence += 1
					_display_new_sentence(_sentences[_current_sentence])
				else: # Continue with the next dialog node
					continue_dialog.emit()

func play_dialog(char : String , dialog : String, player : DialogPlayer) -> void:
	# Play a dialog on dialog box
	if not visible: 
		# Start a new dialog
		_dialog_player = player
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

func end_dialog() -> void:
	# TODO: Allow to close dialog box with an animation
	_display_completed = false
	_current_sentence = 0
	_sentences = []
	hide()

func _split_dialog(dialog : String) -> Array[String]:
	# Split dialog when text is longer than character limit
	if max_characters_to_display == 0:
		return [dialog]
	
	if dialog.length() > max_characters_to_display:
		# Dialog splitting by character limit
		var words : Array = dialog.split(" ")
		var sentences : Array[String] = []
		var clean_sentence : String = ""
		var sentence : String = ""
		var opened_tags = []
		
		# Regex to get bbcodes tags from text
		var regex_tags = RegEx.new()
		regex_tags.compile("\\[.*?\\]")
		
		for word in words:
			# Add each word without tags until reach the characters limit
			var clean_word = regex_tags.sub(word, "", true)
			var aux_sentence = clean_sentence + " " + clean_word
			if aux_sentence.length() < max_characters_to_display:
				sentence += " " + word
				clean_sentence += "" + clean_word
			else:
				# Add remaining open tags from the previous sentence
				if not opened_tags.is_empty():
					for tag in opened_tags:
						sentence = tag + sentence
					opened_tags = []
				
				# Get the open tags in sentence to add them to the next one
				var all_tags = regex_tags.search_all(sentence)
				all_tags = all_tags.map(func(tag): return tag.get_string())
				
				var closed_tags = []
				for i in all_tags.size():
					# Look for openings tags
					if not all_tags[i].begins_with("[/"):
						var tag = all_tags[i].split("=")[0]\
								.replace("[", "").replace("]", "")
						# Look for closing tags and get its opening tag
						for j in range(1, all_tags.size()):
							if all_tags[j].begins_with("[/"):
								if all_tags[j].contains(tag):
									closed_tags.append(all_tags[i])
									break
				# Get tags that do not have a closing tag
				opened_tags = all_tags.filter(
					func(tag): return not tag.begins_with("[/")\
							and not closed_tags.has(tag)
					)
				sentences.append(sentence)
				clean_sentence = ""
				sentence = ""
		return sentences
	return [dialog]

func _display_new_sentence(sentence : String) -> void:
	# Display a new sentence
	dialog_display.text = sentence
	dialog_display.visible_characters = 0
	continue_indicator.visible = false
	_display_completed = false
	type_timer.start()

func _on_type_timer_timeout() -> void:
	# Type next character of the dialog when type timer ends
	if dialog_display.visible_characters < dialog_display.text.length():
		dialog_display.visible_characters += 1
	else:
		type_timer.stop()
		_on_display_completed()

func _on_display_completed() -> void:
	# when it finishes displaying a text
	continue_indicator.visible = true
	_display_completed = true

func _on_dialog_ended() -> void:
	# When the dialog is finished, close the dialog box
	end_dialog()
