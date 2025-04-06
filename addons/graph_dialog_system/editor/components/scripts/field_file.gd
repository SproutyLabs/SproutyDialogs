@tool
extends MarginContainer
class_name GDialogsFileField

## =============================================================================
##  File Field Component
##
##  Component that allows the user to select a file from the file system.
## =============================================================================

## Triggered when the file path is changed.
signal file_path_changed(path: String)

## Placeholder text to show when the field is empty.
@export var _placeholder_text: String = "Select a file..."
## File extension filters.
@export var file_filters: PackedStringArray

## File dialog to select a file.
@onready var _file_dialog: FileDialog = $OpenFileDialog
## Open button to show the file dialog.
@onready var _open_button: Button = %OpenButton
## Clear button to clear the current file path.
@onready var _clear_button: Button = %ClearButton
## Field to show the current file path.
@onready var _path_field: LineEdit = %Field

## Current file path.
var _current_value: String


func _ready():
	# Connect signals
	_file_dialog.connect("file_selected", _on_file_dialog_selected)
	_open_button.button_down.connect(_on_open_pressed)
	_clear_button.button_up.connect(clear_path)

	_open_button.icon = get_theme_icon("Folder", "EditorIcons")
	_clear_button.icon = get_theme_icon("Clear", "EditorIcons")
	
	_path_field.placeholder_text = _placeholder_text


## Get the current value of the field.
func get_value() -> String:
	return _path_field.text


## Set the current value of the field.
func set_value(value: String) -> void:
	_current_value = value
	_path_field.text = value


## Show the file dialog to select a file.
func _on_open_pressed() -> void:
	_file_dialog.filters = file_filters
	_file_dialog.popup_centered()


## Set path of file selected in the file dialog.
func _on_file_dialog_selected(path: String) -> void:
	file_path_changed.emit(path)
	set_value(path)


## Triggered when the text of the field changes.
func _on_field_text_changed(new_text: String) -> void:
	file_path_changed.emit(new_text)
	set_value(new_text)


## Clear the current value of the field.
func clear_path() -> void:
	file_path_changed.emit("")
	set_value("")
