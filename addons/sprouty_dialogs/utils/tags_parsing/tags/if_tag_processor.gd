class_name SproutyDialogsIfTagProcessor
extends SproutyDialogsTagProcessor

# -----------------------------------------------------------------------------
# Sprouty Dialogs If Tag Processor
# -----------------------------------------------------------------------------
## Defines how to process an if condition tag in the dialogue.
##
## This tag allows to shows or hides its content based on a variable comparison.
##
## Attributes:
##   - var: The name of the variable to compare.
##   - op: The operator to compare (eq, ne, gt, lt, ge, le).
##   - val: the value against which the variable will be compared.
##
## Example: [if var="score" op="gt" val="10"]You win![/if]
# -----------------------------------------------------------------------------


func get_tag_name() -> String:
	return "if"


func is_block() -> bool:
	return true


func transform(node: SproutyDialogsTagsParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsTagsParser.ASTNode]:
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
	var parent_node: SproutyDialogsTagsParser.ASTNode = node.parent
	if parent_node == null:
		result = false
	if result:
		var children: Array[SproutyDialogsTagsParser.ASTNode] = node.children
		node.free_self()
		return children
	node.free_tree()
	return []
