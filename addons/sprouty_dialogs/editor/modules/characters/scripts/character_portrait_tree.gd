@tool
extends Tree

# -----------------------------------------------------------------------------
# Character Portrait Tree
# -----------------------------------------------------------------------------
## This module is responsible for the character portrait tree.
## It allows the user to add, remove, rename and duplicate portraits.
# -----------------------------------------------------------------------------

## Triggered when the user selects an item
signal portrait_item_selected(item: TreeItem)

## Character editor reference
@onready var _character_editor: Container = find_parent("CharacterEditor")
## Portrait tree popup menu
@onready var _popup_menu: PopupMenu = $PortraitPopupMenu
## Confirmation dialog for removing a portrait group
@onready var _remove_group_dialog: ConfirmationDialog = $RemoveGroupDialog

## Icon of the character portrait
var _portrait_icon: Texture2D = preload("res://addons/sprouty_dialogs/editor/icons/character.svg")


func _ready() -> void:
	_popup_menu.set_item_icon(0, get_theme_icon("Rename", "EditorIcons"))
	_popup_menu.set_item_icon(1, get_theme_icon("Duplicate", "EditorIcons"))
	_popup_menu.set_item_icon(2, get_theme_icon("Remove", "EditorIcons"))
	create_item() # Create the root item


## Get the portrait data from the tree
func get_portraits_data(from: TreeItem = get_root()) -> Dictionary:
	var data := {}
	for item in from.get_children():
		if item.get_metadata(0).has("group"):
			data[item.get_text(0)] = get_portraits_data(item)
		else:
			data[item.get_text(0)] = item.get_meta("portrait_editor").get_portrait_data()
	return data


## Load the portrait data into the tree
func load_portraits_data(data: Dictionary, parent_item: TreeItem = get_root()) -> void:
	if not data:
		return # If the data is empty, do nothing
	
	for item in data.keys():
		if data[item] is SproutyDialogsPortraitData:
			# If the item is a portrait, create it and load its data
			var editor = _character_editor.portrait_editor_scene.instantiate()
			add_child(editor)
			new_portrait_item(item, data[item], parent_item, editor)
			editor.load_portrait_data(item, data[item])
			remove_child(editor)
		else:
			# If the item is a group, create it and load its children
			var group_item: TreeItem = new_portrait_group(item, parent_item)
			load_portraits_data(data[item], group_item)


## Adds a new portrait item to the tree
func new_portrait_item(name: String, data: SproutyDialogsPortraitData,
		parent_item: TreeItem, portrait_editor: Node) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, _portrait_icon)
	item.set_text(0, name)
	item.set_metadata(0, {"portrait": data})
	item.set_meta("item_path", get_item_path(item))
	item.set_meta("portrait_editor", portrait_editor)
	item.add_button(0, get_theme_icon("Remove", "EditorIcons"), 0, false, "Remove portrait")
	return item


## Adds a new portrait group to the tree
func new_portrait_group(group_name := "Group", parent_item: TreeItem = get_root()) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	item.set_text(0, group_name)
	item.set_metadata(0, {"group": true})
	item.set_meta("item_path", get_item_path(item))
	item.add_button(0, get_theme_icon("Remove", "EditorIcons"), 1, false, "Remove Group")
	return item


## Duplicates a portrait item and adds it to the tree
func duplicate_portrait_item(item: TreeItem) -> TreeItem:
	var new_item: TreeItem = new_portrait_item(
		item.get_text(0) + " (copy)",
		item.get_metadata(0),
		item.get_parent(),
		item.get_meta("portrait_editor")
		)
	item.set_editable(0, true)
	item.select(0)
	_character_editor.on_modified()
	return new_item


## Removes the portrait item from the tree
func remove_portrait_item(item: TreeItem) -> void:
	if item.get_next_visible(true) and item.get_next_visible(true) != item:
		item.get_next_visible(true).select(0)
	item.free()
	_character_editor.on_modified()
	# If the tree is empty, hide the portrait editor panel
	if get_root().get_children().size() == 0:
		_character_editor.show_portrait_editor_panel(false)


## Removes the portrait group and all its children from the tree
func remove_portrait_group(item: TreeItem) -> void:
	for child in item.get_children():
		child.free()
	remove_portrait_item(item) # Remove the group item itself


## Renames the portrait item
func rename_portrait_item(item: TreeItem) -> void:
	item.set_editable(0, true)
	call_deferred("edit_selected")


## Check if the name is already in use
func check_existing_name(name: String, checked_item: TreeItem) -> bool:
	for item in get_root().get_children():
		if item == checked_item:
			continue # Skip the item being checked
		if item.get_text(0) == name:
			return true
	return false


## Get the path of the item in the tree
## The path is a string with the format "Group/Item"
func get_item_path(item: TreeItem) -> String:
	var item_name := item.get_text(0)
	while item.get_parent() != get_root() and item != get_root():
		item_name = item.get_parent().get_text(0) + "/" + item_name
		item = item.get_parent()
	return item_name


## Filters the tree items based on the search term
func filter_branch(parent: TreeItem, filter: String) -> bool:
	var match_found := false
	for item in parent.get_children():
		# Check if the item name matches the filter
		var match_filter = filter.to_lower() in item.get_text(0).to_lower()
		var filter_in_group = false

		# If the item is a group, check if any of its children match the filter
		if item.get_metadata(0).has("group") and not match_filter:
			filter_in_group = filter_branch(item, filter)
		
		item.visible = match_filter or filter.is_empty() or filter_in_group

		if item.visible: # If the item is visible, check that found a match
			match_found = true
	return match_found


#region === Drag and Drop ======================================================

## Get the drag data when dragging an item, returns the item being dragged
func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_item := get_item_at_position(at_position)
	if not drag_item:
		return null

	var preview := Label.new()
	preview.text = drag_item.get_text(0)
	preview.add_theme_stylebox_override("normal",
		get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)
	return drag_item


## Set when can drag data
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = DROP_MODE_INBETWEEN
	return data is TreeItem


## Called when the item is dropped
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var to_item := get_item_at_position(at_position)
	var item := data as TreeItem

	if item == null or to_item == null:
		return
	else:
		# Check if the item is a child of the target item
		var aux := to_item
		while true:
			if aux == item: # Dropping inside itself
				return # Prevent infinite loops
			aux = aux.get_parent()
			if aux == get_root():
				break
	
	var drop_section := get_drop_section_at_position(at_position)
	var parent := to_item.get_parent()

	if to_item.get_metadata(0).has("group") and drop_section == 1:
		parent = to_item

	var new_item := copy_tree_item(item, parent)
	
	if !to_item.get_metadata(0).has("group") and drop_section == 1:
		new_item.move_after(to_item)

	if drop_section == -1:
		new_item.move_before(to_item)

	item.free() # Free the original item
	_character_editor.on_modified()


# Create a copy of the item and its children (if is a group)
func copy_tree_item(item: TreeItem, new_parent: TreeItem) -> TreeItem:
	var new_item: TreeItem = null
	if item.get_metadata(0).has("group"):
		new_item = new_portrait_group(item.get_text(0), new_parent)
	else:
		new_item = new_portrait_item(
			item.get_text(0),
			item.get_metadata(0),
			new_parent,
			item.get_meta("portrait_editor")
			)
	
	for child in item.get_children():
		copy_tree_item(child, new_item)
	return new_item

#endregion

#region === Input Handling =====================================================

## Called when the user right-clicks on a portrait item
func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.set_item_disabled(1, get_selected().get_metadata(0).has("group"))
		_popup_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))


## Called when the user selects a portrait item
func _on_item_selected() -> void:
	portrait_item_selected.emit(get_selected())


## Called when the user double-clicks on a portrait item
func _on_item_activated() -> void:
	rename_portrait_item(get_selected())


## Called when the user edits a portrait item
func _on_item_edited() -> void:
	var item := get_selected()
	
	# If the name is empty, set it to "Unnamed"
	if item.get_text(0).strip_edges() == "":
		item.set_text(0, "Unnamed")
		return

	# If the name is already in use, add a suffix to the name
	if check_existing_name(item.get_text(0), item):
		var suffix := 1
		var name := item.get_text(0).strip_edges() + " (" + str(suffix) + ")"
		# If new the name is already in use, increment the suffix value
		while check_existing_name(name, item):
			name = item.get_text(0).strip_edges() + " (" + str(suffix) + ")"
			suffix += 1
		item.set_text(0, name)
	
	if not item.get_metadata(0).has("group"): # Update the portrait name
		item.get_meta("portrait_editor").set_portrait_name(item.get_text(0))
	_character_editor.on_modified()


## Called when the user selects an item in the popup menu
func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # Rename
			rename_portrait_item(get_selected())
		1: # Duplicate
			duplicate_portrait_item(get_selected())
		2: # Remove
			remove_portrait_item(get_selected())


## Called when the user clicks on a portrait item button
func _on_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		if id == 0: # Remove item button clicked
			remove_portrait_item(item)
		if id == 1: # Remove group button clicked
			if item.get_children().size() > 0:
				# If the group has children, show a confirmation dialog
				_remove_group_dialog.confirmed.connect(remove_portrait_group.bind(item))
				_remove_group_dialog.popup_centered()
			else:
				remove_portrait_item(item)
#endregion
