class_name OptionsNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a options node
## -----------------------------------------------------------------------------

## Process a options node
func process_node(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("Processing options node...")
	continue_to_node.emit(node_data.to_node[0])
