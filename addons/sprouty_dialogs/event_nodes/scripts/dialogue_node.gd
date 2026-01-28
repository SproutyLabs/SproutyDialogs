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
## Emitted when press the expand button in a text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when a text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)

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
## Flag to indicate if translations are enabled
var _translations_enabled: bool = false
## Flag to indicate if the dialog has no translation (only default)
var _dialog_without_translation: bool = true

## Character data resource
var _character_data: SproutyDialogsCharacterData

## Current default dialog text (for UndoRedo)
var _default_text: String = ""
## Flag to check if the default text was modified (for UndoRedo)
var _default_text_modified: bool = false

## Previous selected portrait index (for UndoRedo)
var _previous_portrait_index: int = 0

## Collapse/Expand icons
var _collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var _collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")


func _ready():
	super ()
	# Connect signals to open and update text editor
	_translation_boxes.open_text_editor.connect(open_text_editor.emit)
	_default_text_box.open_text_editor.connect(open_text_editor.emit)
	_translation_boxes.update_text_editor.connect(update_text_editor.emit)
	_default_text_box.update_text_editor.connect(update_text_editor.emit)

	# Connect signals for text changes
	_translation_boxes.modified.connect(modified.emit)
	_default_text_box.text_changed.connect(_on_default_text_changed)
	_default_text_box.text_box_focus_exited.connect(_on_default_focus_exited)

	# Connect signals for character selection
	_portrait_dropdown.item_selected.connect(_on_portrait_selected)
	open_character_file_request.connect(
		open_character_file_request.emit.bind(get_character_path())
	)
	_character_expand_button.toggled.connect(_on_expand_character_button_toggled)
	_character_file_field.path_changed.connect(_on_character_changed)
	_character_name_button.disabled = true

	_translation_boxes.undo_redo = undo_redo
	_set_translation_text_boxes()


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"dialog_key": get_dialog_translation_key(),
		"character": get_character_name(),
		"portrait": get_portrait(),
		"char_expand": _character_expand_button.button_pressed,
		"to_node": get_output_connections(),
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

## Returns the character file path
func get_character_path() -> String:
	return _character_file_field.get_value()


## Returns the selected character key name
func get_character_name() -> String:
	if _character_data != null:
		return _character_data.key_name
	else:
		return ""


## Returns the selected portrait
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


## Load the character portrait
func load_portrait(portrait: String) -> void:
	if portrait == "": # If no portrait is selected, select "(No one)"
		_portrait_dropdown.select(0)
		return
	
	var portrait_index = _find_dropdown_item(_portrait_dropdown, portrait)
	_portrait_dropdown.select(portrait_index)


## Handle the character file path changed signal
func _on_character_changed(path: String) -> void:
	var previous_character_path = get_character_path()
	var previous_portrait = _portrait_dropdown.selected
	load_character(path)
	modified.emit(true)

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Assign Character")
	undo_redo.add_do_method(self, "load_character", path)
	undo_redo.add_undo_method(self, "load_character", previous_character_path)
	undo_redo.add_undo_property(_portrait_dropdown, "selected", previous_portrait)
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


## Handle the portrait dropdown item selected signal
func _on_portrait_selected(index: int) -> void:
	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Select Portrait")
	undo_redo.add_do_property(_portrait_dropdown, "selected", index)
	undo_redo.add_do_property(self, "_previous_portrait_index", index)
	undo_redo.add_undo_property(_portrait_dropdown, "selected", _previous_portrait_index)
	undo_redo.add_undo_property(self, "_previous_portrait_index", _previous_portrait_index)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action()
	# -----------------------------------------------------------------------


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
		if portrait_dict[portrait].data is SproutyDialogsPortraitData:
			portrait_list.append(portrait)
		else:
			portrait_list.append_array(
					_get_portrait_list(portrait_dict[portrait].data).map(
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

## Create the dialog key for translation reference in the CSV file
func get_dialog_translation_key() -> String:
	if start_node != null: return get_start_id() + "_DIALOG_" + str(node_index)
	else: return "UNPLUGGED_DIALOG_" + str(node_index)


## Returns dialog text and its translations
func get_dialogs_text() -> Dictionary:
	var dialogs = _translation_boxes.get_translations_text()
	dialogs["default"] = _default_text_box.get_text()
	if _translations_enabled:
		if _default_locale != "":
			dialogs[_default_locale] = _default_text_box.get_text()
	return dialogs


## Load dialog and translations
func load_dialogs(dialogs: Dictionary) -> void:
	if dialogs.size() > 1: # There are translations
		_dialog_without_translation = false
	
	if _translations_enabled and dialogs.has(_default_locale):
		_default_text_box.set_text(dialogs[_default_locale])
		_default_text = dialogs[_default_locale]
	else: # Use default if translations disabled or no default locale dialog
		_default_text_box.set_text(dialogs["default"])
		_default_text = dialogs["default"]
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
	load_dialogs(dialogs)


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	_translations_enabled = enabled
	if enabled:
		on_locales_changed()
	else: # Hide translation boxes and default locale label
		%DefaultLocaleLabel.visible = false
		_translation_boxes.visible = false


## Set translation text boxes
func _set_translation_text_boxes() -> void:
	_translations_enabled = SproutyDialogsSettingsManager.get_setting("enable_translations")
	_default_locale = SproutyDialogsSettingsManager.get_setting("default_locale")
	var locales = SproutyDialogsSettingsManager.get_setting("locales")
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
	_translation_boxes.visible = _translations_enabled and locales.size() > 1


## Handle the default text box text changed signal
func _on_default_text_changed(new_text: String = "") -> void:
	if _default_text != _default_text_box.get_text():
		var temp = _default_text
		_default_text = _default_text_box.get_text()
		_default_text_modified = true

		# --- UndoRedo ----------------------------------------------------------
		undo_redo.create_action("Edit Dialog Text"
			+ (" (" + _default_locale + ")") if _default_locale != "" else "", 1)
		undo_redo.add_do_property(self, "_default_text", _default_text)
		undo_redo.add_do_method(_default_text_box, "set_text", _default_text)
		undo_redo.add_undo_property(self, "_default_text", temp)
		undo_redo.add_undo_method(_default_text_box, "set_text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# -----------------------------------------------------------------------


## Handle the default text box focus exited signal
func _on_default_focus_exited() -> void:
	if _default_text_modified:
		_default_text_modified = false
		modified.emit(true)

#endregion