@tool
extends VSplitContainer

## -----------------------------------------------------------------------------
## File manager
##
## This script handles the file creation, loading, saving, and closing. It also
## provides methods to create new files and switch between them.
##
## Further, it handles the csv file path to the dialog data and the dialog data
## saving and loading from the csv file.
## -----------------------------------------------------------------------------

## JSON File type. Can be a dialog or a character file.
enum FileType {DIALOG, CHAR}

## Editor main reference
@export var _editor_main: Control
## Workspace reference
@export var _workspace: SplitContainer

## Save file button
@onready var _save_file_button: Button = %SaveFileButton

## File search input
@onready var _file_search: LineEdit = %FileSearch
## File list on side bar
@onready var _file_list: ItemList = %FileList
## Filtered file list
@onready var _filtered_list: ItemList = %FilteredList
## File pop-up menu
@onready var _file_popup_menu: PopupMenu = $PopupWindows/FileMenu

## New dialog file dialog
@onready var _new_dialog_file_dialog: FileDialog = $PopupWindows/NewDialog
## New character file dialog
@onready var _new_char_file_dialog: FileDialog = $PopupWindows/NewChar
## Open file dialog
@onready var _open_file_dialog: FileDialog = $PopupWindows/OpenFile
## Save file dialog
@onready var _save_file_dialog: FileDialog = $PopupWindows/SaveFile
## Confirm close files dialog
@onready var _confirm_close_dialog: AcceptDialog = $PopupWindows/ConfirmCloseFiles

## CSV file container
@onready var _csv_file_field: MarginContainer = $%CSVFileContainer/FileField

## Graph scene reference
var _graph_scene := preload("res://addons/graph_dialog_system/editor/modules/workspace/graph.tscn")

## Dialog file icon
var _dialog_icon := preload("res://addons/graph_dialog_system/icons/Script.svg")
## Character file icon
var _char_icon := preload("res://addons/graph_dialog_system/icons/Character.svg")

## Current file index
var _current_file_index: int = -1
## Files to close queue
var _closing_queue: Array[int] = []


func _ready() -> void:
	# Connect signals
	_open_file_dialog.connect("file_selected", load_file)
	_save_file_dialog.connect("file_selected", save_file)
	_new_dialog_file_dialog.connect("file_selected", new_dialog_file)
	_new_char_file_dialog.connect("file_selected", new_character_file)
	
	# Set confirm closing dialog actions
	_confirm_close_dialog.get_ok_button().hide()
	_confirm_close_dialog.add_button('Save', true, 'save_file')
	_confirm_close_dialog.add_button('Discard', true, 'discard_file')
	_confirm_close_dialog.add_cancel_button('Cancel')
	
	_csv_file_field.connect("file_path_changed", set_csv_file_to_dialog)
	hide_csv_container() # Hide csv container on start
	
	_save_file_button.disabled = true # Disable save button


## Open a file dialog to select a file to open
func select_file_to_open() -> void:
	_open_file_dialog.popup_centered()


## Open a file dialog to select where create a new dialog file
func select_new_dialog_file() -> void:
	_new_dialog_file_dialog.popup_centered()


#region === New Files ==========================================================

## Create a new dialog file
func new_dialog_file(path: String) -> void:
	var file_name := path.split('/')[-1]
	var csv_path = GDialogsTranslationManager.new_csv_template_file(file_name)
	if csv_path.is_empty(): return
	
	# Set csv file path from the dialog data
	_csv_file_field.set_value(csv_path)
	show_csv_container()
	
	var data := {
		"dialog_data": {
			"csv_file_path": csv_path,
			"nodes_data": {}
		}
	}
	# Create a new JSON file and add file to the list
	GDialogsJSONFileManager.save_file(data, path)
	_new_file_item(file_name, path, FileType.DIALOG, data)
	_editor_main.switch_active_tab(0)
	_workspace.show_graph_editor()
	print("[Graph Dialogs] Dialog file '" + file_name + "' created.")


## Create a new character file
func new_character_file(path: String) -> void:
	var file_name: String = path.split('/')[-1]
	var data = {
		"character_data": {
			"csv_file_path": "",
			"key_name": "",
			"description": "",
			"portraits": {}
		}
	}
	# Create a new JSON file and add file to the list
	GDialogsJSONFileManager.save_file(data, path)
	_new_file_item(file_name, path, FileType.CHAR, data)
	_editor_main.switch_active_tab(1)
	print("[Graph Dialogs] Character file '" + file_name + "' created.")


## Create a new file item on the file list
func _new_file_item(file_name: String, path: String, type: FileType, data: Dictionary) -> void:
	var item_index: int = _file_list.item_count
	
	# Check if the file is already loaded
	for index in range(_file_list.item_count):
		if _file_list.get_item_metadata(index)["file_path"] == path:
			print("[Graph Dialogs] File '" + file_name + "' Already loaded.")
			return
	
	# Create new metadata for the file
	var metadata := {
		'file_name': file_name,
		'file_path': path,
		'file_type': type,
		'data': data,
		'modified': false
		}

	match type:
		# Add file item by type
		FileType.DIALOG:
			# Create a graph and load the nodes data
			var graph = _graph_scene.instantiate()
			add_child(graph)
			graph.modified.connect(_on_data_modified)
			var csv_path = data["dialog_data"]["csv_file_path"]
			var dialogs = load_dialogs_from_csv(csv_path)
			graph.load_nodes_data(data, dialogs)
			graph.name = "Graph"
			remove_child(graph)
			metadata['graph'] = graph # Add graph to metadata
			
			# Add item to the file list
			_file_list.add_item(file_name, _dialog_icon)
			_file_list.set_item_metadata(item_index, metadata)
			
		FileType.CHAR:
			# Add item to the file list
			_file_list.add_item(file_name, _char_icon)
			_file_list.set_item_metadata(item_index, metadata)

	_switch_selected_file(item_index)
	_save_file_button.disabled = false
#endregion

#region === Save and Load ======================================================

## Load data from JSON file
func load_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var data = GDialogsJSONFileManager.load_file(path)
		var file_name: String = path.split('/')[-1]
		
		if data.has("dialog_data"): # Load a dialog
			_new_file_item(file_name, path, FileType.DIALOG, data)
			_editor_main.switch_active_tab(0)
			_workspace.show_graph_editor()
		
		elif data.has("character_data"): # Load a character
			_new_file_item(file_name, path, FileType.CHAR, data)
			_editor_main.switch_active_tab(1)
			# TODO: Load character data
		else:
			printerr("[Graph Dialogs] File " + path + "has an invalid format.")
	else:
		printerr("[Graph Dialogs] File " + path + "does not exist.")


## Save data to JSON file
func save_file(index: int = _current_file_index, path: String = "") -> void:
	var file_metadata = _file_list.get_item_metadata(index)
	var data = file_metadata["data"]
	
	match file_metadata["file_type"]:
		FileType.DIALOG: # Save dialog data
			# If there is some error not solved on graph, cannot save
			if file_metadata["graph"].alerts.is_error_alert_active():
				printerr("[Graph Dialogs] Cannot save, please fix the errors.")
				return
			# Get nodes data from the graph
			var graph_data = file_metadata["graph"].get_nodes_data()
			data["dialog_data"]["nodes_data"] = graph_data["nodes_data"]
			file_metadata["data"] = data
			# Save dialogs on csv file
			save_dialogs_on_csv(graph_data["dialogs"], data["dialog_data"]["csv_file_path"])

		FileType.CHAR: # Save character data
			pass # TODO: Update the character data
	
	# Save file on the given path
	var save_path = file_metadata["file_path"] if path.is_empty() else path
	GDialogsJSONFileManager.save_file(data, save_path)
	_file_list.set_item_metadata(index, file_metadata)
	_set_file_as_modified(index, false)
	print("[Graph Dialogs] File '" + file_metadata["file_name"] + "' saved.")
#endregion

#region === Close Files ========================================================

## Close an open file
func close_file(index: int = _current_file_index) -> void:
	if _file_list.item_count == 0: return
	
	index = wrapi(index, 0, _file_list.item_count)
	var metadata := _file_list.get_item_metadata(index)

	if metadata["modified"] and not index in _closing_queue:
		# If the file to be closed is unsaved, alert user before close
		_closing_queue.append(index)
		_confirm_close_dialog.popup_centered()
		return
	
	if index == _current_file_index:
		# If the file to be closed is being edited
		_csv_file_field.set_value("")
		
		if _file_list.item_count == 1:
			# If there are no open files to switch to them
			_current_file_index = -1
		elif index == 0:
			# If the file to close is the first one, switch to second one
			_switch_selected_file(1)
			_current_file_index = 0
		else: # If not the first file, switch to the previous file
			_switch_selected_file(index - 1)
	
	if metadata["file_type"] == FileType.DIALOG:
		metadata["graph"].queue_free()
	
	if _file_list.item_count == 1:
		_workspace.show_start_panel()
		_save_file_button.disabled = true
	
	_file_list.remove_item(index)


## Close all open files
func close_all() -> void:
	_closing_queue.clear()
	
	# Add unsaved files to queue to wait for closing confirmation
	for index in range(_file_list.item_count):
		if _file_list.get_item_metadata(index)["modified"]:
			_closing_queue.append(index)
	
	if _closing_queue.size() > 0: # Alert unsaved changes
		_confirm_close_dialog.popup_centered()
		return
	
	# Close all if none are modified
	_current_file_index = -1
	for index in range(_file_list.item_count):
		close_file(index)
#endregion

#region === Work Files Handling ================================================

## Switch to a selected file
func _switch_selected_file(file_index: int) -> void:
	if _file_list.item_count == 0 or file_index > _file_list.item_count:
		return
	var new_metadata := _file_list.get_item_metadata(file_index)
	
	if _current_file_index > -1: # Update metadata on current file
		var current_metadata := _file_list.get_item_metadata(_current_file_index)
		
		if current_metadata["file_type"] == FileType.DIALOG:
			current_metadata.data.dialog_data.nodes_data = \
					current_metadata["graph"].get_nodes_data()
		
		elif current_metadata["file_type"] == FileType.CHAR:
			pass # TODO: update character metadata
		
		_file_list.set_item_metadata(_current_file_index, current_metadata)
	
	# Switch view to the new file
	if new_metadata["file_type"] == FileType.DIALOG:
		# Switch current graph and change tab view
		_workspace.switch_current_graph(new_metadata["graph"])
		_csv_file_field.set_value(new_metadata["data"]["dialog_data"]["csv_file_path"])
		_editor_main.switch_active_tab(0)
	
	elif new_metadata["file_type"] == FileType.CHAR:
		# TODO: update character data
		_editor_main.switch_active_tab(1)
	_current_file_index = file_index
	_file_list.select(file_index)


## Set a file as modified or unsaved
func _set_file_as_modified(index: int, value: bool) -> void:
	if _current_file_index == -1:
		return
	var suffix := '(*)' if value else ''
	var metadata := _file_list.get_item_metadata(index)
	metadata["modified"] = value
	_file_list.set_item_metadata(index, metadata)
	_file_list.set_item_text(index, metadata["file_name"] + suffix)


## Set the current file as modified
func _on_data_modified() -> void:
	_set_file_as_modified(_current_file_index, true)


## Filter file list by a input filter text
func _filter_file_list(search_text: String) -> void:
	_filtered_list.clear()
	
	for item in _file_list.item_count:
		if _file_list.get_item_text(item).contains(search_text):
			_filtered_list.add_item(
				_file_list.get_item_text(item),
				_file_list.get_item_icon(item)
			)
	_file_list.visible = false
	_filtered_list.visible = true
#endregion

#region === CSV Files Handling =================================================

## Set CSV file path to the current data file
func set_csv_file_to_dialog(path: String) -> void:
	var metadata := _file_list.get_item_metadata(_current_file_index)
	metadata["data"]["dialog_data"]["csv_file_path"] = path
	_file_list.set_item_metadata(_current_file_index, metadata)
	_csv_file_field.set_value(path)
	

## Save all graph dialogs on CSV file
func save_dialogs_on_csv(dialogs: Dictionary, path: String) -> void:
	var header = ["key"]
	var content = []
	
	for dialog_key in dialogs:
		var row = [dialog_key]
		for locale in dialogs[dialog_key]:
			if header.size() < dialogs[dialog_key].size() + 1:
				header.append(locale) # Set header
			row.append(dialogs[dialog_key][locale])
		content.append(row)
	
	GDialogsCSVFileManager.save_file(header, content, path)


## Load all dialogs from a CSV file to a dictionary.
## Returns a dictionary with the dialog data as:
## { dialog_key: {
##     locale_1: dialog_text,
##     locale_2: dialog_text,
##     ...
##     }
## }
func load_dialogs_from_csv(path: String) -> Dictionary:
	var data := GDialogsCSVFileManager.load_file(path)
	if data.is_empty(): # If there is no data, an error occurred
		printerr("[Graph Dialogs] Cannot load dialogs from CSV file.")
		return {}
	var header = data[0]
	var dialogs := {}
	
	# Parse CSV data to a dictionary
	for row in data.slice(1, data.size() - 1):
		# Add a new dict for each dialog key
		var dialog_key = row[0]
		dialogs[dialog_key] = {}
		# Add each dialog in their respective locale
		for i in range(1, row.size()):
			dialogs[dialog_key][header[i]] = row[i]
	
	return dialogs


## Show the CSV file path container
func show_csv_container() -> void:
	if _current_file_index >= 0:
		_csv_file_field.get_parent().visible = true


## Hide the CSV file path container
func hide_csv_container() -> void:
	_csv_file_field.get_parent().visible = false
#endregion

#region === UI Handling ========================================================

func _on_save_file_pressed() -> void:
	save_file() # Save current file


func _on_open_file_pressed() -> void:
	# Open file dialog to select a file
	_open_file_dialog.popup_centered()


func _on_new_dialog_pressed() -> void:
	# Create new dialog file
	_new_dialog_file_dialog.popup_centered()


func _on_new_char_pressed() -> void:
	# Create new character file
	_new_char_file_dialog.popup_centered()


func _on_file_selected(index) -> void:
	# When a file is selected, switch to this file
	_switch_selected_file(index)


func _on_empty_clicked(at_pos: Vector2, mouse_button_index: int) -> void:
	# When the file list is right clicked, show file menu options
	if mouse_button_index == MOUSE_BUTTON_RIGHT and _file_list.item_count > 0:
		var pos := at_pos + _file_list.global_position + Vector2(get_window().position)
		_file_popup_menu.popup(Rect2(pos, _file_popup_menu.size))


func _on_item_clicked(_idx, at_pos: Vector2, mouse_button_index: int) -> void:
	# When a file is right clicked, show the file menu options
	_on_empty_clicked(at_pos, mouse_button_index)


func _on_file_menu_pressed(id: int) -> void:
	# Set the file menu options
	match id:
		0:
			save_file() # Save current file
		1:
			_save_file_dialog.popup_centered() # Save file as
		2:
			close_file() # Close current file
		3:
			close_all() # Close all files


func _on_confirm_closing_action(action) -> void:
	# Set the confirm closing dialog actions
	_confirm_close_dialog.hide()
	if _closing_queue.size() == 0:
		return
	
	match action:
		"save_file":
			for index in _closing_queue:
				save_file(index)
			close_all()
		"discard_file":
			for index in range(_file_list.item_count):
				close_file(index)
	_closing_queue.clear()


func _on_confirm_closing_canceled() -> void:
	_closing_queue.clear() # Clear closing queue


func _on_file_search_text_changed(new_text: String) -> void:
	_filter_file_list(new_text) # Filter file list by input filter text


func _on_file_search_focus_exited() -> void:
	# Disable the filtered list if it has no input filter and loses focus
	if _file_search.text.is_empty():
		_filtered_list.visible = false
		_file_list.visible = true
#endregion
