@tool
extends MarginContainer

# -----------------------------------------------------------------------------
## Variables Editor
##
## This module is responsible for the variables editor.
## It allows the user to add, remove, rename, filter and save variables.
# -----------------------------------------------------------------------------

## Emitted when a variable is changed
signal variable_changed(name: String, type: int, value: Variant)
## Emitted when a text editor is called to edit a string variable
signal open_text_editor(text: String)
## Emitted when change the focus to another text box to update the text editor
signal update_text_editor(text: String)

## Variables container
@onready var _variables_container: VBoxContainer = %VariablesContainer
## Empty label to show when there are no variables
@onready var _empty_label: Label = %EmptyLabel

## Preloaded variable field scene
var _variable_item_scene: PackedScene = preload("res://addons/graph_dialogs/editor/modules/variables/variable_item.tscn")
## Preloaded variable group scene
var _variable_group_scene: PackedScene = preload("res://addons/graph_dialogs/editor/modules/variables/variable_group.tscn")

## Group waiting for be removed
var _remove_group: GraphDialogsVariableGroup = null


func _ready():
	_variables_container.child_order_changed.connect(_on_child_order_changed)
	$RemoveGroupDialog.confirmed.connect(_on_confirm_remove_group)
	%AddVarButton.pressed.connect(_on_add_var_button_pressed)
	%AddFolderButton.pressed.connect(_on_add_folder_button_pressed)
	%SearchBar.text_changed.connect(_on_search_bar_text_changed)
	%SaveButton.pressed.connect(_on_save_button_pressed)

	%AddVarButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddFolderButton.icon = get_theme_icon("Folder", "EditorIcons")
	%SearchBar.right_icon = get_theme_icon("Search", "EditorIcons")
	%SaveButton.icon = get_theme_icon("Save", "EditorIcons")

	_variables_container.set_drag_forwarding(
		_get_container_drag_data,
		_can_drop_data_in_container,
		_drop_data_in_container
	)
	if _variables_container.get_child_count() == 1:
		_empty_label.show() # Show the empty label if there are no variables
	
	_load_variables_data(GraphDialogsVariableManager.get_variables())


## Get the variables data from the container
func _get_variables_data(variables_array: Array = _variables_container.get_children()) -> Dictionary:
	var variables_data: Dictionary = {}
	for child in variables_array:
		if child is GraphDialogsVariableItem:
			var data = child.get_variable_data()
			variables_data[data.name] = {
				"type": data.type,
				"value": data.value
			}
		elif child is GraphDialogsVariableGroup:
			variables_data[child.get_item_name()] = {
				"color": child.get_color(),
				"variables": _get_variables_data(child.get_items())
			}
	return variables_data


## Load variables data into the editor
func _load_variables_data(data: Dictionary, parent: Node = _variables_container) -> void:
	for name in data.keys():
		var value = data[name]
		var new_item = null
		if value.has("type") and value.has("value"): # It's a variable
			new_item = _variable_item_scene.instantiate()
			new_item.parent_group = parent
			new_item.ready.connect(func():
				new_item.set_item_name(name)
				new_item.set_type(value.type)
				new_item.set_value(value.value)
			)
			new_item.variable_renamed.connect(_on_item_rename.bind(new_item))
			new_item.variable_changed.connect(_on_variable_changed)
			new_item.open_text_editor.connect(open_text_editor.emit)
			new_item.update_text_editor.connect(update_text_editor.emit)
		elif value.has("variables") and value.has("color"): # It's a group
			new_item = _variable_group_scene.instantiate()
			new_item.parent_group = parent
			new_item.ready.connect(func():
				new_item.set_item_name(name)
				new_item.set_color(value.color)
				_load_variables_data(value.variables, new_item) # Recursively load group variables
			)
			new_item.group_renamed.connect(_on_item_rename.bind(new_item))
			new_item.remove_pressed.connect(_on_remove_group.bind(new_item))
		
		if parent is GraphDialogsVariableGroup:
			parent.add_item(new_item) # Add item to a group
		else:
			parent.add_child(new_item) # Add item to the main container


#region === Search and Filter ==================================================

## Filter the items based on a given text to search
func _filter_items(variables_array: Array, search_text: String) -> Array:
	var filtered_items = []
	for item in variables_array:
		# Check if find a match in the item name or value
		if item is GraphDialogsVariableItem:
			var var_data = item.get_variable_data()
			if search_text in var_data.name.to_lower() \
					or search_text in str(var_data.value).to_lower():
				filtered_items.append(item)
		# Check if find a match in the group name or any of its items
		elif item is GraphDialogsVariableGroup:
			if search_text in item.get_group_name().to_lower():
				filtered_items.append(item)
			else:
				var group_items = _filter_items(item.get_items(), search_text)
				filtered_items.append_array(group_items)
	return filtered_items


## Filter the portrait tree items
func _on_search_bar_text_changed(new_text: String) -> void:
	var search_text = new_text.strip_edges().to_lower()
	if search_text == "":
		for child in _variables_container.get_children():
			if child is GraphDialogsVariableItem:
				child.show()
			elif child is GraphDialogsVariableGroup:
				child.show_items()
				child.show()
	else:
		var filtered_items = _filter_items(_variables_container.get_children(), search_text)
		for child in _variables_container.get_children():
			if child in filtered_items:
				child.show()
			else:
				child.hide()
				if child is GraphDialogsVariableGroup:
					var count = 0
					for item in child.get_items():
						if item in filtered_items:
							item.show()
							count += 1
						else:
							item.hide()
					if count > 0: # Show the group if it has any visible items
						child.show()
#endregion


## Ensure the variable or group name is unique when renaming an existing one
func _on_item_rename(name: String, item: Variant) -> void:
	var regex = RegEx.new()
	regex.compile("(?: \\(\\d+\\))?$")
	var result = regex.search(name)
	var clean_name = name
	if result: # Remove the suffix like " (1)" if exists
		clean_name = regex.sub(name, "").strip_edges()

	# Check if the name is already in the group
	var group = item.parent_group
	var group_items = []
	
	if group is GraphDialogsVariableGroup: # Check items in a group
		group_items = group.get_items().filter(
			func(sub_item): return sub_item != item)
	else: # Check items in the main container
		group_items = _variables_container.get_children().filter(func(sub_item):
			return sub_item != item and (sub_item is GraphDialogsVariableItem \
				or sub_item is GraphDialogsVariableGroup))
	
	group_items = group_items.map(func(sub_item): return sub_item.get_item_name())
	if group_items.has(clean_name): # If the name already exists in the group
		var suffix := 1 # Add a suffix to make it unique
		while group_items.has(clean_name + " (" + str(suffix) + ")"):
			suffix += 1
		item.set_item_name(clean_name + " (" + str(suffix) + ")")


## Add a new portrait to the tree
func _on_add_var_button_pressed() -> void:
	var new_item = _variable_item_scene.instantiate()
	new_item.variable_renamed.connect(_on_item_rename.bind(new_item))
	new_item.variable_changed.connect(_on_variable_changed)
	new_item.open_text_editor.connect(open_text_editor.emit)
	new_item.update_text_editor.connect(update_text_editor.emit)
	new_item.parent_group = _variables_container
	_variables_container.add_child(new_item)


## Add a new portrait group to the tree
func _on_add_folder_button_pressed() -> void:
	var new_item = _variable_group_scene.instantiate()
	new_item.group_renamed.connect(_on_item_rename.bind(new_item))
	new_item.remove_pressed.connect(_on_remove_group.bind(new_item))
	new_item.parent_group = _variables_container
	_variables_container.add_child(new_item)


## Handle variable changes
func _on_variable_changed(name: String, type: int, value: Variant) -> void:
	variable_changed.emit(name, type, value)


## Save the current variables to the project settings
func _on_save_button_pressed() -> void:
	# Unmark all items as modified
	for child in _variables_container.get_children():
		if child is GraphDialogsVariableItem:
			child.show_as_modified(false)
		if child is GraphDialogsVariableGroup:
			child.show_items_as_modified(false)
			child.show_as_modified(false)
	# Save the variables to project settings
	var data = _get_variables_data()
	GraphDialogsVariableManager.save_variables(data)


## Handle the removal of a group
func _on_remove_group(group: GraphDialogsVariableGroup) -> void:
	_remove_group = group
	if not group.get_items().is_empty():
		$RemoveGroupDialog.popup_centered()
	else: # If the group is empty, remove it directly
		_on_confirm_remove_group()


## Handle the confirmation of group removal
func _on_confirm_remove_group() -> void:
	if _remove_group and _remove_group.get_parent():
		_remove_group.get_parent().remove_child(_remove_group)
		_remove_group.queue_free()
		_remove_group = null


## Handle when the group is empty
func _on_child_order_changed() -> void:
	if _empty_label:
		_empty_label.visible = (_variables_container.get_child_count() == 1)


#region === Drag and Drop ======================================================
func _get_container_drag_data(at_position: Vector2) -> Variant:
	return null


func _can_drop_data_in_container(at_position: Vector2, data: Variant) -> bool:
	return data.has("type")


func _drop_data_in_container(at_position: Vector2, data: Variant) -> void:
	var item = data.item
	var from_group = data.group
	from_group.remove_child(item)
	_variables_container.add_child(item)
	data.item.parent_group = _variables_container
	data.item.update_path_tooltip()

#endregion