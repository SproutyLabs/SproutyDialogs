@tool
extends VSplitContainer

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
			and ProjectSettings.get_setting("graph_dialogs/translation/translation_enabled")
			and ProjectSettings.get_setting("graph_dialogs/translation/translation_with_csv")
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