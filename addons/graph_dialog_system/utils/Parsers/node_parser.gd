class_name NodeParser
extends RefCounted

## ------------------------------------------------------------------
## Parser for process a generic node
## ------------------------------------------------------------------

signal continue_to_node(to_node : String)

func process_node(node_data: Dictionary) -> void:
	# Abstract method to processes a node
	pass
