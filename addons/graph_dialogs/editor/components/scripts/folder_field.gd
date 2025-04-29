@tool
class_name GraphDialogsFolderField
extends MarginContainer

## -----------------------------------------------------------------------------
##  Folder Field Component
##
##  Component that allows the user to select a folder from the file system.
## -----------------------------------------------------------------------------

## Triggered when the folder path is changed.
signal folder_path_changed(path: String)

## File dialog to select a folder.
@onready var _folder_dialog: FileDialog = $OpenFolderDialog
## Open button to show the file dialog.
@onready var _open_button: Button = %OpenButton
## Clear button to clear the current file path.
@onready var _clear_button: Button = %ClearButton
## Field to show the current file path.
@onready var _path_field: LineEdit = %Field

## Current folder path.
var _current_value: String

func _ready():
	# Connect signals
	_folder_dialog.connect("dir_selected", _on_folder_path_selected)
	_open_button.button_down.connect(_on_open_pressed)
	_clear_button.button_up.connect(clear_path)

	_open_button.icon = get_theme_icon("Folder", "EditorIcons")
	_clear_button.icon = get_theme_icon("Clear", "EditorIcons")


## Get the current value of the field.
func get_value() -> String:
	return _path_field.text


## Set the current value of the field.
func set_value(value: String) -> void:
	_current_value = value
	_path_field.text = value


## Show the folder dialog to select a folder.
func _on_open_pressed() -> void:
	_folder_dialog.popup_centered()


## Set path of folder selected in the file dialog.
func _on_folder_path_selected(path: String) -> void:
	folder_path_changed.emit(path)
	set_value(path)


## Triggered when the text of the field changes.
func _on_field_text_changed(new_text: String) -> void:
	folder_path_changed.emit(new_text)
	set_value(new_text)


## Clear the current value of the field.
func clear_path() -> void:
	folder_path_changed.emit("")
	set_value("")