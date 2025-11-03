@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Comment Node
# -----------------------------------------------------------------------------
## Node to add comments to the graph.
# -----------------------------------------------------------------------------

## Text input box reference
@onready var _text_input: TextEdit = $TextInput
## Comment text
@onready var _comment_text: String = _text_input.text

## Flag to check if the comment was modified
var _comment_modified: bool = false


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
		"comment_text": _comment_text,
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	position_offset = dict["offset"]
	size = dict["size"]

	_comment_text = dict["comment_text"]
	_text_input.text = dict["comment_text"]

#endregion


func _on_text_input_changed() -> void:
	if _comment_text != _text_input.text:
		var temp = _comment_text
		_comment_text = _text_input.text
		_comment_modified = true
		
		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Comment", 1)
		undo_redo.add_do_property(self, "_comment_text", _comment_text)
		undo_redo.add_do_property(_text_input, "text", _comment_text)
		undo_redo.add_undo_property(self, "_comment_text", temp)
		undo_redo.add_undo_property(_text_input, "text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


func _on_text_input_focus_exited() -> void:
	if _comment_modified:
		_comment_modified = false
		modified.emit(true)