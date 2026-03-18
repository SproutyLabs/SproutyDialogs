class_name SproutyDialogsSpeedTagProcessor
extends SproutyDialogsTagProcessor


func get_tag_name() -> String:
	return "speed"


func is_block() -> bool:
	return true


func generate(node: SproutyDialogsDialogueParser.ASTNode, dict: Dictionary, variable_manager: SproutyDialogsVariableManager) -> void:
	var attrs: Dictionary = node.attributes
	var rich_text_label: RichTextLabel = RichTextLabel.new()
	rich_text_label.bbcode_enabled = true
	rich_text_label.text = dict["text"]
	var start_pos: int = rich_text_label.get_parsed_text().replace("\n", "").length()
	rich_text_label.text = node.content
	var node_children: Array[SproutyDialogsDialogueParser.ASTNode] = node.get_all_children()
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
