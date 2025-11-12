@tool
class_name EditorSproutyDialogsComboBox
extends LineEdit

# -----------------------------------------------------------------------------
# Sprouty Dialogs Combo Box Component
# -----------------------------------------------------------------------------
## Component that combines a text input with a dropdown list of selectable options. 
## Users can either pick an item from the list or type a custom value directly.
# -----------------------------------------------------------------------------	

## Emitted when an option is selected from the dropdown list
signal option_selected(option: String)
## Emitted when the text in the input field changes
signal input_changed(text: String)
## Emitted when the user submits the input
signal input_submitted(text: String)
## Emitted when the input field loses focus
signal input_focus_exited()

## Input field placeholder text
@export var _placeholder_text: String = "Write something..."
## Dropdown list containing the options
@onready var _dropdown_popup: PopupMenu = $DropdownPopup

## Options to show in the dropdown list
var _options: Array = []


func _ready():
	text_changed.connect(_on_input_text_changed)
	text_submitted.connect(_on_input_text_submitted)
	focus_exited.connect(_on_input_field_focus_exited)
	_dropdown_popup.index_pressed.connect(_on_dropdown_item_selected)
	placeholder_text = placeholder_text
	_dropdown_popup.hide()


## Returns the current text in the input field
func get_value() -> String:
	return text


## Sets the text in the input field
func set_value(value: String) -> void:
	text = value


## Returns the current options for the dropdown list
func get_options() -> Array[String]:
	return _options


## Set the options to show in the dropdown list
func set_options(options: Array) -> void:
	_options = options


## Handle text change in the input field
func _on_input_text_changed(new_text: String) -> void:
	_dropdown_popup.clear()
	if new_text == "":
		for option in _options:
			_dropdown_popup.add_item(option)
	else:
		for option in _options:
			if new_text.to_lower() in option.to_lower():
				_dropdown_popup.add_item(option)
	if _dropdown_popup.item_count > 0:
		_show_dropdown()
	input_changed.emit(new_text)


## Handle text submission in the input field
func _on_input_text_submitted(new_text: String) -> void:
	_dropdown_popup.hide()
	input_submitted.emit(new_text)


## Handle item selection from the dropdown list
func _on_dropdown_item_selected(index: int) -> void:
	var selected_text = _dropdown_popup.get_item_text(index)
	text = selected_text
	option_selected.emit(selected_text)
	input_changed.emit(selected_text)


## Handle focus exit from the input field
func _on_input_field_focus_exited() -> void:
	_dropdown_popup.hide()
	input_focus_exited.emit()


## Show the dropdown list
func _show_dropdown() -> void:
	_dropdown_popup.size.x = size.x
	var rect = get_global_rect()
	rect.position.y += size.y * 2
	_dropdown_popup.popup(rect)