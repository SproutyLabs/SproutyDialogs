@tool
extends VSplitContainer

enum FileType { DIALOG, CHAR }

@export var editor_main : Control
@export var workspace : SplitContainer

@onready var file_list : ItemList = %FileList
@onready var filtered_list : ItemList = %FilteredList
@onready var file_popup_menu : PopupMenu = $PopupWindows/FileMenu
@onready var new_dialog_panel : FileDialog = $PopupWindows/NewDialog
@onready var new_char_panel : FileDialog = $PopupWindows/NewChar
@onready var open_file_panel : FileDialog = $PopupWindows/OpenFile
@onready var save_file_panel : FileDialog = $PopupWindows/SaveFile
@onready var confirm_panel : AcceptDialog = $PopupWindows/ConfirmCloseFiles
@onready var csv_file_field : MarginContainer = $%CSVFileContainer/FileField

var graph_scene := preload("res://addons/graph_dialog_system/editor/graph.tscn")
var dialog_icon := preload("res://addons/graph_dialog_system/icons/Script.svg")
var char_icon := preload("res://addons/graph_dialog_system/icons/Character.svg")

var current_file_index : int = -1
var closing_queue : Array[int] = []

func _ready() -> void:
	open_file_panel.connect("file_selected", load_file)
	save_file_panel.connect("file_selected", save_file)
	new_dialog_panel.connect("file_selected", new_dialog_file)
	new_char_panel.connect("file_selected", new_character_file)
	
	confirm_panel.get_ok_button().hide()
	confirm_panel.add_button('Save', true, 'save_file')
	confirm_panel.add_button('Discard', true, 'discard_file')
	confirm_panel.add_cancel_button('Cancel')
	
	csv_file_field.connect("file_path_changed", set_dialog_csv_file)
	hide_csv_container()
	
	$"%SaveFile".disabled = true

#region --- New File ---
func new_file_item(file_name : String, path : String, type : FileType, data : Dictionary) -> void:
	# Add a new item on file display
	var item_index : int = file_list.item_count
	
	# Check if the file is already loaded
	for index in range(file_list.item_count):
		if file_list.get_item_metadata(index)["file_path"] == path:
			print("[Graph Dialogs] File '" + file_name + "' Already loaded.")
			return
	
	var metadata := {
		'file_name': file_name,
		'file_path': path,
		'file_type': type,
		'data': data,
		'modified': false
		}

	match type: # Add file item by type
		FileType.DIALOG:
			# Load graph on metadata
			var graph = graph_scene.instantiate()
			add_child(graph)
			graph.modified.connect(_on_data_modified)
			graph.load_nodes_data(data)
			graph.name = "Graph"
			remove_child(graph)
			metadata['graph'] = graph
			
			file_list.add_item(file_name, dialog_icon)
			file_list.set_item_metadata(item_index, metadata)
			
		FileType.CHAR:
			file_list.add_item(file_name, char_icon)
			file_list.set_item_metadata(item_index, metadata)
	
	switch_selected_file(item_index)
	$"%SaveFile".disabled = false

func new_dialog_file(path : String) -> void:
	# Create a new dialog file
	var file_name := path.split('/')[-1]
	var csv_path = GDialogsTranslationManager.new_csv_template_file(file_name)
	if csv_path.is_empty(): return
	
	$"%CSVFileContainer"/FileField.set_value(csv_path)
	show_csv_container()
	
	var data := {
		"dialog_data" : {
			"csv_file_path" : csv_path,
			"nodes_data" : {}
		}
	}
	GDialogsJSONFileManager.save_file(data, path)
	new_file_item(file_name, path, FileType.DIALOG, data)
	editor_main.switch_active_tab(0)
	workspace.show_graph_editor()
	
	print("[Graph Dialogs] Dialog file '" + file_name + "' created.")

func new_character_file(path : String) -> void:
	# Create a new character file
	var file_name : String = path.split('/')[-1]
	var data = {
		"character_data" : {
			"csv_file_path" : "",
			"key_name" : "",
			"description": "",
			"portraits": {}
		}
	}
	GDialogsJSONFileManager.save_file(data, path)
	new_file_item(file_name, path, FileType.CHAR, data)
	editor_main.switch_active_tab(1)
	
	print("[Graph Dialogs] Character file '" + file_name + "' created.")
#endregion

#region --- Save and Load ---
func load_file(path : String) -> void:
	# Load dialog data from JSON file
	if FileAccess.file_exists(path):
		var data = GDialogsJSONFileManager.load_file(path)
		var file_name : String = path.split('/')[-1]
		
		if data.has("dialog_data"): # Load a dialog
			new_file_item(file_name, path, FileType.DIALOG, data)
			editor_main.switch_active_tab(0)
			workspace.show_graph_editor()
		
		elif data.has("character_data"): # Load a character
			new_file_item(file_name, path, FileType.CHAR, data)
			editor_main.switch_active_tab(1)
			# TODO: Load character data
		else:
			printerr("[Graph Dialogs] File " + path + "has an invalid format.")
	else:
		printerr("[Graph Dialogs] File " + path + "does not exist.")

func save_file(index : int = current_file_index, path: String = "") -> void:
	# Save dialog data on JSON file
	var file_metadata = file_list.get_item_metadata(index)
	var data = file_metadata["data"]
	
	match file_metadata["file_type"]:
		FileType.DIALOG:
			data["dialog_data"]["nodes_data"] = file_metadata["graph"].get_nodes_data()
			file_metadata["data"] = data
		FileType.CHAR:
			pass # TODO: Update the character data
	
	var save_path = file_metadata["file_path"] if path.is_empty() else path
	GDialogsJSONFileManager.save_file(data, save_path)
	file_list.set_item_metadata(index, file_metadata)
	set_file_as_modified(index, false)
	print("[Graph Dialogs] Dialog file saved.")
#endregion

#region --- Close Files ---
func close_file(index : int = current_file_index) -> void:
	# Close an open file
	if file_list.item_count == 0: return
	
	index = wrapi(index, 0, file_list.item_count)
	var metadata := file_list.get_item_metadata(index)

	if metadata["modified"] and not index in closing_queue:
		# If the file to be closed is unsaved, alert user before close
		closing_queue.append(index)
		confirm_panel.popup_centered()
		return
	
	if index == current_file_index:
		# If the file to be closed is being edited
		csv_file_field.set_value("")
		
		if file_list.item_count == 1:
			# If there are no open files to switch to them
			current_file_index = -1
		elif index == 0:
			# If the file to close is the first one, switch to second one
			switch_selected_file(1)
			current_file_index = 0
		else: # If not the first file, switch to the previous file
			switch_selected_file(index - 1)
	
	if metadata["file_type"] == FileType.DIALOG:
		metadata["graph"].queue_free()
	
	if file_list.item_count == 1:
		workspace.show_start_panel()
		$"%SaveFile".disabled = true
	
	file_list.remove_item(index)

func close_all() -> void:
	# Close all open files
	closing_queue.clear()
	
	# Add unsaved files to queue to wait for closing confirmation
	for index in range(file_list.item_count):
		if file_list.get_item_metadata(index)["modified"]:
			closing_queue.append(index)
	
	if closing_queue.size() > 0: # Alert unsaved changes
		confirm_panel.popup_centered()
		return
	
	# Close all if none are modified
	current_file_index = -1
	for index in range(file_list.item_count):
		close_file(index)
#endregion

#region --- Work Files Handling ---
func switch_selected_file(file_index : int) -> void:
	# Switch current selected file
	if file_list.item_count == 0 or file_index > file_list.item_count:
		return
	var new_metadata := file_list.get_item_metadata(file_index)
	
	if current_file_index > -1: # Update metadata on current file
		var current_metadata := file_list.get_item_metadata(current_file_index)
		
		if current_metadata["file_type"] == FileType.DIALOG:
			current_metadata.data.dialog_data.nodes_data =\
					current_metadata["graph"].get_nodes_data()
		
		elif current_metadata["file_type"] == FileType.CHAR:
			pass # TODO: update character metadata
		
		file_list.set_item_metadata(current_file_index, current_metadata)
	
	# Switch view to the new file
	if new_metadata["file_type"] == FileType.DIALOG:
		# Switch current graph and change tab view
		workspace.switch_current_graph(new_metadata["graph"])
		csv_file_field.set_value(new_metadata["data"]["dialog_data"]["csv_file_path"])
		editor_main.switch_active_tab(0)
	
	elif new_metadata["file_type"] == FileType.CHAR:
		# TODO: update character data
		editor_main.switch_active_tab(1)
	current_file_index = file_index
	file_list.select(file_index)

func set_file_as_modified(index : int, value : bool) -> void:
	# Set a file as modified or unsaved
	if current_file_index == -1:
		return
	var suffix := '(*)' if value else ''
	var metadata := file_list.get_item_metadata(index)
	metadata["modified"] = value
	file_list.set_item_metadata(index, metadata)
	file_list.set_item_text(index, metadata["file_name"] + suffix)

func _on_data_modified() -> void:
	# When data is modified, set file as modified
	set_file_as_modified(current_file_index, true)

func filter_file_list(search_text : String)-> void:
	# Filter file list by a input filter text
	filtered_list.clear()
	
	for item in file_list.item_count:
		if file_list.get_item_text(item).contains(search_text):
			filtered_list.add_item(
				file_list.get_item_text(item), 
				file_list.get_item_icon(item)
			)
	file_list.visible = false
	filtered_list.visible = true
#endregion

#region --- CSV Files Handling ---
func new_csv_file(path : String) -> void:
	# Create a new csv file and associate to a dialog file
	var header = ["key"] # TODO: Set the header by locales
	var content = [""]
	
	GDialogsCSVFileManager.save_file(header, content, path)
	set_dialog_csv_file(path)

func set_dialog_csv_file(path : String) -> void:
	# Set csv file path to the current data file
	var metadata := file_list.get_item_metadata(current_file_index)
	metadata["data"]["dialog_data"]["csv_file_path"] = path
	file_list.set_item_metadata(current_file_index, metadata)
	csv_file_field.set_value(path)

func show_csv_container() -> void:
	if current_file_index >= 0:
		%CSVFileContainer.visible = true
	
func hide_csv_container() -> void:
	%CSVFileContainer.visible = false
#endregion

#region --- UI Handling ---
func _on_save_file_pressed() -> void:
	save_file() # Save current file

func _on_open_file_pressed() -> void:
	# Open a file to load
	open_file_panel.popup_centered()

func _on_new_dialog_pressed() -> void:
	# Create new dialog file
	new_dialog_panel.popup_centered()

func _on_new_char_pressed() -> void:
	# Create new character file
	new_char_panel.popup_centered()

func _on_file_selected(index) -> void:
	# When a file is selected, switch to this file
	switch_selected_file(index)

func _on_empty_clicked(at_pos : Vector2, mouse_button_index : int) -> void:
	# When the file list is right clicked, show file menu options
	if mouse_button_index == MOUSE_BUTTON_RIGHT and file_list.item_count > 0:
		var pos := at_pos + file_list.global_position + Vector2(get_window().position)
		file_popup_menu.popup(Rect2(pos, file_popup_menu.size))

func _on_item_clicked(_idx, at_pos : Vector2, mouse_button_index : int) -> void:
	# When a file is right clicked, show the file menu options
	_on_empty_clicked(at_pos, mouse_button_index)

func _on_file_menu_pressed(id : int) -> void:
	# Set the file menu options
	match id:
		0:
			save_file() # Save current file
		1:
			save_file_panel.popup_centered() # Save file as
		2:
			close_file() # Close current file
		3:
			close_all() # Close all files

func _on_confirm_closing_action(action) -> void:
	# Set the confirm closing dialog actions
	confirm_panel.hide()
	if closing_queue.size() == 0:
		return
	
	match action:
		"save_file":
			for index in closing_queue:
				save_file(index)
			close_all()
		"discard_file":
			for index in range(file_list.item_count):
				close_file(index)
	closing_queue.clear()

func _on_confirm_closing_canceled() -> void:
	closing_queue.clear()

func _on_file_search_text_changed(new_text : String) -> void:
	filter_file_list(new_text) # Filter file list by input filter text

func _on_file_search_focus_exited() -> void:
	# Disable the filtered list if it has no input filter and loses focus
	if %FileSearch.text.is_empty():
		filtered_list.visible = false
		file_list.visible = true
#endregion
