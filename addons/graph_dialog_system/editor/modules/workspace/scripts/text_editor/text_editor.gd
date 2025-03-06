@tool
extends Panel

## =============================================================================
## Text editor
##
## The text editor is used to edit the dialogues from the dialog system.
## It allows the user to add text effects, font styles, colors and others to
## the dialogue in the text boxes using BBCode tags.
## 
## The text editor is shown when the user clicks on the text box expand button.
## =============================================================================

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

## Current option bar shown in the text editor
var _current_option_bar: Control = null

## Text box opened with text to edit
var _opened_text_box: TextEdit

## Expand and collapse icons
var expand_icon: Texture = preload("res://addons/graph_dialog_system/icons/collapse-up.svg")
var collapse_icon: Texture = preload("res://addons/graph_dialog_system/icons/collapse-down.svg")


func _ready():
	hide_text_editor()


## Show the text editor
func show_text_editor(text_box: TextEdit) -> void:
	_opened_text_box = text_box ## Set the text box to edit
	_text_input.text = _opened_text_box.text
	_text_preview.text = _opened_text_box.text
	visible = true


## Hide the text editor
func hide_text_editor() -> void:
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


## Update the text box and preview with the text editor input
func _on_code_edit_text_changed() -> void:
	_opened_text_box.text = _text_input.text
	_text_preview.text = _text_input.text


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
func _get_selected_text_position() -> Array:
	return [
		_text_input.get_selection_from_line(), # From line
		_text_input.get_selection_from_column(), # From column
		_text_input.get_selection_to_line(), # To line
		_text_input.get_selection_to_column() # To column
	]

#region --- Insert tags --------------------------------------------------------

## Insert tags in the selected text
func insert_tags_on_selected_text(
		open_tag: String,
		close_tag: String,
		add_on_empty: bool = false
		) -> void:
	# If there is no text selected
	if not _text_input.has_selection():
		if add_on_empty: _insert_tags_at_cursor_pos(open_tag, close_tag)
		return
	# Get the selection position
	var selection_pos = _get_selected_text_position()
	
	# Insert the tags in the selected text
	_text_input.insert_text(close_tag, selection_pos[2], selection_pos[3])
	_text_input.insert_text(open_tag, selection_pos[0], selection_pos[1])
	_text_input.select(selection_pos[0], selection_pos[1], selection_pos[2],
			selection_pos[3] + open_tag.length() + close_tag.length())


## Insert tags at the cursor position
func _insert_tags_at_cursor_pos(open_tag: String, close_tag: String) -> void:
	var caret_line = _text_input.get_caret_line()
	var caret_column = _text_input.get_caret_column()

	_text_input.insert_text(open_tag + close_tag, caret_line, caret_column)
	_text_input.select(caret_line, caret_column, caret_line,
			caret_column + open_tag.length() + close_tag.length())

#endregion

#region --- Update tags --------------------------------------------------------

## Update the code tags in the selected text
func update_code_tags(
		open_tag: String,
		close_tag: String,
		remove_attr: String = "",
		add_on_empty: bool = false
		) -> void:
	# If there is no text selected
	if not _text_input.has_selection():
		if add_on_empty: _insert_tags_at_cursor_pos(open_tag, close_tag)
		return
	# Get open tag without attributes
	var open_tag_begin = open_tag.split("=")[0].split(" ")[0].replace("]", "")
	var selected_text = _text_input.get_selected_text()

	# If the selected text does not have the open tag, insert the tags
	if not selected_text.contains(open_tag_begin):
		if add_on_empty: insert_tags_on_selected_text(open_tag, close_tag)
		return
	
	var selection_pos = _get_selected_text_position()
	# If the open tag is not at the beginning of the selected text
	if not selected_text.begins_with(open_tag_begin):
		# Get position of opening tag inside the selected text
		var open_tag_pos = selected_text.find(open_tag_begin)
		selected_text = selected_text.substr(open_tag_pos)
		selection_pos[1] += open_tag_pos # Update from column

	# Update the attributes and then replace the tags
	var old_open_tag = selected_text.split("]")[0] + "]"
	open_tag = _update_tag_attributes(old_open_tag, open_tag, remove_attr)

	_text_input.remove_text(selection_pos[0], selection_pos[1],
			selection_pos[0], selection_pos[1] + old_open_tag.length())

	_text_input.insert_text(open_tag, selection_pos[0], selection_pos[1])
	_text_input.select(selection_pos[0], selection_pos[1],
			selection_pos[0], selection_pos[1] + open_tag.length())


## Add an tag attribute to the selected text
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
func _update_tag_attributes(old_tag: String, new_tag: String, remove_attr: String) -> String:
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
		if atr == remove_attr:
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
	insert_tags_on_selected_text("[b]", "[/b]")

## Add italic text to the selected text
func _on_add_italic_pressed() -> void:
	insert_tags_on_selected_text("[i]", "[/i]")

## Add underline text to the selected text
func _on_add_underline_pressed() -> void:
	insert_tags_on_selected_text("[u]", "[/u]")

## Add strikethrough text to the selected text
func _on_add_strikethrough_pressed() -> void:
	insert_tags_on_selected_text("[s]", "[/s]")
#endregion

#region --- Alignment options --------------------------------------------------

## Align the text to the left
func _on_align_text_left_pressed() -> void:
	insert_tags_on_selected_text("[left]", "[/left]")

## Align the text to the center
func _on_align_text_center_pressed() -> void:
	insert_tags_on_selected_text("[center]", "[/center]")

## Align the text to the right
func _on_align_text_right_pressed() -> void:
	insert_tags_on_selected_text("[right]", "[/right]")

## Align the text to fill the width (justify)
func _on_align_text_fill_pressed() -> void:
	insert_tags_on_selected_text("[fill]", "[/fill]")
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
	update_code_tags("[outline_size=" + str(value) + "]", "[/outline_size]")


## Update the outline color tags in the selected text
func _on_outline_color_changed(color: Color) -> void:
	var open_tag = "[outline_color=" + color.to_html() + "]"
	_outline_color_sample_hex.text = "Hex: #[outline_size=5]" + open_tag + color.to_html()
	# Select the color tag when select the hex number
	_select_color_tag_by_hex(open_tag)
	update_code_tags(open_tag, "[/color]")

#endregion
#endregion

#region === Text color options =================================================

## Select the color tag when select the hex number
func _select_color_tag_by_hex(color_tag: String) -> void:
	var tag_length = color_tag.split("=")[0].length() + 1

	if _text_input.get_selected_text().is_valid_html_color():
		_text_input.select(
				_text_input.get_selection_from_line(),
				_text_input.get_selection_from_column() - tag_length,
				_text_input.get_selection_to_line(),
				_text_input.get_selection_to_column() + 1 # "]" lenght
			)

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
	# Select the color tag when select the hex number
	_select_color_tag_by_hex(open_tag)
	update_code_tags(open_tag, "[/color]")


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
	# Select the color tag when select the hex number
	_select_color_tag_by_hex(open_tag)
	update_code_tags(open_tag, "[/bgcolor]")

#endregion

#region === Embedding options ==================================================

func _on_add_variable_pressed() -> void:
	change_option_bar(4)


func _on_add_image_pressed() -> void:
	change_option_bar(5)


func _on_add_url_pressed() -> void:
	change_option_bar(6)
#endregion
