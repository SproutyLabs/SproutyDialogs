class_name SproutyDialogsRepeatTagProcessor
extends SproutyDialogsTagProcessor


func get_tag_name() -> String:
	return "repeat"


func is_block() -> bool:
	return true


func transform(node: SproutyDialogsTagsParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsTagsParser.ASTNode]:
	var attrs: Dictionary = node.attributes
	var times: int = int(attrs.get("value", 0))
	var return_nodes: Array[SproutyDialogsTagsParser.ASTNode] = []
	for i in range(times):
		var children: Array[SproutyDialogsTagsParser.ASTNode] = []
		for child: SproutyDialogsTagsParser.ASTNode in node.children:
			child.parent = node.parent
			children.append(child)
		return_nodes += children
	node.free_self()
	return return_nodes