class_name ConditionNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a condition node
## -----------------------------------------------------------------------------

## Process a condition node
func process_node(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("Processing condition node...")
	continue_to_node.emit(node_data.to_node[0])
