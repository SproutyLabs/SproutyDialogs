@icon("res://addons/graph_dialogs/icons/icon.svg")
class_name DialogBox
extends Panel

# -----------------------------------------------------------------------------
## Dialog Box base class
##
## This class is responsible for displaying the dialogues in the game.
## It handles the display of the text and the character name in the dialog box.
##
## [br][br][i][color=red]This class should not be used directly by the user.
## [/color] Rather, it is used by a [DialogPlayer] to display the dialog.[/i]
# -----------------------------------------------------------------------------

## Emitted when the dialog is started.
signal dialog_starts(character_name: String)
## Emitted when the dialog ends typing.
signal dialog_typing_ends(character_name: String)
## Emitted when the dialog is ended.
signal dialog_ends(character_name: String)

## Emitted when the player press the continue button to continue the dialog tree 
signal continue_dialog
## Emitted when a meta tag is clicked in the dialog.
signal meta_clicked(meta: String)

## Typing speed of the dialog text in seconds.
@export var _typing_speed: float = GraphDialogsSettings.get_setting("default_typing_speed")
## Maximum number of characters to be displayed in the dialog box.[br][br]
## The dialogue will be split according to this limit and displayed in parts
## if the [param split_dialog_by_max_characters] setting is active.
@export var _max_characters: int = GraphDialogsSettings.get_setting("max_characters")

@export_category("Dialog Box Components")
## [RichTextLabel] where dialogue will be displayed.[br][br]
## [color=red]This component is required to display the text in it.[/color]
@export var _dialog_display: RichTextLabel
## [RichTextLabel] where character name will be displayed.[br][br]
## [color=red]If you want to display the character name in the dialog box, 
## you need to set this property.[/color]
@export var _name_display: RichTextLabel
## Visual indicator to indicate press for continue the dialogue (e.g. an arrow).
## [br][br][color=red]If you want to display a continue indicator in the
## dialog box,you need to set this property.[/color]
@export var _continue_indicator: Control
## [Node] where the character portrait will be displayed (portrait parent).[br][br]
## [color=red]If you want to display the portrait in the dialog box, 
## you need to set this property.[/color]
@export var _portrait_display: Node

## Timer to control the typing speed of the dialog.
var _type_timer: Timer
## Timer to control if the dialog can be skipped.
var _can_skip_timer: Timer
## Flag to control if the dialog can be skipped.
var _can_skip: bool = true

## Flag to control if the dialog is completed.
var _display_completed: bool = false
## Array to store the dialog sentences.
var _sentences: Array[String] = []

## Index of the current sentence being displayed.
var _current_sentence: int = 0
## Current character that is being displayed in the dialog.
var _current_character: String = ""

## Flag to check if the dialog box is displaying a portrait.
var _is_displaying_portrait: bool = false
## Flag to check if the dialog box was already started.
var _is_started: bool = false
## Flag to check if the dialog is running
var _is_running: bool = false


func _enter_tree() -> void:
	_type_timer = Timer.new()
	add_child(_type_timer)
	_type_timer.wait_time = _typing_speed
	_type_timer.timeout.connect(_on_type_timer_timeout)

	_can_skip_timer = Timer.new()
	add_child(_can_skip_timer)
	_can_skip_timer.wait_time = GraphDialogsSettings.get_setting("can_skip_delay")
	_can_skip_timer.timeout.connect(func(): _can_skip = true)
	hide()


func _ready() -> void:
	# Connect meta clicked signal to handle meta tags
	if not _dialog_display.is_connected("meta_clicked", _on_dialog_meta_clicked):
		_dialog_display.meta_clicked.connect(_on_dialog_meta_clicked)
	
	_dialog_display.bbcode_enabled = true
	_continue_indicator.visible = false


func _input(event: InputEvent) -> void:
	if not _is_running:
		return
	# Skip dialog typing and show the full text
	if not _display_completed and _can_skip and Input.is_action_just_pressed(
			GraphDialogsSettings.get_setting("continue_input_action")):
		_skip_dialog_typing()
	# Continue dialog when the player press the continue button
	elif _display_completed and Input.is_action_just_pressed(
			GraphDialogsSettings.get_setting("continue_input_action")):
			if _current_sentence < _sentences.size() - 1:
				_current_sentence += 1
				_display_new_sentence(_sentences[_current_sentence])
			else: # Continue with the next dialog node
				continue_dialog.emit()


## Play a dialog on dialog box
func play_dialog(character_name: String, dialog: String) -> void:
	if not _is_started: # First time the dialog is started
		await _on_dialog_box_start()
	if not visible:
		show()

	_current_character = character_name
	_name_display.text = character_name
	_dialog_display.text = dialog
	_current_sentence = 0
	_sentences = []

	# Split the dialog by lines and characters if the settings are enabled
	var dialog_lines = _split_dialog_by_lines(dialog)
	for line in dialog_lines:
		var split_result = _split_dialog_by_characters(line)
		_sentences.append_array(split_result)
	
	# Start the dialog
	_is_started = true
	_is_running = true
	_display_completed = false
	_display_new_sentence(_sentences[_current_sentence])
	dialog_starts.emit(character_name)


## Pause the dialog
func pause_dialog() -> void:
	_is_running = false
	_type_timer.paused = true


## Resume the dialog
func resume_dialog() -> void:
	_is_running = true
	_type_timer.paused = false


## Stop the dialog
func stop_dialog(close_dialog: bool = false) -> void:
	dialog_ends.emit(_current_character)
	_display_completed = false
	_current_sentence = 0
	_is_running = false
	_sentences = []

	if close_dialog: # Close if the dialog ends
		await _on_dialog_box_close()
		_is_started = false
	else: # Hide if the dialog will continue
		hide()


## Return if the dialog box is displaying a portrait
func is_displaying_portrait() -> bool:
	return _is_displaying_portrait


## Set a portrait to be displayed in the dialog box
func display_portrait(character_parent: Node, portrait_node: Node) -> void:
	if not _portrait_display.has_node(NodePath(character_parent.name)):
		character_parent.add_child(portrait_node)
		_portrait_display.add_child(character_parent)
	else:
		# If the character node already exists, add the portrait to it
		_portrait_display.get_node(NodePath(character_parent.name)).add_child(portrait_node)
	_is_displaying_portrait = true


## Skip the dialog typing and show the full text
func _skip_dialog_typing() -> void:
	_dialog_display.visible_characters = _dialog_display.text.length()
	_type_timer.stop()
	# Wait for the continue delay before allowing to skip again
	await get_tree().create_timer(
			GraphDialogsSettings.get_setting("skip_continue_delay")).timeout
	_can_skip = false # Prevent skipping too fast
	_can_skip_timer.start()
	_on_display_completed()

#region === Overrides ==========================================================

## Abstract method to modify in inherited dialog box classes.
## Handle the behavior of the dialog box when starts at the beginning of the dialog.
## This method is called when the dialog box is shown on dialog start.
func _on_dialog_box_start() -> void:
	show()


## Abstract method to modify in inherited dialog box classes.
## Handle the behavior of the dialog box when is closed at the end of the dialog.
## This method is called when the dialog box is closed after the dialog ends.
func _on_dialog_box_close() -> void:
	hide()

#endregion

#region === Split dialog =======================================================

## Split dialog by new lines if the setting is enabled.
## Splits the dialog by lines preserving the continuity of the bbcode tags.
func _split_dialog_by_lines(dialog: String) -> Array:
	if not GraphDialogsSettings.get_setting("new_line_as_new_dialog"):
		return [dialog]
	
	var lines = Array(dialog.split("\n"))
	if lines.size() == 0:
		return [dialog]
	
	var sentences = []
	var opened_tags = []
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")

	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue
		# Add the opened tags from previous lines and update the opened tags
		sentences.append(_add_tags_to_sentence(line, opened_tags))
		opened_tags = _get_opened_tags_from_sentence(line, opened_tags, regex)
	return sentences


## Split dialog by characters max limit if the setting is enabled.
## If the dialog is longer than the max characters limit, it will be split into
## multiple sentences, preserving the continuity of the bbcode tags.
func _split_dialog_by_characters(dialog: String) -> Array:
	if not GraphDialogsSettings.get_setting("split_dialog_by_max_characters") \
			or _max_characters > dialog.length():
		return [dialog]
	
	var words: Array = dialog.split(" ")
	var sentences: Array[String] = []
	var clean_sentence: String = ""
	var sentence: String = ""
	var opened_tags: Array = []
	var next_sentence_tags: Array = []

	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")

	var i = 0
	while i < words.size():
		var word = words[i]
		var clean_word = regex.sub(word, "", true)
		var aux_sentence = clean_sentence + " " + clean_word
		# If the sentence is short than the limit, add the word to the sentence
		if aux_sentence.length() < _max_characters:
			sentence += " " + word
			clean_sentence += "" + clean_word
			opened_tags = _get_opened_tags_from_sentence(word, opened_tags, regex)
			i += 1
		else: # If the sentence is longer, cut it and add to the sentences list
			sentence = _add_tags_to_sentence(sentence, next_sentence_tags)
			next_sentence_tags = opened_tags.duplicate()
			sentence = sentence.strip_edges()
			if sentence != "":
				sentences.append(sentence)
			clean_sentence = ""
			sentence = ""
	
	if sentence != "": # Add the last sentence to the list
		sentence = _add_tags_to_sentence(sentence, next_sentence_tags)
		sentences.append(sentence)
	return sentences


## Get all opened tags from a sentence
func _get_opened_tags_from_sentence(sentence: String, opened_tags: Array, regex: RegEx) -> Array:
	var tags = regex.search_all(sentence).map(
		func(tag): return tag.get_string()
		)
	for tag in tags:
		if tag.begins_with("[/"): # Look for closing tags
			var tag_begin = tag.replace("[/", "[").replace("]", "")
			var open_tag_index = opened_tags.find(
				func(open_tag): return open_tag.begins_with(tag_begin)
			)
			if open_tag_index: # Remove from opened tags if a closing tag was found
				opened_tags.erase(opened_tags[open_tag_index])
		else:
			opened_tags.append(tag) # If not, add to opened tags
	return opened_tags


## Add tags to the beginning of a sentence
func _add_tags_to_sentence(sentence: String, tags: Array) -> String:
	var tags_string = ""
	for tag in tags:
		tags_string += tag
	sentence = tags_string + sentence
	return sentence

#endregion

#region === Display dialog =====================================================

## Display a new sentence
func _display_new_sentence(sentence: String) -> void:
	_dialog_display.text = sentence
	_dialog_display.visible_characters = 0
	_continue_indicator.visible = false
	_display_completed = false
	_type_timer.start()


## Timer to type the dialog characters
func _on_type_timer_timeout() -> void:
	if _dialog_display.visible_characters < _dialog_display.text.length():
		_dialog_display.visible_characters += 1
	else:
		_type_timer.stop()
		_on_display_completed()


## When the dialog finishes displaying a text
func _on_display_completed() -> void:
	_continue_indicator.visible = true
	_display_completed = true
	dialog_typing_ends.emit(_current_character)


## When the dialog ends, close the dialog box
func _on_dialog_ended() -> void:
	stop_dialog()


## When a meta tag is clicked in the dialog
func _on_dialog_meta_clicked(meta: String) -> void:
	if GraphDialogsSettings.get_setting("open_url_on_meta_tag_click"):
		OS.shell_open(meta) # Open the URL in the default browser
	meta_clicked.emit(meta)

#endregion
