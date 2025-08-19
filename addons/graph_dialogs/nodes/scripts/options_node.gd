@tool
class_name OptionsNode
extends BaseNode

## -----------------------------------------------------------------------------
## Options Node
##
## Node to display dialog options in the dialog tree.
## -----------------------------------------------------------------------------

## Option container template
@onready var _option_scene := preload("res://addons/graph_dialogs/editor/components/option_container.tscn")
@onready var _first_option: GraphDialogsOptionContainer = $OptionContainer

var _options_keys: Array = [] ## List of options keys

func _ready():
	super ()
	$AddOptionButton.icon = get_theme_icon("Add", "EditorIcons")
	if _first_option: # Connect signals for the first option container
		_first_option.open_text_editor.connect(get_parent().open_text_editor.emit)
		_first_option.option_removed.connect(_on_option_removed)


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)

	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"options_keys": [],
		"to_node": [],
		"offset": position_offset,
		"size": size
	}
	var data = dict[name.to_snake_case()]
	
	for child in get_children():
		if child is GraphDialogsOptionContainer:
			data["options_keys"].insert(child.option_index, child.get_dialog_key())
			data["to_node"].append("END") # Connections default to END
	
	for connection in connections: # Set the connections to each option
		data["to_node"].set(connection["from_port"], connection["to_node"].to_snake_case())
	
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	_options_keys = dict["options_keys"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]
#endregion


## Get options text and its translations
func get_options_text() -> Array:
	var options_text = []
	for child in get_children():
		if child is GraphDialogsOptionContainer:
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
		if child is GraphDialogsOptionContainer:
			child.on_locales_changed()


## Handle the translation enabled setting change
func on_translation_enabled_changed(enabled: bool) -> void:
	for child in get_children():
		if child is GraphDialogsOptionContainer:
			child.on_translation_enabled_changed(enabled)


## Add a new option
func _add_new_option() -> GraphDialogsOptionContainer:
	var new_option = _option_scene.instantiate()
	var option_index = get_child_count() - 2
	
	add_child(new_option, true)
	move_child(new_option, option_index)
	new_option.update_option_index(option_index)
	
	# Add slot to connect the option
	set_slot(option_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	new_option.open_text_editor.connect(get_parent().open_text_editor.emit)
	new_option.option_removed.connect(_on_option_removed)
	new_option.resized.connect(_on_resized)
	return new_option


func _on_add_option_button_pressed() -> void:
	_add_new_option()


## Handle options when one is removed
func _on_option_removed(index: int) -> void:
	get_child(index).queue_free() # Delete option
	
	# Update the following options to the removed one, by moving them upwards
	for child in get_children(false):
		if child is VBoxContainer and child.get_index() >= index:
			# Update the option index
			child.update_option_index(child.get_index() - 1)
			# Get the connections on next port and move them to current port
			var next_connections = get_parent().get_node_output_connections(name, child.get_index() + 1)
			get_parent().disconnect_node_on_port(name, child.get_index()) # Remove old connections
			for connection in next_connections: # Update to new connections
				get_parent().connect_node(name, child.get_index(),
					connection["to_node"], connection["to_port"])
	
	# Remove the last remaining port
	set_slot(get_child_count() - 3, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Wait to delete the option node
	await get_child(index).tree_exited
	_on_resized() # Resize container vertically
