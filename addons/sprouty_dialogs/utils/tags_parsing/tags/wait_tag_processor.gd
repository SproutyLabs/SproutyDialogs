class_name SproutyDialogsWaitTagProcessor
extends SproutyDialogsTagProcessor

# -----------------------------------------------------------------------------
# Sprouty Dialogs Wait Tag Processor
# -----------------------------------------------------------------------------
## Defines how to process a wait tag in the dialogue.
##
## Inserts a fixed pause (in seconds) between characters. The typewriter waits 
## before continuing with the subsequent content.
##
## Attributes:
##   This tag only has the time to wait attribute in seconds.
##
## (It's an inline tag)
##
## Example: Hello...[wait=1.5] how are you?
# -----------------------------------------------------------------------------


func get_tag_name() -> String:
	return "wait"


func is_block() -> bool:
	return false


func transform(node: SproutyDialogsTagsParser.ASTNode, variable_manager: SproutyDialogsVariableManager) -> Array[SproutyDialogsTagsParser.ASTNode]:
	var text_node: SproutyDialogsTagsParser.ASTNode = SproutyDialogsTagsParser.ASTNode.new("text")
	text_node.content = "\u200B"
	node.add_child(text_node)
	return [node]


func generate(node: SproutyDialogsTagsParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	var attrs: Dictionary = node.attributes
	var rich_text_label: RichTextLabel = RichTextLabel.new()
	rich_text_label.bbcode_enabled = true
	rich_text_label.text = dict["text"]
	var start_pos: int = rich_text_label.get_parsed_text().replace("\n", "").length()
	var end_pos: int = start_pos
	var attrs_value: String = str(attrs["value"])
	var speed_value: float = 0.0
	if attrs_value.is_valid_float():
		if float(attrs_value) >= 0.0:
			speed_value = float(attrs_value)
	if not dict.has("speed"):
		dict["speed"] = []
	dict["speed"].append({
		"value": speed_value,
		"start": start_pos,
		"end": end_pos
	})