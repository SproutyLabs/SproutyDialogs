@tool
extends BaseNode

const NODE_TYPE_ID : int = 3

@onready var option_scene : PackedScene = preload("res://addons/graph_dialog_system/nodes/components/option_container.tscn")

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : NODE_TYPE_ID,
		"options" : {},
		"to_node" : [] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	for child in get_children():
		if child is OptionContainer:
			dict[name.to_snake_case()]["options"][child.name.to_snake_case()] = {
				"id" : child.option_index,
				"dialog_key" : child.dialog_key
			}
			if dict["to_node"][0] != "END" and connections.size() >= child.option_index:
				dict[name.to_snake_case()]["to_node"].append(connections[child.option_index]["to_node"])
	
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	to_node = [dict["to_node"]]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]


func _on_add_option_button_pressed() -> void:
	# Add a new option to the choices
	var new_option = option_scene.instantiate()
	var option_index = get_child_count() - 2
	
	add_child(new_option, true)
	move_child(new_option, option_index)
	new_option.update_option_index(option_index)
	
	# Add slot to connect the option
	set_slot(option_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	new_option.option_removed.connect(_on_option_removed)
	new_option.connect("resized", _on_resized)

func _on_option_removed(index : int) -> void:
	# Handle options when one is removed
	get_child(index).queue_free() # Delete option
	print("Removed option: "+ str(index))
	
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
