class_name SproutyDialogsAutoTagProcessor
extends SproutyDialogsTagProcessor

# -----------------------------------------------------------------------------
# Sprouty Dialogs Auto Tag Processor
# -----------------------------------------------------------------------------
## Defines how to process an auto tag in the dialogue.
##
## Enable/Disable the auto-advance feature, which automatically advances the 
## dialogue after a specified time (in seconds), without requiring user input. 
##
## By default, the auto-advance time is taken from the "Default advance delay" 
## setting from the Sprouty Dialogs settings, but you can override it.
##
## Attributes:
##   - value (bool): [auto=true] or [auto=false]
##       Enable or disable the auto-advance feature. 
##       Note: If no value is provided, it will be enabled by default.
##   - delay (float): [auto delay=0.5] 
##      Specify a custom time in seconds for the auto-advance delay.
##
## (It's an inline tag)
##
## Example:
##	  Hello...[auto delay=0.5] how are you?
##    I'm fine, thanks! [auto=false] Let's continue the conversation.
# -----------------------------------------------------------------------------


func get_tag_name() -> String:
	return "auto"


func is_block() -> bool:
	return false


func generate(node: SproutyDialogsTagsParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	var attrs: Dictionary = node.attributes
	var attrs_value: String = str(attrs.get("value", "true"))
	var attrs_delay: String = str(attrs.get("delay", null))
	var enabled_value: bool = true
	var delay_value = null
	# Get enabled value
	if attrs_value == "false":
		enabled_value = false
	# Get delay value
	if attrs_delay.is_valid_float():
		if float(attrs_delay) >= 0.0:
			delay_value = float(attrs_delay)
	# Add to dict
	if not dict.has("auto"):
		dict["auto"] = {}
	dict["auto"]["enabled"] = enabled_value
	dict["auto"]["delay"] = delay_value
