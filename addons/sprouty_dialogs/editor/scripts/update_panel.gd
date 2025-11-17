@tool
extends PopupPanel

# -----------------------------------------------------------------------------
# Update Panel
# -----------------------------------------------------------------------------
## Panel to show information of a new version of the Sprouty Dialogs plugin.
# -----------------------------------------------------------------------------

## Emitted when the user requests to install the update
signal install_update_requested()

## Version label reference
@onready var _version_label: RichTextLabel = $Container/VersionLabel
## New version info label reference
@onready var _info_label: RichTextLabel = $Container/InfoLabel

## Install button reference
@onready var _install_button: Button = $Container/InstallButton


func _ready() -> void:
	_install_button.pressed.connect(_on_install_button_pressed)
	hide()


## Set the update information for the update panel
func set_update_info(update_info: Dictionary) -> void:
	_version_label.text = "[color=orange][b][i]New Version " + update_info.version + " Available!"
	_info_label.bbcode_text = update_info.body


## Handle Install button pressed
func _on_install_button_pressed() -> void:
	install_update_requested.emit()
	hide()