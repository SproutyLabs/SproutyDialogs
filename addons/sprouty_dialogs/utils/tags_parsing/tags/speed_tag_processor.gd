class_name SproutyDialogsSpeedTagProcessor
extends SproutyDialogsTagProcessor

# -----------------------------------------------------------------------------
# Sprouty Dialogs Speed Tag Processor
# -----------------------------------------------------------------------------
## Defines how to process a typing speed tag in the dialogue.
##
## This tag allows to change the typing speed in which the dialogue will be displayed.
##
## Attributes: 
##   This tag only has the speed attribute and can be passed in two ways:
##   - Absolute speed: [speed=0.03] 
##       Sets the time (in seconds) taken to display each character.
##       Note: A larger value slows down the typing.
##   - Relative speed: [speed=2x]
##       A multiplier relative to the default typing speed configured in tThis text appears twice as fast.he settings 
##      Note: Larger values make typing faster (shorter character intervals).
##
## Example: [speed=2x]This text appears twice as fast.[/speed]
# -----------------------------------------------------------------------------


func get_tag_name() -> String:
	return "speed"


func is_block() -> bool:
	return true


func generate(node: SproutyDialogsTagsParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	var attrs: Dictionary = node.attributes
	var rich_text_label: RichTextLabel = RichTextLabel.new()
	rich_text_label.bbcode_enabled = true
	rich_text_label.text = dict["text"]
	var start_pos: int = rich_text_label.get_parsed_text().replace("\n", "").length()
	rich_text_label.text = node.content
	var node_children: Array[SproutyDialogsTagsParser.ASTNode] = node.get_all_children()
	var text_content: String = ""
	for child in node_children:
		if child.name == "text":
			text_content += child.content
	if text_content == "":
		return
	rich_text_label.text = text_content
	var end_pos: int = start_pos + rich_text_label.get_parsed_text().replace("\n", "").length() - 1
	var attrs_value: String = str(attrs["value"])
	var speed_value: float = 0.0
	if attrs_value[-1] == "x":
		var typing_speed: float = SproutyDialogsSettingsManager.get_setting("default_typing_speed")
		var value: float = float(attrs_value.substr(0, attrs_value.length() - 1))
		if value == 0.0:
			value = 1.0 # Avoid division by zero, treat "0x" as normal speed
		speed_value = typing_speed / value
	else:
		speed_value = float(attrs_value)
	if not dict.has("speed"):
		dict["speed"] = []
	dict["speed"].append({
		"value": speed_value,
		"start": start_pos,
		"end": end_pos
	})
