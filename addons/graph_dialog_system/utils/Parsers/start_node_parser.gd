class_name StartNodeParser
extends NodeParser

## ------------------------------------------------------------------
## Parser for process a start node
## ------------------------------------------------------------------

func process_node(node_data: Dictionary) -> void:
	# Processes the dialogue node
	continue_to_node.emit(node_data.to_node[0])
