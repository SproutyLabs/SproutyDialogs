@tool
extends HSplitContainer

# -----------------------------------------------------------------------------
# Character Editor
# ---------------------------------------------------------------------------- 
## This module is responsible for the character files creation and editing.
## It allows the user to edit character data, including the character's name,
## description, dialogue box, portraits and typing sounds.
# -----------------------------------------------------------------------------

## Triggered when something is modified
signal modified

## Label with the key name of the character
@onready var _key_name_label: Label = %KeyNameLabel
## Label with the default locale for display name
@onready var _name_default_locale_label: Label = %NameDefaultLocaleLabel
## Display name text input field in default locale
@onready var _name_default_locale_field: LineEdit = %NameDefaultLocaleField
## Translation container for display name
@onready var _name_translations_container: VBoxContainer = %NameTranslationsContainer

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

## Portrait tree
@onready var _portrait_tree: Tree = %PortraitTree
## Portrait tree search bar
@onready var _portrait_search_bar: LineEdit = %PortraitSearchBar
## Portrait empty panel
@onready var _portrait_empty_panel: Panel = $PortraitSettings/NoPortraitPanel
## Portrait settings container
@onready var _portrait_editor_container: Container = $PortraitSettings/Container

## Portrait settings panel scene
var portrait_editor_scene := preload("res://addons/sprouty_dialogs/editor/modules/characters/portrait_editor.tscn")

## Current portrait selected
var _current_portrait: TreeItem = null

## Key name of the character (file name)
var _key_name: String = ""
## Character name translations
var _name_translations = {}
## Default locale for dialog text
var _default_locale: String = ""
## Flag to indicate if translations are enabled
var _translations_enabled: bool = false
## Flag to indicate if the dialog has no translation (only default)
var _name_without_translation: bool = true

## Portrait display on dialog box option
var _portrait_on_dialog_box: bool = false


func _ready() -> void:
	# Connect signals
	_dialog_box_scene_field.path_changed.connect(_on_dialog_box_scene_path_changed)
	_to_dialog_box_scene_button.pressed.connect(_on_dialog_box_scene_button_pressed)
	_new_dialog_box_scene_button.pressed.connect(_on_new_dialog_box_scene_pressed)
	_new_dialog_box_dialog.file_selected.connect(_new_dialog_box)
	%PortraitOnDialogBoxToggle.toggled.connect(_on_portrait_dialog_box_toggled)
	_portrait_tree.show_portrait_editor_panel.connect(_show_portrait_editor_panel)
	_portrait_tree.portrait_item_selected.connect(_on_portrait_selected)
	_portrait_tree.modified.connect(on_modified)

	# Set icons for buttons and fields
	_to_dialog_box_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_new_dialog_box_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_portrait_search_bar.right_icon = get_theme_icon("Search", "EditorIcons")
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddFolderButton.icon = get_theme_icon("Folder", "EditorIcons")

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	on_translation_enabled_changed( # Enable/disable translation section
			EditorSproutyDialogsSettingsManager.get_setting("enable_translations")
		)


## Emit the modified signal
func on_modified():
	modified.emit()


## Get the character data from the editor
func get_character_data() -> SproutyDialogsCharacterData:
	var data = SproutyDialogsCharacterData.new()
	data.key_name = _key_name
	data.display_name = _get_name_translations()
	data.description = _description_field.text
	data.dialog_box = ResourceSaver.get_resource_id_for_path(_dialog_box_scene_field.get_value(), true) if \
		EditorSproutyDialogsFileUtils.check_valid_extension(_dialog_box_scene_field.get_value(),
			_dialog_box_scene_field.file_filters) else -1
	data.portrait_on_dialog_box = _portrait_on_dialog_box
	data.portraits = _portrait_tree.get_portraits_data()
	data.typing_sounds = {} # Typing sounds are not implemented yet
	return data


## Load the character data into the editor
func load_character(data: SproutyDialogsCharacterData, name_data: Dictionary) -> void:
	_key_name = data.key_name
	_key_name_label.text = _key_name.to_pascal_case()
	_description_field.text = data.description

	# Character name and its translations
	_set_translation_text_boxes()
	if name_data.is_empty(): # Load from character data
		_load_name_translations(data.display_name)
	else: # Load from provided name CSV data
		_load_name_translations(name_data)
	_update_translations_state()

	# Dialog box scene file
	if not EditorSproutyDialogsFileUtils.check_valid_uid_path(data.dialog_box):
		if data.dialog_box != -1:
			printerr("[Sprouty Dialogs] Dialog box scene not found for character '"
					+ _key_name + "'. Check if the scene file was deleted.")
		_to_dialog_box_scene_button.visible = false
		_new_dialog_box_scene_button.visible = true
		_dialog_box_scene_field.set_value("")
	else:
		_dialog_box_scene_field.set_value(ResourceUID.get_id_path(data.dialog_box))
	
	if EditorSproutyDialogsFileUtils.check_valid_extension(
			_dialog_box_scene_field.get_value(), _dialog_box_scene_field.file_filters):
		_to_dialog_box_scene_button.visible = true
		_new_dialog_box_scene_button.visible = false
	_portrait_on_dialog_box = data.portrait_on_dialog_box
	%PortraitOnDialogBoxToggle.button_pressed = _portrait_on_dialog_box

	# Portraits
	_portrait_tree.load_portraits_data(data.portraits, self)


## Open a scene in the editor
func open_scene_in_editor(path: String) -> void:
	if EditorSproutyDialogsFileUtils.check_valid_extension(path, _dialog_box_scene_field.file_filters):
		if ResourceLoader.exists(path):
			EditorInterface.open_scene_from_path(path)
			await get_tree().process_frame
			EditorInterface.set_main_screen_editor("2D")
	else:
		printerr("[Sprouty Dialogs] Invalid scene file path.")


#region === Character Name Translation =========================================

## Update name translations text boxes when locales change
func on_locales_changed() -> void:
	if _key_name != "":
		var translations = _get_name_translations()
		var previous_default_locale = _default_locale
		_set_translation_text_boxes()
		# Handle when there was no translation before
		if _name_without_translation and _default_locale != "":
			translations[_default_locale] = translations["default"]
			_name_without_translation = false
		# Handle when the default locale changes
		elif previous_default_locale != _default_locale:
			if previous_default_locale != "":
				translations[previous_default_locale] = translations["default"]
			translations["default"] = translations[_default_locale] \
					if translations.has(_default_locale) else translations["default"]
			_name_translations = translations
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
	if EditorSproutyDialogsSettingsManager.get_setting("enable_translations") \
			and EditorSproutyDialogsSettingsManager.get_setting("translate_character_names"):
		_name_translations_container.visible = true
		_name_default_locale_label.visible = true
	else:
		_name_default_locale_label.visible = false
		_name_translations_container.visible = false


## Get character name translations
func _get_name_translations() -> Dictionary:
	var translations = _name_translations
	translations["default"] = _name_default_locale_field.text
	if _translations_enabled:
		if _default_locale != "":
			translations[_default_locale] = _name_default_locale_field.text
		translations.merge(_name_translations_container.get_translations_text())
	return translations


## Load character name translations
func _load_name_translations(translations: Dictionary) -> void:
	_name_translations = translations
	if translations.size() > 1: # There are translations
		_name_without_translation = false

	if _translations_enabled and translations.has(_default_locale):
		_name_default_locale_field.text = translations[_default_locale]
	else: # Use default if translations disabled or no default locale translation
		if translations.has("default"):
			_name_default_locale_field.text = translations["default"]
		else:
			_name_default_locale_field.text = ""
	_name_translations_container.load_translations_text(translations)


## Set character name translations text boxes
func _set_translation_text_boxes() -> void:
	_translations_enabled = EditorSproutyDialogsSettingsManager.get_setting("enable_translations")
	_default_locale = EditorSproutyDialogsSettingsManager.get_setting("default_locale")
	var locales = EditorSproutyDialogsSettingsManager.get_setting("locales")
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

#endregion

#region === Dialog Text box ====================================================

## Handle the dialog box scene file path
func _on_dialog_box_scene_path_changed(path: String) -> void:
	if path.is_empty(): # No path selected
		_to_dialog_box_scene_button.visible = false
		_new_dialog_box_scene_button.visible = true
	elif EditorSproutyDialogsFileUtils.check_valid_extension(path, _dialog_box_scene_field.file_filters):
		_to_dialog_box_scene_button.visible = true # Valid path
		_new_dialog_box_scene_button.visible = false
	on_modified()


## Handle the dialog box scene button press
func _on_dialog_box_scene_button_pressed() -> void:
	open_scene_in_editor(_dialog_box_scene_field.get_value())


## Create a new dialog box scene and open it in the editor
func _on_new_dialog_box_scene_pressed() -> void:
	_new_dialog_box_dialog.set_current_dir(EditorSproutyDialogsFileUtils.get_recent_file_path("dialog_box_files"))
	_new_dialog_box_dialog.get_line_edit().text = "new_dialog_box.tscn"
	_new_dialog_box_dialog.popup_centered()


## Create a new dialog box scene file
func _new_dialog_box(path: String) -> void:
	var default_uid = EditorSproutyDialogsSettingsManager.get_setting("default_dialog_box")
	var default_path = ""
	
	# If no default dialog box is set or the resource does not exist, use the built-in default
	if not EditorSproutyDialogsFileUtils.check_valid_uid_path(default_uid):
		printerr("[Sprouty Dialogs] No default dialog box scene found." \
				+" Check that the default dialog box is set in Settings > General" \
				+" plugin tab, and that the scene resource exists. Using built-in default instead.")
		default_path = EditorSproutyDialogsSettingsManager.DEFAULT_DIALOG_BOX_PATH
		# Use and set the setting to the built-in default
		EditorSproutyDialogsSettingsManager.set_setting("default_dialog_box",
				ResourceSaver.get_resource_id_for_path(default_path, true))
	else: # Use the user-defined default dialog box
		default_path = ResourceUID.get_id_path(default_uid)
	
	var new_scene = load(default_path).instantiate()
	new_scene.name = path.get_file().split(".")[0].to_pascal_case()

	# Creates and set a template script for the new scene
	var script_path := path.get_basename() + ".gd"
	var script = GDScript.new()
	script.source_code = new_scene.get_script().source_code
	ResourceSaver.save(script, script_path)
	new_scene.set_script(load(script_path))

	# Save the new scene file
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	ResourceSaver.save(packed_scene, path)
	new_scene.queue_free()

	# Set the dialog box scene path
	_dialog_box_scene_field.set_value(path)
	_to_dialog_box_scene_button.visible = true
	_new_dialog_box_scene_button.visible = false

	# Open the new scene in the editor
	open_scene_in_editor(path)
	on_modified()

	# Set the recent file path
	EditorSproutyDialogsFileUtils.set_recent_file_path("dialog_box_files", path)


## Handle the text box portrait display toggle
func _on_portrait_dialog_box_toggled(toggled_on: bool) -> void:
	_portrait_on_dialog_box = toggled_on
	on_modified()

#endregion

#region === Portrait Tree ======================================================

## Show or hide the portrait settings panel
func _show_portrait_editor_panel(show: bool) -> void:
	_portrait_empty_panel.visible = not show
	_portrait_editor_container.visible = show


## Add a new portrait to the tree
func _on_add_portrait_button_pressed() -> void:
	var parent: TreeItem = _portrait_tree.get_root()
	if _portrait_tree.get_selected():
		if _portrait_tree.get_selected().get_metadata(0) and \
			_portrait_tree.get_selected().get_metadata(0).has("group"):
			parent = _portrait_tree.get_selected()
		else:
			parent = _portrait_tree.get_selected().get_parent()
	var portrait_editor = portrait_editor_scene.instantiate()
	add_child(portrait_editor)
	var item: TreeItem = _portrait_tree.new_portrait_item(
			"New Portrait", portrait_editor.get_portrait_data(), parent, portrait_editor
		)
	portrait_editor.request_open_scene_in_editor.connect(open_scene_in_editor)
	portrait_editor.modified.connect(on_modified)
	remove_child(portrait_editor)
	item.set_editable(0, true)
	item.select(0)
	_portrait_tree.call_deferred("edit_selected")
	on_modified()


## Add a new portrait group to the tree
func _on_add_folder_button_pressed() -> void:
	var parent: TreeItem = _portrait_tree.get_root()
	if _portrait_tree.get_selected():
		if _portrait_tree.get_selected().get_metadata(0) and \
			_portrait_tree.get_selected().get_metadata(0).has("group"):
			parent = _portrait_tree.get_selected()
		else:
			parent = _portrait_tree.get_selected().get_parent()
	var item: TreeItem = _portrait_tree.new_portrait_group("New Group", parent)
	item.set_editable(0, true)
	item.select(0)
	_portrait_tree.call_deferred("edit_selected")
	on_modified()


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
	_switch_current_portrait(item)


## Switch the portrait settings to the portrait selected
func _switch_current_portrait(item: TreeItem) -> void:
	if item == _current_portrait:
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
