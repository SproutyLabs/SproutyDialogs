@tool
class_name EditorSproutyDialogsFileManager
extends Control

# -----------------------------------------------------------------------------
# Sprouty Dialogs File manager
# -----------------------------------------------------------------------------
## This script handles the files management for the Sprouty Dialogs editor.
## It allows creating, opening, saving and switching between dialog and character files.
# -----------------------------------------------------------------------------

## Emitted when requesting to switch current graph in the dialogue editor
signal request_to_switch_graph(graph: EditorSproutyDialogsGraphEditor)
## Emitted when requesting to switch current character in the character editor
signal request_to_switch_character(char_editor: Control)
## Emitted when requesting to switch to a specific tab
signal request_to_switch_tab(tab: int)
## Emitted when all dialog files have been closed
signal all_dialog_files_closed
## Emitted when all character files have been closed
signal all_character_files_closed

## New dialog button
@onready var _new_dialog_button: Button = %NewDialogButton
## New character button
@onready var _new_char_button: Button = %NewCharButton
## Open file button
@onready var _open_file_button: Button = %OpenFileButton
## Save file button
@onready var _save_file_button: Button = %SaveFileButton

## New dialog file dialog
@onready var new_dialog_file_dialog: FileDialog = $PopupDialogs/NewDialog
## New character file dialog
@onready var new_char_file_dialog: FileDialog = $PopupDialogs/NewChar
## Open file dialog
@onready var open_file_dialog: FileDialog = $PopupDialogs/OpenFile
## Save file dialog
@onready var save_file_dialog: FileDialog = $PopupDialogs/SaveFile

## File list manager
@onready var _file_list: Control = $FileList
## CSV file path field
@onready var _csv_file_field: EditorSproutyDialogsFileField = $CSVFileField/FileField

## Icons for new dialog and character buttons
var _new_dialog_icon := preload("res://addons/sprouty_dialogs/editor/icons/add-dialog.svg")
var _new_char_icon := preload("res://addons/sprouty_dialogs/editor/icons/add-char.svg")

## Prefab scenes reference
var _graph_scene := preload("res://addons/sprouty_dialogs/editor/modules/graph_editor/graph_editor.tscn")
var _char_scene := preload("res://addons/sprouty_dialogs/editor/modules/characters/character_editor.tscn")

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	# Connect signals
	_new_dialog_button.pressed.connect(on_new_dialog_pressed)
	_new_char_button.pressed.connect(on_new_character_pressed)
	_open_file_button.pressed.connect(on_open_file_pressed)
	_save_file_button.pressed.connect(save_file)

	open_file_dialog.file_selected.connect(load_file)
	save_file_dialog.file_selected.connect(save_file)
	new_dialog_file_dialog.file_selected.connect(new_dialog_file)
	new_char_file_dialog.file_selected.connect(new_character_file)

	_file_list.file_selected.connect(switch_to_selected_file)
	_file_list.file_closed.connect(_on_file_closed)
	_file_list.request_save_file.connect(save_file)
	_file_list.request_save_file_as.connect(save_file_dialog.popup_centered)

	_csv_file_field.path_changed.connect(_on_csv_file_path_changed)

	# Set icons for buttons
	_open_file_button.icon = get_theme_icon("Folder", "EditorIcons")
	_save_file_button.icon = get_theme_icon("Save", "EditorIcons")
	_new_dialog_button.icon = _new_dialog_icon
	_new_char_button.icon = _new_char_icon
	
	_csv_file_field.get_parent().hide() # Hide CSV file field by default
	_save_file_button.disabled = true # Disable save button

	await get_tree().process_frame # Wait a frame to ensure undo_redo is ready
	_file_list.undo_redo = undo_redo


## Returns the current open file path
func get_current_file_path() -> String:
	var file_metadata = _file_list.get_item_metadata(_file_list.get_current_index())
	return file_metadata["file_path"] if file_metadata else ""


#region === New Files ==========================================================

## Create a new dialog file
func new_dialog_file(path: String) -> void:
	# Create a new dialogue data resource
	var resource = SproutyDialogsDialogueData.new()
	var csv_path = SproutyDialogsSettingsManager.get_setting("csv_translations_folder") \
			+"/" + path.get_file().get_basename() + ".csv"
	
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
		and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
		if not FileAccess.file_exists(csv_path):
			# Create a new CSV file for translations
			csv_path = SproutyDialogsCSVFileManager.new_csv_template_file(path.get_file())
			if csv_path.is_empty(): return
			# Refresh the filesystem to ensure the CSV file is imported
			var editor_interface = Engine.get_singleton("EditorInterface")
			editor_interface.get_resource_filesystem().scan()
			await editor_interface.get_resource_filesystem().resources_reimported
		
		_csv_file_field.set_value(csv_path)
		_csv_file_field.get_parent().show()
		resource.csv_file_uid = ResourceSaver.get_resource_id_for_path(csv_path, true)
	
	ResourceSaver.save(resource, path)
	var graph = _new_graph_from_resource(resource)
	_file_list.new_file_item(path, resource, graph, csv_path)
	request_to_switch_tab.emit(0)
	_save_file_button.disabled = false
	SproutyDialogsFileUtils.set_recent_file_path("dialog_files", path)
	print("[Sprouty Dialogs] Dialog file '" + path.get_file() + "' created.")


## Create a new graph instance and load the data from a resource
func _new_graph_from_resource(resource: SproutyDialogsDialogueData) -> EditorSproutyDialogsGraphEditor:
	var graph = _graph_scene.instantiate()
	graph.modified.connect(_on_data_modified)
	graph.undo_redo = undo_redo
	add_child(graph)
	var dialogs = resource.dialogs if resource.dialogs else {}
	# Load dialogs from CSV file if translation is enabled
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
		and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
		if SproutyDialogsFileUtils.check_valid_uid_path(resource.csv_file_uid):
			dialogs = SproutyDialogsCSVFileManager.load_dialogs_from_csv(
					ResourceUID.get_id_path(resource.csv_file_uid))
	graph.load_graph_data(resource, dialogs)
	graph.name = "Graph"
	remove_child(graph)
	return graph


## Create a new character file
func new_character_file(path: String) -> void:
	# Create a new character data resource
	var resource = SproutyDialogsCharacterData.new()
	resource.key_name = path.get_file().get_basename()
	ResourceSaver.save(resource, path)

	var char_editor = _new_character_from_resource(resource)
	_file_list.new_file_item(path, resource, char_editor)
	request_to_switch_tab.emit(1)

	_save_file_button.disabled = false
	SproutyDialogsFileUtils.set_recent_file_path("character_files", path)
	print("[Sprouty Dialogs] Character file '" + path.get_file() + "' created.")


## Create a new character editor instance and load the data from a resource
func _new_character_from_resource(resource: SproutyDialogsCharacterData) -> Control:
	var char_editor = _char_scene.instantiate()
	char_editor.modified.connect(_on_data_modified)
	char_editor.undo_redo = undo_redo
	add_child(char_editor)
	var name_data = resource.display_name if resource.display_name else {}
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
		and SproutyDialogsSettingsManager.get_setting("translate_character_names") \
		and SproutyDialogsSettingsManager.get_setting("use_csv_for_character_names") \
		and SproutyDialogsSettingsManager.get_setting("use_csv_files"): # Load character names from CSV file
		name_data = SproutyDialogsCSVFileManager.load_character_names_from_csv(resource.key_name)
		name_data["default"] = resource.display_name["default"] if resource.display_name.has("default") else ""
	char_editor.load_character(resource, name_data)
	char_editor.name = "CharacterEditor"
	remove_child(char_editor)
	return char_editor
#endregion

#region === Save and Load ======================================================

## Load data from a dialog or character resource file
func load_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var resource = load(path)
		SproutyDialogsFileUtils.set_recent_file_path("graph_dialogs_files", path)

		if resource is SproutyDialogsDialogueData:
			SproutyDialogsFileUtils.set_recent_file_path("dialogue_files", path)
			var graph = _new_graph_from_resource(resource)
			var csv_path_uid = resource.csv_file_uid
			var csv_path = ""
			if SproutyDialogsFileUtils.check_valid_uid_path(csv_path_uid):
				csv_path = ResourceUID.get_id_path(csv_path_uid)
			_file_list.new_file_item(path, resource, graph, csv_path)
			request_to_switch_tab.emit(0)
			_save_file_button.disabled = false
		
		elif resource is SproutyDialogsCharacterData:
			SproutyDialogsFileUtils.set_recent_file_path("character_files", path)
			var char_editor = _new_character_from_resource(resource)
			_file_list.new_file_item(path, resource, char_editor)
			request_to_switch_tab.emit(1)
			_save_file_button.disabled = false
		
		else:
			printerr("[Sprouty Dialogs] File " + path + " is not a valid dialogue or character resource.")
			return
	else:
		printerr("[Sprouty Dialogs] File " + path + "does not exist.")


## Save data to resource file
func save_file(index: int = _file_list.get_current_index(), path: String = "") -> void:
	var file_metadata = _file_list.get_item_metadata(index)
	var save_path = file_metadata["file_path"] if path.is_empty() else path
	var data = file_metadata.data
	
	if data is SproutyDialogsDialogueData:
		# If there is some error not solved on graph, cannot save
		if file_metadata.cache_node.alerts.is_error_alert_active():
			printerr("[Sprouty Dialogs] Cannot save, please fix the errors.")
			return
		var graph_editor_data = file_metadata["cache_node"].get_graph_data()
		data.graph_data = graph_editor_data["nodes_data"]
		data.dialogs = graph_editor_data["dialogs"]
		data.characters = graph_editor_data["characters"]

		# Set the CSV file path if exists
		if SproutyDialogsFileUtils.check_valid_extension(_csv_file_field.get_value(), ["*.csv"]):
			data.csv_file_uid = ResourceSaver.get_resource_id_for_path(_csv_file_field.get_value(), true)
		
		file_metadata["data"] = data

		# Save the CSV file with the dialogs
		if SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
			if SproutyDialogsFileUtils.check_valid_uid_path(data.csv_file_uid):
				SproutyDialogsCSVFileManager.save_dialogs_on_csv(
					graph_editor_data["dialogs"],
					ResourceUID.get_id_path(data.csv_file_uid)
				)
				SproutyDialogsTranslationManager.collect_translations()
				# Refresh the filesystem to ensure the translations are imported
				var editor_interface = Engine.get_singleton("EditorInterface")
				editor_interface.get_resource_filesystem().scan()
				await editor_interface.get_resource_filesystem().resources_reimported

	elif data is SproutyDialogsCharacterData:
		data = file_metadata["cache_node"].get_character_data()
		file_metadata["data"] = data

		# Save character names on csv file
		if SproutyDialogsSettingsManager.get_setting("translate_character_names") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_for_character_names") \
			and SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
			SproutyDialogsCSVFileManager.save_character_names_on_csv(data.key_name, data.display_name)
	
	# Save file on the given path
	ResourceSaver.save(file_metadata["data"], save_path)
	_file_list.set_item_metadata(index, file_metadata)
	_file_list.set_file_as_modified(index, false)

	print("[Sprouty Dialogs] File '" + file_metadata.file_name + "' saved.")

#endregion

#region === File options buttons ===============================================

## Open file dialog to select a file
func on_open_file_pressed() -> void:
	open_file_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("graph_dialogs_files"))
	open_file_dialog.popup_centered()


## Create new dialog file
func on_new_dialog_pressed() -> void:
	new_dialog_file_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("dialogue_files"))
	new_dialog_file_dialog.popup_centered()


## Create new character file
func on_new_character_pressed() -> void:
	new_char_file_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("character_files"))
	new_char_file_dialog.popup_centered()

#endregion


## Switch to a selected file
func switch_to_selected_file(file_metadata: Dictionary) -> void:
	if file_metadata.data is SproutyDialogsDialogueData:
		request_to_switch_graph.emit(file_metadata["cache_node"])
		_csv_file_field.set_value(file_metadata.csv_file)
		request_to_switch_tab.emit(0)
	
	elif file_metadata.data is SproutyDialogsCharacterData:
		request_to_switch_character.emit(file_metadata["cache_node"])
		request_to_switch_tab.emit(1)


## Switch to the file on the current tab
func switch_to_file_on_tab(tab: int, current_content: Node) -> void:
	if _file_list.get_item_count() == 0 or _file_list.get_current_index() == -1:
		return # No files open or no file selected
	var to_file := -1

	# Check if the current content has a file index
	if current_content and current_content.has_meta("file_index"):
		to_file = current_content.get_meta("file_index")
	else:
		return # No file index found, no file to switch to
	
	_file_list.set_current_index(to_file)


## Handle when a file is closed
func _on_file_closed(metadata: Dictionary) -> void:
	# Show start panel if there are no dialogs open
	if _file_list.get_dialogs_count() == 0:
		all_dialog_files_closed.emit()
		_csv_file_field.set_value("") # Clear CSV file path field
	
	# Show start panel if there are no characters open
	if _file_list.get_characters_count() == 0:
		all_character_files_closed.emit()

	# Disable save button if there are no files open
	if _file_list.get_dialogs_count() == 0 and _file_list.get_characters_count() == 0:
		_save_file_button.disabled = true


## Set the current file as modified
func _on_data_modified(modified: bool = true) -> void:
	_file_list.set_file_as_modified(_file_list.get_current_index(), modified)


## Update the CSV file path to the current dialog file
func _on_csv_file_path_changed(path: String) -> void:
	if not SproutyDialogsFileUtils.check_valid_extension(path, ["*.csv"]):
		printerr("[Sprouty Dialogs] Invalid CSV file path: " + path)
		return
	_csv_file_field.set_value(path)
	var data = _file_list.get_item_metadata(_file_list.get_current_index())
	data.csv_file = path
	_file_list.set_item_metadata(_file_list.get_current_index(), data)