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


## Insert tags in the selected text
func _insert_code_tags(open_tag: String, close_tag: String):
	var origin_line = _text_input.get_selection_origin_line()
	var origin_column = _text_input.get_selection_origin_column()
	var to_line = _text_input.get_selection_to_line()
	var to_column = _text_input.get_selection_to_column()
	
	if origin_column == to_column: # If there is no text selected
		_text_input.insert_text(open_tag + close_tag, origin_line, origin_column)
		return

	# Always put the open tag first and the close tag at the end of selection
	if origin_line > to_line or (origin_line == to_line and origin_column > to_column):
		# Swap the origin and end positions of the selection
		var temp_line = origin_line
		var temp_column = origin_column
		origin_line = to_line
		origin_column = to_column
		to_line = temp_line
		to_column = temp_column
	
	_text_input.insert_text(close_tag, to_line, to_column)
	_text_input.insert_text(open_tag, origin_line, origin_column)


#region === Text options =======================================================

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

#enregion