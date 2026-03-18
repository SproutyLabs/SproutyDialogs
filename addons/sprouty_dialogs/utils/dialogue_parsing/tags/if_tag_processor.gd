class_name SproutyDialogsIfTagProcessor
extends SproutyDialogsTagProcessor


func get_tag_name() -> String:
	return "if"


func is_block() -> bool:
	return true


func transform(node: SproutyDialogsDialogueParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsDialogueParser.ASTNode]:
	var result: bool = false
	var attrs: Dictionary = node.attributes
	var variable_data: Dictionary = variable_manager.get_variable_data(attrs["var"])
	var value: Variant = null
	var operator: String = attrs["op"]
	var comparison_result: bool = false
	if variable_data != {}:
		match variable_data["type"]:
			TYPE_BOOL: value = attrs["val"] == "true"
			TYPE_INT: value = int(attrs["val"])
			TYPE_FLOAT: value = float(attrs["val"])
			TYPE_STRING: value = attrs["val"]
			_: value = null
		match operator:
			"eq": comparison_result = variable_data["value"] == value
			"ne": comparison_result = variable_data["value"] != value
			"lt": comparison_result = variable_data["value"] < value
			"gt": comparison_result = variable_data["value"] > value
			"le": comparison_result = variable_data["value"] <= value
			"ge": comparison_result = variable_data["value"] >= value
			_: comparison_result = false
		result = comparison_result
	var parent_node: SproutyDialogsDialogueParser.ASTNode = node.parent
	if parent_node == null:
		result = false
	if result:
		var children: Array[SproutyDialogsDialogueParser.ASTNode] = node.children
		node.free_self()
		return children
	node.free_tree()
	return []
