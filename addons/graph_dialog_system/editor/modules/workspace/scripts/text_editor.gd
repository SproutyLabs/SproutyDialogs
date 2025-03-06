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

## Text color picker
@onready var _text_color_picker: ColorPickerButton = %TextColorPicker
## Color sample hex code
@onready var _text_color_sample_hex: RichTextLabel = %TextColorSample
## Background color picker
@onready var _bg_color_picker: ColorPickerButton = %BgColorPicker
## Background sample color hex code
@onready var _bg_color_sample_hex: RichTextLabel = %BgColorSample

## Effects options bars (pulse, wave, shake, etc.)
@onready var _effects_bars: Array = %EffectsContainer.get_children()

## Current effect bar shown in the text editor
var _current_effect_bar: Control = null
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


## Change the current option bar shown in the text editor
func _change_option_bar(bar_index: int) -> void:
	if _current_option_bar:
		_current_option_bar.hide()
	_current_option_bar = _options_bars[bar_index]
	_options_bars[bar_index].show()


#region === Code tags handling =================================================

## Get the position of the selected text in the text input
func _get_selected_text_position() -> Array:
	return [
		_text_input.get_selection_from_line(), # From line
		_text_input.get_selection_from_column(), # From column
		_text_input.get_selection_to_line(), # To line
		_text_input.get_selection_to_column() # To column
	]


## Insert tags at the cursor position
func _insert_tags_at_cursor_pos(open_tag: String, close_tag: String) -> void:
	var caret_line = _text_input.get_caret_line()
	var caret_column = _text_input.get_caret_column()

	_text_input.insert_text(open_tag + close_tag, caret_line, caret_column)
	_text_input.select(caret_line, caret_column, caret_line,
			caret_column + open_tag.length() + close_tag.length())


## Insert tags in the selected text
func _insert_tags_on_selected_text(
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


## Update the code tags in the selected text
func _update_code_tags(
		open_tag: String,
		close_tag: String,
		remove_attr: String = "",
		add_on_empty: bool = false
		) -> void:
	# If there is no text selected
	if not _text_input.has_selection():
		if add_on_empty: _insert_tags_at_cursor_pos(open_tag, close_tag)
		return
	# Open tag without attributes
	var open_tag_begin = open_tag.split("=")[0].split(" ")[0].replace("]", "")

	# If the selected text does not have the open tag, insert the tags
	if not _text_input.get_selected_text().begins_with(open_tag_begin):
		if add_on_empty: _insert_tags_on_selected_text(open_tag, close_tag)
		return

	# Get the old open tag to replace it with the new one
	var old_open_tag = _text_input.get_selected_text().split("]")[0] + "]"
	open_tag = _update_tag_attributes(old_open_tag, open_tag, remove_attr)

	var selection_pos = _get_selected_text_position()
	_text_input.remove_text(selection_pos[0], selection_pos[1],
			selection_pos[0], selection_pos[1] + old_open_tag.length())

	_text_input.insert_text(open_tag, selection_pos[0], selection_pos[1])
	_text_input.select(selection_pos[0], selection_pos[1],
			selection_pos[0], selection_pos[1] + open_tag.length())


## Get the attributes from a tag
func _get_tag_atributes(tag: String) -> Dictionary:
	var atributes = tag.split(" ")
	var tag_attributes = {}

	for atr in atributes.slice(1):
		var atr_split = atr.split("=")
		tag_attributes[atr_split[0]] = atr_split[1].replace("]", "")

	return tag_attributes


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
	
#endregion

#region === Text style options =================================================

## Add bold text to the selected text
func _on_add_bold_pressed() -> void:
	_insert_tags_on_selected_text("[b]", "[/b]")


## Add italic text to the selected text
func _on_add_italic_pressed() -> void:
	_insert_tags_on_selected_text("[i]", "[/i]")


## Add underline text to the selected text
func _on_add_underline_pressed() -> void:
	_insert_tags_on_selected_text("[u]", "[/u]")


## Add strikethrough text to the selected text
func _on_add_strikethrough_pressed() -> void:
	_insert_tags_on_selected_text("[s]", "[/s]")


## Align the text to the left
func _on_align_text_left_pressed() -> void:
	_insert_tags_on_selected_text("[left]", "[/left]")


## Align the text to the center
func _on_align_text_center_pressed() -> void:
	_insert_tags_on_selected_text("[center]", "[/center]")


## Align the text to the right
func _on_align_text_right_pressed() -> void:
	_insert_tags_on_selected_text("[right]", "[/right]")


## Align the text to fill the width (justify)
func _on_align_text_fill_pressed() -> void:
	_insert_tags_on_selected_text("[fill]", "[/fill]")


## Change the font of the selected text
func _on_change_text_font_pressed() -> void:
	_change_option_bar(0)


## Change the text size of the selected text
func _on_change_text_size_pressed() -> void:
	_change_option_bar(1)
#endregion

#region === Text color options =================================================

## Change the text color of the selected text
func _on_change_text_color_pressed() -> void:
	_change_option_bar(2)
	_current_tags = [
		"[color=" + _text_color_picker.color.to_html() + "]",
		"[/color]"
	]
	_insert_tags_on_selected_text(_current_tags[0], _current_tags[1])


## Update the text color tags in the selected text
func _on_text_color_picker_changed(color: Color) -> void:
	_current_tags = [
		"[color=" + color.to_html() + "]",
		"[/color]"
	]
	_text_color_sample_hex.text = "Hex: #" + _current_tags[0] + color.to_html()
	
	# If the selected text is only the hex number, select the whole color tag
	if _text_input.get_selected_text().is_valid_hex_number():
		_text_input.select(
				_text_input.get_selection_from_line(),
				_text_input.get_selection_from_column() - 7, # "[color=" lenght
				_text_input.get_selection_to_line(),
				_text_input.get_selection_to_column() + 1 # "]" lenght
			)
	_update_code_tags(_current_tags[0], _current_tags[1])


## Change the background color of the selected text
func _on_change_bg_color_pressed() -> void:
	_change_option_bar(3)
	_current_tags = [
		"[bgcolor=" + _bg_color_picker.color.to_html() + "]",
		"[/bgcolor]"
	]
	_insert_tags_on_selected_text(_current_tags[0], _current_tags[1])


## Update the background color tags in the selected text
func _on_bg_color_picker_changed(color: Color) -> void:
	_current_tags = [
		"[bgcolor=" + color.to_html() + "]",
		"[/bgcolor]"
	]
	_bg_color_sample_hex.text = "Hex: #" + _current_tags[0] + color.to_html()

	# If the selected text is only the hex number, select the whole color tag
	if _text_input.get_selected_text().is_valid_hex_number():
		_text_input.select(
				_text_input.get_selection_from_line(),
				_text_input.get_selection_from_column() - 9, # "[color=" lenght
				_text_input.get_selection_to_line(),
				_text_input.get_selection_to_column() + 1 # "]" lenght
			)
	_update_code_tags(_current_tags[0], _current_tags[1])

#endregion

#region === Embedding options ==================================================

func _on_add_variable_pressed() -> void:
	_change_option_bar(4)


func _on_add_image_pressed() -> void:
	_change_option_bar(5)


func _on_add_url_pressed() -> void:
	_change_option_bar(6)
#endregion

#region === Effects options ====================================================

## Show the effects list
func _on_add_effect_pressed() -> void:
	# Hide the current effect bar when opening the effects menu
	if _current_option_bar != _options_bars[7] and _current_effect_bar:
		_current_effect_bar.hide()
		_current_effect_bar = null
	_change_option_bar(7)
	
	# Show popup menu with the effects
	var pos := get_global_mouse_position() + Vector2(get_window().position)
	%EffectsMenu.popup(Rect2(pos, %EffectsMenu.get_contents_minimum_size()))


## Change the current effect bar shown in the text editor
func _change_effect_bar(bar_index: int) -> void:
	if _current_effect_bar:
		_current_effect_bar.hide()
	_current_effect_bar = _effects_bars[bar_index]
	_effects_bars[bar_index].show()


## Select an effect from the effects menu
func _on_effects_menu_id_pressed(id: int) -> void:
	match id:
		0:
			_on_pulse_effect_pressed()
		1:
			_on_wave_effect_pressed()
		2:
			_on_tornado_effect_pressed()
		3:
			_on_shake_effect_pressed()
		4:
			_on_fade_effect_pressed()
		5:
			_on_rainbow_effect_pressed()


## Add an effect attribute to the selected text
func _add_effect_attribute(
		tag_name: String,
		attr: String,
		value: Variant,
		default_value: Variant) -> void:
	var open_tag = "[" + tag_name
	var close_tag = "[/" + tag_name + "]"

	if value != default_value:
		open_tag += " " + attr + "=" + str(value) + "]"
		_update_code_tags(open_tag, close_tag)
	else:
		_update_code_tags(open_tag + "]", close_tag, attr)


#region === Pulse effect handling ===============================================

## Add pulse effect to the selected text
func _on_pulse_effect_pressed() -> void:
	_change_effect_bar(0)
	_insert_tags_on_selected_text("[pulse]", "[/pulse]", true)

## Update the pulse frequency value
func _on_pulse_freq_value_changed(value: float) -> void:
	_add_effect_attribute("pulse", "freq", snapped(value, 0.1), 1.0)

## Update the pulse color value
func _on_pulse_color_changed(color: Color) -> void:
	_add_effect_attribute("pulse", "color", color.to_html(), "#ffffff40")

## Update the pulse ease value
func _on_pulse_ease_value_changed(value: float) -> void:
	_add_effect_attribute("pulse", "ease", snapped(value, 0.1), -2.0)
#endregion

#region === Wave effect handling ===============================================

## Add wave effect to the selected text
func _on_wave_effect_pressed() -> void:
	_change_effect_bar(1)
	_insert_tags_on_selected_text("[wave]", "[/wave]", true)

## Update the wave amplitude value
func _on_wave_amp_value_changed(value: float) -> void:
	_add_effect_attribute("wave", "amp", snapped(value, 0.1), 20.0)

## Update the wave frequency value
func _on_wave_freq_value_changed(value: float) -> void:
	_add_effect_attribute("wave", "freq", snapped(value, 0.1), 5.0)

## Update the wave speed value
func _on_wave_connected_toggled(toggled_on: bool) -> void:
	_add_effect_attribute("wave", "connected", int(toggled_on), 1)
#endregion

#region === Tornado effect handling ============================================

## Add tornado effect to the selected text
func _on_tornado_effect_pressed() -> void:
	_change_effect_bar(2)
	_insert_tags_on_selected_text("[tornado]", "[/tornado]", true)

## Update the tornado radius value
func _on_tornado_radius_value_changed(value: float) -> void:
	_add_effect_attribute("tornado", "radius", snapped(value, 0.1), 10.0)

## Update the tornado frequency value
func _on_tornado_freq_value_changed(value: float) -> void:
	_add_effect_attribute("tornado", "freq", snapped(value, 0.1), 1.0)

## Update the tornado connected value
func _on_tornado_connected_toggled(toggled_on: bool) -> void:
	_add_effect_attribute("tornado", "connected", int(toggled_on), 1)
#endregion

#region === Shake effect handling ==============================================

## Add shake effect to the selected text
func _on_shake_effect_pressed() -> void:
	_change_effect_bar(3)
	_insert_tags_on_selected_text("[shake]", "[/shake]", true)

## Update the shake rate value
func _on_shake_rate_value_changed(value: float) -> void:
	_add_effect_attribute("shake", "rate", snapped(value, 0.1), 20.0)

## Update the shake level value
func _on_shake_level_value_changed(value: float) -> void:
	_add_effect_attribute("shake", "level", snapped(value, 0.1), 5.0)

## Update the shake connected value
func _on_shake_connected_toggled(toggled_on: bool) -> void:
	_add_effect_attribute("shake", "connected", int(toggled_on), 1)
#endregion

#region === Fade effect handling ===============================================

## Add fade effect to the selected text
func _on_fade_effect_pressed() -> void:
	_change_effect_bar(4)
	_insert_tags_on_selected_text("[fade]", "[/fade]", true)

## Update the fade start value
func _on_fade_start_value_changed(value: float) -> void:
	_add_effect_attribute("fade", "start", snapped(value, 0.1), 0.0)

## Update the fade length value
func _on_fade_length_value_changed(value: float) -> void:
	_add_effect_attribute("fade", "length", snapped(value, 0.1), 10.0)
#endregion

#region === Rainbow effect handling ============================================

## Add rainbow effect to the selected text
func _on_rainbow_effect_pressed() -> void:
	_change_effect_bar(5)
	_insert_tags_on_selected_text("[rainbow]", "[/rainbow]", true)

## Update the rainbow frequency value
func _on_rainbow_freq_value_changed(value: float) -> void:
	_add_effect_attribute("rainbow", "freq", snapped(value, 0.1), 1.0)

## Update the rainbow saturation value
func _on_rainbow_sat_value_changed(value: float) -> void:
	_add_effect_attribute("rainbow", "sat", snapped(value, 0.1), 0.8)

## Update the rainbow 'value' value
func _on_rainbow_val_value_changed(value: float) -> void:
	_add_effect_attribute("rainbow", "val", snapped(value, 0.1), 0.8)

## Update the rainbow speed value
func _on_rainbow_speed_value_changed(value: float) -> void:
	_add_effect_attribute("rainbow", "speed", snapped(value, 0.1), 1.0)
#endregion

#endregion