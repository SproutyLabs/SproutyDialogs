extends SproutyDialogsEventInterpreter

# -----------------------------------------------------------------------------
# Sprouty Dialogs Custom Event Interpreter
# -----------------------------------------------------------------------------
## Node that process custom event nodes of the Sprouty Dialogs plugin.
##
## You must add a 'process' method to each custom node to do something with it.
## Each method must be added to the [node_processors] dictionary with the node
## name as the key to access the method.
##
## In this way, DialogPlayer will call this method when the node is found in the 
## dialog tree to process the node's action.
##
## At the end of the process method, you must emit the 'continue_to_node' signal
## with the next node to process as parameter, to notify the DialogPlayer to
## continue processing the dialogue tree.
##
## If you need to access the dialog box or other resources, you can do so from 
## DialogPlayer using get_parent(), since this node will be its child.
# -----------------------------------------------------------------------------

func _init():
	# Add the process method to the processors with the node name 
	node_processors["custom_node"] = _process_custom_node


## Process the node data to do something
func _process_custom_node(node_data: Dictionary) -> void:
	# Print a debug message
	if print_debug: print("[Sprouty Dialogs] Processing custom node...")

	# Do something
	print_rich("[color=tomato][b]Custom Node Print:[/b][/color] " + node_data.print_text)

	# Call to continue to the next node
	continue_to_node.emit(node_data.to_node[0])