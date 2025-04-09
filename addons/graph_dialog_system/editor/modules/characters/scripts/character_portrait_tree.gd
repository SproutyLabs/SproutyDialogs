@tool
extends Tree

## Triggered when something is modified
signal modified

## Portrait tree popup menu
@onready var _popup_menu: PopupMenu = $PortraitPopupMenu

## Icon of the character portrait.
var _portrait_icon: Texture2D = preload("res://addons/graph_dialog_system/icons/character.svg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_popup_menu.set_item_icon(0, get_theme_icon('Rename', 'EditorIcons'))
	_popup_menu.set_item_icon(1, get_theme_icon('Duplicate', 'EditorIcons'))
	_popup_menu.set_item_icon(2, get_theme_icon('Remove', 'EditorIcons'))


## Emit the modified signal
func on_modified():
	modified.emit()


## Adds a new portrait item to the tree.
func new_portrait(name: String, data: Dictionary, parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, _portrait_icon)
	item.set_text(0, name)
	item.set_metadata(0, data)
	item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 0, false, 'Remove portrait')
	on_modified()
	return item


## Adds a new portrait group to the tree.
func new_portrait_group(group_name := "Group", parent_item: TreeItem = get_root()) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, get_theme_icon('Folder', 'EditorIcons'))
	item.set_text(0, group_name)
	item.set_metadata(0, {'group': true})
	on_modified()
	return item


## Duplicates a portrait item and adds it to the tree.
func duplicate_portrait_item(item: TreeItem) -> TreeItem:
	var new_item: TreeItem = new_portrait(
		item.get_text(0) + " (copy)",
		item.get_metadata(0),
		item.get_parent()
		)
	new_item.set_editable(0, true)
	new_item.select(0)
	return new_item


## Removes the portrait item from the tree.
func remove_portrait_item(item: TreeItem) -> void:
	if item.get_next_visible(true) and item.get_next_visible(true) != item:
		item.get_next_visible(true).select(0)
	item.free()
	on_modified()


#region === Input Handling ========================================================

## Called when the user right-clicks on a portrait item.
func _on_portrait_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.set_item_disabled(1, get_selected().get_metadata(0).has('group'))
		_popup_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))


## Called when the user selects an item in the popup menu.
func _on_portrait_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # Rename
			get_selected().set_editable(0, true)
			edit_selected()
		1: # Duplicate
			duplicate_portrait_item(get_selected())
		2: # Remove
			remove_portrait_item(get_selected())


## Called when the user edits a portrait item.
func _on_portrait_item_edited() -> void:
	on_modified()


## Called when the user clicks on a portrait item button.
func _on_portrait_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		if id == 0: # Remove button clicked
			remove_portrait_item(item)

#endregion