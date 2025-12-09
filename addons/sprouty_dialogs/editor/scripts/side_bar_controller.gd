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

## Version button reference
@onready var version_button: Button = %VersionButton


func _ready():
	_on_expand_button_pressed() # File manager is expanded by default


## Set the plugin version on the version button
func set_plugin_version(version: String) -> void:
	version_button.text = "v" + version


## Set the version status on the version button
func set_version_status(status: int) -> void:
	match status:
		0: # Up to date
			version_button.modulate = Color.WHITE
		1: # Update available
			version_button.modulate = Color.ORANGE
		2: # Failure
			version_button.modulate = Color.GRAY


## Show or hide the CSV file path field
func csv_path_field_visible(visible: bool) -> void:
	if _csv_file_field:
		_csv_file_field.visible = (visible
			and SproutyDialogsSettingsManager.get_setting("enable_translations")
			and SproutyDialogsSettingsManager.get_setting("use_csv_files")
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
