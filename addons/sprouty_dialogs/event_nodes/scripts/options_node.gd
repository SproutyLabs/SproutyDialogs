@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Options Node
# -----------------------------------------------------------------------------
## Node to display dialog options in the dialog tree.
# -----------------------------------------------------------------------------

## Emitted when press the expand button in a text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when a text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)

## Option container template
@onready var _option_scene := preload("res://addons/sprouty_dialogs/editor/components/option_container.tscn")

## First option container
var _first_option: EditorSproutyDialogsOptionContainer

## List of options keys
var _options_keys: Array = []


func _ready():
	super ()
	$AddOptionButton.icon = get_theme_icon("Add", "EditorIcons")
	if not get_child(0) is EditorSproutyDialogsOptionContainer:
		_first_option = _add_new_option() # Add the first option
	else:
		_first_option = get_child(0)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)

	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"options_keys": [],
		"to_node": get_output_connections(),
		"offset": position_offset,
		"size": size
	}
	var data = dict[name.to_snake_case()]
	
	for child in get_children():
		if child is EditorSproutyDialogsOptionContainer:
			data["options_keys"].insert(child.option_index, child.get_dialog_key())
	
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	_options_keys = dict["options_keys"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]
#endregion


## Returns options text and its translations
func get_options_text() -> Array:
	var options_text = []
	for child in get_children():
		if child is EditorSproutyDialogsOptionContainer:
			options_text.append({
				child.get_dialog_key(): child.get_dialogs_text()
			})
	return options_text


## Load options text and translations
func load_options_text(dialogs: Dictionary) -> void:
	for option in _options_keys.size():
		if option == 0: # Load the first option
			_first_option.load_dialogs(dialogs[_options_keys[option]])
		else:
			var new_option = _add_new_option()
			new_option.load_dialogs(dialogs[_options_keys[option]])


## Update the locale text boxes
func on_locales_changed() -> void:
	for child in get_children():
		if child is EditorSproutyDialogsOptionContainer:
			child.on_locales_changed()


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	for child in get_children():
		if child is EditorSproutyDialogsOptionContainer:
			child.on_translation_enabled_changed(enabled)


## Create a new option
func _new_option() -> EditorSproutyDialogsOptionContainer:
	var new_option = _option_scene.instantiate()
	new_option.undo_redo = undo_redo
	new_option.open_text_editor.connect(open_text_editor.emit)
	new_option.update_text_editor.connect(update_text_editor.emit)
	new_option.option_removed.connect(_on_option_removed)
	new_option.modified.connect(modified.emit)
	new_option.resized.connect(func():
		position_offset.y += 0.01
		_on_resized()
		)
	return new_option


## Add a new option
func _add_new_option() -> EditorSproutyDialogsOptionContainer:
	var new_option = _new_option()
	var option_index = get_child_count() - 1
	
	add_child(new_option, true)
	move_child(new_option, option_index)
	new_option.update_option_index(option_index)
	
	# Add slot to connect the option
	set_slot(option_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	return new_option


## Add an option at a given index
func _add_option(index: int, new_option: EditorSproutyDialogsOptionContainer) -> void:
	add_child(new_option, true)
	move_child(new_option, index)
	new_option.update_option_index(index)

	# Add a new slot
	set_slot(get_child_count() - 2, false, 0, Color.WHITE, true, 0, Color.WHITE)

	# Update the following options to the new one, by moving them downwards
	var options = get_children().filter(func(c): return c is EditorSproutyDialogsOptionContainer)
	options.reverse()
	for option in options:
		if option.get_index() > index:
			option.update_option_index(option.get_index())
			# Get the connections on previous port and move them to current port
			var prev_connections = get_parent().get_node_output_connections(name, option.get_index() - 1)
			get_parent().disconnect_node_on_port(name, option.get_index() - 1) # Remove old connections
			for connection in prev_connections: # Update to new connections
				get_parent().connect_node(name, option.get_index(),
					connection["to_node"], connection["to_port"])

	_on_resized() # Resize container vertically


## Remove an option at a given index
func _remove_option(index: int) -> void:
	for child in get_children():
		# Update the following options to the removed one, by moving them upwards
		if child is EditorSproutyDialogsOptionContainer and child.get_index() >= index:
			child.update_option_index(child.get_index() - 1)
			# Get the connections on next port and move them to current port
			var next_connections = get_parent().get_node_output_connections(name, child.get_index() + 1)
			get_parent().disconnect_node_on_port(name, child.get_index()) # Remove old connections
			for connection in next_connections: # Update to new connections
				get_parent().connect_node(name, child.get_index(),
					connection["to_node"], connection["to_port"])
	
	remove_child(get_child(index))

	# Remove the last remaining port
	set_slot(get_child_count() - 1, false, 0, Color.WHITE, false, 0, Color.WHITE)
	_on_resized() # Resize container vertically


## Handle when the add option button is pressed
func _on_add_option_button_pressed() -> void:
	_add_new_option()
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Add Option")
	undo_redo.add_do_method(self, "_add_new_option")
	undo_redo.add_undo_method(self, "_remove_option", get_child_count() - 2)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle when an option is removed
func _on_option_removed(index: int) -> void:
	var temp_connections = get_parent().get_node_output_connections(name, index)
	var temp_node = get_child(index)
	_remove_option(index)
	modified.emit(true)
	
	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Remove Option")
	undo_redo.add_do_method(self, "_remove_option", index)
	undo_redo.add_undo_method(self, "_add_option", index, temp_node)
	if temp_connections.size() > 0: # Restore connections if there were any
		undo_redo.add_undo_method(get_parent(), "connect_node", name, index,
				temp_connections[0]["to_node"], temp_connections[0]["to_port"])
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------