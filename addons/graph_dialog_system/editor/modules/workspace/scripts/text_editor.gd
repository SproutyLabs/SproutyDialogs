@tool
extends Panel

## =============================================================================
## Text editor
##
## This script handles a text editor window.
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

## Text color picker from the text editor
@onready var _text_color_picker: ColorPickerButton = %TextColorPicker
## Color sample hex code from the text editor
@onready var _text_color_sample_hex: RichTextLabel = %TextColorSample
## Background color picker from the text editor
@onready var _bg_color_picker: ColorPickerButton = %BgColorPicker
## Background sample color hex code from the text editor
@onready var _bg_color_sample_hex: RichTextLabel = %BgColorSample

## Current option bar shown in the text editor
var _current_option_bar: Control = null
## Current tags to insert in the text: [open_tag, close_tag]
var _current_tags: Array = []

## Text box opened with text to edit
var _opened_text_box: TextEdit

## Expand and collapse icons
var _expand_icon: Texture = preload("res://addons/graph_dialog_system/icons/collapse-up.svg")
var _collapse_icon: Texture = preload("res://addons/graph_dialog_system/icons/collapse-down.svg")


func _ready():
	visible = false


## Show the text editor
func show_text_editor(text_box: TextEdit) -> void:
	_opened_text_box = text_box ## Set the text box to edit
	_text_input.text = _opened_text_box.text
	_text_preview.text = _opened_text_box.text
	visible = true


## Hide the text editor
func hide_text_editor() -> void:
	visible = false


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
		_preview_expand_button.icon = _collapse_icon
		_preview_box.size_flags_vertical = SizeFlags.SIZE_EXPAND_FILL
		_text_boxes_container.collapsed = false
	else:
		_preview_expand_button.icon = _expand_icon
		_preview_box.size_flags_vertical = SizeFlags.SIZE_FILL
		_text_boxes_container.collapsed = true


#region === Code tags handling =================================================

## Get the position of the selected text in the text input
func _get_selected_text_position() -> Array:
	return [
		_text_input.get_selection_origin_line(), # Origin line
		_text_input.get_selection_origin_column(), # Origin column
		_text_input.get_selection_to_line(), # To line
		_text_input.get_selection_to_column() # To column
	]

## Sort the selection order to insert the tags
func _sort_selection_order(selection: Array) -> Array:
	var origin_line = selection[0]
	var origin_column = selection[1]
	var to_line = selection[2]
	var to_column = selection[3]

	print("\norigin_line: " + str(selection[0]) + "\nto_line: " + str(selection[2]) +
		"\norigin_column: " + str(selection[1]) + "\nto_column: " + str(selection[3]))
	
	var sort_selection = []
	# Always put the open tag first and the close tag at the end of selection
	if origin_line > to_line or (origin_line == to_line and origin_column > to_column):
		sort_selection = [to_line, to_column, origin_line, origin_column]
	else:
		sort_selection = [origin_line, origin_column, to_line, to_column]
	
	print("\norigin_line: " + str(sort_selection[0]) + "\nto_line: " + str(sort_selection[2]) +
		"\norigin_column: " + str(sort_selection[1]) + "\nto_column: " + str(sort_selection[3]))
	return sort_selection
	

## Insert tags in the selected text
func _insert_code_tags(open_tag: String, close_tag: String) -> void:
	# If there is no text selected, return
	if not _text_input.has_selection():
		return
	# Get the selection position
	var selection_pos = _get_selected_text_position()
	selection_pos = _sort_selection_order(selection_pos)

	_text_input.insert_text(close_tag, selection_pos[2], selection_pos[3])
	_text_input.insert_text(open_tag, selection_pos[0], selection_pos[1])
 
	_text_input.select(selection_pos[0], selection_pos[1], selection_pos[2],
			selection_pos[3] + open_tag.length() + close_tag.length())


## Update the code tags in the selected text
func _update_code_tags(open_tag: String, close_tag: String) -> void:
	# If there is no text selected, return
	if not _text_input.has_selection():
		return
	# Get the selection position and open tag without the attributes
	var selection_pos = _get_selected_text_position()
	var open_tag_begin = open_tag.split("=")[0].split(" ")[0]

	print("selected text: " + _text_input.get_selected_text())
	
	# Check if the selected text has the open tag
	if not _text_input.get_selected_text().begins_with(open_tag_begin):
		_insert_code_tags(open_tag, close_tag)
		return
	
	# Sort the selection order
	selection_pos = _sort_selection_order(selection_pos)
	_text_input.remove_text(selection_pos[0], selection_pos[1],
			selection_pos[0], selection_pos[1] + open_tag.length())
	
	_text_input.insert_text(open_tag, selection_pos[0], selection_pos[1])
	_text_input.select(selection_pos[0], selection_pos[1],
			selection_pos[2], selection_pos[3])
#endregion

#region === Text style options =================================================

## Add bold text to the selected text
func _on_add_bold_pressed() -> void:
	_insert_code_tags("[b]", "[/b]")


## Add italic text to the selected text
func _on_add_italic_pressed() -> void:
	_insert_code_tags("[i]", "[/i]")


## Add underline text to the selected text
func _on_add_underline_pressed() -> void:
	_insert_code_tags("[u]", "[/u]")


## Add strikethrough text to the selected text
func _on_add_strikethrough_pressed() -> void:
	_insert_code_tags("[s]", "[/s]")


## Align the text to the left
func _on_align_text_left_pressed() -> void:
	_insert_code_tags("[left]", "[/left]")


## Align the text to the center
func _on_align_text_center_pressed() -> void:
	_insert_code_tags("[center]", "[/center]")


## Align the text to the right
func _on_align_text_right_pressed() -> void:
	_insert_code_tags("[right]", "[/right]")


## Align the text to fill the width (justify)
func _on_align_text_fill_pressed() -> void:
	_insert_code_tags("[fill]", "[/fill]")


## Change the font of the selected text
func _on_change_text_font_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[0]
	_options_bars[0].show()


## Change the text size of the selected text
func _on_change_text_size_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[1]
	_options_bars[1].show()
#endregion

#region === Text color options =================================================

## Change the text color of the selected text
func _on_change_text_color_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[2]
	_options_bars[2].show()
	_current_tags = [
		"[color=" + _text_color_picker.color.to_html() + "]",
		"[/color]"
	]
	_insert_code_tags(_current_tags[0], _current_tags[1])


## Update the text color tags in the selected text
func _on_text_color_picker_changed(color: Color) -> void:
	_current_tags = [
		"[color=" + color.to_html() + "]",
		"[/color]"
	]
	_text_color_sample_hex.text = "hex: #" + _current_tags[0] + color.to_html()
	_update_code_tags(_current_tags[0], _current_tags[1])


## Change the background color of the selected text
func _on_change_bg_color_pressed() -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[3]
	_options_bars[3].show()
	_current_tags = [
		"[bgcolor=" + _bg_color_picker.color.to_html() + "]",
		"[/bgcolor]"
	]
	_insert_code_tags(_current_tags[0], _current_tags[1])


## Update the background color tags in the selected text
func _on_bg_color_picker_changed(color: Color) -> void:
	_current_tags = [
		"[bgcolor=" + color.to_html() + "]",
		"[/bgcolor]"
	]
	_bg_color_sample_hex.text = "hex: #" + _current_tags[0] + color.to_html()
	_update_code_tags(_current_tags[0], _current_tags[1])

#endregion