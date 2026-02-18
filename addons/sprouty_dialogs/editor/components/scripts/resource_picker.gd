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
enum ResourceType {DIALOG_CHAR, DIALOGUE, CHARACTER, PORTRAIT_SCENE, DIALOG_BOX}

## Resource type to load
@export var resource_type: ResourceType = ResourceType.DIALOG_CHAR
## If true, show the icon button without the arrow button
@export var only_icon: bool = false
## If true, a clear button will be added to the popup menu
@export var add_clear_button: bool = false

## File filters for load dialog
var _file_filters: PackedStringArray
## File type to load the last used path
var _recent_file_type: String
## File dialog title
var _dialog_title: String


func _ready() -> void:
	resource_changed.connect(_on_resource_changed)
	remove_child(get_child(1)) # Remove extra space

	if only_icon: # Show the icon button without the arrow button
		get_child(2).icon = get_theme_icon("Load", "EditorIcons")
		remove_child(get_child(1))
	
	set_resource_type(resource_type)


## Set the resource type to load
func set_resource_type(type: ResourceType) -> void:
	resource_type = type
	match type:
		ResourceType.DIALOG_CHAR:
			base_type = "SproutyDialogsDialogueData,SproutyDialogsCharacterData"
			_dialog_title = "Open a File"
			_recent_file_type = "sprouty_files"
			_file_filters = ["*.tres"]
		ResourceType.DIALOGUE:
			base_type = "SproutyDialogsDialogueData"
			_dialog_title = "Open a Dialogue"
			_recent_file_type = "dialogue_files"
			_file_filters = ["*.tres"]
		ResourceType.CHARACTER:
			base_type = "SproutyDialogsCharacterData"
			_dialog_title = "Open a Character"
			_recent_file_type = "character_files"
			_file_filters = ["*.tres"]
		ResourceType.PORTRAIT_SCENE:
			base_type = "PackedScene"
			_dialog_title = "Open a Portrait Scene"
			_recent_file_type = "portrait_files"
			_file_filters = ["*.tscn"]
		ResourceType.DIALOG_BOX:
			base_type = "PackedScene"
			_dialog_title = "Open a Dialog Box Scene"
			_recent_file_type = "dialog_box_files"
			_file_filters = ["*.tscn"]


func _set_create_options(menu_node: Object) -> void:
	if not menu_node.is_connected("id_pressed", _on_popup_id_pressed):
		menu_node.id_pressed.connect(_on_popup_id_pressed)
	if add_clear_button:
		menu_node.add_icon_item(get_theme_icon("Clear", "EditorIcons"), "Clear", 2)
		menu_node.add_separator()
	pass # Avoid new resource options


## Handle when an item from the pop-up menu is pressed
func _on_popup_id_pressed(id: int) -> void:
	match id:
		0: # Load button pressed
			var file_dialog = get_child(get_child_count() - 1)
			file_dialog.set_current_dir(
				SproutyDialogsFileUtils.get_recent_file_path(_recent_file_type))
			file_dialog.filters = _file_filters
			file_dialog.title = _dialog_title
		1: # Quick load button pressed
			pass
		2: # Clear button pressed
			clear_pressed.emit()


## Handle when resources are changed
func _on_resource_changed(res: Resource) -> void:
	SproutyDialogsFileUtils.set_recent_file_path(_recent_file_type, res.resource_path)
	edited_resource = null
	resource_picked.emit(res)