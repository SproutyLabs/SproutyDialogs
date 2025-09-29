@tool
extends HSplitContainer

# -----------------------------------------------------------------------------
# Text Settings
# -----------------------------------------------------------------------------
## This script handles the text settings panel in the Sprouty Dialogs editor.
## It allows to configure the text behavior, display and skipping options.
# -----------------------------------------------------------------------------

## Typing speed field
@onready var _typing_speed_field: SpinBox = %TypingSpeedField
## Open URL on meta tag toggle
@onready var _open_url_on_meta_toggle: CheckButton = %OpenUrlOnMetaToggle

## New line as new dialog toggle
@onready var _new_line_toggle: CheckButton = %NewLineToggle
## Split dialog by max characters toggle
@onready var _split_dialog_toggle: CheckButton = %SplitDialogToggle
## Max characters per dialog field
@onready var _max_character_field: SpinBox = %MaxCharacterField

## Allow skip reveal toggle
@onready var _allow_skip_reveal_toggle: CheckButton = %AllowSkipRevealToggle
## Can skip delay field
@onready var _can_skip_delay_field: SpinBox = %CanSkipDelayField
## Skip continue delay field
@onready var _skip_continue_delay_field: SpinBox = %SkipContinueDelayField


func _ready():
	_typing_speed_field.value_changed.connect(_on_typing_speed_changed)
	_open_url_on_meta_toggle.toggled.connect(_on_open_url_on_meta_toggled)

	_new_line_toggle.toggled.connect(_on_new_line_toggled)
	_split_dialog_toggle.toggled.connect(_on_split_dialog_toggled)
	_max_character_field.value_changed.connect(_on_max_character_changed)

	_allow_skip_reveal_toggle.toggled.connect(_on_allow_skip_reveal_toggled)
	_can_skip_delay_field.value_changed.connect(_on_can_skip_delay_changed)
	_skip_continue_delay_field.value_changed.connect(_on_skip_continue_delay_changed)

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Load settings and set the values in the UI
func _load_settings() -> void:
	_typing_speed_field.value = \
			EditorSproutyDialogsSettingsManager.get_setting("default_typing_speed")
	_open_url_on_meta_toggle.button_pressed = \
			EditorSproutyDialogsSettingsManager.get_setting("open_url_on_meta_tag_click")
	_new_line_toggle.button_pressed = \
			EditorSproutyDialogsSettingsManager.get_setting("new_line_as_new_dialog")
	_split_dialog_toggle.button_pressed = \
			EditorSproutyDialogsSettingsManager.get_setting("split_dialog_by_max_characters")
	_max_character_field.value = \
			EditorSproutyDialogsSettingsManager.get_setting("max_characters")
	_allow_skip_reveal_toggle.button_pressed = \
			EditorSproutyDialogsSettingsManager.get_setting("allow_skip_text_reveal")
	_can_skip_delay_field.value = \
			EditorSproutyDialogsSettingsManager.get_setting("can_skip_delay")
	_skip_continue_delay_field.value = \
			EditorSproutyDialogsSettingsManager.get_setting("skip_continue_delay")


## Update settings when the panel is selected
func update_settings() -> void:
	pass


## Handle when the typing speed is changed
func _on_typing_speed_changed(value: float) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("default_typing_speed", value)


## Handle when the open URL on meta tag toggle is changed
func _on_open_url_on_meta_toggled(pressed: bool) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("open_url_on_meta_tag_click", pressed)


## Handle when the new line as new dialog toggle is changed
func _on_new_line_toggled(pressed: bool) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("new_line_as_new_dialog", pressed)


## Handle when the split dialog by max characters toggle is changed
func _on_split_dialog_toggled(pressed: bool) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("split_dialog_by_max_characters", pressed)


## Handle when the max characters per dialog is changed
func _on_max_character_changed(value: float) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("max_characters", value)


## Handle when the allow skip reveal toggle is changed
func _on_allow_skip_reveal_toggled(pressed: bool) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("allow_skip_text_reveal", pressed)


## Handle when the can skip delay is changed
func _on_can_skip_delay_changed(value: float) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("can_skip_delay", value)


## Handle when the skip continue delay is changed
func _on_skip_continue_delay_changed(value: float) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("skip_continue_delay", value)