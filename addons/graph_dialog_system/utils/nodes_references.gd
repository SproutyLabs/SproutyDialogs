class_name NodesReferences
extends RefCounted

static var nodes_scenes_path : Array[String] = [
	"res://addons/graph_dialog_system/nodes/start_node.tscn",
	"res://addons/graph_dialog_system/nodes/comment_node.tscn",
	"res://addons/graph_dialog_system/nodes/dialogue_node.tscn",
	"res://addons/graph_dialog_system/nodes/options_node.tscn",
	"res://addons/graph_dialog_system/nodes/condition_node.tscn",
	"res://addons/graph_dialog_system/nodes/set_variable_node.tscn",
	"res://addons/graph_dialog_system/nodes/signal_node.tscn",
	"res://addons/graph_dialog_system/nodes/wait_node.tscn",
]

static var nodes_parsers : Array[NodeParser] = [
	StartNodeParser.new(),
	null, # Comment node does nothing
	DialogueNodeParser.new(),
	OptionsNodeParser.new(),
	ConditionNodeParser.new(),
	SetVariableNodeParser.new(),
	SignalNodeParser.new(),
	WaitNodeParser.new()
]

static func get_nodes_count() -> int:
	return nodes_scenes_path.size()
