@tool
class_name EditorSproutyDialogsVariableEditor
extends MarginContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Editor
# -----------------------------------------------------------------------------
## This module is the main interface for managing variables in the Sprouty Dialogs 
## editor. It allows the user to add, remove, rename, filter and save variables.
# -----------------------------------------------------------------------------

## Emitted when a variable is changed
signal variable_changed(var_data: Dictionary)
## Emitted when a text editor is called to edit a string variable
signal open_text_editor(text: String)
## Emitted when change the focus to another text box to update the text editor
signal update_text_editor(text: String)

## Variables container
@onready var _variable_container: VBoxContainer = %VariableContainer
## Empty label to show when there are no variables
@onready var _empty_label: Label = %EmptyLabel
## Saved variables button
@onready var _save_button: Button = %SaveButton

## Preloaded variable field scene
var _variable_item_scene: PackedScene = preload("res://addons/sprouty_dialogs/editor/modules/variables/components/variable_item.tscn")
## Preloaded variable group scene
var _variable_group_scene: PackedScene = preload("res://addons/sprouty_dialogs/editor/modules/variables/components/variable_group.tscn")

## Group waiting for be removed
var _remove_group: EditorSproutyDialogsVariableGroup = null

## Modified counter to track changes
var _modified_counter: int = 0

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	_variable_container.child_order_changed.connect(_on_child_order_changed)
	$RemoveGroupDialog.confirmed.connect(_on_confirm_remove_group)
	%AddVarButton.pressed.connect(_on_add_var_button_pressed)
	%AddGroupButton.pressed.connect(_on_add_group_button_pressed)
	%SearchBar.text_changed.connect(_on_search_bar_text_changed)
	_save_button.pressed.connect(_on_save_button_pressed)

	%AddVarButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddGroupButton.icon = get_theme_icon("Folder", "EditorIcons")
	%SearchBar.right_icon = get_theme_icon("Search", "EditorIcons")
	_save_button.icon = get_theme_icon("Save", "EditorIcons")
	_save_button.text = ""

	_variable_container.set_drag_forwarding(
		_get_container_drag_data,
		_can_drop_data_in_container,
		_drop_data_in_container
	)
	if _variable_container.get_child_count() == 1:
		_empty_label.show() # Show the empty label if there are no variables
	
	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_variables_data(SproutyDialogsSettingsManager.get_setting("variables"))


## Get the variables data from the container
func _get_variables_data(variables_array: Array = _variable_container.get_children()) -> Dictionary:
	var variables_data: Dictionary = {}
	for child in variables_array:
		if child is EditorSproutyDialogsVariableItem:
			var data = child.get_variable_data()
			variables_data[data.name] = {
				"index": child.get_index() - 1,
				"type": data.type,
				"value": data.value,
				"metadata": data.metadata
			}
		elif child is EditorSproutyDialogsVariableGroup:
			variables_data[child.get_item_name()] = {
				"index": child.get_index() - 1,
				"color": child.get_color(),
				"variables": _get_variables_data(child.get_items())
			}
	return variables_data


## Load variables data into the editor
func _load_variables_data(data: Dictionary, parent: Node = _variable_container) -> void:
	# Sort keys by their index value
	var sorted_keys := data.keys()
	sorted_keys.sort_custom(func(a, b):
		return data[a]["index"] < data[b]["index"]
	)
	# Create items in the index order
	for name in sorted_keys:
		var value = data[name]
		var new_item = null
		if value.has("type") and value.has("value"): # It's a variable
			new_item = _new_variable_item()
			new_item.parent_group = parent
			new_item.ready.connect(func():
				new_item.set_item_name(name)
				new_item.set_type(value.type, value.metadata)
				new_item.set_value(value.value)
			)
		elif value.has("variables") and value.has("color"): # It's a group
			new_item = _new_variable_group()
			new_item.parent_group = parent
			new_item.ready.connect(func():
				new_item.set_item_name(name)
				new_item.set_color(value.color)
				_load_variables_data(value.variables, new_item) # Recursively load group variables
			)
		
		if parent is EditorSproutyDialogsVariableGroup:
			parent.add_item(new_item) # Add item to a group
		else:
			parent.add_child(new_item) # Add item to the main container


## Create a new variable item
func _new_variable_item() -> EditorSproutyDialogsVariableItem:
	var new_item = _variable_item_scene.instantiate()
	new_item.variable_renamed.connect(_on_item_rename.bind(new_item))
	new_item.variable_changed.connect(_on_variable_changed)
	new_item.open_text_editor.connect(open_text_editor.emit)
	new_item.update_text_editor.connect(update_text_editor.emit)
	new_item.remove_pressed.connect(_on_remove_variable.bind(new_item))
	new_item.modified.connect(_on_modified)
	new_item.undo_redo = undo_redo
	return new_item


## Create a new variable group
func _new_variable_group() -> EditorSproutyDialogsVariableGroup:
	var new_group = _variable_group_scene.instantiate()
	new_group.group_renamed.connect(_on_item_rename.bind(new_group))
	new_group.remove_pressed.connect(_on_remove_group.bind(new_group))
	new_group.modified.connect(_on_modified)
	new_group.undo_redo = undo_redo
	return new_group


## Mark the variable item as modified
func _on_modified(was_modified: bool) -> void:
	if was_modified:
		if _modified_counter == 0:
			_save_button.text = "(*)"
		_modified_counter += 1
	else:
		_modified_counter -= 1
		if _modified_counter <= 0:
			_save_button.text = ""
			_modified_counter = 0


#region === Search and Filter ==================================================

## Filter the items based on a given text to search
func _filter_items(variables_array: Array, search_text: String) -> Array:
	var filtered_items = []
	for item in variables_array:
		# Check if find a match in the item name or value
		if item is EditorSproutyDialogsVariableItem:
			var var_data = item.get_variable_data()
			if search_text in var_data.name.to_lower() \
					or search_text in str(var_data.value).to_lower():
				filtered_items.append(item)
				item.show()
		# Check if find a match in the group name or any of its items
		elif item is EditorSproutyDialogsVariableGroup:
			if search_text in item.get_item_name().to_lower():
				filtered_items.append(item)
				item.show()
			else:
				var group_items = _filter_items(item.get_items(), search_text)
				if group_items.size() > 0:
					item.show()
				filtered_items.append_array(group_items)
	return filtered_items


## Filter the portrait tree items
func _on_search_bar_text_changed(new_text: String) -> void:
	var search_text = new_text.strip_edges().to_lower()
	if search_text == "":
		_change_items_visibility(true, _variable_container.get_children())
	else:
		_change_items_visibility(false, _variable_container.get_children())
		_filter_items(_variable_container.get_children(), search_text)


## Change the items visibility
func _change_items_visibility(visible: bool, items: Array) -> void:
	for child in items:
		if child is EditorSproutyDialogsVariableItem:
			child.visible = visible
		elif child is EditorSproutyDialogsVariableGroup:
			child.visible = visible
			_change_items_visibility(visible, child.get_items())

#endregion

## Ensure unique item's name
func _ensure_unique_name(name: String, item: Variant) -> String:
	var group = item.parent_group
	var group_items = []
	
	# Check items in the parent group
	if group is EditorSproutyDialogsVariableGroup:
		group_items = group.get_items().filter(
			func(sub_item): return sub_item != item)
	else: # Check items in the main container
		group_items = _variable_container.get_children().filter(func(sub_item):
			return sub_item != item and (sub_item is EditorSproutyDialogsVariableItem \
				or sub_item is EditorSproutyDialogsVariableGroup))
	
	group_items = group_items.map(func(sub_item): return sub_item.get_item_name())
	var empty_name = "New Variable" if item is EditorSproutyDialogsVariableItem else "New group"
	var unique_name = SproutyDialogsFileUtils.ensure_unique_name(name, group_items, empty_name)
	if unique_name != name:
		item.set_item_name(unique_name)
	return unique_name


## Ensure the variable or group name is unique when renaming an existing one
func _on_item_rename(old_name: String, new_name: String, item: Variant) -> void:
	var unique_name = _ensure_unique_name(new_name, item)
	item.update_path_tooltip()
	
	if item.new_item:
		item.new_item = false
		return # Do not register undo redo
	if unique_name == old_name:
		return # Do not register undo redo
	
	item.mark_as_modified(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Rename "
		+ ("Group" if item is EditorSproutyDialogsVariableGroup else "Variable")
		+" '" + old_name + "' to '" + unique_name + "'")
	undo_redo.add_do_method(item, "set_item_name", unique_name)
	undo_redo.add_undo_method(item, "set_item_name", _ensure_unique_name(old_name, item))
	undo_redo.add_do_method(item, "mark_as_modified", true)
	undo_redo.add_undo_method(item, "mark_as_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Add a new portrait to the tree
func _on_add_var_button_pressed() -> void:
	var new_item = _new_variable_item()
	new_item.parent_group = _variable_container
	_variable_container.add_child(new_item)
	_on_modified(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Add Variable")
	undo_redo.add_do_reference(new_item)
	undo_redo.add_do_method(_variable_container, "add_child", new_item)
	undo_redo.add_undo_method(_variable_container, "remove_child", new_item)
	undo_redo.add_do_method(self , "_on_modified", true)
	undo_redo.add_undo_method(self , "_on_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------
	

## Add a new portrait group to the tree
func _on_add_group_button_pressed() -> void:
	var new_item = _new_variable_group()
	new_item.parent_group = _variable_container
	_variable_container.add_child(new_item)
	_on_modified(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Add Variable Group")
	undo_redo.add_do_reference(new_item)
	undo_redo.add_do_method(_variable_container, "add_child", new_item)
	undo_redo.add_undo_method(_variable_container, "remove_child", new_item)
	undo_redo.add_do_method(self , "_on_modified", true)
	undo_redo.add_undo_method(self , "_on_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle variable changes
func _on_variable_changed(var_data: Dictionary) -> void:
	variable_changed.emit(var_data)


## Save the current variables to the project settings
func _on_save_button_pressed() -> void:
	# Unmark all items as modified
	for child in _variable_container.get_children():
		if child is EditorSproutyDialogsVariableItem or \
			child is EditorSproutyDialogsVariableGroup:
			child.clear_modified_state()
	_modified_counter = 0
	_save_button.text = ""

	# Save the variables to project settings
	var data = _get_variables_data()
	SproutyDialogsSettingsManager.set_setting("variables", data)


## Handle the removal of a variable item
func _on_remove_variable(item: EditorSproutyDialogsVariableItem) -> void:
	var parent = item.get_parent()
	if parent:
		parent.remove_child(item)
		_on_modified(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Remove Variable")
		undo_redo.add_do_method(parent, "remove_child", item)
		undo_redo.add_undo_method(parent, "add_child", item)
		undo_redo.add_undo_reference(item)

		undo_redo.add_do_method(self , "_on_modified", true)
		undo_redo.add_undo_method(self , "_on_modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle the removal of a variable group
func _on_remove_group(group: EditorSproutyDialogsVariableGroup) -> void:
	_remove_group = group
	if not group.get_items().is_empty():
		$RemoveGroupDialog.popup_centered()
	else: # If the group is empty, remove it directly
		_on_confirm_remove_group()


## Handle the confirmation of group removal
func _on_confirm_remove_group() -> void:
	var parent = _remove_group.get_parent()
	if _remove_group and parent:
		parent.remove_child(_remove_group)
		var temp = _remove_group
		_remove_group = null
		_on_modified(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Remove Variable Group")
		undo_redo.add_undo_reference(temp)
		undo_redo.add_do_method(parent, "remove_child", temp)
		undo_redo.add_undo_method(parent, "add_child", temp)
		undo_redo.add_do_method(self , "_on_modified", true)
		undo_redo.add_undo_method(self , "_on_modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the group is empty
func _on_child_order_changed() -> void:
	if _empty_label:
		_empty_label.visible = (_variable_container.get_child_count() == 1)


#region === Drag and Drop ======================================================
func _get_container_drag_data(at_position: Vector2) -> Variant:
	return null


func _can_drop_data_in_container(at_position: Vector2, data: Variant) -> bool:
	return data.has("type")


func _drop_data_in_container(at_position: Vector2, data: Variant) -> void:
	var item = data.item
	var from_group = data.group
	var from_index = from_group.get_children().find(item)
	from_group.remove_child(item)
	_variable_container.add_child(item)
	item.parent_group = _variable_container
	item.update_path_tooltip()
	item.mark_as_modified(true)

	# Emit renamed signal to ensure unique names
	data.item.emit_signal(("group" if data.type == "group" else "variable") + "_renamed",
			data.item.get_item_name(), data.item.get_item_name())

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Move Variable "
		+ ("Group" if data.type == "group" else "Item") + " to Container")
	
	undo_redo.add_do_method(from_group, "remove_child", item)
	undo_redo.add_do_method(_variable_container, "add_child", item)
	undo_redo.add_do_property(item, "parent_group", _variable_container)
	undo_redo.add_do_method(item, "update_path_tooltip")

	undo_redo.add_undo_method(_variable_container, "remove_child", item)
	undo_redo.add_undo_method(from_group, "add_child", item)
	undo_redo.add_undo_method(from_group, "move_child", item, from_index)
	undo_redo.add_do_property(item, "parent_group", from_group)
	undo_redo.add_undo_method(item, "update_path_tooltip")
	undo_redo.add_undo_reference(item)

	undo_redo.add_do_method(item, "mark_as_modified", true)
	undo_redo.add_undo_method(item, "mark_as_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------

#endregion