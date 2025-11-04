@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Text Editor Effects
# -----------------------------------------------------------------------------
## Controller to add godot default text effects to the text in the text editor.
# -----------------------------------------------------------------------------

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor
## Effects options bars (pulse, wave, shake, etc.)
@onready var _effects_bars: Array = %EffectsContainer.get_children()
## Pulse effect color sample hex code
@onready var _pulse_color_sample_hex: RichTextLabel = %PulseColorSample

## Current effect bar shown in the text editor
var _current_effect_bar: Control = null


## Change the current effect bar shown in the text editor
func _change_effect_bar(bar_index: int) -> void:
	if _current_effect_bar:
		_current_effect_bar.hide()
	_current_effect_bar = _effects_bars[bar_index]
	_effects_bars[bar_index].show()


## Show the effects list menu when the effects button is pressed
func _on_add_effect_pressed() -> void:
	# Hide the current effect bar when opening the effects menu
	if visible == false and _current_effect_bar:
		_current_effect_bar.hide()
		_current_effect_bar = null
	text_editor.change_option_bar(7)
	
	# Show popup menu with the effects
	var pos := get_global_mouse_position() + Vector2(get_window().position)
	%EffectsMenu.popup(Rect2(pos, %EffectsMenu.get_contents_minimum_size()))

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


#region === Pulse effect handling ===============================================

## Add pulse effect to the selected text
func _on_pulse_effect_pressed() -> void:
	_change_effect_bar(0)
	text_editor.insert_tags_on_selected_text("[pulse]", "[/pulse]", true, "example")

## Update the pulse frequency value
func _on_pulse_freq_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("pulse", "freq", snapped(value, 0.1), 1.0)

## Update the pulse color value
func _on_pulse_color_changed(color: Color) -> void:
	text_editor.add_attribute_to_tag("pulse", "color", color.to_html(), "#ffffff40")
	_pulse_color_sample_hex.text = "Hex: #[color=" + color.to_html() + "]" + color.to_html()

## Update the pulse ease value
func _on_pulse_ease_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("pulse", "ease", snapped(value, 0.1), -2.0)
#endregion

#region === Wave effect handling ===============================================

## Add wave effect to the selected text
func _on_wave_effect_pressed() -> void:
	_change_effect_bar(1)
	text_editor.insert_tags_on_selected_text("[wave]", "[/wave]", true, "example")

## Update the wave amplitude value
func _on_wave_amp_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("wave", "amp", snapped(value, 0.1), 20.0)

## Update the wave frequency value
func _on_wave_freq_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("wave", "freq", snapped(value, 0.1), 5.0)

## Update the wave speed value
func _on_wave_connected_toggled(toggled_on: bool) -> void:
	text_editor.add_attribute_to_tag("wave", "connected", int(toggled_on), 1)
#endregion

#region === Tornado effect handling ============================================

## Add tornado effect to the selected text
func _on_tornado_effect_pressed() -> void:
	_change_effect_bar(2)
	text_editor.insert_tags_on_selected_text("[tornado]", "[/tornado]", true, "example")

## Update the tornado radius value
func _on_tornado_radius_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("tornado", "radius", snapped(value, 0.1), 10.0)

## Update the tornado frequency value
func _on_tornado_freq_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("tornado", "freq", snapped(value, 0.1), 1.0)

## Update the tornado connected value
func _on_tornado_connected_toggled(toggled_on: bool) -> void:
	text_editor.add_attribute_to_tag("tornado", "connected", int(toggled_on), 1)
#endregion

#region === Shake effect handling ==============================================

## Add shake effect to the selected text
func _on_shake_effect_pressed() -> void:
	_change_effect_bar(3)
	text_editor.insert_tags_on_selected_text("[shake]", "[/shake]", true, "example")

## Update the shake rate value
func _on_shake_rate_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("shake", "rate", snapped(value, 0.1), 20.0)

## Update the shake level value
func _on_shake_level_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("shake", "level", snapped(value, 0.1), 5.0)

## Update the shake connected value
func _on_shake_connected_toggled(toggled_on: bool) -> void:
	text_editor.add_attribute_to_tag("shake", "connected", int(toggled_on), 1)
#endregion

#region === Fade effect handling ===============================================

## Add fade effect to the selected text
func _on_fade_effect_pressed() -> void:
	_change_effect_bar(4)
	text_editor.insert_tags_on_selected_text("[fade]", "[/fade]", true, "example")

## Update the fade start value
func _on_fade_start_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("fade", "start", snapped(value, 0.1), 0.0)

## Update the fade length value
func _on_fade_length_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("fade", "length", snapped(value, 0.1), 10.0)
#endregion

#region === Rainbow effect handling ============================================

## Add rainbow effect to the selected text
func _on_rainbow_effect_pressed() -> void:
	_change_effect_bar(5)
	text_editor.insert_tags_on_selected_text("[rainbow]", "[/rainbow]", true, "example")

## Update the rainbow frequency value
func _on_rainbow_freq_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("rainbow", "freq", snapped(value, 0.1), 1.0)

## Update the rainbow saturation value
func _on_rainbow_sat_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("rainbow", "sat", snapped(value, 0.1), 0.8)

## Update the rainbow 'value' value
func _on_rainbow_val_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("rainbow", "val", snapped(value, 0.1), 0.8)

## Update the rainbow speed value
func _on_rainbow_speed_value_changed(value: float) -> void:
	text_editor.add_attribute_to_tag("rainbow", "speed", snapped(value, 0.1), 1.0)
#endregion
