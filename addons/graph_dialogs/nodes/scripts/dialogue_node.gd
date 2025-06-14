@tool
class_name DialogueNode
extends BaseNode

## -----------------------------------------------------------------------------
## Dialogue Node
##
## Node to display dialogues in the dialog system.
## Allows to set dialog text and translations for different characters.
## -----------------------------------------------------------------------------

## Emitted when the dialogue node was processed.
signal dialogue_processed(character: String, dialog: String, next_node: String)

## Character dropdown selector
@onready var _character_dropdown: OptionButton = %CharacterSelect
## Portrait dropdown selector
@onready var _portrait_dropdown: OptionButton = %PortraitSelect
## Text box for dialog in default locale
@onready var _default_text_box: HBoxContainer = %DefaultTextBox
## Text boxes container for translations
@onready var _translation_boxes: VBoxContainer = %Translations

## Character key
@onready var _char_key: String = _character_dropdown.get_item_text(_character_dropdown.selected)

## Default locale for dialog text
var _default_locale: String = ""


func _ready():
	super ()
	# Connect signal to open text editor from graph
	_translation_boxes.open_text_editor.connect(get_parent().open_text_editor.emit)
	_default_text_box.open_text_editor.connect(
			get_parent().open_text_editor.emit.bind(_default_text_box.text_box)
		)
	_set_characters_dropdown()
	_set_translation_text_boxes()


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"char_key": "",
		"dialog_key": get_dialog_translation_key(),
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	_char_key = dict["char_key"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]


func process_node(node_data: Dictionary) -> void:
	var character = node_data["char_key"]
	var dialog = tr(node_data["dialog_key"])
	dialogue_processed.emit(character, dialog, node_data["to_node"][0])

#endregion


## Load dialog and translations
func load_dialogs(dialogs: Dictionary) -> void:
	_default_text_box.set_text(dialogs[_default_locale])
	_translation_boxes.load_translations_text(dialogs)


## Get dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = {}
	dialogs[_default_locale] = _default_text_box.get_text()
	dialogs.merge(_translation_boxes.get_translations_text())
	return dialogs


## Create the dialog key for translation reference in the CSV file
func get_dialog_translation_key() -> String:
	print("get_dialog_translation_key: ", _char_key, " ", _default_locale)
	if start_node != null: return get_start_id() + "_" + str(node_index)
	else: return "DIALOG_NODE_" + str(node_index)


## Set translation text boxes
func _set_translation_text_boxes() -> void:
	_default_locale = ProjectSettings.get_setting("graph_dialogs/translation/default_locale")
	%DefaultLocaleLabel.text = "(" + _default_locale + ")"
	_default_text_box.set_text("")
	_translation_boxes.set_translation_boxes(
			ProjectSettings.get_setting("graph_dialogs/translation/locales").filter(
				func(locale): return locale != _default_locale
			)
		)


## Update the locale text boxes
func on_locales_changed() -> void:
	var dialogs = get_dialogs_text()
	_set_translation_text_boxes()
	load_dialogs(dialogs)


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	%DefaultLocaleLabel.visible = enabled
	_translation_boxes.visible = enabled


## Handle the character references change
func on_character_references_changed() -> void:
	var selected_item = _character_dropdown.get_item_text(_character_dropdown.selected)
	var items = _set_characters_dropdown()

	if items.has(selected_item): # If the selected item is in the list, select it
		_character_dropdown.select(items.index_of(selected_item))
	else: # Select the first item if the selected item is not found
		_character_dropdown.select(0)


## Set the character dropdown options from project settings
func _set_characters_dropdown() -> Array:
	if not ProjectSettings.has_setting("graph_dialogs/references/characters"):
		return []
	_character_dropdown = %CharacterSelect
	var characters = ProjectSettings.get_setting("graph_dialogs/references/characters").keys()
	_character_dropdown.clear()
	characters.insert(0, "(No one)")
	for character in characters:
		_character_dropdown.add_item(character.capitalize() if character != "(No one)" else character)
	return characters


## Set the portrait dropdown options based on character selection
func _set_portrait_dropdown(character: String) -> void:
	pass