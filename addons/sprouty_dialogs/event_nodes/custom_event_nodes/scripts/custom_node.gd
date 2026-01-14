@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Custom Node
# -----------------------------------------------------------------------------
## Custom node example that print a text in console
# -----------------------------------------------------------------------------

## Text input box reference
@onready var _text_input: TextEdit = $TextInput
## Current print text
@onready var _print_text: String = _text_input.text

## Flag to check if the comment was modified (for undo redo)
var _text_modified: bool = false


func _ready():
	super () # Required to initialize the node

	# Connect text input signals
	_text_input.text_changed.connect(_on_text_input_changed)
	_text_input.focus_exited.connect(_on_text_input_focus_exited)


#region === Node Data ==========================================================

## Returns the node data.
## Called when the dialogue tree is saved.
## You need to set the required data to process your node!
func get_data() -> Dictionary:
	var dict := {}

	dict[name.to_snake_case()] = {
		# Required node data
		"node_type": node_type,
		"node_index": node_index,
		"offset": position_offset,
		"size": size,
		
		# Get the node output connections
		"to_node": get_output_connections(),

		# Custom node data (You need to set this by yourself!)
		"print_text": _print_text,
	}
	return dict


## Loads the node data.
## Called when the dialogue tree is loaded.
## You need to set the data into your node to recover it when is loaded!
func set_data(dict: Dictionary) -> void:
	# Load required node data
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	position_offset = dict["offset"]
	to_node = dict["to_node"]
	size = dict["size"]

	# Set print text in the input field
	_text_input.text = dict["print_text"]
	_print_text = dict["print_text"]

#endregion


## Handle when the text input change
func _on_text_input_changed() -> void:
	if _print_text != _text_input.text: # If the text has change, update it
		var temp = _print_text
		_print_text = _text_input.text
		_text_modified = true
		
		# --- UndoRedo (If you want to use it) --------------------------
		undo_redo.create_action("Edit Comment", 1)
		undo_redo.add_do_property(self, "_comment_text", _print_text)
		undo_redo.add_do_property(_text_input, "text", _print_text)
		undo_redo.add_undo_property(self, "_comment_text", temp)
		undo_redo.add_undo_property(_text_input, "text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


## Handle when the input is unfocus, to notify if the node was modified
func _on_text_input_focus_exited() -> void:
	if _text_modified:
		_text_modified = false
		modified.emit(true) # Notify that a node in the graph was modified