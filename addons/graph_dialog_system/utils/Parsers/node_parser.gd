class_name NodeParser
extends RefCounted

## -----------------------------------------------------------------------------
## Parser for process a generic node
##
## This class is used to process a generic node from a dialog tree.
## The node data is a dictionary with the node information.
## -----------------------------------------------------------------------------

## Signal emitted to continue to the next node in the dialog tree.
signal continue_to_node(to_node: String)

## Process a node from the dialog tree.
func process_node(node_data: Dictionary) -> void:
	# Abstract method to implement in the child class
	pass
