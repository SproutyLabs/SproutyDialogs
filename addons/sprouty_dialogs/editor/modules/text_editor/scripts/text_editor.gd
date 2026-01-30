@tool
class_name EditorSproutyDialogsTextEditor
extends Panel

# -----------------------------------------------------------------------------
# Sprouty Dialogs Text editor
# -----------------------------------------------------------------------------
## The text editor component is a panel that allows the user to add text effects, 
## font styles, colors and others using BBCode tags in a user friendly way.
## 
## The text editor is shown when the user clicks on a text box expand button.
# -----------------------------------------------------------------------------

## Text boxes container from the text editor
@onready var _text_boxes_container: VSplitContainer = %TextBoxes
## Input text box from the text editor
@onready var _text_input: CodeEdit = %TextBox
## Text preview label from the text editor
@onready var _text_preview: RichTextLabel = %TextPreview
## Preview box from the text editor
@onready var _preview_box: MarginContainer = %PreviewBox
## Preview expand button from the text editor
@onready var _preview_expand_button: Button = %ExpandPreviewButton
## Container with the options bars menus
@onready var _options_bars: Array = %OptionMenus.get_children()

## Text color picker
@onready var _text_color_picker: ColorPickerButton = %TextColorPicker
## Color sample hex code
@onready var _text_color_sample_hex: RichTextLabel = %TextColorSample
## Background color picker
@onready var _bg_color_picker: ColorPickerButton = %BgColorPicker
## Background sample color hex code
@onready var _bg_color_sample_hex: RichTextLabel = %BgColorSample
## Outline sample color hex code
@onready var _outline_color_sample_hex: RichTextLabel = %OutlineColorSample

## Variable name input
@onready var _variable_name_input: EditorSproutyDialogsComboBox = %VariableNameInput
## Variable type dropdown
@onready var _variable_type_dropdown: OptionButton

## Variable manager instance to parse variables
@onready var _variable_manager := SproutyDialogsVariableManager.new()

## Current option bar shown in the text editor
var _current_option_bar: Control = null

## Text box opened with text to edit
## Can be a LineEdit or TextEdit
var _opened_text_box: Variant

## Expand and collapse icons
var expand_icon: Texture = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var collapse_icon: Texture = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")


func _ready():
	# Set variable type dropdown
	%VariableTypeField.add_child(
		SproutyDialogsVariableUtils.get_types_dropdown(false,
			["Nil", "Variable", "Dictionary", "Array"] # Excluded from options
		))
	_variable_type_dropdown = %VariableTypeField.get_child(0)
	_variable_type_dropdown.flat = true
	_variable_type_dropdown.item_selected.connect(_on_variable_type_selected)
	_variable_name_input.option_selected.connect(_on_variable_name_submitted)

	hide_text_editor()
	add_child(_variable_manager)


## Return the text input from the text editor
func get_text_input() -> CodeEdit:
	return _text_input


## Show the text editor
## Needs a LineEdit or TextEdit from where to get and update the text
func show_text_editor(text_box: Variant) -> void:
	_opened_text_box = text_box
	_text_input.text = _opened_text_box.text
	if not _opened_text_box.text_changed.is_connected(_on_text_box_text_changed):
		_opened_text_box.text_changed.connect(_on_text_box_text_changed)
	_text_preview.text = _variable_manager.parse_variables(_opened_text_box.text, true)
	visible = true


## Update the text editor with the text box content
func update_text_editor(text_box: Variant) -> void:
	if visible and text_box != _opened_text_box:
		_opened_text_box = text_box
		_text_input.text = _opened_text_box.text
		if not _opened_text_box.text_changed.is_connected(_on_text_box_text_changed):
			_opened_text_box.text_changed.connect(_on_text_box_text_changed)
		_text_preview.text = _variable_manager.parse_variables(_opened_text_box.text, true)


## Hide the text editor
func hide_text_editor() -> void:
	_text_preview.text = ""
	_text_input.text = ""
	visible = false


## Change the current option bar shown in the text editor
func change_option_bar(bar_index: int) -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[bar_index]
	_options_bars[bar_index].show()


## Close the text editor
func _on_close_button_pressed() -> void:
	hide_text_editor()


## Update text on text editor with the text box content when it changes
func _on_text_box_text_changed(_arg: Variant = null) -> void:
	if _text_input.text == _opened_text_box.text:
		return # If the text is the same, do nothing
	var caret_line = _text_input.get_caret_line()
	var caret_column = _text_input.get_caret_column()
	_text_input.text = _opened_text_box.text
	_text_input.set_caret_line(caret_line)
	_text_input.set_caret_column(caret_column)
	_text_preview.text = _variable_manager.parse_variables(_text_input.text, true)


## Update the text box and preview with the text editor input
func _on_code_edit_text_changed() -> void:
	if not _opened_text_box:
		hide_text_editor()
		return
	_opened_text_box.text = _text_input.text
	_opened_text_box.text_changed.emit(_text_input.text)
	_text_preview.text = _variable_manager.parse_variables(_text_input.text, true)


## Expsnd or collapse the text preview box
func _on_preview_expand_button_toggled(toggled_on: bool) -> void:
	_text_preview.visible = toggled_on
	if toggled_on:
		_preview_expand_button.icon = collapse_icon
		_preview_box.size_flags_vertical = SizeFlags.SIZE_EXPAND_FILL
		_text_boxes_container.collapsed = false
	else:
		_preview_expand_button.icon = expand_icon
		_preview_box.size_flags_vertical = SizeFlags.SIZE_FILL
		_text_boxes_container.collapsed = true


#region === BBCode tags handling ===============================================

## Get the position of the selected text in the text input
func get_selected_text_position() -> Array[Vector2i]:
	return [
		Vector2i( # From position: x: column, y: line
			_text_input.get_selection_from_column(),
			_text_input.get_selection_from_line(),
		),
		Vector2i( # To position: x: column, y: line
			_text_input.get_selection_to_column(),
			_text_input.get_selection_to_line()
		)
	]

## Find the given tags around the cursor position
func find_tags_around_cursor(open_tag: String, close_tag: String) -> Array[Vector2i]:
	var caret_line = _text_input.get_caret_line()
	var caret_column = _text_input.get_caret_column()
	
	var open_tag_pos = _text_input.search(
			open_tag, TextEdit.SEARCH_BACKWARDS, caret_line, caret_column)
	var close_tag_pos = _text_input.search(
			close_tag, TextEdit.SEARCH_WHOLE_WORDS, caret_line, caret_column)

	var before_close_tag = _text_input.search(
			close_tag, TextEdit.SEARCH_BACKWARDS, caret_line, caret_column)

	if open_tag_pos.x == -1 or close_tag_pos.x == -1:
		return [] # If there are no tags around the cursor, tags not found
	
	if open_tag_pos.y > caret_line or open_tag_pos.x > caret_column:
		return [] # If the open tag is after the cursor, tags not found
	
	if close_tag_pos.y < caret_line or close_tag_pos.x < caret_column:
		return [] # If the close tag is before the cursor, tags not found

	if ((before_close_tag.y < caret_line or before_close_tag.x < caret_column)
			and (before_close_tag.y > open_tag_pos.y or before_close_tag.x > open_tag_pos.x)):
		return [] # If there are a close tag between the open tag and the cursor, tags not found

	_text_input.select(open_tag_pos.y, open_tag_pos.x,
		close_tag_pos.y, close_tag_pos.x + close_tag.length())
	
	return [open_tag_pos, close_tag_pos]

#region --- Insert tags --------------------------------------------------------

## Insert tags in the selected text
## If there is no text selected, do nothing or add tags with a placeholder.
## if add_on_empty is true, the placeholder will be added between the tags.
func insert_tags_on_selected_text(
		open_tag: String,
		close_tag: String,
		add_on_empty: bool = false,
		placeholder: String = ""
		) -> void:
	# If there is no text selected
	if not _text_input.has_selection():
		if add_on_empty: # Add the tags with a placeholder
			insert_tags_at_cursor_pos(open_tag + placeholder, close_tag)
		return
	# Get the selection position
	var selection_pos = get_selected_text_position()
	
	# Insert the tags in the selected text
	_text_input.insert_text(close_tag, selection_pos[1].y, selection_pos[1].x)
	_text_input.insert_text(open_tag, selection_pos[0].y, selection_pos[0].x)
	_text_input.select(
			selection_pos[0].y,
			selection_pos[0].x - open_tag.length(),
			selection_pos[1].y,
			selection_pos[1].x + open_tag.length() + close_tag.length()
		)


## Insert tags at the cursor position
func insert_tags_at_cursor_pos(open_tag: String, close_tag: String) -> void:
	var caret_line = _text_input.get_caret_line()
	var caret_column = _text_input.get_caret_column()

	_text_input.insert_text(open_tag + close_tag, caret_line, caret_column)
	_text_input.select(caret_line, caret_column, caret_line,
			caret_column + open_tag.length() + close_tag.length())

#endregion

#region --- Update tags --------------------------------------------------------

## Update the code tags in the selected text
## With ignore_attr you can specify an attribute that will not be updated.
## If there is no text selected, do nothing or add tags with a placeholder.
## if add_on_empty is true, the placeholder will be added between the tags.
## For some cases, an additional tag can be added using add_another_tag array
## with the open and close tag strings.
func update_code_tags(
		open_tag: String,
		close_tag: String,
		ignore_attr: String = "",
		add_on_empty: bool = false,
		add_another_tag: Array = []
		) -> void:
	# Get open tag without attributes
	var open_tag_begin = open_tag.split("=")[0].split(" ")[0].replace("]", "")
	var selected_text = _text_input.get_selected_text()
	var tags_pos = []

	# If there is text selected
	if _text_input.has_selection():
		# If the selected text contains the open tag
		if selected_text.contains(open_tag_begin):
			tags_pos = get_selected_text_position()

			# If the selected text does not begin with the open tag, find it
			if not selected_text.begins_with(open_tag_begin):
				var open_tag_pos = _text_input.search(
						open_tag_begin, TextEdit.SEARCH_WHOLE_WORDS,
						tags_pos[0].y, tags_pos[0].x)
				
				_text_input.select(open_tag_pos.y, open_tag_pos.x, tags_pos[1].y, tags_pos[1].x)
				tags_pos[0] = open_tag_pos # Update the open tag position
		else:
			# If the selected text is a color, find the color tags to update
			if selected_text.is_valid_html_color():
				tags_pos = find_tags_around_cursor(open_tag_begin, close_tag)
			else:
				# If the selected text does not contain the open tag
				if add_on_empty:
					insert_tags_on_selected_text(open_tag, close_tag)
					if not add_another_tag.is_empty():
						insert_tags_on_selected_text(add_another_tag[0], add_another_tag[1])
				return
	else:
		# Find the tags around the cursor position if there are no tags selected
		tags_pos = find_tags_around_cursor(open_tag_begin, close_tag)
		
		if tags_pos.is_empty(): # If there are no tags around the cursor
			if add_on_empty:
				insert_tags_at_cursor_pos(open_tag, close_tag)
				if not add_another_tag.is_empty():
					insert_tags_at_cursor_pos(add_another_tag[0], add_another_tag[1])
			return
	
	# Get open tag with attributes and update it
	selected_text = _text_input.get_selected_text()
	var old_open_tag = selected_text.split("]")[0] + "]"
	open_tag = _update_tag_attributes(old_open_tag, open_tag, ignore_attr)

	# Replace the tags in the selected text
	_text_input.remove_text(tags_pos[0].y, tags_pos[0].x,
			tags_pos[0].y, tags_pos[0].x + old_open_tag.length())

	_text_input.insert_text(open_tag, tags_pos[0].y, tags_pos[0].x)
	_text_input.select(tags_pos[0].y, tags_pos[0].x,
		tags_pos[0].y, tags_pos[0].x + open_tag.length())


## Add an tag attribute to the selected text
## If the value is the default value, the attribute will be removed from the tag
func add_attribute_to_tag(
		tag_name: String,
		attr: String,
		value: Variant,
		default_value: Variant) -> void:
	var open_tag = "[" + tag_name
	var close_tag = "[/" + tag_name + "]"

	if value != default_value:
		open_tag += " " + attr + "=" + str(value) + "]"
		update_code_tags(open_tag, close_tag)
	else:
		update_code_tags(open_tag + "]", close_tag, attr)


## Update the attributes of a tag
func _update_tag_attributes(old_tag: String, new_tag: String, ignore_attr: String) -> String:
	var old_tag_split = old_tag.replace("]", "").split(" ")
	var new_tag_split = new_tag.replace("]", "").split(" ")
	
	if old_tag_split.size() == 1 and new_tag_split.size() == 1:
		return new_tag # If there are no attributes in the tags
	
	# Get the attributes from the old tag and update them with the new ones
	var tag_attributes := _get_tag_atributes(old_tag)
	
	for atr in new_tag_split.slice(1):
		var atr_split = atr.split("=")
		tag_attributes[atr_split[0]] = atr_split[1]

	# Update the tag with the new attributes
	var updated_tag = new_tag_split[0]
	for atr in tag_attributes:
		if atr == ignore_attr:
			continue
		updated_tag += " " + atr + "=" + tag_attributes[atr]
	
	if not updated_tag.ends_with("]"):
		updated_tag += "]" # Close the tag
	return updated_tag


## Get the attributes from a tag
func _get_tag_atributes(tag: String) -> Dictionary:
	var atributes = tag.split(" ")
	var tag_attributes = {}

	for atr in atributes.slice(1):
		var atr_split = atr.split("=")
		tag_attributes[atr_split[0]] = atr_split[1].replace("]", "")

	return tag_attributes
#endregion
#endregion

#region === Text style options =================================================

#region --- Basic style options ------------------------------------------------

## Add bold text to the selected text
func _on_add_bold_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[b]", "[/b]", true, "text")

## Add italic text to the selected text
func _on_add_italic_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[i]", "[/i]", true, "text")

## Add underline text to the selected text
func _on_add_underline_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[u]", "[/u]", true, "text")

## Add strikethrough text to the selected text
func _on_add_strikethrough_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[s]", "[/s]", true, "text")
#endregion

#region --- Alignment options --------------------------------------------------

## Align the text to the left
func _on_align_text_left_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[left]", "[/left]", true, "text")

## Align the text to the center
func _on_align_text_center_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[center]", "[/center]", true, "text")

## Align the text to the right
func _on_align_text_right_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[right]", "[/right]", true, "text")

## Align the text to fill the width (justify)
func _on_align_text_fill_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	insert_tags_on_selected_text("[fill]", "[/fill]", true, "text")
#endregion

#region --- Outline options ----------------------------------------------------

## Add outline to the selected text
func _on_add_text_outline_pressed() -> void:
	change_option_bar(1)
	insert_tags_on_selected_text(
		"[outline_color=ff0000]",
		"[/outline_color]"
		)
	insert_tags_on_selected_text(
		"[outline_size=5]",
		"[/outline_size]"
		)


## Update the outline size tags in the selected text
func _on_outline_size_value_changed(value: float) -> void:
	update_code_tags("[outline_size=" + str(value) + "]", "[/outline_size]", "", true,
			["[outline_color=" + _outline_color_sample_hex.text.split("]")[-1] + "]", "[/outline_color]"])


## Update the outline color tags in the selected text
func _on_outline_color_changed(color: Color) -> void:
	var open_tag = "[outline_color=" + color.to_html() + "]"
	_outline_color_sample_hex.text = "Hex: #[outline_size=5]" + open_tag + color.to_html()
	update_code_tags(open_tag, "[/outline_color]", "", true, ["[outline_size=5]", "[/outline_size]"])

#endregion
#endregion

#region === Text color options =================================================

## Change the text color of the selected text
func _on_change_text_color_pressed() -> void:
	change_option_bar(2)
	insert_tags_on_selected_text(
		"[color=" + _text_color_picker.color.to_html() + "]",
		"[/color]"
		)


## Update the text color tags in the selected text
func _on_text_color_picker_changed(color: Color) -> void:
	var open_tag = "[color=" + color.to_html() + "]"
	_text_color_sample_hex.text = "Hex: #" + open_tag + color.to_html()
	update_code_tags(open_tag, "[/color]", "", true)


## Change the background color of the selected text
func _on_change_bg_color_pressed() -> void:
	change_option_bar(3)
	insert_tags_on_selected_text(
		"[bgcolor=" + _bg_color_picker.color.to_html() + "]",
		"[/bgcolor]"
		)


## Update the background color tags in the selected text
func _on_bg_color_picker_changed(color: Color) -> void:
	var open_tag = "[bgcolor=" + color.to_html() + "]"
	_bg_color_sample_hex.text = "Hex: #" + open_tag + color.to_html()
	update_code_tags(open_tag, "[/bgcolor]", "", true)

#endregion

#region === Embedding options ==================================================

## Add a variable at the cursor position
func _on_add_variable_pressed() -> void:
	change_option_bar(4)


## Update the variable type to filter variables
func _on_variable_type_selected(index: int) -> void:
	var type = _variable_type_dropdown.get_item_id(index)
	var metadata = _variable_type_dropdown.get_item_metadata(index)
	_variable_name_input.set_options(
		SproutyDialogsVariableUtils.get_variables_of_type(type, metadata)
	)


## Update the variable tags in the selected text
func _on_variable_name_submitted(new_text: String) -> void:
	update_code_tags("{" + new_text, "}", "", true)


## Add a url in the selected text
func _on_add_url_pressed() -> void:
	change_option_bar(6)


## Update the url tags in the selected text
func _on_url_input_submitted(new_text: String) -> void:
	update_code_tags("[url=" + new_text + "]", "[/url]", "", true)

#endregion
