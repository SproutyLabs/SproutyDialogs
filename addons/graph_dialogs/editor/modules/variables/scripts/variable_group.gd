@tool
class_name GraphDialogsVariableGroup
extends Container

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
## The variable group color
@export var group_color: Color = Color(1, 1, 1)

## Items container
@onready var _items_container: VBoxContainer = %ItemsContainer

var collapse_up_icon: Texture2D = preload("res://addons/graph_dialogs/icons/interactable/collapse-up.svg")
var collapse_down_icon: Texture2D = preload("res://addons/graph_dialogs/icons/interactable/collapse-down.svg")


func _ready() -> void:
	%RemoveButton.pressed.connect(remove_pressed.emit.bind(group_name))
	%ExpandableButton.toggled.connect(_on_expandable_button_toggled)
	%GroupName.text_changed.connect(_on_name_changed)

	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%RemoveButton.tooltip_text = "Remove Group"
	%ExpandableButton.tooltip_text = "Expand"
	%ExpandableButton.button_pressed = true

	$%DragButton.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	mouse_filter = Control.MOUSE_FILTER_PASS


## Handle the name change event
func _on_name_changed(new_name: String) -> void:
	group_name = new_name
	group_changed.emit(group_name)
	print("Variable group changed: ", group_name)


## Handle the expandable button toggled event
func _on_expandable_button_toggled(is_pressed: bool) -> void:
	_items_container.get_parent().visible = is_pressed
	%ExpandableButton.icon = collapse_up_icon if is_pressed else collapse_down_icon
	%ExpandableButton.tooltip_text = "Collapse" if is_pressed else "Expand"


#region === Drag and Drop ======================================================

## Show the drop highlight below the last item
func show_drop_highlight(_above: bool) -> void:
	_items_container.get_child(-1).show_drop_highlight(false)


func _get_drag_data(at_position: Vector2) -> Variant:
	var preview = Label.new()
	preview.text = "Dragging: " + group_name + " (Group)"
	set_drag_preview(preview)
	var data = {
	    "item": self,
		"group": get_parent(),
	    "type": "group"
	}
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var can = data.has("type") and data.item != self
	if can: _items_container.get_child(-1).show_drop_highlight(false)
	return can


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item = data.item
	var to_group = _items_container
	var from_group = data.group
	from_group.remove_child(item)
	to_group.add_child(data.item)

#endregion