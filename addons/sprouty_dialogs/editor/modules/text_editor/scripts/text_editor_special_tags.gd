@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Text Editor Special Tags
# -----------------------------------------------------------------------------
## Controller to add special text effect tags to the text in the text editor.
# -----------------------------------------------------------------------------

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor
## Tags options bars (speed, wait, if, etc.)
@onready var _tags_bars: Array = $TagsContainer.get_children()

## Speed tag fields
@onready var _speed_type_dropdown = %SpeedTypeDropdown
@onready var _speed_input: SpinBox = %SpeedInput

## Wait tag fields
@onready var _wait_input: SpinBox = %WaitInput

## Current tag bar shown in the text editor
var _current_tag_bar: Control = null


## Change the current tag bar shown in the text editor
func _change_tag_bar(bar_index: int) -> void:
	if _current_tag_bar:
		_current_tag_bar.hide()
	_current_tag_bar = _tags_bars[bar_index]
	_current_tag_bar.show()


## Show the tags list menu when the tags button is pressed
func _on_add_tag_pressed() -> void:
	# Hide the current tag bar when opening the tags menu
	if visible == false and _current_tag_bar:
		_current_tag_bar.hide()
		_current_tag_bar = null
	text_editor.change_option_bar(8)
	
	# Show popup menu with the tags
	var pos := get_global_mouse_position() + Vector2(get_window().position)
	$TagsMenu.popup(Rect2(pos, $TagsMenu.get_contents_minimum_size()))


## Select a tag from the tags menu
func _on_tags_menu_id_pressed(id: int) -> void:
	match id:
		0:
			_on_speed_tag_pressed()
		1:
			_on_wait_tag_pressed()
		2:
			_on_if_tag_pressed()


#region === Speed tag handling =================================================

## Add speed tag to the selected text
func _on_speed_tag_pressed() -> void:
	_change_tag_bar(0)
	_update_speed_tag(_speed_input.value)


## Update the speed type
func _on_speed_type_selected(index: int) -> void:
	var type_id: int = _speed_type_dropdown.get_item_id(index)
	match type_id:
		0: # Absolute Speed
			_speed_input.suffix = "s"
			_speed_input.step = 0.001
			_speed_input.value = 0.0
		1: # Relative Speed
			_speed_input.suffix = "x"
			_speed_input.step = 0.01
			_speed_input.value = 1.0


## Update the speed value
func _on_speed_value_changed(value: float) -> void:
	_update_speed_tag(value)


## Update the speed tag
func _update_speed_tag(value: float) -> void:
	if not text_editor:
		return
	match _speed_type_dropdown.selected:
		0: # Absolute Speed
			text_editor.update_code_tags("[speed=" + str(value) + "]", "[/speed]", "", true)
		1: # Relative Speed
			text_editor.update_code_tags("[speed=" + str(value) + "x]", "[/speed]", "", true)

#endregion

#region === Wait tag handling ==================================================

## Add wait tag to the selected text
func _on_wait_tag_pressed() -> void:
	_change_tag_bar(1)
	_on_wait_value_changed(_wait_input.value)

## Update the wait value
func _on_wait_value_changed(value: float) -> void:
	text_editor.update_code_tags("[wait=" + str(value) + "]", "", "", true)

#endregion

#region === If tag handling =================================================

## Add if tag to the selected text
func _on_if_tag_pressed() -> void:
	_change_tag_bar(2)

#endregion