@tool
extends PanelContainer

## File manager reference
@export var _file_manager: Container
## Empty panel reference
@onready var _empty_panel: Panel = $EmptyPanel


func _ready() -> void:
	show_start_panel()
	%NewCharacterButton.icon = get_theme_icon("Add", "EditorIcons")
	%OpenCharacterButton.icon = get_theme_icon("Folder", "EditorIcons")


## Get the current character editor panel
func get_current_character_panel() -> Container:
	if get_child_count() > 1:
		return get_child(1)
	return null


## Switch the current character editor panel
func switch_current_character_panel(new_panel: Container) -> void:
	# Remove old panel and switch to the new one
	if get_child_count() > 1:
		remove_child(get_child(1))
	add_child(new_panel)


#region === UI Panel Handling ==================================================

## Show the start panel instead of character panel
func show_start_panel() -> void:
	$CharacterPanel.visible = false
	_empty_panel.visible = true


## Show the character panel
func show_character_panel() -> void:
	$CharacterPanel.visible = true
	_empty_panel.visible = false
#endregion

#region === Start panel Handling ===============================================

## Show dialog to open a dialog file
func _on_open_character_file_pressed() -> void:
	_file_manager.select_file_to_open()

## Show dialog to create a new dialog file
func _on_new_character_file_pressed() -> void:
	_file_manager.select_new_character_file()
#endregion