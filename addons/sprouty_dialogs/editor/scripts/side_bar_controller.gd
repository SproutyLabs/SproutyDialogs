@tool
extends VSplitContainer

# -----------------------------------------------------------------------------
# Side Bar Controller
# -----------------------------------------------------------------------------
## Controller to manage the side bar in the editor.
## It provides methods to show or hide the file manager and the CSV file path field.
# -----------------------------------------------------------------------------

## File manager reference
@onready var file_manager: Control = %FileManager
## CSV file field reference
@onready var _csv_file_field: Control = %CSVFileField

## Side bar container to show the file manager
@onready var _content_container: Container = $ContentContainer
## Expand button to show the file manager
@onready var _expand_bar: Container = $ExpandBar


func _ready():
	_on_expand_button_pressed() # File manager is expanded by default


## Show or hide the CSV file path field
func csv_path_field_visible(visible: bool) -> void:
	if _csv_file_field:
		_csv_file_field.visible = (visible
			and EditorSproutyDialogsSettingsManager.get_setting("enable_translations")
			and EditorSproutyDialogsSettingsManager.get_setting("use_csv")
		)


## Collapse the file manager
func _on_close_button_pressed() -> void:
	if get_parent() is SplitContainer:
		get_parent().collapsed = true
		_content_container.hide()
		_expand_bar.show()


## Expand the file manager
func _on_expand_button_pressed() -> void:
	if get_parent() is SplitContainer:
		get_parent().collapsed = false
		_content_container.show()
		_expand_bar.hide()