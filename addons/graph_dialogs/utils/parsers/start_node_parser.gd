class_name StartNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a start node
## -----------------------------------------------------------------------------

## Process the next node from the start node on the dialog tree
func process_node(node_data: Dictionary) -> void:
	# Processes the next node connected to the start node
	continue_to_node.emit(node_data.to_node[0])
