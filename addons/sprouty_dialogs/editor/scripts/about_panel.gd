@tool
extends PopupPanel

# -----------------------------------------------------------------------------
# About Panel
# -----------------------------------------------------------------------------
## Panel to show information about the Sprouty Dialogs plugin and update the
## plugin if a new version is available.
# -----------------------------------------------------------------------------

## Emitted when the user requests to check for updates
signal check_updates_requested()

## Version label reference
@onready var _version_label: Label = $Container/VersionLabel
## Version status label reference
@onready var _version_status_label: RichTextLabel = $Container/VersionStatusLabel
## Update button reference
@onready var _update_button: Button = $Container/UpdateButton
## Check Updates button reference
@onready var _check_updates_button: Button = $Container/CheckUpdatesButton

## Update dialog reference
@onready var _update_panel: PopupPanel


func _ready() -> void:
	if find_child("UpdatePanel"): _update_panel = $UpdatePanel
	$Container/Credits/CreditsLabel.meta_clicked.connect(_open_url)
	$Container/Links/DocsButton.pressed.connect(_on_docs_button_pressed)
	$Container/Links/GithubButton.pressed.connect(_on_github_button_pressed)
	$Container/Links/DonateButton.pressed.connect(_on_donate_button_pressed)
	_check_updates_button.icon = get_theme_icon("Reload", "EditorIcons")
	_check_updates_button.pressed.connect(_on_check_updates_button_pressed)
	_update_button.pressed.connect(_on_update_button_pressed)
	_check_updates_button.show()
	_update_button.hide()
	hide()


## Set the version of the plugin
func set_plugin_version(version: String) -> void:
	_version_label.text = "Version " + version


## Set the version status
func set_version_status(status: int) -> void:
	match status:
		0: # Up to date
			_version_status_label.bbcode_text = "[center][color=greenyellow]The plugin is up to date[/color]"
			_check_updates_button.visible = true
			_update_button.visible = false
		1: # Update available
			_version_status_label.bbcode_text = "[center][color=orange]A new version is available![/color]"
			_check_updates_button.visible = false
			_update_button.visible = true
		2: # Failure
			_version_status_label.bbcode_text = "[center][color=gray]Could not check for updates[/color]"
			_check_updates_button.visible = true
			_update_button.visible = false


## Handle Update button pressed
func _on_update_button_pressed() -> void:
	_update_panel.popup_centered()


## Open a URL in the default web browser
func _open_url(meta: String) -> void:
	OS.shell_open(meta)


## Handle Docs button pressed
func _on_docs_button_pressed() -> void:
	_open_url("https://SproutyLabs.github.io/SproutyDialogsDocs")


## Handle GitHub button pressed
func _on_github_button_pressed() -> void:
	_open_url("https://github.com/SproutyLabs/SproutyDialogs")


## Handle Donate button pressed
func _on_donate_button_pressed() -> void:
	_open_url("https://ko-fi.com/kazymila")


## Handle check for updates button pressed
func _on_check_updates_button_pressed() -> void:
	_version_status_label.text = "[center]Checking for updates..."
	check_updates_requested.emit()