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

## Resource types enum
enum ResourceType {DIALOGUE, CHARACTER, DIALOG_CHAR, SCENE}

## Resource type to search for
@export var resource_type: ResourceType = ResourceType.DIALOG_CHAR
## If true, show the icon button without the arrow button
@export var only_icon: bool = false


func _ready() -> void:
	resource_changed.connect(_on_resource_changed)
	remove_child(get_child(1)) # Remove extra space

	if only_icon: # Show the icon button without the arrow button
		get_child(2).icon = get_theme_icon("Load", "EditorIcons")
		remove_child(get_child(1))
	
	match resource_type:
		ResourceType.DIALOGUE:
			base_type = "SproutyDialogsDialogueData"
		ResourceType.CHARACTER:
			base_type = "SproutyDialogsCharacterData"
		ResourceType.DIALOG_CHAR:
			base_type = "SproutyDialogsDialogueData,SproutyDialogsCharacterData"
		ResourceType.SCENE:
			base_type = "PackedScene"


func _set_create_options(menu_node: Object) -> void:
	pass # Remove new resource options


## Handle when resources are changed
func _on_resource_changed(res: Resource) -> void:
	edited_resource = null
	resource_picked.emit(res)