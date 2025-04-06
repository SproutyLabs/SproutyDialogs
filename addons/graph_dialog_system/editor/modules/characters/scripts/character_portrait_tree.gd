@tool
extends Tree

## Portrait tree popup menu
@onready var _popup_menu: PopupMenu = $PortraitPopupMenu

## Icon of the character portrait.
var _portrait_icon: Texture2D = preload("res://addons/graph_dialog_system/icons/character.svg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_popup_menu.set_item_icon(0, get_theme_icon('Rename', 'EditorIcons'))
	_popup_menu.set_item_icon(1, get_theme_icon('Duplicate', 'EditorIcons'))
	_popup_menu.set_item_icon(2, get_theme_icon('Remove', 'EditorIcons'))

## Adds a new portrait item to the tree.
func new_portrait(name: String, data: Dictionary, parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, _portrait_icon)
	item.set_text(0, name)
	item.set_metadata(0, data)
	item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 0, false, 'Remove portrait')
	return item

## Adds a new portrait group to the tree.
func new_portrait_group(group_name := "Group", parent_item: TreeItem = get_root()) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, get_theme_icon('Folder', 'EditorIcons'))
	item.set_text(0, group_name)
	item.set_metadata(0, {'group': true})
	return item