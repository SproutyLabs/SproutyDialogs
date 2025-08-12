@tool
class_name GraphDialogsVariableGroup
extends Container

# -----------------------------------------------------------------------------
## Variable Group
##
## This class represents a group of variables in the Graph Dialogs editor.
# It allows the user to add, remove, rename and duplicate variable groups.
# -----------------------------------------------------------------------------

## Emitted when the group is renamed
signal group_renamed(name: String)
## Emitted when the remove button is pressed
signal remove_pressed()

## The variable group name
@export var group_name: String = ""
## The variable group color
@export var group_color: Color = Color(1, 1, 1)

## Group name input field
@onready var _name_input: LineEdit = %NameInput
## Expandable button to show/hide items
@onready var _expandable_button: Button = %ExpandableButton
## Items container
@onready var _items_container: VBoxContainer = %ItemsContainer
## Empty label to show when the group is empty
@onready var _empty_label: Label = %EmptyLabel
## Drop highlight
@onready var _drop_highlight: ColorRect = %DropHighlight

var collapse_up_icon: Texture2D = preload("res://addons/graph_dialogs/icons/interactable/collapse-up.svg")
var collapse_down_icon: Texture2D = preload("res://addons/graph_dialogs/icons/interactable/collapse-down.svg")


func _ready() -> void:
	_items_container.child_order_changed.connect(_on_child_order_changed)
	_name_input.editing_toggled.connect(_on_name_changed)
	_expandable_button.toggled.connect(_on_expandable_button_toggled)
	_expandable_button.tooltip_text = "Expand"
	_expandable_button.button_pressed = true
	
	%RemoveButton.pressed.connect(remove_pressed.emit)
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%RemoveButton.tooltip_text = "Remove Group"

	# Drag and drop setup
	%DragButton.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_empty_label.get_child(0).color = get_theme_color("accent_color", "Editor")
	_on_mouse_exited() # Hide the drop highlight
	_on_name_changed(false) # Initialize the name input field


## Returns all items in the group
func get_items() -> Array:
	return _items_container.get_children().filter(func(item):
		return item is GraphDialogsVariableItem or item is GraphDialogsVariableGroup)


## Show all the items in the group
func show_items() -> void:
	for item in _items_container.get_children():
		if item is GraphDialogsVariableItem or item is GraphDialogsVariableGroup:
			item.show()


## Rename the group
func rename(new_name: String) -> void:
	group_name = new_name
	_name_input.text = new_name


## Show modified indicator for all items in the group
func show_modified_indicator(show: bool) -> void:
	for item in _items_container.get_children():
		if item is GraphDialogsVariableItem or item is GraphDialogsVariableGroup:
			item.show_modified_indicator(show)


## Handle the name change event
func _on_name_changed(toggled_on: bool) -> void:
	if toggled_on: return # Ignore when editing starts
	var new_name = _name_input.text.strip_edges()
	if new_name == "": new_name = "New Group"
	group_name = new_name
	group_renamed.emit(group_name)


## Handle the expandable button toggled event
func _on_expandable_button_toggled(is_pressed: bool) -> void:
	_items_container.get_parent().visible = is_pressed
	_expandable_button.icon = collapse_up_icon if is_pressed else collapse_down_icon
	_expandable_button.tooltip_text = "Collapse" if is_pressed else "Expand"


## Handle when the group is empty
func _on_child_order_changed() -> void:
	_empty_label.visible = (_items_container.get_child_count() == 1)


#region === Drag and Drop ======================================================

## Show the drop highlight above or below the last item
func show_drop_highlight(above: bool) -> void:
	if _items_container.get_child_count() > 1:
		_items_container.get_child(-1).show_drop_highlight(above)
	elif _empty_label.is_visible():
		_empty_label.get_child(0).show() # Show label highlight
	_drop_highlight.show()


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
	if can: show_drop_highlight(false)
	return can


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_on_mouse_exited() # Hide the drop highlight
	_drop_highlight.hide()

	var item = data.item
	var to_group = _items_container
	var from_group = data.group
	from_group.remove_child(item)
	to_group.add_child(data.item)


## Handle mouse exit event to hide drop highlight
func _on_mouse_exited() -> void:
	_empty_label.get_child(0).hide()
	_drop_highlight.hide()
#endregion