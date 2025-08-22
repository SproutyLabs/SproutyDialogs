@tool
class_name WaitNode
extends BaseNode

# -----------------------------------------------------------------------------
## Wait Node
##
## Node to add a wait time to the dialog.
# -----------------------------------------------------------------------------

## Time input spin box
@onready var time_input: SpinBox = $Container/SpinBox
## Wait time value
@onready var time_value: float = time_input.value


func _ready():
	super ()

#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"time": time_value,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]

	time_value = dict["time"]
	time_input.value = dict["time"]

#endregion

func _on_time_value_changed(value: float) -> void:
	time_value = value
	graph_editor.on_modified()
