@tool
class_name NodesReferences
extends RefCounted

## ------------------------------------------------------------------
## References to every dialog node
##
## This script is used to store the references to every dialog node
## scene and its parser. It is used to create the dialog nodes in the
## graph editor and for process them later.
## ------------------------------------------------------------------

## Path to the nodes scenes.
const NODES_PATH = "res://addons/graph_dialog_system/nodes/"

## Dictionary to store the nodes references.
static var nodes: Dictionary = {
	"start_node": {
		"scene": preload(NODES_PATH + "start_node.tscn"),
		"parser": StartNodeParser.new()
	},
	"comment_node": {
		"scene": preload(NODES_PATH + "comment_node.tscn"),
		"parser": null
	},
	"dialogue_node": {
		"scene": preload(NODES_PATH + "dialogue_node.tscn"),
		"parser": DialogueNodeParser.new()
	},
	"options_node": {
		"scene": preload(NODES_PATH + "options_node.tscn"),
		"parser": OptionsNodeParser.new()
	},
	"condition_node": {
		"scene": preload(NODES_PATH + "condition_node.tscn"),
		"parser": ConditionNodeParser.new()
	},
	"set_variable_node": {
		"scene": preload(NODES_PATH + "set_variable_node.tscn"),
		"parser": SetVariableNodeParser.new()
	},
	"signal_node": {
		"scene": preload(NODES_PATH + "signal_node.tscn"),
		"parser": SignalNodeParser.new()
	},
	"wait_node": {
		"scene": preload(NODES_PATH + "wait_node.tscn"),
		"parser": WaitNodeParser.new()
	},
	
	# [!] ADD NEW NODES HERE TO USE THEM [!]
}
