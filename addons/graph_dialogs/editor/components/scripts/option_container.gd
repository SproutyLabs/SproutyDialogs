@tool
class_name GraphDialogsOptionContainer
extends VBoxContainer

## -----------------------------------------------------------------------------
## Option container component
##
## Component that display a dialog option in the options node.
## -----------------------------------------------------------------------------

## Emitted when pressing the expand button to open the text editor
signal open_text_editor(text_box: TextEdit)
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

## Option position index
var option_index: int = 0
## Default locale for dialog text
var _default_locale: String = ""


func _ready() -> void:
	_default_text_box.open_text_editor.connect(open_text_editor.emit.bind(_default_text_box.text_box))
	_translation_boxes.open_text_editor.connect(open_text_editor.emit)
	_remove_button.pressed.connect(_on_remove_button_pressed)
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_show_remove_button()
	_set_translation_text_boxes()


## Return the dialog key for this option
func get_dialog_key() -> String:
	if get_parent().start_node:
		# <start id>_OPTIONS_<options node index>_<option index> -> START_OPTION_1_1
		return (get_parent().get_start_id() + "_OPTION_"
			+ str(get_parent().node_index) + "_" + str(option_index))
	return "OPTION_" + str(get_parent().node_index) + "_" + str(option_index)


## Get dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = {}
	dialogs[_default_locale] = _default_text_box.get_text()
	dialogs.merge(_translation_boxes.get_translations_text())
	return dialogs


## Load dialog and translations
func load_dialogs(dialogs: Dictionary) -> void:
	_default_text_box.set_text(dialogs[_default_locale])
	_translation_boxes.load_translations_text(dialogs)


## Update the locale text boxes
func on_locales_changed() -> void:
	var dialogs = get_dialogs_text()
	_set_translation_text_boxes()
	load_dialogs(dialogs)


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	%DefaultLocaleLabel.visible = enabled
	_translation_boxes.visible = enabled


## Set translation text boxes
func _set_translation_text_boxes() -> void:
	_default_locale = GraphDialogsSettings.get_setting("default_locale")
	%DefaultLocaleLabel.text = "(" + _default_locale + ")"
	_default_text_box.set_text("")
	_translation_boxes.set_translation_boxes(
			GraphDialogsSettings.get_setting("locales").filter(
				func(locale): return locale != _default_locale
			)
		)


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
