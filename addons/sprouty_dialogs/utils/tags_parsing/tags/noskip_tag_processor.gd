class_name SproutyDialogsNoSkipTagProcessor
extends SproutyDialogsTagProcessor

# -----------------------------------------------------------------------------
# Sprouty Dialogs No-Skip Tag Processor
# -----------------------------------------------------------------------------
## Defines how to process an noskip tag in the dialogue.
##
## Disable the text reveal skip feature, which allows the player to skip 
## the text reveal animation and instantly display the full text.
##
## Attributes:
##   This tag only has the disable attribute, which can be `true` or `false`.
##   You can use the tag without any attributes, in which case it will be `true` by default.
##
## (It's an inline tag, you can use it to disable/enable text reveal skipping
## across different dialogue node events)
##
## Example:
##    Pay attention to each word! [noskip] 
##    This is the secret of the universe (...) 
##    [noskip=false] Now you can skip the text reveal animation.
# -----------------------------------------------------------------------------


func get_tag_name() -> String:
	return "noskip"


func is_block() -> bool:
	return false


func generate(node: SproutyDialogsTagsParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	var attrs_value: String = str(node.attributes.get("value", "true"))
	var enabled_value: bool = true
	if attrs_value == "false":
		enabled_value = false
	dict["noskip"] = enabled_value
