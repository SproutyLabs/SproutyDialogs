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
@onready var char_selector: OptionButton = %CharacterSelect
## Text box for dialog in default locale
@onready var default_text_box: HBoxContainer = %DefaultTextBox
## Text boxes container for translations
@onready var translation_boxes: VBoxContainer = %Translations

## Character key
@onready var char_key: String = char_selector.get_item_text(char_selector.selected)

## Default locale for dialog text
var default_locale: String = ""


func _ready():
	super ()
	# Connect signal to open text editor from graph
	translation_boxes.open_text_editor.connect(get_parent().open_text_editor.emit)
	default_text_box.open_text_editor.connect(
			get_parent().open_text_editor.emit.bind(default_text_box.text_box)
		)
	
	_set_translation_text_boxes()
	GraphDialogsTranslationManager.translation_settings.connect(
			"locales_changed", _on_locales_changed
		)
	GraphDialogsTranslationManager.translation_settings.connect(
			"default_locale_changed", _on_locales_changed
		)


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
		"offset": {
			"x": position_offset.x,
			"y": position_offset.y
		}
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	char_key = dict["char_key"]
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]


func process_node(node_data: Dictionary) -> void:
	var character = node_data["char_key"]
	var dialog = tr(node_data["dialog_key"])
	dialogue_processed.emit(character, dialog, node_data["to_node"][0])

#endregion


## Load dialog and translations
func load_dialogs(dialogs: Dictionary) -> void:
	default_text_box.set_text(dialogs[default_locale])
	translation_boxes.load_translations_text(dialogs)


## Get dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = {}
	dialogs[default_locale] = default_text_box.get_text()
	dialogs.merge(translation_boxes.get_translations_text())
	return dialogs


## Create the dialog key for translation reference in the CSV file
func get_dialog_translation_key() -> String:
	if start_node != null: return get_start_id() + "_" + str(node_index)
	else: return "NODE_" + str(node_index)


## Set translation text boxes
func _set_translation_text_boxes() -> void:
	default_locale = GraphDialogsTranslationManager.default_locale
	%DefaultLocaleLabel.text = "(" + default_locale + ")"
	default_text_box.set_text("")
	translation_boxes.set_translation_boxes(
			GraphDialogsTranslationManager.locales.filter(
				func(locale): return locale != default_locale
			)
		)


## Update the locale text boxes
func _on_locales_changed() -> void:
	var dialogs = get_dialogs_text()
	_set_translation_text_boxes()
	load_dialogs(dialogs)
