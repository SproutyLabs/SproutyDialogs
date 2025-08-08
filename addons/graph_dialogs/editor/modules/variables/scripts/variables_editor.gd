@tool
extends MarginContainer

# -----------------------------------------------------------------------------
## Variables Editor
##
## This module is responsible for the variables editor.
## It allows the user to add, remove, rename and duplicate variables.
# -----------------------------------------------------------------------------

## Variables container
@onready var _variables_container: VBoxContainer = %VariablesContainer

## Preloaded variable field scene
var _variable_item_scene: PackedScene = preload("res://addons/graph_dialogs/editor/modules/variables/variable_item.tscn")
## Preloaded variable group scene
var _variable_group_scene: PackedScene = preload("res://addons/graph_dialogs/editor/modules/variables/variable_group.tscn")


func _ready():
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
			variables_data[child.group_name] = {
				"color": child.group_color,
				"variables": _get_variables_data(child.get_items())
			}
	return variables_data


#region === Search and Filter ==================================================

## Filter the variables based on the search text
func _filter_items(variables_array: Array, search_text: String, full_match: bool = false) -> Array:
	search_text = search_text.strip_edges().to_lower()
	var filtered_items = []
	for item in variables_array:
		# Check if find a match in the item name or value
		if item is GraphDialogsVariableItem:
			var var_data = item.get_variable_data()
			if full_match and (search_text == var_data.name.to_lower() \
					or search_text == str(var_data.value).to_lower()):
				filtered_items.append(item)
			if not full_match and (search_text in var_data.name.to_lower() \
					or search_text in str(var_data.value).to_lower()):
				filtered_items.append(item)
		# Check if find a match in the group name or any of its items
		elif item is GraphDialogsVariableGroup:
			if full_match and search_text == item.group_name.to_lower():
				filtered_items.append(item)
			elif not full_match and search_text in item.group_name.to_lower():
				filtered_items.append(item)
			else:
				var group_items = _filter_items(item.get_items(), search_text, full_match)
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

## Add a new portrait to the tree
func _on_add_var_button_pressed() -> void:
	var new_var = _variable_item_scene.instantiate()
	new_var.variable_renamed.connect(_on_variable_renamed.bind(new_var))
	new_var.variable_changed.connect(_on_variable_changed)
	_variables_container.add_child(new_var)


## Add a new portrait group to the tree
func _on_add_folder_button_pressed() -> void:
	var new_group = _variable_group_scene.instantiate()
	new_group.group_renamed.connect(_on_group_renamed.bind(new_group))
	_variables_container.add_child(new_group)


## Handle variable renaming to ensure unique names
func _on_variable_renamed(name: String, item: GraphDialogsVariableItem) -> void:
	var matches = _filter_items(_variables_container.get_children(), name, true)
	print("Renamed variable to: ", name, " | Matches: ", matches)
	if matches.size() > 1:
		item.rename_variable(name + " (" + str(matches.size()) + ")")


## Handle group renaming to ensure unique names
func _on_group_renamed(name: String, item: GraphDialogsVariableGroup) -> void:
	var matches = _filter_items(_variables_container.get_children(), name, true)
	print("Renamed group to: ", name, " | Matches: ", matches)
	if matches.size() > 1:
		item.rename_group(name + " (" + str(matches.size()) + ")")


## Handle variable changes
func _on_variable_changed(name: String, type: int, value: Variant) -> void:
	print("Variable changed: ", name, " (", type, ") = ", value)


## Save the current variables to the project settings
func _on_save_button_pressed() -> void:
	for child in _variables_container.get_children():
		if child is GraphDialogsVariableItem or child is GraphDialogsVariableGroup:
			child.show_modified_indicator(false)
	#TODO: Save to project settings
	var data = _get_variables_data()
	print("Saving variables data: ", data)


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

#endregion