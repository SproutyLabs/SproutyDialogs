@tool
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

## Emitted when a dialogue has changed
signal dialogue_changed(dialogue: SproutyDialogsDialogueData)
## Emitted when a character has changed
signal character_changed(character: SproutyDialogsCharacterData)

## New dialog button
@onready var _new_dialog_button: Button = %NewDialogButton
## New character button
@onready var _new_char_button: Button = %NewCharButton
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
## Close editor warning dialog
@onready var _close_editor_warning: AcceptDialog = %CloseEditorWarning
## Missing character references dialog
@onready var _missing_chars_dialog: ConfirmationDialog = $PopupDialogs/MissingCharacters

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

## Save shortcut (Command/Ctrl-S)
var _save_shortcut: Shortcut = Shortcut.new()

## File index to save as
var _save_as_file_index: int = -1

## Editor main reference
var plugin_editor: Control = null

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	# Set save shortcut
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_S
	key_event.ctrl_pressed = true
	key_event.command_or_control_autoremap = true
	_save_shortcut.events = [key_event]

	# Connect signals
	_new_dialog_button.pressed.connect(on_new_dialog_pressed)
	_new_char_button.pressed.connect(on_new_character_pressed)
	_save_file_button.pressed.connect(save_file)

	open_file_dialog.file_selected.connect(load_file)
	save_file_dialog.file_selected.connect(func(path): save_file(_save_as_file_index, path))
	new_dialog_file_dialog.file_selected.connect(new_dialog_file)
	new_char_file_dialog.file_selected.connect(new_character_file)

	_file_list.file_selected.connect(switch_to_selected_file)
	_file_list.file_closed.connect(_on_file_closed)
	_file_list.request_save_file.connect(save_file)
	_file_list.request_save_file_as.connect((func(index):
			_save_as_file_index=index
			save_file_dialog.current_path=_file_list.get_item_metadata(index)["file_path"]
			save_file_dialog.popup_centered()
			)
		)

	_close_editor_warning.custom_action.connect(_on_confirm_closing_editor_action)
	_close_editor_warning.canceled.connect(func(): return null)

	_csv_file_field.path_changed.connect(_on_csv_file_path_changed)

	# Set confirm closing editor dialog actions
	_close_editor_warning.get_ok_button().hide()
	_close_editor_warning.add_button("Save files", true, "save_files")
	_close_editor_warning.add_button("Don't Save & Quit", true, "discard_files")
	_close_editor_warning.add_cancel_button("Cancel")
	_close_editor_warning.exclusive = false

	# Set icons for buttons
	_save_file_button.icon = get_theme_icon("Save", "EditorIcons")
	_new_dialog_button.icon = _new_dialog_icon
	_new_char_button.icon = _new_char_icon
	
	_csv_file_field.get_parent().hide() # Hide CSV file field by default
	_save_file_button.disabled = true # Disable save button

	# Add the resource picker to open and load resources
	var editor_resource_picker := EditorSproutyDialogsResourcePicker.new()
	%OpenButtonContainer.add_child(editor_resource_picker)
	editor_resource_picker.resource_picked.connect(
		func(res: Resource) -> void: load_file(res.resource_path)
		)

	await get_tree().process_frame # Wait a frame to ensure undo_redo is ready
	_file_list.undo_redo = undo_redo
	
	# Load the last opened files
	_load_opened_files()


func _input(event: InputEvent) -> void:
	# Capture save shortcut (Command/Ctrl-S)
	if _save_shortcut.matches_event(event) and event.is_pressed() and not event.is_echo():
		if plugin_editor.visible and plugin_editor.tab_container.current_tab < 2 \
				and not _file_list.get_current_index() < 0:
			save_file() # Save current file
			
			# Prevent default Ctrl-S behavior in the editor when saving only sprouty files
			if SproutyDialogsSettingsManager.get_setting("save_sprouty_only"):
				get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Display warning when editor is closed
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _file_list.has_unsaved_files():
			_close_editor_warning.popup_centered()


## Returns the current open file path
func get_current_file_path() -> String:
	var file_metadata = _file_list.get_item_metadata(_file_list.get_current_index())
	return file_metadata["file_path"] if file_metadata else ""


#region === New Files ==========================================================

## Create a new dialog file
func new_dialog_file(path: String) -> void:
	# Create a new dialogue data resource
	var resource = SproutyDialogsDialogueData.new()
	var csv_folder = SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	var csv_path = csv_folder + ("/" if csv_folder != "res://" else "") \
			+ path.get_file().get_basename() + ".csv"
	
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
		and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
		if not FileAccess.file_exists(csv_path):
			# Create a new CSV file for translations
			csv_path = SproutyDialogsCSVFileManager.new_csv_template_file(path.get_file())
			if csv_path.is_empty(): return
			# Refresh the filesystem to ensure the CSV file is imported
			var editor_interface = Engine.get_singleton("EditorInterface")
			editor_interface.get_resource_filesystem().scan()
		
		_csv_file_field.set_value(csv_path)
		_csv_file_field.get_parent().show()
		resource.csv_file_uid = ResourceSaver.get_resource_id_for_path(csv_path, true)
	else:
		csv_path = ""
	
	ResourceSaver.save(resource, path)
	var graph = _new_graph_from_resource(resource)
	_file_list.new_file_item(path, resource, graph, csv_path)
	request_to_switch_tab.emit(0)
	_save_file_button.disabled = false
	SproutyDialogsFileUtils.set_recent_file_path("dialog_files", path)
	_save_opened_files()
	print("[Sprouty Dialogs] Dialog file '" + path.get_file() + "' created.")


## Create a new graph instance and load the data from a resource
func _new_graph_from_resource(resource: SproutyDialogsDialogueData) -> EditorSproutyDialogsGraphEditor:
	var graph = _graph_scene.instantiate()
	dialogue_changed.connect(graph.dialogue_changed.emit)
	character_changed.connect(graph.character_changed.emit)
	graph.modified.connect(_on_data_modified)
	graph.view_state_changed.connect(_on_editor_view_state_changed)
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
	_save_opened_files()
	print("[Sprouty Dialogs] Character file '" + path.get_file() + "' created.")


## Create a new character editor instance and load the data from a resource
func _new_character_from_resource(resource: SproutyDialogsCharacterData) -> Control:
	var char_editor = _char_scene.instantiate()
	char_editor.modified.connect(_on_data_modified)
	char_editor.view_state_changed.connect(_on_editor_view_state_changed)
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
func load_file(path: String, check_resources: bool = true, view_state: Dictionary = {}) -> void:
	if _file_list.is_file_loaded(path):
		_file_list.switch_to_file_path(path)
		_save_opened_files()
		return
	
	if FileAccess.file_exists(path):
		var resource = load(path)
		SproutyDialogsFileUtils.set_recent_file_path("sprouty_files", path)

		if resource is SproutyDialogsDialogueData:
			SproutyDialogsFileUtils.set_recent_file_path("dialogue_files", path)
			var graph = _new_graph_from_resource(resource)
			if not view_state.is_empty():
				graph.load_editor_state(view_state)
			var csv_path_uid = resource.csv_file_uid
			var csv_path = ""
			if SproutyDialogsFileUtils.check_valid_uid_path(csv_path_uid):
				csv_path = ResourceUID.get_id_path(csv_path_uid)
			_file_list.new_file_item(path, resource, graph, csv_path)
			request_to_switch_tab.emit(0)
			_save_file_button.disabled = false
			_save_opened_files()
			if check_resources:
				_check_missing_characters(resource)
		
		elif resource is SproutyDialogsCharacterData:
			SproutyDialogsFileUtils.set_recent_file_path("character_files", path)
			var char_editor = _new_character_from_resource(resource)
			if not view_state.is_empty():
				char_editor.load_editor_state(view_state)
			_file_list.new_file_item(path, resource, char_editor)
			request_to_switch_tab.emit(1)
			_save_file_button.disabled = false
			_save_opened_files()
		
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
		dialogue_changed.emit(data)

		# Set the CSV file path if exists
		if SproutyDialogsFileUtils.check_valid_extension(_csv_file_field.get_value(), ["*.csv"]) \
				and FileAccess.file_exists(_csv_file_field.get_value()):
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

	elif data is SproutyDialogsCharacterData:
		data = file_metadata["cache_node"].get_character_data()
		file_metadata["data"] = data
		character_changed.emit(data)

		# Save character names on csv file
		if SproutyDialogsSettingsManager.get_setting("translate_character_names") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_for_character_names") \
			and SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
			SproutyDialogsCSVFileManager.save_character_names_on_csv(data.key_name, data.display_name)
	
	# Save file on the given path
	if file_metadata["data"] is SproutyDialogsCharacterData:
		file_metadata["data"].take_over_path(save_path)
	
	var result = ResourceSaver.save(file_metadata["data"], save_path)
	if result != OK:
		print("[Sprouty Dialogs] File '" + file_metadata.file_name + "' could not be saved.")
		return
	
	# Update the character resources in the inspector
	var inspector = Engine.get_singleton("EditorInterface").get_inspector()
	var current_edited = inspector.get_edited_object()
	if current_edited is SproutyDialogsCharacterData and file_metadata["data"] is SproutyDialogsCharacterData:
		if current_edited.key_name == file_metadata["data"].key_name:
			EditorInterface.edit_resource(file_metadata["data"])
	
	_file_list.set_item_metadata(index, file_metadata)
	_file_list.set_file_as_modified(index, false)

	print("[Sprouty Dialogs] File '" + file_metadata.file_name + "' saved.")

#endregion

#region === Check missing resources ============================================

## Check for missing character references in a dialogue resource
func _check_missing_characters(dialog_data: SproutyDialogsDialogueData) -> void:
	var char_references = dialog_data.get_all_character_references()
	var missing_chars = []
	var char_list = ""

	for id in dialog_data.characters.keys():
		for char in dialog_data.characters[id].keys():
			if not SproutyDialogsFileUtils.check_valid_uid_path(dialog_data.characters[id][char]):
				if not missing_chars.has(char):
					missing_chars.append(char)
					char_list += "\n - " + char.capitalize() + " (References: " + str(char_references[char]) + ")"
	
	if not missing_chars.is_empty():
		if _missing_chars_dialog.confirmed.is_connected(_reassign_missing_characters.bind(dialog_data)):
			_missing_chars_dialog.confirmed.disconnect(_reassign_missing_characters.bind(dialog_data))
		_missing_chars_dialog.confirmed.connect(_reassign_missing_characters.bind(dialog_data))
		_missing_chars_dialog.dialog_text = _missing_chars_dialog.dialog_text.replace("[dialogue]", dialog_data.resource_path)
		_missing_chars_dialog.dialog_text = _missing_chars_dialog.dialog_text.replace("[list]", char_list)
		_missing_chars_dialog.popup_centered()


## Search and reassign missing characters in a dialogue resource
func _reassign_missing_characters(dialog_data: SproutyDialogsDialogueData) -> void:
	# Get all character resources
	var characters: Dictionary = {}
	var character_resources = SproutyDialogsFileUtils.get_resources_of_type("character")

	for res in character_resources:
		var uid = ResourceSaver.get_resource_id_for_path(res.resource_path, true)
		characters[res.key_name] = uid
	
	# Reassign missing characters
	var chars_not_found = []
	for id in dialog_data.characters.keys():
		for char in dialog_data.characters[id].keys():
			if not SproutyDialogsFileUtils.check_valid_uid_path(dialog_data.characters[id][char]):
				if characters.has(char):
					dialog_data.characters[id][char] = characters[char]
				else:
					chars_not_found.append(char)
	
	if not chars_not_found.is_empty():
		push_warning("[Sprouty Dialogs] Some characters were not found in the project: " \
				+ str(chars_not_found).replace("[", "").replace("]", "") \
				+ ". Please check if the character files exist.")
	
	# Update the dialogue resource
	var result = ResourceSaver.save(dialog_data, dialog_data.resource_path)
	if result != OK:
		print("[Sprouty Dialogs] File '" + dialog_data.file_name + "' could not be saved.")
		return
	
	# Reload the dialogue
	await _file_list.close_file(_file_list.get_current_index())
	load_file(dialog_data.resource_path, false)

#endregion

#region === File options buttons ===============================================
## Open file dialog to select a file
func on_open_file_pressed() -> void:
	open_file_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("sprouty_files"))
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
		on_translation_enabled_changed()
		request_to_switch_tab.emit(0)
	
	elif file_metadata.data is SproutyDialogsCharacterData:
		request_to_switch_character.emit(file_metadata["cache_node"])
		request_to_switch_tab.emit(1)
	
	_save_opened_files()


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
	
	# Save the updated list of opened files
	_save_opened_files()


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


## Create a csv for the current dialogue file if doesn't have one
## when the translations settings are enabled
func on_translation_enabled_changed(_enabled: bool = false) -> void:
	if _file_list.get_current_index() == -1:
		return
	
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("use_csv_files"):
		var data = _file_list.get_item_metadata(_file_list.get_current_index())
		var csv_folder = SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
		if csv_folder == "":
			printerr("[Sprouty Dialogs] Cannot create csv for '" + data.file_name + "', you need to set up a CSV translations folder.")
			return # No CSV translations folder

		if not data.data is SproutyDialogsDialogueData:
			return

		if data.data.csv_file_uid == -1:
			var csv_path = csv_folder + ("/" if csv_folder != "res://" else "") \
					+ data.file_name.get_basename() + ".csv"
		
			if not FileAccess.file_exists(csv_path):
				# Create a new CSV file for translations
				csv_path = SproutyDialogsCSVFileManager.new_csv_template_file(data.file_name)
				if csv_path.is_empty(): return
				# Refresh the filesystem to ensure the CSV file is imported
				var editor_interface = Engine.get_singleton("EditorInterface")
				editor_interface.get_resource_filesystem().scan()
			
			_csv_file_field.set_value(csv_path)
			_csv_file_field.get_parent().show()
			data.data.csv_file_uid = ResourceSaver.get_resource_id_for_path(csv_path, true)


## Handle the confirm closing editor dialog actions
func _on_confirm_closing_editor_action(action) -> void:
	_close_editor_warning.hide()
	match action:
		"save_files": # Save all files
			for index in _file_list.get_item_count():
				save_file(index)
		"discard_files":
			get_tree().quit()


## Save the list of currently opened files to the project settings
func _save_opened_files() -> void:
	var opened_files: Array = []

	for index in range(_file_list.get_item_count()):
		var metadata = _file_list.get_item_metadata(index)
		if not metadata.has("file_path"):
			continue
		var path: String = metadata["file_path"]
		# Try to get a stable UID for the resource
		var uid = ResourceSaver.get_resource_id_for_path(path, true)
		var view_state: Dictionary = {}
		if metadata.has("cache_node") and metadata["cache_node"] != null:
			view_state = metadata["cache_node"].get_editor_state()
		# Save an entry with both uid and path (path as fallback) and view state
		opened_files.append({"uid": uid, "path": path, "view_state": view_state})

	# Save the currently selected file index
	var current_index = _file_list.get_current_index()
	SproutyDialogsSettingsManager.set_setting("last_opened_files", opened_files)
	SproutyDialogsSettingsManager.set_setting("last_selected_file_index", current_index)


## Load the list of last opened files from the project settings
func _load_opened_files() -> void:
	var last_opened_files = SproutyDialogsSettingsManager.get_setting("last_opened_files")
	var last_selected_index = SproutyDialogsSettingsManager.get_setting("last_selected_file_index")
	last_selected_index = last_selected_index if last_selected_index != null else -1
	
	if not (last_opened_files is Array and last_opened_files.size() > 0):
		return

	for entry in last_opened_files:
		var uid = entry["uid"] if entry.has("uid") else -1
		var path = entry["path"] if entry.has("path") else ""
		var view_state = entry["view_state"] if entry.has("view_state") else {}

		# Try to use UID first
		if SproutyDialogsFileUtils.check_valid_uid_path(uid):
			var uid_path = ResourceUID.get_id_path(uid)
			load_file(uid_path, false, view_state)
		# If UID is not valid, try to use the path
		elif path != "" and FileAccess.file_exists(path):
			load_file(path, false, view_state)
		else:
			push_warning("[Sprouty Dialogs] File with path '" + path + "' not found. Skipping.")

	# Restore the previously selected file
	if last_selected_index >= 0 and last_selected_index < _file_list.get_item_count():
		switch_to_selected_file(_file_list.get_item_metadata(last_selected_index))


## Handle editor view state changes and save them to the settings
func _on_editor_view_state_changed(view_state: Dictionary) -> void:
	var current_index = _file_list.get_current_index()
	if current_index < 0:
		return
	var file_metadata = _file_list.get_item_metadata(current_index)
	if file_metadata == null:
		return
	if file_metadata.has("cache_node") and file_metadata["cache_node"] != null:
		var file_list = SproutyDialogsSettingsManager.get_setting("last_opened_files")
		file_list[current_index]["view_state"] = view_state
		SproutyDialogsSettingsManager.set_setting("last_opened_files", file_list)
