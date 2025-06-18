@tool
class_name DialogueNode
extends BaseNode

## -----------------------------------------------------------------------------
## Dialogue Node
##
## Node to display dialogues in the dialog system.
## Allows to set dialog text and translations for different characters.
## -----------------------------------------------------------------------------

## Character dropdown selector
@onready var _character_dropdown: OptionButton = %CharacterSelect
## Portrait dropdown selector
@onready var _portrait_dropdown: OptionButton = %PortraitSelect
## Text box for dialog in default locale
@onready var _default_text_box: HBoxContainer = %DefaultTextBox
## Text boxes container for translations
@onready var _translation_boxes: VBoxContainer = %Translations

## Default locale for dialog text
var _default_locale: String = ""


func _ready():
	super ()
	# Connect signal to open text editor from graph
	if graph_editor is GraphEdit:
		_translation_boxes.open_text_editor.connect(graph_editor.open_text_editor.emit)
		_default_text_box.open_text_editor.connect(
			graph_editor.open_text_editor.emit.bind(_default_text_box.text_box)
		)
	_character_dropdown.item_selected.connect(_set_portrait_dropdown)
	_set_characters_dropdown()
	_set_translation_text_boxes()


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = graph_editor.get_node_connections(name)

	var character = _character_dropdown.get_item_metadata(_character_dropdown.selected)
	var portrait = _portrait_dropdown.get_item_text(_portrait_dropdown.selected)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"dialog_key": get_dialog_translation_key(),
		"character": get_character_name(),
		"portrait": portrait if portrait != "(No one)" else "",
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]

	# Set character and portrait dropdowns
	var char_index = _find_dropdown_item(_character_dropdown, dict["character"])
	var portrait_index = _find_dropdown_item(_portrait_dropdown, dict["portrait"])

	_character_dropdown.select(char_index if char_index != -1 else 0)
	_set_portrait_dropdown(_character_dropdown.selected)
	_portrait_dropdown.select(portrait_index if portrait_index != -1 else 0)

#endregion


## Get dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = {}
	dialogs[_default_locale] = _default_text_box.get_text()
	dialogs.merge(_translation_boxes.get_translations_text())
	return dialogs


## Create the dialog key for translation reference in the CSV file
func get_dialog_translation_key() -> String:
	if start_node != null: return get_start_id() + "_" + str(node_index)
	else: return "DIALOG_NODE_" + str(node_index)


## Get the selected character key name
func get_character_name() -> String:
	var character = _character_dropdown.get_item_metadata(_character_dropdown.selected)
	if character is GraphDialogsCharacterData:
		return character.key_name
	else:
		return ""


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


## Handle the character references change
func on_character_references_changed() -> void:
	var selected_item = _character_dropdown.get_item_text(_character_dropdown.selected)
	var items = _set_characters_dropdown()

	if items.has(selected_item): # If the selected item is in the list, select it
		_character_dropdown.select(items.find(selected_item))
	else: # Select the first item if the selected item is not found
		_character_dropdown.select(0)


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


#region === Dropdowns ==========================================================

## Set the character dropdown options from project settings
func _set_characters_dropdown() -> Array:
	if not ProjectSettings.has_setting("graph_dialogs/references/characters"):
		return []
	var char_references = ProjectSettings.get_setting("graph_dialogs/references/characters")
	var characters = char_references.keys()
	characters.insert(0, "(No one)")
	_character_dropdown.clear()

	for character in characters:
		if character == "(No one)": # Special case for no character selected
			_character_dropdown.add_item(character)
			continue
		
		_character_dropdown.add_item(character.capitalize())
		# Set character resource as metadata for the character item
		_character_dropdown.set_item_metadata(
			_character_dropdown.get_item_count() - 1,
			load(ResourceUID.get_id_path(char_references[character]))
		)
	return characters


## Set the portrait dropdown options based on character selection
func _set_portrait_dropdown(character_item: int) -> void:
	var character = _character_dropdown.get_item_metadata(character_item)
	_portrait_dropdown.clear()
	if not character is GraphDialogsCharacterData:
		_portrait_dropdown.add_item("(No one)")
		return
	
	var portraits = character.portraits
	if portraits.size() == 0:
		_portrait_dropdown.add_item("(No one)")
		return

	var portrait_list = _get_portrait_list(portraits)
	for portrait in portrait_list:
		_portrait_dropdown.add_item(portrait)


## Get the list of portrait paths from the portrait dictionary
func _get_portrait_list(portrait_dict: Dictionary) -> Array:
	var portrait_list = []

	for portrait in portrait_dict.keys():
		if portrait_dict[portrait].has("portrait_scene"):
			portrait_list.append(portrait)
		else:
			portrait_list.append_array(
					_get_portrait_list(portrait_dict[portrait]).map(
						func(p): return portrait + "/" + p
					)
				)

	return portrait_list


## Find the index of the dropdown item by its text
func _find_dropdown_item(dropdown: OptionButton, item: String) -> int:
	for i in range(dropdown.get_item_count()):
		if dropdown.get_item_text(i).to_lower() == item.to_lower():
			return i
	return -1

#endregion