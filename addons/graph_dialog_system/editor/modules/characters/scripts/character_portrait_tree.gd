@tool
extends Tree

## Triggered when something is modified
signal modified

## Portrait tree popup menu
@onready var _popup_menu: PopupMenu = $PortraitPopupMenu

## Icon of the character portrait
var _portrait_icon: Texture2D = preload("res://addons/graph_dialog_system/icons/character.svg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_popup_menu.set_item_icon(0, get_theme_icon('Rename', 'EditorIcons'))
	_popup_menu.set_item_icon(1, get_theme_icon('Duplicate', 'EditorIcons'))
	_popup_menu.set_item_icon(2, get_theme_icon('Remove', 'EditorIcons'))
	create_item() # Create the root item
	

## Emit the modified signal
func on_modified():
	modified.emit()


## Adds a new portrait item to the tree
func new_portrait_item(name: String, data: Dictionary, parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, _portrait_icon)
	item.set_text(0, name)
	item.set_metadata(0, data)
	item.set_meta('item_path', get_item_path(item))
	item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 0, false, 'Remove portrait')
	return item


## Adds a new portrait group to the tree
func new_portrait_group(group_name := "Group", parent_item: TreeItem = get_root()) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, get_theme_icon('Folder', 'EditorIcons'))
	item.set_text(0, group_name)
	item.set_metadata(0, {'group': true})
	item.set_meta('item_path', get_item_path(item))
	return item


## Duplicates a portrait item and adds it to the tree
func duplicate_portrait_item(item: TreeItem) -> TreeItem:
	var new_item: TreeItem = new_portrait_item(
		item.get_text(0) + " (copy)",
		item.get_metadata(0),
		item.get_parent()
		)
	item.set_editable(0, true)
	item.select(0)
	on_modified()
	return new_item


## Removes the portrait item from the tree
func remove_portrait_item(item: TreeItem) -> void:
	if item.get_next_visible(true) and item.get_next_visible(true) != item:
		item.get_next_visible(true).select(0)
	item.free()
	on_modified()


## Renames the portrait item
func rename_portrait_item(item: TreeItem) -> void:
	item.set_editable(0, true)
	item.select(0)


## Get the path of the item in the tree
## The path is a string with the format "Group/Item"
func get_item_path(item: TreeItem) -> String:
	var item_name := item.get_text(0)
	while item.get_parent() != get_root() and item != get_root():
		item_name = item.get_parent().get_text(0) + "/" + item_name
		item = item.get_parent()
	return item_name

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

	if to_item.get_metadata(0).has('group') and drop_section == 1:
		parent = to_item

	var new_item := copy_tree_item(item, parent)
	
	if !to_item.get_metadata(0).has('group') and drop_section == 1:
		new_item.move_after(to_item)

	if drop_section == -1:
		new_item.move_before(to_item)

	item.free() # Free the original item


# Create a copy of the item and its children (if is a group)
func copy_tree_item(item: TreeItem, new_parent: TreeItem) -> TreeItem:
	var new_item: TreeItem = null
	if item.get_metadata(0).has('group'):
		new_item = new_portrait_group(item.get_text(0), new_parent)
	else:
		new_item = new_portrait_item(item.get_text(0), item.get_metadata(0), new_parent)
	
	for child in item.get_children():
		copy_tree_item(child, new_item)
	return new_item

#endregion

#region === Input Handling =====================================================
## Called when the user right-clicks on a portrait item
func _on_portrait_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.set_item_disabled(1, get_selected().get_metadata(0).has('group'))
		_popup_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))


## Called when the user double-clicks on a portrait item
func _on_portrait_item_activated() -> void:
	rename_portrait_item(get_selected())


## Called when the user selects an item in the popup menu
func _on_portrait_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # Rename
			rename_portrait_item(get_selected())
		1: # Duplicate
			duplicate_portrait_item(get_selected())
		2: # Remove
			remove_portrait_item(get_selected())


## Called when the user clicks on a portrait item button
func _on_portrait_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		if id == 0: # Remove button clicked
			remove_portrait_item(item)

#endregion
