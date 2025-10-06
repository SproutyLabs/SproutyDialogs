@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Signal Node
# -----------------------------------------------------------------------------
## Node to emit a signal between dialog nodes.
# -----------------------------------------------------------------------------

## Signal argument text input
@onready var _text_input: LineEdit = $Input
## Signal argument value
@onready var _signal_argument: String = _text_input.text


func _ready():
	super ()

#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"signal_argument": _signal_argument,
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

	_signal_argument = dict["signal_argument"]
	_text_input.text = dict["signal_argument"]

#endregion

func _on_input_text_changed(new_text: String) -> void:
	if _signal_argument != new_text:
		_signal_argument = new_text
		modified.emit(true)
