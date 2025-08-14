@tool
class_name GraphDialogsFileField
extends MarginContainer

## -----------------------------------------------------------------------------
##  File Field Component
##
##  Component that allows the user to select a file from the file system.
## -----------------------------------------------------------------------------

## Emitted when the file path changes.
signal file_path_changed(path: String)
## Emitted when the file path is submitted.
signal file_path_submitted(path: String)

## Placeholder text to show when the field is empty.
@export var _placeholder_text: String = "Select a file..."
## File type to load the last used path.
@export var _recent_file_type: String = ""
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


func _ready():
	# Connect signals
	_file_dialog.file_selected.connect(_on_file_dialog_selected)
	_path_field.text_submitted.connect(_on_field_text_submitted)
	_path_field.text_changed.connect(_on_field_text_changed)
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
	_path_field.text = value


## Disable the field for editing.
func disable_field(disable: bool) -> void:
	_path_field.editable = not disable
	_open_button.disabled = disable
	_clear_button.disabled = disable


## Show the file dialog to select a file.
func _on_open_pressed() -> void:
	_file_dialog.set_current_dir(GraphDialogsFileUtils.get_recent_file_path(_recent_file_type))
	_file_dialog.filters = file_filters
	_file_dialog.popup_centered()


## Set path of file selected in the file dialog.
func _on_file_dialog_selected(path: String) -> void:
	file_path_submitted.emit(path)
	file_path_changed.emit(path)
	set_value(path)
	GraphDialogsFileUtils.set_recent_file_path(_recent_file_type, path)


## Handle the text change event of the field.
func _on_field_text_changed(new_text: String) -> void:
	file_path_changed.emit(new_text)
	set_value(new_text)


## Handle the text submission event of the field.
func _on_field_text_submitted(new_text: String) -> void:
	file_path_submitted.emit(new_text)
	set_value(new_text)


## Clear the current value of the field.
func clear_path() -> void:
	file_path_changed.emit("")
	set_value("")
