@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Text Editor Font Options
# -----------------------------------------------------------------------------
## Controller to add font options to the text in the text editor.
## Use the [font][/font] tag to apply the font options to the text.
# -----------------------------------------------------------------------------

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor

## Font other options container
@onready var _font_other_options: Control = %FontOptions
## Font options expand button
@onready var _font_options_expand_button: Button = %FontOptionsExpandButton


## Change the font of the selected text
func _on_change_text_font_pressed() -> void:
	text_editor.change_option_bar(0)
	_on_font_options_expand_toggled(false)


## Show the font spacing options bar
func _on_font_options_expand_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_font_options_expand_button.icon = text_editor.expand_icon
		_font_other_options.show()
	else:
		_font_options_expand_button.icon = text_editor.collapse_icon
		_font_other_options.hide()


## Change the font size of the selected text
func _on_font_size_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "s", snapped(value, 0.1), 0.0)


## Change the font of the selected text
func _on_font_file_path_changed(path: String) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "n", path, "")


## Update the font glyph spacing value
func _on_font_gl_space_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "gl", snapped(value, 0.1), 0.0)


## Update the font space spacing value
func _on_font_sp_space_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "sp", snapped(value, 0.1), 0.0)


## Update the font top spacing value
func _on_font_top_space_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "top", snapped(value, 0.1), 0.0)


## Update the font bottom spacing value
func _on_font_bottom_space_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "bt", snapped(value, 0.1), 0.0)


## Update the font embolden value
func _on_font_embolden_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "emb", snapped(value, 0.1), 0.0)


## Update the font italics value
func _on_font_slant_value_changed(value: float) -> void:
	if text_editor.find_tags_around_cursor("[font", "[/font]").is_empty():
		text_editor.insert_tags_on_selected_text("[font]", "[/font]", true, "text")
	text_editor.add_attribute_to_tag("font", "sln", snapped(value, 0.1), 0.0)