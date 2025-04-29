class_name WaitNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a wait node
## -----------------------------------------------------------------------------

## Process a wait node
func process_node(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("Processing wait node...")
	continue_to_node.emit(node_data.to_node[0])
