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


## Update settings when the panel is selected
func update_settings() -> void:
	pass


## Load settings and set the values in the UI
func _load_settings() -> void:
	_typing_speed_field.value = \
			SproutyDialogsSettingsManager.get_setting("default_typing_speed")
	_open_url_on_meta_toggle.button_pressed = \
			SproutyDialogsSettingsManager.get_setting("open_url_on_meta_tag_click")
	_new_line_toggle.button_pressed = \
			SproutyDialogsSettingsManager.get_setting("new_line_as_new_dialog")
	_split_dialog_toggle.button_pressed = \
			SproutyDialogsSettingsManager.get_setting("split_dialog_by_max_characters")
	_max_character_field.value = \
			SproutyDialogsSettingsManager.get_setting("max_characters")
	_allow_skip_reveal_toggle.button_pressed = \
			SproutyDialogsSettingsManager.get_setting("allow_skip_text_reveal")
	_can_skip_delay_field.value = \
			SproutyDialogsSettingsManager.get_setting("can_skip_delay")
	_skip_continue_delay_field.value = \
			SproutyDialogsSettingsManager.get_setting("skip_continue_delay")
	
	_set_reset_button(_typing_speed_field, "default_typing_speed")
	_set_reset_button(_open_url_on_meta_toggle, "open_url_on_meta_tag_click")
	_set_reset_button(_new_line_toggle, "new_line_as_new_dialog")
	_set_reset_button(_split_dialog_toggle, "split_dialog_by_max_characters")
	_set_reset_button(_max_character_field, "max_characters")
	_set_reset_button(_allow_skip_reveal_toggle, "allow_skip_text_reveal")
	_set_reset_button(_can_skip_delay_field, "can_skip_delay")
	_set_reset_button(_skip_continue_delay_field, "skip_continue_delay")


## Setup the reset button of a field
func _set_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is SpinBox:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_value_no_signal(default_value)
			reset_button.hide()
		)
		reset_button.visible = field.value != default_value
	
	elif field is CheckButton:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_pressed_no_signal(default_value)
			reset_button.hide()
		)
		reset_button.visible = field.button_pressed != default_value


## Show the reset button of a field
func _show_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is SpinBox:
		reset_button.visible = field.value != default_value
	elif field is CheckButton:
		reset_button.visible = field.button_pressed != default_value


## Handle when the typing speed is changed
func _on_typing_speed_changed(value: float) -> void:
	SproutyDialogsSettingsManager.set_setting("default_typing_speed", value)
	_show_reset_button(_typing_speed_field, "default_typing_speed")


## Handle when the open URL on meta tag toggle is changed
func _on_open_url_on_meta_toggled(pressed: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("open_url_on_meta_tag_click", pressed)
	_show_reset_button(_open_url_on_meta_toggle, "open_url_on_meta_tag_click")


## Handle when the new line as new dialog toggle is changed
func _on_new_line_toggled(pressed: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("new_line_as_new_dialog", pressed)
	_show_reset_button(_new_line_toggle, "new_line_as_new_dialog")


## Handle when the split dialog by max characters toggle is changed
func _on_split_dialog_toggled(pressed: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("split_dialog_by_max_characters", pressed)
	_show_reset_button(_split_dialog_toggle, "split_dialog_by_max_characters")


## Handle when the max characters per dialog is changed
func _on_max_character_changed(value: float) -> void:
	SproutyDialogsSettingsManager.set_setting("max_characters", value)
	_set_reset_button(_max_character_field, "max_characters")


## Handle when the allow skip reveal toggle is changed
func _on_allow_skip_reveal_toggled(pressed: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("allow_skip_text_reveal", pressed)
	_show_reset_button(_allow_skip_reveal_toggle, "allow_skip_text_reveal")


## Handle when the can skip delay is changed
func _on_can_skip_delay_changed(value: float) -> void:
	SproutyDialogsSettingsManager.set_setting("can_skip_delay", value)
	_show_reset_button(_can_skip_delay_field, "can_skip_delay")


## Handle when the skip continue delay is changed
func _on_skip_continue_delay_changed(value: float) -> void:
	SproutyDialogsSettingsManager.set_setting("skip_continue_delay", value)
	_show_reset_button(_skip_continue_delay_field, "skip_continue_delay")