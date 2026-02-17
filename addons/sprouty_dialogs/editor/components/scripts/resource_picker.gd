@tool
class_name EditorSproutyDialogsResourcePicker
extends EditorResourcePicker

# -----------------------------------------------------------------------------
# Sprouty Dialogs Resource Picker Component
# -----------------------------------------------------------------------------
## Component that allows to pick a dialogue, character or scene resource.
# -----------------------------------------------------------------------------

## Emitted when a resource is picked (changed)
## Use it instead of resource_changed
signal resource_picked(res: Resource)
## Emitted when the clear button is pressed
signal clear_pressed

## Resource types enum
enum ResourceType {DIALOG_CHAR, DIALOGUE, CHARACTER, SCENE}

## Resource type to search for
@export var resource_type: ResourceType = ResourceType.DIALOG_CHAR
## If true, show the icon button without the arrow button
@export var only_icon: bool = false
## If true, a clear button will be added to the popup menu
@export var add_clear_button: bool = false

## The options popup menu
var popup_menu: Object


func _ready() -> void:
	resource_changed.connect(_on_resource_changed)
	remove_child(get_child(1)) # Remove extra space

	if only_icon: # Show the icon button without the arrow button
		get_child(2).icon = get_theme_icon("Load", "EditorIcons")
		remove_child(get_child(1))

	match resource_type:
		ResourceType.DIALOG_CHAR:
			base_type = "SproutyDialogsDialogueData,SproutyDialogsCharacterData"
		ResourceType.DIALOGUE:
			base_type = "SproutyDialogsDialogueData"
		ResourceType.CHARACTER:
			base_type = "SproutyDialogsCharacterData"
		ResourceType.SCENE:
			base_type = "PackedScene"


func _set_create_options(menu_node: Object) -> void:
	if add_clear_button:
		menu_node.add_icon_item(get_theme_icon("Clear", "EditorIcons"), "Clear", 3)
		menu_node.add_separator()
		if not menu_node.is_connected("id_pressed", _on_popup_id_pressed):
			menu_node.id_pressed.connect(_on_popup_id_pressed)
		popup_menu = menu_node
	pass # Avoid new resource options


func _on_popup_id_pressed(id: int) -> void:
	match id:
		3: # Clear button selected
			clear_pressed.emit()


## Handle when resources are changed
func _on_resource_changed(res: Resource) -> void:
	edited_resource = null
	resource_picked.emit(res)