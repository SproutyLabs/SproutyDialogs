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

## Flag to check if the signal was modified
var _signal_modified: bool = false


func _ready():
	super ()
	# Connect text input signals
	_text_input.text_changed.connect(_on_text_input_changed)
	_text_input.focus_exited.connect(_on_text_input_focus_exited)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"signal_argument": _signal_argument,
		"to_node": get_output_connections(),
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


func _on_text_input_changed(new_text: String) -> void:
	if _signal_argument != new_text:
		var temp = _signal_argument
		_signal_argument = new_text
		_signal_modified = true

		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Signal", 1)
		undo_redo.add_do_property(self, "_signal_argument", _signal_argument)
		undo_redo.add_do_property(_text_input, "text", _signal_argument)
		undo_redo.add_undo_property(self, "_signal_argument", temp)
		undo_redo.add_undo_property(_text_input, "text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


func _on_text_input_focus_exited() -> void:
	if _signal_modified:
		_signal_modified = false
		modified.emit(true)