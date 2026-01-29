@tool
class_name EditorSproutyDialogsCharacterEditor
extends HSplitContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Character Editor
# ---------------------------------------------------------------------------- 
## This module is responsible for the character files creation and editing.
## It allows the user to edit character data, including the character's name,
## description, dialogue box, portraits and typing sounds.
# -----------------------------------------------------------------------------

## Triggered when something is modified
signal modified(modified: bool)

## Label with the key name of the character
@onready var _key_name_label: Label = %KeyNameLabel
## Label with the default locale for display name
@onready var _name_default_locale_label: Label = %NameDefaultLocaleLabel
## Display name text input field in default locale
@onready var _name_default_locale_field: LineEdit = %NameDefaultLocaleField
## Translation container for display name
@onready var _name_translations_container: EditorSproutyDialogsTranslationsContainer = %NameTranslationsContainer

## Description text input field
@onready var _description_field: TextEdit = %DescriptionField
## Dialog box scene file field
@onready var _dialog_box_scene_field: EditorSproutyDialogsFileField = %DialogBoxSceneField
## Dialog box scene button
@onready var _to_dialog_box_scene_button: Button = %ToDialogBoxSceneButton
## Dialog box new scene button
@onready var _new_dialog_box_scene_button: Button = %NewDialogBoxSceneButton
## New dialog box scene dialog
@onready var _new_dialog_box_dialog: FileDialog = $NewDialogBoxDialog

## Default portrait dropdown
@onready var _default_portrait_dropdown: OptionButton = %DefaultPortraitDropdown
## Portrait scale section
@onready var _portraits_transform_settings: PanelContainer = %TransformSettings

## Portrait tree
@onready var _portrait_tree: Tree = %PortraitTree
## Portrait tree search bar
@onready var _portrait_search_bar: LineEdit = %PortraitSearchBar
## Portrait empty panel
@onready var _portrait_empty_panel: Panel = $PortraitSettings/NoPortraitPanel
## Portrait settings container
@onready var _portrait_editor_container: Container = $PortraitSettings/Container

## Collapse/Expand icon resources
var collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

## Portrait settings panel scene
var _portrait_editor_scene := preload("res://addons/sprouty_dialogs/editor/modules/characters/portrait_editor.tscn")

## Current portrait selected
var _current_portrait: TreeItem = null
## Previous portrait selected
var _previous_portrait: TreeItem = null

## Key name of the character (file name)
var _key_name: String = ""
## Default locale for dialog text
var _default_locale: String = ""
## Flag to indicate if translations are enabled
var _translations_enabled: bool = false
## Flag to indicate if the dialog has no translation (only default)
var _name_without_translation: bool = true

## Portrait display on dialog box option
var _portrait_on_dialog_box: bool = false

## Default display name (for UndoRedo)
var _default_display_name: String = ""
## Flag to indicate if the default display name was modified
var _default_name_modified: bool = false

## Description text (for UndoRedo)
var _description_text: String = ""
## Flag to indicate if the description text was modified
var _description_modified: bool = false

## Dialog box scene file path (for UndoRedo)
var _dialog_box_path: String = ""

## Modified counter to track changes
var _modified_counter: int = 0

## Previous selected default portrait index (for UndoRedo)
var _previous_portrait_index: int = 0

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	# Connect display name signals
	_name_default_locale_field.text_changed.connect(_on_default_display_name_changed)
	_name_default_locale_field.mouse_exited.connect(_on_default_display_focus_exited)
	_name_translations_container.modified.connect(_on_modified)
	_name_translations_container.undo_redo = undo_redo

	# Connect description signals
	_description_field.text_changed.connect(_on_description_text_changed)
	_description_field.mouse_exited.connect(_on_description_focus_exited)

	# Connect dialog box signals
	_dialog_box_scene_field.path_changed.connect(_on_dialog_box_scene_path_changed)
	_to_dialog_box_scene_button.pressed.connect(_on_dialog_box_scene_button_pressed)
	_new_dialog_box_scene_button.pressed.connect(_on_new_dialog_box_scene_pressed)
	_new_dialog_box_dialog.file_selected.connect(_new_dialog_box)
	%PortraitOnDialogBoxToggle.toggled.connect(_on_portrait_dialog_box_toggled)

	# Connect portrait signals
	_default_portrait_dropdown.item_selected.connect(_on_default_portrait_selected)
	_portrait_tree.portrait_list_changed.connect(_update_default_portrait_dropdown)
	_portrait_tree.portrait_path_changed.connect(_on_portrait_path_changed)

	_portraits_transform_settings.modified.connect(modified.emit)
	_portraits_transform_settings.transform_settings_changed.connect(_update_portraits_transform)
	_portraits_transform_settings.undo_redo = undo_redo

	_portrait_tree.show_portrait_editor_panel.connect(_show_portrait_editor_panel)
	_portrait_tree.portrait_item_selected.connect(_on_portrait_selected)
	_portrait_tree.modified.connect(_on_modified)
	_portrait_tree.undo_redo = undo_redo

	%PortraitSearchBar.text_changed.connect(_on_portrait_search_bar_text_changed)
	%AddPortraitButton.pressed.connect(_on_add_portrait_button_pressed)
	%AddGroupButton.pressed.connect(_on_add_portrait_group_button_pressed)

	# Set icons for buttons and fields
	_to_dialog_box_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_new_dialog_box_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_portrait_search_bar.right_icon = get_theme_icon("Search", "EditorIcons")
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddGroupButton.icon = get_theme_icon("Folder", "EditorIcons")

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	on_translation_enabled_changed( # Enable/disable translation section
			SproutyDialogsSettingsManager.get_setting("enable_translations")
		)


## Emit the modified signal
func _on_modified(mark_as_modified: bool) -> void:
	if mark_as_modified:
		_modified_counter += 1
	elif _modified_counter > 0:
		_modified_counter -= 1
	modified.emit(_modified_counter > 0)


## Handle the description text change
func _on_description_text_changed() -> void:
	if _description_field.text != _description_text:
		var temp = _description_text
		_description_text = _description_field.text
		_description_modified = true

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Change Character Description", 1)
		undo_redo.add_do_property(_description_field, "text", _description_text)
		undo_redo.add_undo_property(_description_field, "text", temp)
		undo_redo.add_do_method(self, "_on_modified", true)
		undo_redo.add_undo_method(self, "_on_modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle the description focus exit
func _on_description_focus_exited() -> void:
	if _description_modified:
		_description_modified = false
		_on_modified(true)


## Expand/hide the dialog box settings
func _on_expand_dialog_box_button_toggled(toggled_on: bool) -> void:
	%DialogBoxSettings.visible = toggled_on
	%ExpandDialogBoxButton.icon = collapse_up_icon if toggled_on else collapse_down_icon


## Expand/hide the portrait settings
func _on_expand_portraits_settings_button_toggled(toggled_on: bool) -> void:
	%PortraitSettings.visible = toggled_on
	%ExpandPortraitsSettingsButton.icon = collapse_up_icon if toggled_on else collapse_down_icon


## Expand/hide the portraits list
func _on_expand_portraits_button_toggled(toggled_on: bool) -> void:
	%Portraits.visible = toggled_on
	%ExpandPortraitsButton.icon = collapse_up_icon if toggled_on else collapse_down_icon


#region === Character Data =====================================================

## Returns the character data from the editor
func get_character_data() -> SproutyDialogsCharacterData:
	var data = SproutyDialogsCharacterData.new()
	data.key_name = _key_name
	data.display_name = _get_name_translations()
	data.description = _description_field.text

	data.dialog_box_uid = ResourceSaver.get_resource_id_for_path(
				_dialog_box_scene_field.get_value(), true) \
		if _check_valid_dialog_box_scene(_dialog_box_scene_field.get_value()) else -1
	
	data.dialog_box_path = _dialog_box_scene_field.get_value() \
		if _check_valid_dialog_box_scene(_dialog_box_scene_field.get_value()) else ""
	
	data.portrait_on_dialog_box = _portrait_on_dialog_box
	data.default_portrait = _get_default_portrait_selected()
	data.main_transform_settings = _portraits_transform_settings.get_transform_settings()
	data.portraits = _portrait_tree.get_portraits_data()
	data.typing_sounds = {} # Typing sounds are not implemented yet
	return data


## Load the character data into the editor.
## If name_data is provided, it will be used to load the name translations.
## Otherwise, the name translations will be loaded from the character data.
func load_character(data: SproutyDialogsCharacterData, name_data: Dictionary) -> void:
	_key_name = data.key_name
	_key_name_label.text = _key_name.to_pascal_case()
	_description_field.text = data.description

	# Character name and its translations
	_set_translation_text_boxes()
	if name_data.is_empty():
		_load_name_translations(data.display_name)
	else: # Load from provided name CSV data
		if SproutyDialogsSettingsManager.get_setting("fallback_to_resource"):
			for locale in name_data.keys():
				if name_data[locale] == "" and data.display_name.has(locale):
					name_data[locale] = data.display_name[locale]
		_load_name_translations(name_data)
	_update_translations_state()

	# Dialog box scene file
	if not SproutyDialogsFileUtils.check_valid_uid_path(data.dialog_box_uid):
		if data.dialog_box_uid != -1:
			printerr("[Sprouty Dialogs] Dialog box not found for character '" + _key_name
					+"'. Check that the file '" + data.dialog_box_path + "' exists.")
		_to_dialog_box_scene_button.visible = false
		_new_dialog_box_scene_button.visible = true
		_dialog_box_scene_field.set_value("")
	else:
		_dialog_box_path = ResourceUID.get_id_path(data.dialog_box_uid)
		_dialog_box_scene_field.set_value(_dialog_box_path)
	
	if SproutyDialogsFileUtils.check_valid_extension(
			_dialog_box_scene_field.get_value(), _dialog_box_scene_field.file_filters):
		_to_dialog_box_scene_button.visible = true
		_new_dialog_box_scene_button.visible = false
	_portrait_on_dialog_box = data.portrait_on_dialog_box
	%PortraitOnDialogBoxToggle.button_pressed = _portrait_on_dialog_box

	# Portraits
	_portraits_transform_settings.set_transform_settings(data.main_transform_settings)
	_portrait_tree.load_portraits_data(data.portraits, _portrait_editor_scene)
	_portrait_tree.update_portraits_transform(data.main_transform_settings)
	_update_default_portrait_dropdown(data.default_portrait)

	_modified_counter = 0

#endregion

#region === Name Translations ==================================================

## Update name translations text boxes when locales change
func on_locales_changed() -> void:
	if _key_name != "":
		var translations = _get_name_translations()
		var previous_default_locale = _default_locale
		_set_translation_text_boxes()
		# Handle when there was no translation before
		if _name_without_translation and _default_locale != "":
			translations[_default_locale] = translations["default"]
			_default_display_name = translations["default"]
			_name_without_translation = false
		# Handle when the default locale changes
		elif previous_default_locale != _default_locale:
			if previous_default_locale != "":
				translations[previous_default_locale] = translations["default"]
			translations["default"] = translations[_default_locale] \
					if translations.has(_default_locale) else translations["default"]
			_default_display_name = translations["default"]
		_load_name_translations(translations)


## Handle the translation enabled change
func on_translation_enabled_changed(enabled: bool) -> void:
	_translations_enabled = enabled
	if enabled: on_locales_changed()
	else: # Hide translation boxes and default locale label
		_name_default_locale_label.visible = false
		_name_translations_container.visible = false


## Update the translations state based on project settings
func _update_translations_state() -> void:
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("translate_character_names"):
		_name_translations_container.visible = true
		_name_default_locale_label.visible = true
	else:
		_name_default_locale_label.visible = false
		_name_translations_container.visible = false


## Returns character name translations
func _get_name_translations() -> Dictionary:
	var translations = _name_translations_container.get_translations_text()
	translations["default"] = _name_default_locale_field.text
	if _translations_enabled:
		if _default_locale != "":
			translations[_default_locale] = _name_default_locale_field.text
	return translations


## Load character name translations
func _load_name_translations(translations: Dictionary) -> void:
	if translations.size() > 1: # There are translations
		_name_without_translation = false

	if _translations_enabled and translations.has(_default_locale):
		_name_default_locale_field.text = translations[_default_locale]
		_default_display_name = translations[_default_locale]
	else: # Use default if translations disabled or no default locale translation
		if translations.has("default"):
			_name_default_locale_field.text = translations["default"]
			_default_display_name = translations["default"]
		else:
			_name_default_locale_field.text = ""
			_default_display_name = ""
	_name_translations_container.load_translations_text(translations)


## Set character name translations text boxes
func _set_translation_text_boxes() -> void:
	_translations_enabled = SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("translate_character_names")
	_default_locale = SproutyDialogsSettingsManager.get_setting("default_locale")
	var locales = SproutyDialogsSettingsManager.get_setting("locales")
	_translations_enabled = _translations_enabled and locales.size() > 0
	_default_locale = _default_locale if _translations_enabled else ""
	_name_default_locale_label.text = "(" + _default_locale + ")"
	_name_default_locale_field.text = ""
	_name_translations_container.set_translation_boxes(
			locales.filter(
				func(locale): return locale != (_default_locale if _translations_enabled else "")
			)
		)
	_name_default_locale_label.visible = _translations_enabled and _default_locale != ""
	_name_translations_container.visible = _translations_enabled and locales.size() > 1


## Handle the default display name text change
func _on_default_display_name_changed(new_text: String) -> void:
	if new_text != _default_display_name:
		var temp = _default_display_name
		_default_display_name = new_text
		_default_name_modified = true

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Change Display Name", 1)
		undo_redo.add_do_property(_name_default_locale_field, "text", new_text)
		undo_redo.add_undo_property(_name_default_locale_field, "text", temp)
		undo_redo.add_do_method(self, "_on_modified", true)
		undo_redo.add_undo_method(self, "_on_modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle the default display name focus exit
func _on_default_display_focus_exited() -> void:
	if _default_name_modified:
		_default_name_modified = false
		_on_modified(true)

#endregion

#region === Dialog Box =========================================================

## Check if a dialog box scene path is valid
func _check_valid_dialog_box_scene(path: String, print_error: bool = true) -> bool:
	var is_valid = SproutyDialogsFileUtils.check_valid_extension(path,
			_dialog_box_scene_field.file_filters) and FileAccess.file_exists(path)
	
	if is_valid: # Check if the scene inherits from DialogBox class
		var scene = load(path).instantiate()
		if not scene is DialogBox:
			if print_error:
				printerr("[Sprouty Dialogs] The scene '" + path + "' is not valid."
						+" The root node must inherit from DialogBox class.")
			is_valid = false
			scene.queue_free()
	
	return is_valid


## Handle the dialog box scene file path
func _on_dialog_box_scene_path_changed(path: String) -> void:
	# If the path is valid, show the open scene button and hide the new scene button
	var is_valid = _check_valid_dialog_box_scene(path)
	_to_dialog_box_scene_button.visible = is_valid
	_new_dialog_box_scene_button.visible = not is_valid
	var temp = _dialog_box_path
	_dialog_box_path = path
	_on_modified(true)
	
	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Change Dialog Box Scene")
	undo_redo.add_do_method(_dialog_box_scene_field, "set_value", path)
	undo_redo.add_undo_method(_dialog_box_scene_field, "set_value", temp)
	undo_redo.add_do_property(self, "_dialog_box_path", path)
	undo_redo.add_undo_property(self, "_dialog_box_path", temp)

	undo_redo.add_do_property(_to_dialog_box_scene_button, "visible", is_valid)
	undo_redo.add_undo_property(_to_dialog_box_scene_button, "visible",
		_check_valid_dialog_box_scene(temp, false))
	
	undo_redo.add_do_property(_new_dialog_box_scene_button, "visible", not is_valid)
	undo_redo.add_undo_property(_new_dialog_box_scene_button, "visible",
		not _check_valid_dialog_box_scene(temp, false))
	
	undo_redo.add_do_method(self, "_on_modified", true)
	undo_redo.add_undo_method(self, "_on_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle the dialog box scene button press
func _on_dialog_box_scene_button_pressed() -> void:
	SproutyDialogsFileUtils.open_scene_in_editor(
			_dialog_box_scene_field.get_value(), get_tree())


## Create a new dialog box scene and open it in the editor
func _on_new_dialog_box_scene_pressed() -> void:
	_new_dialog_box_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("dialog_box_files"))
	_new_dialog_box_dialog.get_line_edit().text = "new_dialog_box.tscn"
	_new_dialog_box_dialog.popup_centered()


## Create a new dialog box scene file
func _new_dialog_box(scene_path: String) -> void:
	SproutyDialogsFileUtils.create_new_scene_file(scene_path, "dialog_box")
	
	# Set the dialog box scene path
	_dialog_box_scene_field.set_value(scene_path)
	_on_dialog_box_scene_path_changed(scene_path)

	# Open the new scene in the editor
	SproutyDialogsFileUtils.open_scene_in_editor(scene_path, get_tree())
	_on_modified(true)


## Handle the text box portrait display toggle
func _on_portrait_dialog_box_toggled(toggled_on: bool) -> void:
	var temp = _portrait_on_dialog_box
	_portrait_on_dialog_box = toggled_on
	_on_modified(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Toggle Portrait on Dialog Box")
	undo_redo.add_do_property(%PortraitOnDialogBoxToggle, "button_pressed", toggled_on)
	undo_redo.add_undo_property(%PortraitOnDialogBoxToggle, "button_pressed", temp)
	undo_redo.add_do_method(self, "_on_modified", true)
	undo_redo.add_undo_method(self, "_on_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------

#endregion

#region === Portrait Settings ==================================================

## Handle the default dropdown update when a portrait is moved 
func _on_portrait_path_changed(new_path: String, prev_path: String) -> void:
	var selected = _default_portrait_dropdown.get_item_text(
			_default_portrait_dropdown.selected)
	
	if selected == prev_path: # Update the selected default portrait name
		_update_default_portrait_dropdown(new_path)
	else: # Otherwise, update the dropdown keeping the current selected
		_update_default_portrait_dropdown()


## Update the default portrait dropdown options
func _update_default_portrait_dropdown(selected_portrait: String = "") -> void:
	var portraits = _portrait_tree.get_portrait_list()
	
	# Keep current selected item
	if selected_portrait == "" and _default_portrait_dropdown.selected != -1:
		selected_portrait = _default_portrait_dropdown.get_item_text(
				_default_portrait_dropdown.selected)
	
	_default_portrait_dropdown.clear()
	_default_portrait_dropdown.add_item("(no one)")
	
	if portraits.size() == 0:
		return # No portrait to select

	for portrait in portraits:
		_default_portrait_dropdown.add_item(portrait)
		if portrait == selected_portrait: # Select the current item
			_default_portrait_dropdown.select(_default_portrait_dropdown.item_count - 1)


## Returns the default portrait selected
func _get_default_portrait_selected() -> String:
	var option = _default_portrait_dropdown.get_item_text(
			_default_portrait_dropdown.selected)
	return option if option != "(no one)" else ""


## Handle when a portrait is selected
func _on_default_portrait_selected(index: int) -> void:
	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Select Default Portrait")
	undo_redo.add_do_property(_default_portrait_dropdown, "selected", index)
	undo_redo.add_undo_property(_default_portrait_dropdown, "selected", _previous_portrait_index)
	undo_redo.add_do_property(self, "_previous_portrait_index", index)
	undo_redo.add_undo_property(self, "_previous_portrait_index", _previous_portrait_index)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action()
	# -----------------------------------------------------------------------


## Show or hide the transform settings section
func _on_expand_transform_settings_toggled(toggled_on: bool) -> void:
	_portraits_transform_settings.visible = toggled_on
	%ExpandTransformSettingsButton.icon = collapse_up_icon if toggled_on else collapse_down_icon


## Update the preview of all portraits
func _update_portraits_transform() -> void:
	_portrait_tree.update_portraits_transform(
			_portraits_transform_settings.get_transform_settings())

#endregion

#region === Portrait Tree ======================================================

## Show or hide the portrait settings panel
func _show_portrait_editor_panel(show: bool) -> void:
	_portrait_empty_panel.visible = not show
	_portrait_editor_container.visible = show


## Add a new portrait to the tree
func _on_add_portrait_button_pressed() -> void:
	var parent: TreeItem = _portrait_tree.get_root()
	var item_selected = _portrait_tree.get_selected()
	
	if item_selected: # If an item is selected, add to its group
		if item_selected.get_metadata(0) and \
				item_selected.get_metadata(0).has("group"):
			parent = item_selected
		else:
			parent = item_selected.get_parent()
			if not parent: # If no parent, add to root
				parent = _portrait_tree.get_root()
	
	# Create a new portrait editor and create a new portrait item
	var portrait_editor = _portrait_editor_scene.instantiate()
	add_child(portrait_editor)
	var item: TreeItem = _portrait_tree.new_portrait_item(
			"New Portrait", portrait_editor.get_portrait_data(), parent, portrait_editor
		)
	portrait_editor.modified.connect(_on_modified)
	remove_child(portrait_editor)
	item.set_editable(0, true)
	item.select(0)
	_portrait_tree.call_deferred("edit_selected")
	var temp = _current_portrait
	_current_portrait = item

	_update_default_portrait_dropdown()
	_update_portraits_transform()
	_on_modified(true)
	
	# --- UndoRedo -----------------------------------------------------
	undo_redo.create_action("Add New Portrait")
	undo_redo.add_do_reference(item)
	undo_redo.add_do_method(parent, "add_child", item)
	undo_redo.add_do_property(self, "_current_portrait", item)
	undo_redo.add_do_method(self, "_select_item_on_tree", item)
	
	undo_redo.add_undo_method(parent, "remove_child", item)
	undo_redo.add_undo_property(self, "_current_portrait", temp)
	undo_redo.add_undo_method(self, "_select_item_on_tree", temp)

	undo_redo.add_do_method(self, "_update_default_portrait_dropdown")
	undo_redo.add_undo_method(self, "_update_default_portrait_dropdown")
	
	undo_redo.add_do_method(self, "_on_modified", true)
	undo_redo.add_undo_method(self, "_on_modified", false)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Add a new portrait group to the tree
func _on_add_portrait_group_button_pressed() -> void:
	var parent: TreeItem = _portrait_tree.get_root()
	var item_selected = _portrait_tree.get_selected()

	if item_selected: # If an item is selected, add to its group
		if item_selected.get_metadata(0) and \
			item_selected.get_metadata(0).has("group"):
			parent = item_selected
		else:
			parent = item_selected.get_parent()
			if not parent: # If no parent, add to root
				parent = _portrait_tree.get_root()

	# Create a new portrait group item
	var item: TreeItem = _portrait_tree.new_portrait_group("New Group", parent)
	item.set_editable(0, true)
	item.select(0)
	_portrait_tree.call_deferred("edit_selected")
	_on_modified(true)

	# --- UndoRedo -----------------------------------------------------
	undo_redo.create_action("Add New Portrait Group")
	undo_redo.add_do_reference(item)
	undo_redo.add_do_method(parent, "add_child", item)
	undo_redo.add_undo_method(parent, "remove_child", item)
	undo_redo.add_do_method(self, "_on_modified", true)
	undo_redo.add_undo_method(self, "_on_modified", false)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Filter the portrait tree items
func _on_portrait_search_bar_text_changed(new_text: String) -> void:
	_portrait_tree.filter_branch(_portrait_tree.get_root(), new_text)


## Update the portrait settings when a portrait is selected
func _on_portrait_selected(item: TreeItem) -> void:
	# Check if the selected item is a portrait
	if item == null or item.get_metadata(0) == null:
		return # No item selected
	
	if item.get_metadata(0).has("group"):
		_show_portrait_editor_panel(false)
	else:
		_show_portrait_editor_panel(true)
	
	if _previous_portrait != item:
		_previous_portrait = _current_portrait
	
	_switch_current_portrait(item)

	if _previous_portrait == item:
		return # No register undoredo action

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Select Portrait: " + item.get_text(0))
	undo_redo.add_do_method(self, "_select_item_on_tree", item)
	undo_redo.add_undo_method(self, "_select_item_on_tree", _previous_portrait)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Select an item on the portrait tree
func _select_item_on_tree(item: Variant) -> void:
	if not item is TreeItem: # No item to select
		_show_portrait_editor_panel(false)
		return
	if item.get_tree() != _portrait_tree:
		return # Item does not belong to this tree
	
	_portrait_tree.deselect_all()
	_portrait_tree.set_selected(item, 0)


## Switch the portrait settings to the portrait selected
func _switch_current_portrait(item: TreeItem) -> void:
	if not item:
		return # No change
	
	# Update the current portrait data
	if _current_portrait and not _current_portrait.get_metadata(0).has("group"):
		var current_data = _current_portrait.get_meta("portrait_editor").get_portrait_data()
		_current_portrait.set_metadata(0, {"portrait": current_data})

	# Switch the portrait editor panel
	if not item.get_metadata(0).has("group"):
		if _portrait_editor_container.get_child_count() > 0:
			_portrait_editor_container.remove_child(_portrait_editor_container.get_child(0))
		_portrait_editor_container.add_child(item.get_meta("portrait_editor"))
		_current_portrait = item

#endregion
