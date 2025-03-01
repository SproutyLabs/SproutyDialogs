class_name SetVariableNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a set variable node
## -----------------------------------------------------------------------------

## Process a set variable node
func process_node(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("Processing set variable node...")
	continue_to_node.emit(node_data.to_node[0])
