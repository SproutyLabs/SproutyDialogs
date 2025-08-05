@tool
class_name GraphDialogsVariableGroup
extends PanelContainer

# -----------------------------------------------------------------------------
## Variable Group
##
## This class represents a group of variables in the Graph Dialogs editor.
# It allows the user to add, remove, rename and duplicate variable groups.
# -----------------------------------------------------------------------------

## Emitted when the variable group is changed
signal group_changed(name: String)
## Emitted when the remove button is pressed
signal remove_pressed(variable_name: String)

## The variable group name
@export var group_name: String = "New Group"


func _ready() -> void:
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%RemoveButton.pressed.connect(remove_pressed.emit.bind(group_name))
	%ExpandableButton.toggled.connect(_on_expandable_button_toggled)
	%GroupName.text_changed.connect(_on_name_changed)


## Handle the name change event
func _on_name_changed(new_name: String) -> void:
	group_name = new_name
	group_changed.emit(group_name)
	print("Variable group changed: ", group_name)


## Handle the expandable button toggled event
func _on_expandable_button_toggled(is_pressed: bool) -> void:
	%SubPanel.visible = is_pressed
