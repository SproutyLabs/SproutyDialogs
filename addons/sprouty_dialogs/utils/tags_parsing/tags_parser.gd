class_name SproutyDialogsTagsParser

# -----------------------------------------------------------------------------
# Sprouty Dialogs Tags Parser
# -----------------------------------------------------------------------------
## Class that process special tags from the dialogues (such as speed, if, etc).
## 
## The tag processors are defined in the "/tags" folder and they are automatically
## registered. All processors must extends from SproutyDialogsTagProcessor class.
# -----------------------------------------------------------------------------

var raw_text: String = ""
var bbcode_text: String = ""
var ast_root: ASTNode = null
var dialog_data: Dictionary = {}

var _tag_processors: Dictionary[String, SproutyDialogsTagProcessor] = {}
var _variable_manager: SproutyDialogsVariableManager = null


func _init(text: String, variable_manager: SproutyDialogsVariableManager) -> void:
	_scan_tags_folder()
	
	raw_text = text
	_variable_manager = variable_manager
	_parse_dialogue_text()


#region === Tag Processor Registration ======================================================================

func _scan_tags_folder() -> void:
	var folder_path: String = "res://addons/sprouty_dialogs/utils/tags_parsing/tags"
	var dir: DirAccess = DirAccess.open(folder_path)
	if not dir:
		push_warning("[Sprouty Dialogs] Error: Could not open tags directory. No custom tags will be registered.")
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and not file_name.begins_with("."):
			var path: String = folder_path + "/" + file_name
			_register_tag_processor(path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _register_tag_processor(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	if not script:
		return
	var tag_processor: SproutyDialogsTagProcessor = script.new()
	if not tag_processor or not tag_processor.has_method("get_tag_name"):
		push_warning("[Sprouty Dialogs] Warning: Script at %s does not implement get_tag_name() method. Skipping." % path)
		return
	var tag_name: String = tag_processor.get_tag_name()
	if tag_name == null or tag_name == "":
		return
	_tag_processors[tag_name] = tag_processor


#endregion ===============================================================================================


#region === Dialogue Parsing ===============================================================================

func _parse_dialogue_text() -> void:
	# First parse variables, then construct AST, and finally generate final text content based on the AST
	var parsed_text: String = _variable_manager.parse_variables(raw_text, true)
	bbcode_text = parsed_text
	_construct_ast(parsed_text)
	ast_root = _transform_ast(ast_root)[0]
	dialog_data = _generate_dialog_data(ast_root)
	bbcode_text = dialog_data.get("text", "")
	var temp_rich_text_label: RichTextLabel = RichTextLabel.new()
	temp_rich_text_label.bbcode_enabled = true
	temp_rich_text_label.text = bbcode_text


func _construct_ast(parsed_text: String) -> void:
	ast_root = ASTNode.new("root")
	var stack: ASTStack = ASTStack.new([ast_root])
	var pos: int = 0 # Current index into the parsed text string
	var length: int = parsed_text.length() # Total length of parsed text, cached to avoid repeated calls in the loop
	var text_buffer: String = "" # Buffer accumulating plain text characters between tags

	while pos < length:
		var character: String = parsed_text[pos] # The character at the current index
		if character == "\\" and pos + 1 < length:
			# Handle escape character
			if parsed_text[pos + 1] in ["[", "]", "\\"]:
				text_buffer += parsed_text[pos + 1]
				pos += 2
			else:
				text_buffer += character
				pos += 1
			continue
		if character == "[":
			# Try to parse tag first. Only flush existing text_buffer if the tag is recognized.
			var tag_info: Dictionary = _parse_tag(parsed_text, pos)
			if tag_info != {}:
				# If we have buffered text, flush it before inserting a tag node
				if text_buffer != "":
					var text_node: ASTNode = ASTNode.new("text")
					text_node.content = text_buffer
					stack.back().add_child(text_node)
					text_buffer = ""
				var tag_name: String = tag_info["name"] # The name of the parsed tag (e.g. "speed", "wait")
				var is_end: bool = tag_info["is_end"] # Whether this is a closing tag (e.g. [/speed])
				var attributes: Dictionary = tag_info["attributes"] # Key-value pairs parsed from the tag (e.g. {"speed": 0.05})
				var end_pos: int = tag_info["end_pos"] # The index of the closing bracket in the original string

				if is_end:
					if stack.size() <= 1:
						# Mismatched end tag, ignore or handle error
						push_warning("[Sprouty Dialogs] Warning: Mismatched end tag [%s] at position %s." % [tag_name, str(pos)])
						pos = end_pos + 1
						continue
					if stack.back().name == tag_name:
						stack.pop()
					else:
						# Mismatched end tag, ignore or handle error
						push_warning("[Sprouty Dialogs] Warning: Mismatched end tag [%s] at position %s. Expected [/%s]." % [tag_name, str(pos), stack.back().name])
				else:
					# Handle start tag
					var new_node: ASTNode = ASTNode.new(tag_name)
					new_node.attributes = attributes
					stack.back().add_child(new_node)
					if _tag_processors.has(tag_name) and _tag_processors[tag_name].is_block():
						stack.push(new_node)
				pos = end_pos + 1
			else:
				# Not a recognized tag: append the whole bracketed substring to buffer
				var close_pos: int = parsed_text.find("]", pos) # Index of the closing bracket, or -1 if not found
				if close_pos == -1:
					# No closing bracket: just append the '[' character
					text_buffer += character
					pos += 1
				else:
					# Append the entire '[...]' fragment so bbcode-like tags stay intact
					text_buffer += parsed_text.substr(pos, close_pos - pos + 1)
					pos = close_pos + 1
		else:
			text_buffer += character
			pos += 1
	if text_buffer != "":
		var text_node: ASTNode = ASTNode.new("text")
		text_node.content = text_buffer
		stack.back().add_child(text_node)
		text_buffer = ""
	if stack.size() > 1:
		# Unclosed tags at the end, could handle error or ignore
		push_warning("[Sprouty Dialogs] Warning: Unclosed tags at the end of dialogue text.")


func _transform_ast(node: ASTNode) -> Array[ASTNode]:
	var result: Array[ASTNode] = []
	for child in node.children:
		result.append_array(_transform_ast(child))
	node.children = result
	if _tag_processors.has(node.name):
		return _tag_processors[node.name].transform(node, _variable_manager)
	return [node]


func _generate_dialog_data(node: ASTNode, dict: Dictionary = {}) -> Dictionary:
	if not dict.has("text"):
		dict.set("text", "")
	if node.name == "text":
		dict["text"] = dict["text"] + node.content
	if _tag_processors.has(node.name):
		_tag_processors[node.name].generate(node, dict, _variable_manager)
	for child in node.children:
		_generate_dialog_data(child, dict)
	return dict


func _parse_tag(input: String, start: int) -> Dictionary:
	if input[start] != "[":
		return {}
	var end: int = input.find("]", start)
	if end == -1:
		return {}
	var tag_content: String = input.substr(start + 1, end - start - 1)
	if tag_content == "" or tag_content.strip_edges() == "":
		return {}
	var is_end: bool = (tag_content[0] == "/")
	if is_end:
		tag_content = tag_content.substr(1, tag_content.length() - 1)
	# Use a tokenizer that respects quoted values (so key="a b c" is kept together)
	var parts: PackedStringArray = _split_tag_parts(tag_content)
	var tag_name: String = parts[0]
	var attrs: Dictionary = {}
	# Handle shorthand form like [name=value]
	if tag_name.find("=") != -1:
		var kv: PackedStringArray = tag_name.split("=", false) # key-value pair from the tag name
		tag_name = kv[0]
		var value: String = ""
		if kv.size() > 1:
			value = kv[1]
		if value.length() >= 2 and value[0] in ["\"", "'"] and value[value.length() - 1] == value[0]:
			value = value.substr(1, value.length() - 2)
		# store shorthand value in a normalized key
		attrs["value"] = value
	
	if not _tag_processors.has(tag_name):
		return {}
	
	for i in range(1, parts.size()):
		var attr_part: String = parts[i]
		var equal_pos: int = attr_part.find("=")
		if equal_pos != -1:
			var key: String = attr_part.substr(0, equal_pos)
			var value: String = attr_part.substr(equal_pos + 1, attr_part.length() - equal_pos - 1)
			if value.length() >= 2 and value[0] in ["\"", "'"] and value[value.length() - 1] == value[0]:
				value = value.substr(1, value.length() - 2)
			attrs[key] = value
	return {
		"name": tag_name,
		"attributes": attrs,
		"is_end": is_end,
		"end_pos": end
	}


# Tokenizer that splits a tag content string by spaces but preserves quoted substrings
func _split_tag_parts(content: String) -> PackedStringArray:
	var parts: Array = [] # Collected tokens after splitting
	var cur: String = "" # Current token being built character by character
	var in_quote: String = "" # The quote character that opened the current quoted section, or empty if not in quotes
	var pos: int = 0 # Current index into the content string
	var length: int = content.length() # Total length of content, cached to avoid repeated calls in the loop
	while pos < length:
		var character: String = content[pos] # The character at the current index
		if (character == '"' or character == "'"):
			# toggle quote state and include the quote in the token so later code can trim it
			if in_quote == "":
				in_quote = character
				cur += character
			elif in_quote == character:
				cur += character
				in_quote = ""
			else:
				# different quote character inside another quote: just append
				cur += character
		elif character == " " and in_quote == "":
			if cur != "":
				parts.append(cur)
				cur = ""
			# else skip additional spaces
		else:
			cur += character
		pos += 1
	if cur != "":
		parts.append(cur)
	return PackedStringArray(parts)


func print_ast(node: ASTNode, indent: int = 0) -> void:
	var indent_str: String = ""
	for i in range(indent):
		indent_str += "--"
	if node.name == "text":
		var display_content: String = node.content.replace("\n", "\\n").replace("\t", "\\t")
		print(indent_str + "Text: \"" + display_content + "\"")
	else:
		print(indent_str + "Tag: " + node.name + ", Attributes: " + str(node.attributes))
	for child in node.children:
		print_ast(child, indent + 1)


#endregion ===============================================================================================


class ASTNode:
	var name: String = ""
	var content: String = ""
	var attributes: Dictionary = {}
	var children: Array[ASTNode] = []: set = set_children
	var parent: ASTNode = null
	
	func _init(init_name: String) -> void:
		name = init_name
	
	func add_child(child: ASTNode, pos: int = -1) -> void:
		if pos >= 0 and pos < children.size():
			children.insert(pos, child)
		else:
			children.append(child)
		child.parent = self
	
	func set_children(new_children: Array[ASTNode]) -> void:
		children = new_children
		for child in children:
			child.parent = self
	
	## Recursively get all descendant nodes of this node in a flat array.
	func get_all_children() -> Array[ASTNode]:
		var result: Array[ASTNode] = []
		for child in children:
			result.append(child)
			result.append_array(child.get_all_children())
		return result
	
	
	## Free this node by clearing its children and removing reference to parent.
	## Should be called when you want to dispose of a single node to avoid memory leaks.
	## For disposing of entire subtrees, call free_tree() instead.
	func free_self() -> void:
		children = []
		parent = null
	
	## Recursively free this node and all its descendants.
	## Should be called when you want to dispose of an entire subtree of the AST to avoid memory leaks.
	func free_tree() -> void:
		for child in children:
			child.free_tree()
		free_self()


class ASTStack:
	var items: Array[ASTNode] = []
	
	func _init(init_items: Array[ASTNode]=[]) -> void:
		items = init_items
	
	func push(item: ASTNode) -> void:
		items.append(item)
	
	func pop() -> ASTNode:
		if items.size() > 0:
			return items.pop_back()
		return null
	
	func back() -> ASTNode:
		if items.size() > 0:
			return items[items.size() - 1]
		return null
	
	func size() -> int:
		return items.size()
