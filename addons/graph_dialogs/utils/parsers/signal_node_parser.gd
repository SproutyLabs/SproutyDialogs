class_name SignalNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a signal node
## -----------------------------------------------------------------------------

## Process a signal node
func process_node(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("Processing signal node...")
	continue_to_node.emit(node_data.to_node[0])
