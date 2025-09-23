@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialogue Node
# -----------------------------------------------------------------------------
## Node to add dialog lines to the graph. It allows to set the character,
## portrait, dialog text and its translations.
# -----------------------------------------------------------------------------

## Emitted when is requesting to open a character file
signal open_character_file_request(path: String)

## Character data resource field
@onready var _character_file_field: EditorSproutyDialogsFileField = %CharacterFileField
## Character expand/collapse button
@onready var _character_expand_button: Button = %CharacterExpandButton
## Character name label
@onready var _character_name_button: Button = %CharacterNameButton
## Portrait dropdown selector
@onready var _portrait_dropdown: OptionButton = %PortraitSelect
## Text box for dialog in default locale
@onready var _default_text_box: EditorSproutyDialogsExpandableTextBox = %DefaultTextBox
## Text boxes container for translations
@onready var _translation_boxes: EditorSproutyDialogsTranslationsContainer = %Translations

## Default locale for dialog text
var _default_locale: String = ""
## Character data resource
var _character_data: SproutyDialogsCharacterData

## Collapse/Expand icons
var _collapse_up_icon = preload("res://addons/sprouty_dialogs/icons/interactable/collapse-up.svg")
var _collapse_down_icon = preload("res://addons/sprouty_dialogs/icons/interactable/collapse-down.svg")


func _ready():
	super ()
	if graph_editor is GraphEdit:
		# Connect signals to open and update text editor
		_translation_boxes.open_text_editor.connect(graph_editor.open_text_editor.emit)
		_default_text_box.open_text_editor.connect(graph_editor.open_text_editor.emit)
		_translation_boxes.update_text_editor.connect(graph_editor.update_text_editor.emit)
		_default_text_box.update_text_editor.connect(graph_editor.update_text_editor.emit)

		# Connect signals to mark the graph as modified
		_translation_boxes.modified.connect(graph_editor.on_modified)
		_default_text_box.text_changed.connect(graph_editor.on_modified)

		# Connect signals for character selection
		_portrait_dropdown.item_selected.connect(graph_editor.on_modified.unbind(1))
		open_character_file_request.connect(
			graph_editor.open_character_file_request.emit.bind(get_character_path())
		)
	_character_expand_button.toggled.connect(_on_expand_character_button_toggled)
	_character_file_field.path_changed.connect(load_character)
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
		"char_expand": _character_expand_button.button_pressed,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	# Show or hide character section
	_character_expand_button.button_pressed = dict["char_expand"]
	position_offset = dict["offset"]
	size = dict["size"]

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
	if not character is SproutyDialogsCharacterData:
		printerr("[Sprouty Dialogs] Invalid character resource: " + path)
		_clear_character_field()
		return
	
	# Show the character's display name and set the portrait dropdown
	_character_file_field.set_value(path)
	_character_name_button.disabled = false
	_character_name_button.text = character.key_name.capitalize()
	if not _character_name_button.pressed.is_connected(open_character_file_request.emit.bind(path)):
		_character_name_button.pressed.connect(open_character_file_request.emit.bind(path))
	_set_portrait_dropdown(character)
	_character_data = character
	graph_editor.on_modified()


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
func _set_portrait_dropdown(character_data: SproutyDialogsCharacterData) -> void:
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
		if portrait_dict[portrait] is SproutyDialogsPortraitData:
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


## Handle the expand character button pressed signal
func _on_expand_character_button_toggled(toggled_on: bool) -> void:
	$CharacterContainer/Content.visible = toggled_on
	if toggled_on:
		_character_expand_button.icon = _collapse_up_icon
	else:
		_character_expand_button.icon = _collapse_down_icon
	position_offset.y += -size.y / 4 if toggled_on else size.y / 4
	_on_resized()


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
	_default_locale = EditorSproutyDialogsSettingsManager.get_setting("default_locale")
	%DefaultLocaleLabel.text = "(" + _default_locale + ")"
	_default_text_box.set_text("")
	_translation_boxes.set_translation_boxes(
			EditorSproutyDialogsSettingsManager.get_setting("locales").filter(
				func(locale): return locale != _default_locale
			)
		)

#endregion