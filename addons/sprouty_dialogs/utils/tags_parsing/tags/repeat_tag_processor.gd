class_name SproutyDialogsRepeatTagProcessor
extends SproutyDialogsTagProcessor

const MAX_TIMES: int = 10000

func get_tag_name() -> String:
	return "repeat"


func is_block() -> bool:
	return true


func transform(node: SproutyDialogsTagsParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsTagsParser.ASTNode]:
	var attrs: Dictionary = node.attributes
	var times: int = int(attrs.get("value", 0))
	var return_nodes: Array[SproutyDialogsTagsParser.ASTNode] = []
	if times > MAX_TIMES:
		times = MAX_TIMES
		push_warning("[Sprouty Dialogs] The content will be repeated only %d times." % MAX_TIMES
				+ " Highest values are not allowed to prevent the system from freezing.")
	for i in range(times):
		var children: Array[SproutyDialogsTagsParser.ASTNode] = []
		for child: SproutyDialogsTagsParser.ASTNode in node.children:
			child.parent = node.parent
			children.append(child)
		return_nodes += children
	node.free_self()
	return return_nodes