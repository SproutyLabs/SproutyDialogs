@tool
class_name SproutyDialogsVariableUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Utils
# -----------------------------------------------------------------------------
## This class provides utility methods to handle variables, such as get the UI 
## fields and components needed to edit variables in the editor and get the 
## assignment and comparison operators available for each variable type.
# -----------------------------------------------------------------------------

## Assignment operators for variables
enum ASSIGN_OPS {
	ASSIGN, ## Direct assignment operator (=)
	ADD_ASSIGN, ## Addition assignment operator (+=)
	SUB_ASSIGN, ## Subtraction assignment operator (-=)
	MUL_ASSIGN, ## Multiplication assignment operator (*=)
	DIV_ASSIGN, ## Division assignment operator (/=)
	EXP_ASSIGN, ## Exponentiation assignment operator (**=)
	MOD_ASSIGN, ## Modulus assignment operator (%=)
}

## Path to the variable icon
const VAR_ICON_PATH = "res://addons/sprouty_dialogs/editor/icons/variable.svg"
## Path to the dictionary field scene
const DICTIONARY_FIELD_PATH := "res://addons/sprouty_dialogs/editor/components/dictionary_field.tscn"
## Path to the array field scene
const ARRAY_FIELD_PATH := "res://addons/sprouty_dialogs/editor/components/array_field.tscn"
## Path to the file field scene
const FILE_FIELD_PATH := "res://addons/sprouty_dialogs/editor/components/file_field.tscn"


## Returns a list with the names of variables of the given type.
## If a type is specified, it returns only the variables of that type.
## If no type is specified, it returns all variables.
## If no variables are found, it returns an empty array.
static func get_variables_of_type(type: int = -1, metadata: Dictionary = {}, group: Dictionary = {}) -> Array:
	if group.is_empty(): # Get all variables
		group = SproutyDialogsSettingsManager.get_setting("variables")
	
	var variable_list: Array = []
	for key in group.keys():
		if group[key].has("variables"): # Recursively check in groups
			var sub_variables = get_variables_of_type(type, metadata, group[key].variables)
			for sub_key in sub_variables:
				variable_list.append(key + "/" + sub_key)
		# Check if the variable type matches or if no type is specified
		elif type == -1 or (group[key].type == type and metadata == {}) \
				or (group[key].type == type and group[key].metadata == metadata):
			variable_list.append(key)
	return variable_list


#region === Variable Type Fields ===============================================

## Returns an OptionButton component with all the variable types
## that can be selected. You can exclude types by passing their names
## in the 'excluded' array. Also, you can hide the label text by setting
## 'label' to false.
static func get_types_dropdown(label: bool = true, excluded: Array[String] = []) -> OptionButton:
	var dropdown: OptionButton = OptionButton.new()
	dropdown.name = "TypeDropdown"
	dropdown.tooltip_text = "Select variable type"
	dropdown.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var root = Engine.get_singleton("EditorInterface").get_base_control()
	var types_dict = {
		"Variable": {
			"icon": load(VAR_ICON_PATH),
			"type": 40,
			"metadata": {},
		},
		"Nil": {
			"icon": root.get_theme_icon("Nil", "EditorIcons"),
			"type": TYPE_NIL,
			"metadata": {},
		},
		"bool": {
			"icon": root.get_theme_icon("bool", "EditorIcons"),
			"type": TYPE_BOOL,
			"metadata": {},
		},
		"int": {
			"icon": root.get_theme_icon("int", "EditorIcons"),
			"type": TYPE_INT,
			"metadata": {},
		},
		"float": {
			"icon": root.get_theme_icon("float", "EditorIcons"),
			"type": TYPE_FLOAT,
			"metadata": {},
		},
		"String": {
			"icon": root.get_theme_icon("String", "EditorIcons"),
			"type": TYPE_STRING,
			"metadata": {},
		},
		"Vector2": {
			"icon": root.get_theme_icon("Vector2", "EditorIcons"),
			"type": TYPE_VECTOR2,
			"metadata": {},
		},
		"Vector3": {
			"icon": root.get_theme_icon("Vector3", "EditorIcons"),
			"type": TYPE_VECTOR3,
			"metadata": {},
		},
		"Vector4": {
			"icon": root.get_theme_icon("Vector4", "EditorIcons"),
			"type": TYPE_VECTOR4,
			"metadata": {},
		},
		"Color": {
			"icon": root.get_theme_icon("Color", "EditorIcons"),
			"type": TYPE_COLOR,
			"metadata": {},
		},
		"Expression": {
			"icon": root.get_theme_icon("Variant", "EditorIcons"),
			"type": TYPE_STRING,
			"metadata": {"hint": PROPERTY_HINT_EXPRESSION, "hint_string": ""},
		},
		"Dictionary": {
			"icon": root.get_theme_icon("Dictionary", "EditorIcons"),
			"type": TYPE_DICTIONARY,
			"metadata": {},
		},
		"Array": {
			"icon": root.get_theme_icon("Array", "EditorIcons"),
			"type": TYPE_ARRAY,
			"metadata": {},
		},
		"File Path": {
			"icon": root.get_theme_icon("FileBrowse", "EditorIcons"),
			"type": TYPE_STRING,
			"metadata": {"hint": PROPERTY_HINT_FILE, "hint_string": ""},
		},
		"Dir Path": {
			"icon": root.get_theme_icon("FolderBrowse", "EditorIcons"),
			"type": TYPE_STRING,
			"metadata": {"hint": PROPERTY_HINT_DIR, "hint_string": ""},
		},

		# ----------------------------------
		# Add more types as needed here (!)
		# ----------------------------------
	}
	
	# Populate the dropdown with types
	for type_name in types_dict.keys():
		if excluded.has(type_name):
			continue # Skip excluded types
		
		var type_info = types_dict[type_name]
		dropdown.add_icon_item(
			type_info["icon"], # Type icon
			type_name, # Type name label
			type_info["type"] # Type as ID
			)
		# Store additional data as metadata
		dropdown.set_item_metadata(dropdown.get_item_count() - 1, type_info["metadata"])
	
	if not label: # Hide option text in button
		dropdown.clip_text = true
	
	return dropdown


## Create a new field based on the variable type.
## Returns a dictionary with the field created and its default value.
## You can pass an initial value and property data for hints.
## Also, you can pass callables for when the value changes
## or when the field is modified.
static func new_field_by_type(
		type: int,
		init_value: Variant = null,
		property_data: Dictionary = {},
		on_value_changed: Callable = func(value, type, field): return ,
		on_modified_callable: Callable = func(): return ,
		) -> Dictionary:
	var field = null
	var default_value = null
	match type:
		TYPE_NIL:
			field = Button.new()
			field.text = "<null>"
			field.disabled = true
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			default_value = null
		
		TYPE_BOOL:
			field = CheckBox.new()
			if init_value != null:
				field.button_pressed = init_value
			default_value = field.button_pressed
			field.toggled.connect(on_value_changed.bind(type, field))
			field.toggled.connect(on_modified_callable.unbind(1))
		
		TYPE_INT:
			# Enum int
			if property_data.has("hint") and \
					property_data["hint"] == PROPERTY_HINT_ENUM:
				field = OptionButton.new()
				for option in property_data["hint_string"].split(","):
					field.add_item(option.split(":")[0])
				
				if init_value != null:
					field.select(init_value)
				default_value = field.selected
				field.item_selected.connect(on_value_changed.bind(type, field))
				field.item_selected.connect(on_modified_callable.unbind(1))
			else: # Regular int
				field = SpinBox.new()
				field.step = 1
				field.allow_greater = true
				field.allow_lesser = true

				# If the property is a int between a range, set range values
				if property_data.has("hint_string"):
					var range_settings = property_data["hint_string"].split(",")
					if range_settings.size() > 1:
						field.min_value = int(range_settings[0])
						field.max_value = int(range_settings[1])
						if range_settings.size() > 2:
							field.step = int(range_settings[2])
				
				if init_value != null:
					field.value = init_value
				default_value = field.value
				field.value_changed.connect(on_value_changed.bind(type, field))
				field.get_line_edit().focus_exited.connect(on_modified_callable)
		
		TYPE_FLOAT:
			field = SpinBox.new()
			field.step = 0.01
			field.allow_greater = true
			field.allow_lesser = true

			# If the property is a float between a range, set range values
			if property_data.has("hint_string"):
				var range_settings = property_data["hint_string"].split(",")
				if range_settings.size() > 1:
					field.min_value = float(range_settings[0])
					field.max_value = float(range_settings[1])
					if range_settings.size() > 2:
						field.step = float(range_settings[2])
		
			if init_value != null:
				field.value = init_value
			default_value = field.value
			field.value_changed.connect(on_value_changed.bind(type, field))
			field.get_line_edit().focus_exited.connect(on_modified_callable)
		
		TYPE_STRING:
			var line_edit = LineEdit.new()
			line_edit.name = "TextEdit"
			line_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			line_edit.placeholder_text = "Write text here..."
			line_edit.text_changed.connect(on_value_changed.bind(type, field))
			line_edit.focus_exited.connect(on_modified_callable)
			
			if not property_data.is_empty():
				# File path string
				if property_data["hint"] == PROPERTY_HINT_FILE:
					field = load(FILE_FIELD_PATH).instantiate()
					field.file_filters = PackedStringArray(
						property_data["hint_string"].split(",")
						)
					if init_value != null:
						field.ready.connect(func(): field.set_value(init_value))
					default_value = init_value if init_value != null else ""
					field.path_changed.connect(on_value_changed.bind(type, field))
					field.field_focus_exited.connect(on_modified_callable)
				# Directory path string
				elif property_data["hint"] == PROPERTY_HINT_DIR:
					field = load(FILE_FIELD_PATH).instantiate()
					field.ready.connect(func(): field.open_directory(true))
					field.file_filters = PackedStringArray(
						property_data["hint_string"].split(",")
						)
					if init_value != null:
						field.ready.connect(func(): field.set_value(init_value))
					default_value = init_value if init_value != null else ""
					field.path_changed.connect(on_value_changed.bind(type, field))
					field.field_focus_exited.connect(on_modified_callable)
				# Enum string
				elif property_data["hint"] == PROPERTY_HINT_ENUM:
					field = OptionButton.new()
					var options := []
					for enum_option in property_data["hint_string"].split(","):
						options.append(enum_option.split(':')[0].strip_edges())
						field.add_item(options[-1])
					if init_value != null:
						field.select(options.find(init_value))
					default_value = field.selected
					field.item_selected.connect(on_value_changed.bind(type, field))
					field.item_selected.connect(on_modified_callable.unbind(1))
				# Expression string
				elif property_data["hint"] == PROPERTY_HINT_EXPRESSION:
					line_edit.placeholder_text = "Write a expression here..."
					field = line_edit
					if init_value != null:
						field.text = init_value
					default_value = line_edit.text
				else:
					# Regular string
					field = line_edit
					if init_value != null:
						field.text = init_value
					default_value = line_edit.text
			else:
				# String with expandable field
				field = HBoxContainer.new()
				field.add_child(line_edit)
				var button = Button.new()
				button.name = "ExpandButton"
				button.icon = Engine.get_singleton("EditorInterface").get_base_control().\
						get_theme_icon("DistractionFree", "EditorIcons")
				field.add_child(button)
				if init_value != null:
					line_edit.text = init_value
				default_value = line_edit.text
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			var components_names = ["x", "y", "z", "w"]
			field = HFlowContainer.new()

			for i in range(0, vector_n):
				# Create a container for each component
				var container = HBoxContainer.new()
				container.name = components_names[i] # x, y, z, w
				container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
				field.add_child(container)

				# Add a label and a SpinBox for each component
				var label = Label.new()
				label.text = components_names[i]
				container.add_child(label)

				var component_field = SpinBox.new()
				component_field.name = "Field"
				component_field.step = 0.01
				component_field.allow_greater = true
				component_field.allow_lesser = true
				container.add_child(component_field)

				if init_value != null:
					component_field.value = init_value[i]
				default_value = Vector2.ZERO if type == TYPE_VECTOR2 \
					else Vector3.ZERO if type == TYPE_VECTOR3 else Vector4.ZERO
				
				component_field.get_line_edit().focus_exited.connect(on_modified_callable)
				component_field.value_changed.connect(func(value):
					var vector_value = default_value
					for j in range(0, vector_n):
						if field.get_child_count() > j:
							var component = field.get_child(j).get_node("Field")
							vector_value[j] = component.value
					on_value_changed.call(vector_value, type, field)
				)
		
		TYPE_COLOR:
			field = ColorPickerButton.new()
			field.custom_minimum_size = Vector2(60, 60)
			if init_value != null:
				field.color = Color(init_value)
			default_value = field.color.to_html()
			field.color_changed.connect(on_value_changed.bind(type, field))
			field.focus_exited.connect(on_modified_callable)
		
		TYPE_DICTIONARY:
			field = load(DICTIONARY_FIELD_PATH).instantiate()
			field.ready.connect(func():
				if init_value != null:
					field.set_dictionary(init_value)
				default_value = field.get_dictionary()
			)
			field.dictionary_changed.connect(on_value_changed.bind(type, field))
			field.modified.connect(on_modified_callable)
		
		TYPE_ARRAY:
			field = load(ARRAY_FIELD_PATH).instantiate()
			field.ready.connect(func():
				if init_value != null:
					field.set_array(init_value)
				default_value = field.get_array()
			)
			field.array_changed.connect(on_value_changed.bind(type, field))
			field.modified.connect(on_modified_callable)

		TYPE_OBJECT:
			field = RichTextLabel.new()
			field.bbcode_enabled = true
			field.fit_content = true
			field.text = "[color=tomato]Objects/Resources are not directly supported[/color]"
			field.tooltip_text = "Use @export_file(\"*.extension\") to load it from file instead."
		
		40: # Variable field
			field = EditorSproutyDialogsComboBox.new()
			var popup = PopupMenu.new()
			popup.name = "DropdownPopup"
			field.add_child(popup)
			field.set_placeholder("Variable name...")
			field.set_options(get_variables_of_type())
			if init_value != null:
				field.set_value(init_value)
			default_value = field.get_value()
			field.input_changed.connect(on_value_changed.bind(type, field))
			field.input_focus_exited.connect(on_modified_callable)
		
		# ----------------------------------
		# Add more types as needed here (!)
		# ----------------------------------

		_:
			field = RichTextLabel.new()
			field.bbcode_enabled = true
			field.fit_content = true
			if type > TYPE_MAX:
				field.text = "[color=tomato]Invalid type value[/color]"
			else:
				field.text = "[color=tomato]" + type_string(type) + " is not supported[/color]"
	
	return {
		"field": field,
		"default_value": default_value
	}


## Sets a value in the given field based on its type.
static func set_field_value(field: Control, type: int, value: Variant) -> void:
	if value == null:
		return # Do nothing if value is null
	match type:
		TYPE_BOOL:
			if field is CheckBox:
				field.set_pressed_no_signal(value)
		
		TYPE_INT, TYPE_FLOAT:
			if field is OptionButton: # Enum int
				field.select(value)
			if field is SpinBox: # Regular int/float
				field.set_value_no_signal(value)
		
		TYPE_STRING:
			if field is OptionButton: # Enum string
				field.select(value)
			if field is EditorSproutyDialogsFileField: # File/Directory path
				field.set_value(value)
			if field is HBoxContainer: # Expandable string
				field = field.get_node("TextEdit")
			if field is LineEdit: # Regular string
				field.text = str(value)
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			if field is HFlowContainer:
				for i in range(0, vector_n):
					if field.get_child_count() > i:
						var component = field.get_child(i).get_node("Field")
						if component is SpinBox:
							component.set_value_no_signal(float(value[i]))
		TYPE_COLOR:
			if field is ColorPickerButton:
				field.color = Color(value)
		
		TYPE_DICTIONARY:
			if field is EditorSproutyDialogsDictionaryField:
				field.set_dictionary(value)
		
		TYPE_ARRAY:
			if field is EditorSproutyDialogsArrayField:
				field.set_array(value)
		
		40: # Variable field
			if field is EditorSproutyDialogsComboBox:
				field.set_value(value)
		
		# ----------------------------------
		# Add more types as needed here (!)
		# ----------------------------------

		_:
			pass # Do nothing for unsupported types

#endregion

#region === Variable Type Operators ============================================

## Returns a list of assignment operators by type.
static func get_assignment_operators(type: int) -> Dictionary:
	match type:
		TYPE_BOOL:
			return { # Boolean assignment
				"=": ASSIGN_OPS.ASSIGN
				}
		TYPE_INT, TYPE_FLOAT:
			return { # Arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
				"*=": ASSIGN_OPS.MUL_ASSIGN,
				"/=": ASSIGN_OPS.DIV_ASSIGN,
				"**=": ASSIGN_OPS.EXP_ASSIGN,
				"%=": ASSIGN_OPS.MOD_ASSIGN
			}
		TYPE_STRING:
			return { # String assignment and concatenation
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
			}
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			return { # Vector arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
				"*=": ASSIGN_OPS.MUL_ASSIGN,
				"/=": ASSIGN_OPS.DIV_ASSIGN,
			}
		TYPE_COLOR:
			return { # Color arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
			}
		_:
			return { # Default to assignment for other types
				"=": ASSIGN_OPS.ASSIGN
			}


## Returns all the comparison operators as a dictionary.
static func get_comparison_operators() -> Dictionary:
	return {
		"==": OP_EQUAL,
		"!=": OP_NOT_EQUAL,
		"<": OP_LESS,
		">": OP_GREATER,
		"<=": OP_LESS_EQUAL,
		">=": OP_GREATER_EQUAL
	}

#endregion
