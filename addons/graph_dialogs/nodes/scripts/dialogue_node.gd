@tool
class_name DialogueNode
extends BaseNode

## -----------------------------------------------------------------------------
## Dialogue Node
##
## Node to display dialogues in the dialog system.
## Allows to set dialog text and translations for different characters.
## -----------------------------------------------------------------------------

## Emitted when is requesting to open a character file
signal open_character_file_request(path: String)

## Character data resource field
@onready var _character_file_field: GraphDialogsFileField = %CharacterFileField
## Character name label
@onready var _character_name_button: Button = %CharacterNameButton
## Portrait dropdown selector
@onready var _portrait_dropdown: OptionButton = %PortraitSelect
## Text box for dialog in default locale
@onready var _default_text_box: HBoxContainer = %DefaultTextBox
## Text boxes container for translations
@onready var _translation_boxes: VBoxContainer = %Translations

## Default locale for dialog text
var _default_locale: String = ""
## Character data resource
var _character_data: GraphDialogsCharacterData


func _ready():
	super ()
	# Connect signal to open text editor from graph
	if graph_editor is GraphEdit:
		_translation_boxes.open_text_editor.connect(graph_editor.open_text_editor.emit)
		_default_text_box.open_text_editor.connect(
			graph_editor.open_text_editor.emit.bind(_default_text_box.text_box)
		)
		open_character_file_request.connect(
			graph_editor.open_character_file_request.emit.bind(get_character_path())
		)
	_character_file_field.file_path_changed.connect(load_character)
	_set_translation_text_boxes()
	_character_name_button.disabled = true


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = graph_editor.get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"dialog_key": get_dialog_translation_key(),
		"character": get_character_name(),
		"portrait": get_portrait(),
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

#endregion

#region === Characters =========================================================

## Get the character file path
func get_character_path() -> String:
	return _character_file_field.get_value()


## Get the selected character key name
func get_character_name() -> String:
	if _character_data != null:
		return _character_data.key_name
	else:
		return ""


## Get the selected portrait
func get_portrait() -> String:
	var portrait = _portrait_dropdown.get_item_text(_portrait_dropdown.selected)
	if portrait == "(No one)":
		return ""
	else:
		return portrait


## Load the character data from the file field
func load_character(path: String) -> void:
	if path == "":
		_clear_character_field()
		return
	
	var character = load(path)
	if not character is GraphDialogsCharacterData:
		printerr("[Graph Dialogs] Invalid character resource: " + path)
		_clear_character_field()
		return
	
	# Show the character's display name and set the portrait dropdown
	_character_file_field.set_value(path)
	_character_name_button.disabled = false
	_character_name_button.text = character.key_name.capitalize()
	_character_name_button.pressed.connect(open_character_file_request.emit.bind(path))
	_set_portrait_dropdown(character)
	_character_data = character


## Load the character portrait
func load_portrait(portrait: String) -> void:
	if portrait == "": # If no portrait is selected, select "(No one)"
		_portrait_dropdown.select(0)
		return
	
	var portrait_index = _find_dropdown_item(_portrait_dropdown, portrait)
	_portrait_dropdown.select(portrait_index)


## Clear the character field and reset the portrait dropdown
func _clear_character_field() -> void:
	_portrait_dropdown.clear()
	_portrait_dropdown.add_item("(No one)")
	_character_name_button.text = "(No one)"
	_character_name_button.disabled = true
	_character_data = null


## Set the portrait dropdown options based on character selection
func _set_portrait_dropdown(character_data: GraphDialogsCharacterData) -> void:
	_portrait_dropdown.clear()
	_portrait_dropdown.add_item("(No one)")
	var portraits = character_data.portraits

	if portraits.size() == 0:
		return # No portraits available

	var portrait_list = _get_portrait_list(portraits)
	for portrait in portrait_list:
		_portrait_dropdown.add_item(portrait)


## Get the list of portrait paths from the portrait dictionary
func _get_portrait_list(portrait_dict: Dictionary) -> Array:
	var portrait_list = []

	for portrait in portrait_dict.keys():
		if portrait_dict[portrait] is GraphDialogsPortraitData:
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

#region === Dialogs ============================================================

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
	_default_locale = ProjectSettings.get_setting("graph_dialogs/translation/default_locale")
	%DefaultLocaleLabel.text = "(" + _default_locale + ")"
	_default_text_box.set_text("")
	_translation_boxes.set_translation_boxes(
			ProjectSettings.get_setting("graph_dialogs/translation/locales").filter(
				func(locale): return locale != _default_locale
			)
		)

#endregion