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

	%AddVarButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddFolderButton.icon = get_theme_icon("Folder", "EditorIcons")
	%SearchBar.right_icon = get_theme_icon("Search", "EditorIcons")

	_variables_container.set_drag_forwarding(
		_get_drag_data, _can_drop_data, _drop_data
	)


## Add a new portrait to the tree
func _on_add_var_button_pressed() -> void:
	var new_var = _variable_item_scene.instantiate()
	_variables_container.add_child(new_var)


## Add a new portrait group to the tree
func _on_add_folder_button_pressed() -> void:
	var new_group = _variable_group_scene.instantiate()
	_variables_container.add_child(new_group)


## Filter the portrait tree items
func _on_search_bar_text_changed(new_text: String) -> void:
	pass


#region === Drag and Drop ======================================================
func _get_drag_data(at_position: Vector2) -> Variant:
	return null


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data.has("type")


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item = data.item
	var from_group = data.group
	from_group.remove_child(item)
	_variables_container.add_child(item)

#endregion