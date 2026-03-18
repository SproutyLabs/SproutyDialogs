@abstract
class_name SproutyDialogsTagProcessor


@abstract func get_tag_name() -> String


@abstract func is_block() -> bool


# Transforms an AST node into zero or more AST nodes for subsequent processing.
#
# Parameters:
#   node (SproutyDialogsDialogueParser.ASTNode): The AST node to transform.
#   variable_manager (SproutyDialogsVariableManager): Provides access to variable
#     resolution and state required during transformation.
#
# Returns:
#   Array[SproutyDialogsDialogueParser.ASTNode]: An array of AST nodes that will
#     replace or augment the original node in the processing pipeline. The default
#     implementation returns an array containing the original node unchanged.
func transform(node: SproutyDialogsDialogueParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsDialogueParser.ASTNode]:
	return [node]


# Generates runtime output or side-effects from the given AST node.
#
# This method is intended to produce runtime effects and may modify the
# provided `dict` in-place to return values or side-effects back to the
# caller. In other words, one of the primary uses of `dict` is as a mutable
# output/context container that the processor can update (for example: adding
# generated strings, status flags, or other metadata).
#
# Parameters:
#   node (SproutyDialogsDialogueParser.ASTNode): The AST node to generate from.
#   dict (Dictionary): A mutable dictionary passed by the caller that the
#     generator may read from and modify to communicate generated values,
#     outputs, or state changes. This parameter is intentionally mutable and
#     should be treated as an output/context bag as well as input.
#   variable_manager (SproutyDialogsVariableManager): Used to read/update
#     variables required while generating output.
#
# Returns:
#   void: This method performs side-effects (including in-place updates to
#     `dict`) and does not return a value. Concrete tag processors should
#     override this method to implement behavior that may alter `dict`.
func generate(node: SproutyDialogsDialogueParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	pass
