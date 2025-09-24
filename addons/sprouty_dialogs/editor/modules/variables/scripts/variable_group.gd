@tool
class_name EditorSproutyDialogsVariableGroup
extends Container

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Group Component
# -----------------------------------------------------------------------------
## This class represents a group of variables in the Sprouty Dialogs editor.
## It allows the user to set the group name and color, and contains variable items.
# -----------------------------------------------------------------------------

## Emitted when the group is renamed
signal group_renamed(name: String)
## Emitted when the remove button is pressed
signal remove_pressed()

## The variable group name
@export var _group_name: String = ""
## The variable group color
@export var _group_color: Color = Color(1, 1, 1)

## Group name input field
@onready var _name_input: LineEdit = %NameInput
## Color picker for selecting group color
@onready var _color_picker: ColorPickerButton = %ColorPicker
## Expandable button to show/hide items
@onready var _expandable_button: Button = %ExpandableButton

## Items container
@onready var _items_container: VBoxContainer = %ItemsContainer
## Drop highlight
@onready var _drop_highlight: ColorRect = %DropHighlight
## Empty label to show when the group is empty
@onready var _empty_label: Label = %EmptyLabel

## Collapse icons for the expandable button
var _collapse_up_icon: Texture2D = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var _collapse_down_icon: Texture2D = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

## Preloaded style for the group
var _group_style: StyleBoxFlat = preload("res://addons/sprouty_dialogs/editor/theme/variable_group_subpanel.tres")

## Parent group of the item
var parent_group: Node = null


func _ready() -> void:
	_items_container.child_order_changed.connect(_on_child_order_changed)
	_name_input.editing_toggled.connect(_on_name_changed)
	_color_picker.color_changed.connect(_on_color_changed)
	_expandable_button.toggled.connect(_on_expandable_button_toggled)
	_expandable_button.tooltip_text = "Expand Group"
	_expandable_button.button_pressed = true
	
	%RemoveButton.pressed.connect(remove_pressed.emit)
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%RemoveButton.tooltip_text = "Remove Group"

	# Drag and drop setup
	%DragButton.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set highlight and group initial colors
	_empty_label.get_child(0).color = get_theme_color("accent_color", "Editor")
	_color_picker.color = get_theme_color("accent_color", "Editor")
	_on_color_changed(_color_picker.color) # Set initial color

	show_as_modified(false) # Initialize the modified indicator
	_on_name_changed(false) # Initialize the name input field
	_on_mouse_exited() # Hide the drop highlight


## Return the group path in the variables tree
func get_item_path() -> String:
	if parent_group is EditorSproutyDialogsVariableGroup:
		return parent_group.get_item_path() + "/" + _group_name
	else:
		return _group_name


## Returns the group name
func get_item_name() -> String:
	return _group_name


## Set the group name
func set_item_name(new_name: String) -> void:
	_group_name = new_name
	_name_input.text = new_name
	update_path_tooltip()
	for item in get_items():
		item.update_path_tooltip()


## Returns the group color
func get_color() -> Color:
	return _group_color


## Set the group color
func set_color(new_color: Color) -> void:
	_color_picker.color = new_color
	_on_color_changed(new_color)
	show_as_modified(false)


## Returns all items in the group
func get_items() -> Array:
	return _items_container.get_children().filter(func(item):
		return item is EditorSproutyDialogsVariableItem or item is EditorSproutyDialogsVariableGroup)


## Add an item to the group
## The item can be a EditorSproutyDialogsVariableItem or another EditorSproutyDialogsVariableGroup
func add_item(item: Node) -> void:
	_items_container.add_child(item)


## Show all the items in the group
func show_items() -> void:
	for item in _items_container.get_children():
		if item is EditorSproutyDialogsVariableItem or item is EditorSproutyDialogsVariableGroup:
			item.show()


## Show modified indicator for all items in the group
func show_items_as_modified(show: bool) -> void:
	for item in _items_container.get_children():
		if item is EditorSproutyDialogsVariableItem or item is EditorSproutyDialogsVariableGroup:
			item.show_as_modified(show)


## Show the modified indicator for the group
func show_as_modified(show: bool) -> void:
	%ModifiedIndicator.visible = show


## Update the tooltip with the current group path
func update_path_tooltip() -> void:
	var path = get_item_path()
	_name_input.tooltip_text = path


## Handle the name change event
func _on_name_changed(toggled_on: bool) -> void:
	if toggled_on: return # Ignore when editing starts
	var new_name = _name_input.text.strip_edges()
	if new_name == "": new_name = "New Group"
	_group_name = new_name
	group_renamed.emit(_group_name)
	show_as_modified(true)
	update_path_tooltip()
	for item in get_items():
		item.update_path_tooltip()


## Handle the color change event
func _on_color_changed(new_color: Color) -> void:
	var style = _group_style.duplicate()
	style.border_color = new_color
	$Container/Header/Bar.add_theme_stylebox_override("panel", style)
	$Container/SubPanel.add_theme_stylebox_override("panel", style)
	_group_color = new_color
	show_as_modified(true)


## Handle the expandable button toggled event
func _on_expandable_button_toggled(is_pressed: bool) -> void:
	$Container/LastSeparator.visible = is_pressed
	_items_container.get_parent().visible = is_pressed
	_expandable_button.icon = _collapse_up_icon if is_pressed else _collapse_down_icon
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
	preview.text = "Dragging: " + _group_name + " (Group)"
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
	data.item.parent_group = self
	data.item.update_path_tooltip()


## Handle mouse exit event to hide drop highlight
func _on_mouse_exited() -> void:
	_empty_label.get_child(0).hide()
	_drop_highlight.hide()

#endregion