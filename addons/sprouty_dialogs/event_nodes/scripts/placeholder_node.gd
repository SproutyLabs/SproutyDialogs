@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Placeholder Node
# -----------------------------------------------------------------------------
## Node that replace a custom node not found in the graph.
# -----------------------------------------------------------------------------

## Original node data
var _node_data: Dictionary = {}

#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}

	# Update the position and connections
	_node_data["offset"] = position_offset
	_node_data["to_node"] = get_output_connections()

	dict[name.to_snake_case()] = _node_data
	return dict # Return the updated node data


func set_data(dict: Dictionary) -> void:
	# Keep the original node data
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	position_offset = dict["offset"]
	to_node = dict["to_node"]
	size = dict["size"]
	_node_data = dict

	# Set the original node slots to keep connections
	_set_node_slots(_node_data["to_node"])

#endregion

## Set as many slots as the original node has to keep the same connections
func _set_node_slots(connections: Array) -> void:
	if connections.size() <= 1:
		return
	
	for index in range(1, connections.size()):
		var slot_holder = Control.new()
		slot_holder.size.y = 25
		add_child(slot_holder)
		set_slot_enabled_right(index, true)


## Ignore vertical resize restriction
func _on_resized() -> void:
	pass