@tool
class_name EditorSproutyDialogsOptionContainer
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Option Container Component
# -----------------------------------------------------------------------------
## Component that display a dialog option in the options node.
# -----------------------------------------------------------------------------

## Emitted when the text in any of the text boxes changes
signal modified
## Emitted when pressing the expand button to open the text editor
signal open_text_editor(text_box: TextEdit)
## Emitted when change the focus to another text box while the text editor is open
signal update_text_editor(text_box: TextEdit)
## Triggered when the option is removed
signal option_removed(index)

## Option header to display the option position index
@onready var _option_label: Label = $OptionHeader/OptionLabel
## Remove button
@onready var _remove_button: Button = $OptionHeader/RemoveButton

## Expandable text box for the option text
@onready var _default_text_box: Control = $ExpandableTextBox
## Translations container to handle the dialog translations
@onready var _translation_boxes: Control = $TranslationsContainer

## Default locale for dialog text
var _default_locale: String = ""
## Flag to indicate if translations are enabled
var _translations_enabled: bool = false
## Flag to indicate if the dialog has no translation (only default)
var _dialog_without_translation: bool = true

## Dialog texts and their translations
var _dialogs_text: Dictionary = {}
## Option position index
var option_index: int = 0


func _ready() -> void:
	_default_text_box.open_text_editor.connect(open_text_editor.emit)
	_translation_boxes.open_text_editor.connect(open_text_editor.emit)
	_default_text_box.update_text_editor.connect(update_text_editor.emit)
	_translation_boxes.update_text_editor.connect(update_text_editor.emit)
	_default_text_box.text_changed.connect(modified.emit)
	_translation_boxes.modified.connect(modified.emit)
	_remove_button.pressed.connect(_on_remove_button_pressed)
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_show_remove_button()
	_set_translation_text_boxes()
	on_translation_enabled_changed( # Enable/disable translation section
			EditorSproutyDialogsSettingsManager.get_setting("enable_translations")
		)


## Return the dialog key for this option
func get_dialog_key() -> String:
	if get_parent().start_node:
		# <start id>_OPT<options node index>_<option index> -> START_OPT1_1
		return (get_parent().get_start_id() + "_OPT"
			+ str(get_parent().node_index) + "_" + str(option_index + 1))
	return "UNPLUGGED_OPT" + str(get_parent().node_index) + "_" + str(option_index + 1)


## Get dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = _dialogs_text
	dialogs["default"] = _default_text_box.get_text()
	if _translations_enabled:
		if _default_locale != "":
			dialogs[_default_locale] = _default_text_box.get_text()
		dialogs.merge(_translation_boxes.get_translations_text())
	return dialogs


## Load dialog and translations
func load_dialogs(dialogs: Dictionary) -> void:
	_dialogs_text = dialogs
	if dialogs.size() > 1: # There are translations
		_dialog_without_translation = false
	
	if _translations_enabled and dialogs.has(_default_locale):
		_default_text_box.set_text(dialogs[_default_locale])
	else: # Use default if translations disabled or no default locale dialog
		_default_text_box.set_text(dialogs["default"])
	_translation_boxes.load_translations_text(dialogs)


## Update the locale text boxes
func on_locales_changed() -> void:
	var dialogs = get_dialogs_text()
	var previous_default_locale = _default_locale
	_set_translation_text_boxes()
	# Handle when there was no translation before
	if _dialog_without_translation and _default_locale != "":
		dialogs[_default_locale] = dialogs["default"]
		_dialog_without_translation = false
	# Handle when the default locale changes
	elif previous_default_locale != _default_locale:
		if previous_default_locale != "":
			dialogs[previous_default_locale] = dialogs["default"]
		dialogs["default"] = dialogs[_default_locale] \
				if dialogs.has(_default_locale) else dialogs["default"]
		_dialogs_text = dialogs
	load_dialogs(dialogs)


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	_translations_enabled = enabled
	if enabled: on_locales_changed()
	%DefaultLocaleLabel.visible = enabled
	_translation_boxes.visible = enabled


## Set translation text boxes
func _set_translation_text_boxes() -> void:
	_translations_enabled = EditorSproutyDialogsSettingsManager.get_setting("enable_translations")
	_default_locale = EditorSproutyDialogsSettingsManager.get_setting("default_locale")
	var locales = EditorSproutyDialogsSettingsManager.get_setting("locales")
	_translations_enabled = _translations_enabled and locales.size() > 0
	_default_locale = _default_locale if _translations_enabled else ""
	%DefaultLocaleLabel.text = "(" + _default_locale + ")"
	_default_text_box.set_text("")
	_translation_boxes.set_translation_boxes(
			locales.filter(
				func(locale): return locale != (_default_locale if _translations_enabled else "")
			)
		)
	%DefaultLocaleLabel.visible = _translations_enabled and _default_locale != ""
	_translation_boxes.visible = _translations_enabled


## Update the option position index
func update_option_index(index: int) -> void:
	_option_label.text = "Option #" + str(index + 1)
	name = name.split('_')[0] + "_" + str(index)
	option_index = index
	_show_remove_button()


## Show remove button only when it is not the first option
func _show_remove_button() -> void:
	$OptionHeader/RemoveButton.visible = option_index


## Remove option when the remove button is pressed
func _on_remove_button_pressed() -> void:
	option_removed.emit(option_index)
