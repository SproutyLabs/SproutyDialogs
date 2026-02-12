@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# File List Manager
# -----------------------------------------------------------------------------
## This script manages the file list in the Sprouty Dialogs editor.
## It handles the open files in the editor, allows users to open new files,
## close files, and switch between them. It also provides a search functionality.
# -----------------------------------------------------------------------------

## Emitted when a file is selected from the file list.
signal file_selected(metadata: Dictionary)
## Emitted when a file is closed.
signal file_closed(metadata: Dictionary)
## Emitted when requesting to save a file.
signal request_save_file(index: int)
## Emitted when requesting to save a file as.
signal request_save_file_as()

## File search input
@onready var _file_search: LineEdit = $FileSearch
## File list on side bar
@onready var _file_list: ItemList = $FileItemList
## Filtered file list
@onready var _filtered_list: ItemList = $FilteredList
## File pop-up menu
@onready var _file_popup_menu: PopupMenu = %FileMenu
## Confirm close files dialog
@onready var _confirm_close_dialog: AcceptDialog = %ConfirmCloseFiles

## Dialog icon
@onready var _dialog_icon := get_theme_icon('Script', 'EditorIcons')
## Character icon
var _char_icon := preload("res://addons/sprouty_dialogs/editor/icons/character.svg")

## Current file index
var _current_file_index: int = -1
## Files to close queue
var _closing_queue: Array[int] = []

## Number of dialogs in the file list
var _dialogs_count: int = 0
## Number of characters in the file list
var _characters_count: int = 0

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	# Connect signals
	_file_search.text_changed.connect(_on_file_search_text_changed)
	_file_list.item_selected.connect(_on_file_selected)
	_file_list.item_clicked.connect(_on_item_clicked)
	_file_list.empty_clicked.connect(_on_empty_clicked)

	_filtered_list.item_selected.connect(_on_file_selected)
	_filtered_list.item_clicked.connect(_on_item_clicked)
	_filtered_list.empty_clicked.connect(_on_empty_clicked)

	_file_popup_menu.id_pressed.connect(_on_file_menu_pressed)
	_confirm_close_dialog.custom_action.connect(_on_confirm_closing_action)
	_confirm_close_dialog.canceled.connect(_on_confirm_closing_canceled)
	
	# Set icons for buttons
	_file_popup_menu.set_item_icon(0, get_theme_icon("Save", "EditorIcons"))
	_file_popup_menu.set_item_icon(1, get_theme_icon("Save", "EditorIcons"))
	_file_popup_menu.set_item_icon(3, get_theme_icon("Close", "EditorIcons"))
	_file_popup_menu.set_item_icon(4, get_theme_icon("Close", "EditorIcons"))
	_file_search.right_icon = get_theme_icon("Search", "EditorIcons")

	# Set confirm closing dialog actions
	_confirm_close_dialog.get_ok_button().hide()
	_confirm_close_dialog.add_button('Save', true, 'save_file')
	_confirm_close_dialog.add_button('Discard', true, 'discard_file')
	_confirm_close_dialog.add_cancel_button('Cancel')


## Returns the current file index
func get_current_index() -> int:
	return _current_file_index


## Set the current file index selected in the file list
func set_current_index(index: int) -> void:
	if index < 0 or index >= _file_list.item_count:
		return # Invalid index, do nothing
	_current_file_index = index
	_file_list.select(index)


## Returns the file list item count
func get_item_count() -> int:
	return _file_list.item_count


## Returns the dialogs count in the file list
func get_dialogs_count() -> int:
	return _dialogs_count


## Returns the characters count in the file list
func get_characters_count() -> int:
	return _characters_count


## Returns the metadata from a file item at the given index
func get_item_metadata(index: int) -> Dictionary:
	if index < 0 or index >= _file_list.item_count:
		printerr("[Sprouty Dialogs] Invalid file index to get metadata.")
		return {}
	return _file_list.get_item_metadata(index)


## Returns the metadata from a file item at the given index
func set_item_metadata(index: int, metadata: Dictionary) -> void:
	if index < 0 or index >= _file_list.item_count:
		printerr("[Sprouty Dialogs] Invalid file index to set metadata.")
		return
	_file_list.set_item_metadata(index, metadata)


## Set metadata for a resource in the file list
func set_resource_metadata(index: int, property: String, value: Variant) -> void:
	if index < 0 or index >= _file_list.item_count:
		printerr("[Sprouty Dialogs] Invalid file index to set metadata.")
		return
	var metadata := _file_list.get_item_metadata(index)
	metadata.data.set(property, value)
	_file_list.set_item_metadata(index, metadata)


## Check if the file is already loaded
func is_file_loaded(path: String) -> bool:
	for index in range(_file_list.item_count):
		if _file_list.get_item_metadata(index)["file_path"] == path:
			return true
	return false


## Create a new file item on the file list
func new_file_item(path: String, data: Resource, cache_node: Node, csv_file: String = "") -> void:
	var file_name := path.get_file()
	var item_index: int = _file_list.item_count

	# Check if the file is already loaded
	if is_file_loaded(path):
		return

	# Create new metadata for the file
	var metadata := {
		"file_name": file_name,
		"file_path": path,
		"csv_file": csv_file,
		"data": data,
		"cache_node": cache_node,
		"modified": false
		}
	cache_node.set_meta("file_index", item_index)

	if data is SproutyDialogsDialogueData:
		_file_list.add_item(file_name, _dialog_icon)
		_dialogs_count += 1
	elif data is SproutyDialogsCharacterData:
		_file_list.add_item(file_name, _char_icon)
		_characters_count += 1
	else:
		printerr("[Sprouty Dialogs] File " + file_name + " has an invalid format.")
		return
	
	_file_list.set_item_metadata(item_index, metadata)
	_on_file_selected(item_index)


## Close an open file
func close_file(index: int = _current_file_index) -> void:
	if _file_list.item_count == 0: return
	
	index = wrapi(index, 0, _file_list.item_count)
	var metadata := _file_list.get_item_metadata(index)

	# If the file to be closed is unsaved, alert user before close
	if metadata["modified"] and not index in _closing_queue:
		_closing_queue.append(index)
		_confirm_close_dialog.popup_centered()
		return

	# If the file to be closed is being edited
	if index == _current_file_index:
		# If there are no open files to switch to them
		if _file_list.item_count == 1:
			_current_file_index = -1
		# If the file to close is the first one, switch to second one
		elif index == 0:
			_switch_to_file(1)
			_current_file_index = 0
		else: # If not the first file, switch to the previous file
			_switch_to_file(index - 1)
	
	# Free the cached graph or character panel
	metadata["cache_node"].queue_free()
	_dialogs_count -= 1 if metadata.data is SproutyDialogsDialogueData else 0
	_characters_count -= 1 if metadata.data is SproutyDialogsCharacterData else 0
	
	_file_list.remove_item(index)
	file_closed.emit(metadata)


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
	for index in range(_file_list.item_count):
		close_file(index)
	_current_file_index = -1


## Set a file as modified or unsaved
func set_file_as_modified(index: int, value: bool) -> void:
	if _current_file_index == -1:
		return
	var suffix := '(*)' if value else ''
	var metadata := _file_list.get_item_metadata(index)
	metadata["modified"] = value
	_file_list.set_item_metadata(index, metadata)
	_file_list.set_item_text(index, metadata["file_name"] + suffix)


## Filter file list by a input filter text
func _filter_file_list(search_text: String) -> void:
	_filtered_list.clear()
	
	for item in _file_list.item_count:
		if _file_list.get_item_text(item).contains(search_text):
			_filtered_list.add_item(
				_file_list.get_item_text(item),
				_file_list.get_item_icon(item)
			)
	_file_list.hide()
	_filtered_list.show()


## Update metadata for a file in the file list
func _update_file_metadata(index: int) -> void:
	if index < 0 or index >= _file_list.item_count:
		return # Invalid index, do nothing
	
	var metadata := _file_list.get_item_metadata(index)
	
	if metadata.data is SproutyDialogsDialogueData:
		var graph_editor_data = metadata["cache_node"].get_graph_data()
		metadata.data.graph_data = graph_editor_data["nodes_data"]
		metadata.data.dialogs = graph_editor_data["dialogs"]
		metadata.data.characters = graph_editor_data["characters"]
	
	elif metadata.data is SproutyDialogsCharacterData:
		metadata.data = metadata["cache_node"].get_character_data()
	
	_file_list.set_item_metadata(index, metadata)
	return


## Switch to the given file in the file list
func _switch_to_file(index: int) -> void:
	if index < 0 or index >= _file_list.item_count:
		return # Invalid index, do nothing
	_update_file_metadata(_current_file_index)
	set_current_index(index)
	file_selected.emit(_file_list.get_item_metadata(index))


## Handle file selection from the file list
func _on_file_selected(index: int) -> void:
	var temp = _current_file_index
	_switch_to_file(index)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Select File: " + str(_file_list.get_item_text(index)))
	undo_redo.add_do_method(self, "_switch_to_file", index)
	undo_redo.add_undo_method(self, "_switch_to_file", temp)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## When the file list is right clicked, show file menu options
func _on_empty_clicked(at_pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT and _file_list.item_count > 0:
		var pos := at_pos + _file_list.global_position + Vector2(get_window().position)
		_file_popup_menu.popup(Rect2(pos, _file_popup_menu.size))


## When a file is right clicked, show the file menu options
func _on_item_clicked(_idx, at_pos: Vector2, mouse_button_index: int) -> void:
	_on_empty_clicked(at_pos, mouse_button_index)


## Set the file menu options
func _on_file_menu_pressed(id: int) -> void:
	match id:
		0:
			request_save_file.emit(get_current_index()) # Save current file
		1:
			request_save_file_as.emit() # Save file as
		2:
			close_file() # Close current file
		3:
			close_all() # Close all files


## Set the confirm closing dialog actions
func _on_confirm_closing_action(action) -> void:
	_confirm_close_dialog.hide()
	if _closing_queue.size() == 0:
		return
	
	match action:
		"save_file":
			for index in _closing_queue:
				request_save_file.emit(index)
			close_all()
		"discard_file":
			for index in range(_file_list.item_count):
				close_file(index)
			_current_file_index = -1
	_closing_queue.clear()


## Cancel the closing confirmation dialog
func _on_confirm_closing_canceled() -> void:
	_closing_queue.clear()


## Filter the file list by the input search text
func _on_file_search_text_changed(new_text: String) -> void:
	if new_text == "":
		_file_list.show()
		_filtered_list.hide()
	else:
		_filter_file_list(new_text)


## Disable the filtered list if it has no input filter and loses focus
func _on_file_search_focus_exited() -> void:
	if _file_search.text.is_empty():
		_filtered_list.hide()
		_file_list.show()