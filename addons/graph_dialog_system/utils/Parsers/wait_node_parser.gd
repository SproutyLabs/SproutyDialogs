class_name WaitNodeParser
extends NodeParser

## ------------------------------------------------------------------
## Parser for process a wait node
## ------------------------------------------------------------------

func process_node(node_data: Dictionary) -> void:
	# Processes the dialogue node
	# TODO: Process the node
	continue_to_node.emit(node_data.to_node[0])
