@tool
class_name EditorSproutyDialogsFileField
extends MarginContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs File Field Component
# -----------------------------------------------------------------------------
## Component that allows the user to select a file from the file system.
## Also can be configured to select a directory instead of a file.
# -----------------------------------------------------------------------------

## Emitted when the file or folder path changes.
signal path_changed(path: String)
## Emitted when the file or folder path is submitted.
signal path_submitted(path: String)

## Emitted when the field loses focus.
signal field_focus_exited()

## Flag to open a directory instead of a file.
@export var _open_directory: bool = false
## Placeholder text to show when the field is empty.
@export var _placeholder_text: String = "Select a file..."
## File type to load the last used path.
@export var _recent_file_type: String = ""
## File extension filters.
@export var file_filters: PackedStringArray

## File dialog to select a file.
@onready var _open_dialog: FileDialog = $OpenDialog
## Field to show the current file path.
@onready var _path_field: LineEdit = %PathField
## Open button to show the file dialog.
@onready var _open_button: Button = %OpenButton
## Clear button to clear the current file path.
@onready var _clear_button: Button = %ClearButton


func _ready():
	# Connect signals
	_path_field.text_submitted.connect(_on_field_text_submitted)
	_path_field.text_changed.connect(_on_field_text_changed)
	_path_field.focus_exited.connect(field_focus_exited.emit)
	_open_button.button_down.connect(_on_open_pressed)
	_clear_button.button_up.connect(clear_path)

	_open_button.icon = get_theme_icon("Folder", "EditorIcons")
	_clear_button.icon = get_theme_icon("Clear", "EditorIcons")
	
	_path_field.placeholder_text = _placeholder_text
	open_directory(_open_directory)


## Returns the current value of the field.
func get_value() -> String:
	return _path_field.text


## Set the current value of the field.
func set_value(value: String) -> void:
	_path_field.text = value


## Configure the field to open a directory instead of a file.
func open_directory(open_dir: bool) -> void:
	_open_directory = open_dir
	if _open_directory:
		_open_dialog.dir_selected.connect(_on_path_dialog_selected)
		_open_dialog.file_mode = _open_dialog.FILE_MODE_OPEN_DIR
		_open_dialog.ok_button_text = "Select Current Folder"
		_open_dialog.title = "Select a Directory"
		_path_field.placeholder_text = "Select a directory..."
	else:
		_open_dialog.file_selected.connect(_on_path_dialog_selected)
		_open_dialog.file_mode = _open_dialog.FILE_MODE_OPEN_FILE
		_open_dialog.ok_button_text = "Open File"
		_open_dialog.title = "Open a File"
		_path_field.placeholder_text = "Select a file..."


## Disable the field for editing.
func disable_field(disable: bool) -> void:
	_path_field.editable = not disable
	_open_button.disabled = disable
	_clear_button.disabled = disable


## Show the file dialog to select a file.
func _on_open_pressed() -> void:
	_open_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path(_recent_file_type))
	_open_dialog.filters = file_filters
	_open_dialog.popup_centered()


## Set path of file or folder selected in the file dialog.
func _on_path_dialog_selected(path: String) -> void:
	path_submitted.emit(path)
	path_changed.emit(path)
	set_value(path)
	SproutyDialogsFileUtils.set_recent_file_path(_recent_file_type, path)
	field_focus_exited.emit()


## Handle the text change event of the field.
func _on_field_text_changed(new_text: String) -> void:
	path_changed.emit(new_text)


## Handle the text submission event of the field.
func _on_field_text_submitted(new_text: String) -> void:
	path_submitted.emit(new_text)


## Clear the current value of the field.
func clear_path() -> void:
	set_value("")
	path_changed.emit("")
