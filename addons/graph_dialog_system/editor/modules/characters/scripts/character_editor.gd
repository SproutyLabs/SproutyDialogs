@tool
extends HSplitContainer

## -----------------------------------------------------------------------------
## Character Editor
## 
## This module is responsible for the character files creation and editing.
## It allows the user to edit character data, including the character's name,
## description, dialogue box, portraits and typing sounds.
## -----------------------------------------------------------------------------

## Triggered when something is modified
signal modified

## New scene dialog
@onready var new_scene_dialog: FileDialog = $NewSceneDialog

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
## Text box scene file field
@onready var _text_box_scene_field: GDialogsFileField = %TextBoxSceneField
## Text box scene button
@onready var _to_text_box_scene_button: Button = %ToTextBoxSceneButton
## Text box new scene button
@onready var _new_text_box_scene_button: Button = %NewTextBoxSceneButton

## Portrait tree
@onready var _portrait_tree: Tree = %PortraitTree
## Portrait tree search bar
@onready var _portrait_search_bar: LineEdit = %PortraitSearchBar
## Portrait empty panel
@onready var _portrait_empty_panel: Panel = $PortraitSettings/EmptyPanel
## Portrait settings container
@onready var _portrait_editor_container: Container = $PortraitSettings/Container

## Default text box scene
var _default_text_box_scene := preload("res://addons/graph_dialog_system/utils/default_text_box.tscn")

## Portrait settings panel scene
var _portrait_scene := preload("res://addons/graph_dialog_system/editor/modules/characters/portrait_editor.tscn")
## Current portrait selected
var _current_portrait: TreeItem = null

## Key name of the character (file name)
var _key_name: String = ""
## Default locale for dialog text
var _default_locale: String = ""

## Portrait display on text box option
var _portrait_on_text_box: bool = false


func _ready() -> void:
	_set_translation_text_boxes()
	if GDialogsTranslationManager.translation_settings:
		# Connect to the translation settings signals
		GDialogsTranslationManager.translation_settings.connect(
			"locales_changed", _on_locales_changed
		)
		GDialogsTranslationManager.translation_settings.connect(
			"default_locale_changed", _on_locales_changed
		)
	_portrait_tree.connect("modified", on_modified)
	_portrait_tree.connect("portrait_item_selected", _on_portrait_selected)
	_to_text_box_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_new_text_box_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_portrait_search_bar.right_icon = get_theme_icon("Search", "EditorIcons")
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddFolderButton.icon = get_theme_icon("Folder", "EditorIcons")


## Emit the modified signal
func on_modified():
	modified.emit()


## Get the character data from the editor
func get_character_data() -> Dictionary:
	var data = {
		"character_data": {
			"key_name": _key_name,
			"display_name": {_key_name: get_name_translations()},
			"description": _description_field.text,
			"text_box": _text_box_scene_field.get_value(),
			"portrait_on_text_box": _portrait_on_text_box,
			"portraits": {},
			"typing_sounds": {}
		}
	}
	return data


## Load the character data into the editor
func load_character(data: Dictionary, name_data: Dictionary) -> void:
	_key_name = data.key_name
	_key_name_label.text = _key_name.to_pascal_case()
	var name_translations = name_data[_key_name]
	_description_field.text = data.description

	# Character name and its translations
	_set_translation_text_boxes()
	_name_default_locale_field.text = name_translations[_default_locale]
	_name_translations_container.load_translations_text(name_translations)

	# Text box scene file
	_text_box_scene_field.set_value(data.text_box)
	if check_valid_file(data.text_box, _text_box_scene_field.file_filters):
		_to_text_box_scene_button.visible = true
		_new_text_box_scene_button.visible = false
	_portrait_on_text_box = data.portrait_on_text_box
	%PortraitOnTextBoxToggle.button_pressed = _portrait_on_text_box


## Check if the path has valid extension
func check_valid_file(path: String, extensions: Array) -> bool:
	if path.is_empty():
		return false
	for ext in extensions:
		if path.ends_with(ext.replace("*", "")):
			return true
	return false


## Open a scene in the editor
func open_scene_in_editor(path: String) -> void:
	if check_valid_file(path, _text_box_scene_field.file_filters):
		if ResourceLoader.exists(path):
			EditorInterface.open_scene_from_path(path)
			await get_tree().process_frame
			EditorInterface.set_main_screen_editor("2D")
	else:
		printerr("[Graph Dialogs] Invalid scene file path.")


#region === Character Name Translation =========================================

## Get character name translations
func get_name_translations() -> Dictionary:
	var translations = {}
	translations[_default_locale] = _name_default_locale_field.text
	translations.merge(_name_translations_container.get_translations_text())
	return translations


## Load character name translations
func load_name_translations(translations: Dictionary) -> void:
	_name_default_locale_field = translations[_default_locale]
	_name_translations_container.load_translations_text(translations)


## Set character name translations text boxes
func _set_translation_text_boxes() -> void:
	_default_locale = GDialogsTranslationManager.default_locale
	_name_default_locale_label.text = "(" + _default_locale + ")"
	_name_default_locale_field.text = ""
	_name_translations_container.set_translation_boxes(
			GDialogsTranslationManager.locales.filter(
				func(locale): return locale != _default_locale
			)
		)


## Update name translations text boxes when locales change
func _on_locales_changed() -> void:
	var translations = get_name_translations()
	_set_translation_text_boxes()
	load_name_translations(translations)

#endregion

#region === Text box ===========================================================

## Handle the text box scene file path
func _on_text_box_scene_path_changed(path: String) -> void:
	if path.is_empty(): # No path selected
		_to_text_box_scene_button.visible = false
		_new_text_box_scene_button.visible = true
	elif check_valid_file(path, _text_box_scene_field.file_filters):
		_to_text_box_scene_button.visible = true # Valid path
		_new_text_box_scene_button.visible = false
	on_modified()


## Handle the text box scene button press
func _on_text_box_scene_button_pressed() -> void:
	open_scene_in_editor(_text_box_scene_field.get_value())


## Create a new text box scene and open it in the editor
func _on_new_text_box_scene_pressed() -> void:
	if not new_scene_dialog.is_connected("file_selected", _on_new_text_box_path_selected):
		new_scene_dialog.connect("file_selected", _on_new_text_box_path_selected)
	new_scene_dialog.get_line_edit().text = "new_text_box.tscn"
	new_scene_dialog.popup_centered()


## Create a new text box scene file
func _on_new_text_box_path_selected(path: String) -> void:
	var new_scene = _default_text_box_scene.instantiate()
	new_scene.name = path.get_file().split(".")[0].to_pascal_case()

	# Save the new scene file
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	ResourceSaver.save(packed_scene, path)
	new_scene.queue_free()

	# Set the text box scene path
	_text_box_scene_field.set_value(path)
	_to_text_box_scene_button.visible = true
	_new_text_box_scene_button.visible = false

	# Open the new scene in the editor
	open_scene_in_editor(path)
	on_modified()


## Handle the text box portrait display toggle
func _on_portrait_text_box_toggled(toggled_on: bool) -> void:
	_portrait_on_text_box = toggled_on
	on_modified()

#endregion

#region === Portrait Tree ======================================================

## Add a new portrait to the tree
func _on_add_portrait_button_pressed() -> void:
	var parent: TreeItem = _portrait_tree.get_root()
	if _portrait_tree.get_selected():
		if _portrait_tree.get_selected().get_metadata(0) and \
			_portrait_tree.get_selected().get_metadata(0).has("group"):
			parent = _portrait_tree.get_selected()
		else:
			parent = _portrait_tree.get_selected().get_parent()
	var portrait_editor = _portrait_scene.instantiate()
	add_child(portrait_editor)
	var item: TreeItem = _portrait_tree.new_portrait_item(
			"New Portrait", {}, parent, portrait_editor
		)
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


## Show or hide the portrait settings panel
func _show_portrait_editor_panel(show: bool) -> void:
	_portrait_empty_panel.visible = not show
	_portrait_editor_container.visible = show


## Update the portrait settings when a portrait is selected
func _on_portrait_selected(item: TreeItem) -> void:
	# Check if the selected item is a portrait
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
		_current_portrait.set_metadata(0, current_data)

	# Switch the portrait editor panel
	if not item.get_metadata(0).has("group"):
		if _portrait_editor_container.get_child_count() > 0:
			_portrait_editor_container.remove_child(_portrait_editor_container.get_child(0))
		_portrait_editor_container.add_child(item.get_meta("portrait_editor"))
		_current_portrait = item

#endregion
