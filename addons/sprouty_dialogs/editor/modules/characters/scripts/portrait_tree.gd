@tool
extends Tree

# -----------------------------------------------------------------------------
# Portrait Tree
# -----------------------------------------------------------------------------
## This module is responsible for the character portrait tree.
## It allows the user to add, remove, rename and duplicate portraits.
# -----------------------------------------------------------------------------

## Emitted when the portrait data is modified
signal modified(modified: bool)
## Triggered when the user selects an item
signal portrait_item_selected(item: TreeItem)
## Emitted to show/hide the portrait editor panel
signal show_portrait_editor_panel(show: bool)

## Emitted when the portrait list is changed
signal portrait_list_changed
## Emitted when the path of a portrait is changed
signal portrait_path_changed(new_path: String, prev_path: String)

## Portrait tree popup menu
@onready var _popup_menu: PopupMenu = $PortraitPopupMenu
## Confirmation dialog for removing a portrait group
@onready var _remove_group_dialog: ConfirmationDialog = $RemoveGroupDialog

## Icon of the character portrait
var _portrait_icon: Texture2D = preload("res://addons/sprouty_dialogs/editor/icons/character.svg")

## Data of the item being renamed
var renaming_item: Dictionary = {
	"item": null,
	"prev_path": ""
}

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	# Connect tree signals
	item_mouse_selected.connect(_on_item_mouse_selected)
	button_clicked.connect(_on_item_button_clicked)
	item_activated.connect(_on_item_activated)
	item_selected.connect(_on_item_selected)
	item_edited.connect(_on_item_edited)

	# Set up popup menu
	_popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	_popup_menu.set_item_icon(0, get_theme_icon("Rename", "EditorIcons"))
	_popup_menu.set_item_icon(1, get_theme_icon("Duplicate", "EditorIcons"))
	_popup_menu.set_item_icon(2, get_theme_icon("Remove", "EditorIcons"))
	create_item() # Create the root item


#region === Portrait Data ======================================================

## Returns the portrait data from the tree
func get_portraits_data(from: TreeItem = get_root()) -> Dictionary:
	var data := {}
	for item in from.get_children():
		if item.get_metadata(0).has("group"):
			data[item.get_text(0)] = {
				"index": item.get_index(),
				"data": get_portraits_data(item)
			}
		else:
			data[item.get_text(0)] = {
				"index": item.get_index(),
				"data": item.get_meta("portrait_editor").get_portrait_data()
			}
	return data


## Load the portrait data into the tree
func load_portraits_data(
		data: Dictionary,
		portrait_editor_scene: PackedScene,
		parent_item: TreeItem = get_root()) -> void:
	if not data:
		return # If the data is empty, do nothing
	
	# Sort keys by their index value
	var sorted_keys := data.keys()
	sorted_keys.sort_custom(func(a, b):
		return data[a]["index"] < data[b]["index"]
	)
	for item in sorted_keys:
		if data[item].data is SproutyDialogsPortraitData:
			# If the item is a portrait, create it and load its data
			var editor = portrait_editor_scene.instantiate()
			add_child(editor)
			var portrait = new_portrait_item(item, data[item].data, parent_item, editor, false)
			editor.load_portrait_data(item, data[item].data)
			remove_child(editor)
		else:
			# If the item is a group, create it and load its children
			var group_item: TreeItem = new_portrait_group(item, parent_item, false)
			load_portraits_data(data[item].data, portrait_editor_scene, group_item)

#endregion

## Returns a list of all the portrait paths
func get_portrait_list(from: TreeItem = get_root()) -> Array:
	var portraits = []
	for item in from.get_children():
		if not item.get_metadata(0).has("group"):
			# If it's a portrait, add its path
			portraits.append(get_item_path(item))
		else: # If it's a group, recursively get portraits from the group
			portraits.append_array(get_portrait_list(item))
	return portraits


## Adds a new portrait item to the tree
func new_portrait_item(name: String, data: SproutyDialogsPortraitData, parent_item: TreeItem,
		portrait_editor: EditorSproutyDialogsPortraitEditor, new_item: bool = true) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	portrait_editor.modified.connect(modified.emit)
	portrait_editor.undo_redo = undo_redo
	item.set_icon(0, _portrait_icon)
	item.set_text(0, name)
	item.set_meta("name", name)
	item.set_meta("new_item", new_item)
	item.set_metadata(0, {"portrait": data})
	item.set_meta("item_path", get_item_path(item))
	item.set_meta("portrait_editor", portrait_editor)
	item.add_button(0, get_theme_icon("Remove", "EditorIcons"), 0, false, "Remove portrait")
	return item


## Adds a new portrait group to the tree
func new_portrait_group(name: String, parent_item: TreeItem = get_root(), new_item: bool = true) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	item.set_text(0, name)
	item.set_meta("name", name)
	item.set_meta("new_item", new_item)
	item.set_metadata(0, {"group": true})
	item.set_meta("item_path", get_item_path(item))
	item.add_button(0, get_theme_icon("Remove", "EditorIcons"), 1, false, "Remove Group")
	return item


## Duplicates a portrait item and adds it to the tree
func duplicate_portrait_item(item: TreeItem) -> TreeItem:
	var new_editor = item.get_meta("portrait_editor").duplicate()
	var new_name = item.get_text(0) + " (copy)"
	var new_item: TreeItem = new_portrait_item(
		new_name,
		item.get_metadata(0)["portrait"],
		item.get_parent(),
		new_editor
		)
	new_editor.ready.connect(
		new_editor.load_portrait_data.bind(new_name, item.get_metadata(0)["portrait"]))
	new_item.set_editable(0, true)
	new_item.select(0)

	portrait_list_changed.emit()
	modified.emit(true)

	# --- UndoRedo -----------------------------------------------------
	var parent := item.get_parent()
	undo_redo.create_action("Duplicate Portrait")
	undo_redo.add_do_reference(new_item)
	undo_redo.add_do_method(parent, "add_child", new_item)
	undo_redo.add_undo_method(parent, "remove_child", new_item)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.add_do_method(self, "emit_signal", "portrait_list_changed")
	undo_redo.add_undo_method(self, "emit_signal", "portrait_list_changed")
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------
	return new_item


## Removes a portrait or group from the tree
func remove_portrait_item(item: TreeItem) -> void:
	# Select the next visible item before removing the current one
	var next_item := item.get_next_visible(true)
	if next_item and next_item != item:
		next_item.select(0)
	var parent := item.get_parent()
	parent.remove_child(item)

	portrait_list_changed.emit()
	modified.emit(true)

	# If the tree is empty, hide the portrait editor panel
	if get_root().get_children().size() == 0:
		show_portrait_editor_panel.emit(false)
	
	# --- UndoRedo -----------------------------------------------------
	undo_redo.create_action("Remove Portrait")
	undo_redo.add_undo_reference(item)
	undo_redo.add_do_method(parent, "remove_child", item)
	undo_redo.add_undo_method(parent, "add_child", item)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.add_do_method(self, "emit_signal", "portrait_list_changed")
	undo_redo.add_undo_method(self, "emit_signal", "portrait_list_changed")
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Renames the portrait item
func rename_portrait_item(item: TreeItem) -> void:
	renaming_item.item = item
	renaming_item.prev_path = get_item_path(item)

	item.set_editable(0, true)
	call_deferred("edit_selected")


## Ensure the item has a valid name (unique and not empty)
func ensure_valid_item_name(item: TreeItem) -> void:
	var name := item.get_text(0)
	var siblings_names := []
	var parent := item.get_parent()

	if not parent:
		parent = get_root()
	# Get all the sibling names
	for child in parent.get_children():
		if child != item:
			siblings_names.append(child.get_text(0))
	
	# Ensure the name is unique
	var unique_name = SproutyDialogsFileUtils.ensure_unique_name(name, siblings_names)
	if name != unique_name:
		item.set_text(0, unique_name)


## Returns the path of the item in the tree
## The path is a string with the format "Group/Item"
func get_item_path(item: TreeItem) -> String:
	var item_name := item.get_text(0)
	while item.get_parent() != get_root() and item != get_root():
		item_name = item.get_parent().get_text(0) + "/" + item_name
		item = item.get_parent()
	return item_name


## Filters the tree items based on the search term
func filter_branch(parent: TreeItem, filter: String) -> bool:
	var match_found := false
	for item in parent.get_children():
		# Check if the item name matches the filter
		var match_filter = filter.to_lower() in item.get_text(0).to_lower()
		var filter_in_group = false

		# If the item is a group, check if any of its children match the filter
		if item.get_metadata(0).has("group") and not match_filter:
			filter_in_group = filter_branch(item, filter)
		
		item.visible = match_filter or filter.is_empty() or filter_in_group

		if item.visible: # If the item is visible, check that found a match
			match_found = true
	return match_found


## Update the preview of all portraits
func update_portraits_transform(parent_transform: Dictionary, from: TreeItem = get_root()) -> void:
	for item in from.get_children():
		if not item.get_metadata(0).has("group"):
			item.get_meta("portrait_editor").update_preview_transform(parent_transform)
		else: # If it's a group, recursively update the portraits
			update_portraits_transform(parent_transform, item)


#region === Drag and Drop ======================================================
## Get the drag data when dragging an item, returns the item being dragged
func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_item := get_item_at_position(at_position)
	if not drag_item:
		return null

	var preview := Label.new()
	preview.text = drag_item.get_text(0)
	preview.add_theme_stylebox_override("normal",
		get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)
	return drag_item


## Set when can drag data
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = DROP_MODE_INBETWEEN
	return data is TreeItem


## Called when the item is dropped
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var to_item := get_item_at_position(at_position)
	var item := data as TreeItem

	if item == null or to_item == null:
		return
	
	# Check if the item is a child of the target item
	var aux := to_item
	while true:
		if aux == item: # Dropping inside itself
			return # Prevent infinite loops
		aux = aux.get_parent()
		if aux == get_root():
			break
	
	# Get the drop section (-1: above, 0: inside, 1: below)
	var drop_section := get_drop_section_at_position(at_position)
	var parent := item.get_parent()
	var index := item.get_index()
	var prev_path = get_item_path(item)

	undo_redo.create_action("Move Portrait")

	# If dropping into a group, set the parent to the group
	if to_item.get_metadata(0).has("group") and drop_section == 1:
		if to_item.get_children().size() == 0:
			# If the group is empty, just add the item to the group
			parent.remove_child(item)
			to_item.add_child(item)

			# --- UndoRedo -------------------------------------------------
			undo_redo.add_do_method(parent, "remove_child", item)
			undo_redo.add_do_method(to_item, "add_child", item)
			# --------------------------------------------------------------
		else: # If the group has children, move the item to the first position
			var first_child := to_item.get_first_child()
			item.move_before(first_child)

			# --- UndoRedo -------------------------------------------------
			undo_redo.add_do_method(item, "move_before", first_child)
			# --------------------------------------------------------------

	
	# Move the new item after the target item
	if !to_item.get_metadata(0).has("group") and drop_section == 1:
		item.move_after(to_item)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.add_do_method(item, "move_after", to_item)
		# ------------------------------------------------------------------

	if drop_section == -1: # Move the new item before the target item
		item.move_before(to_item)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.add_do_method(item, "move_before", to_item)
		# ------------------------------------------------------------------

	# Ensure the item has a unique name after moving
	var temp_name := item.get_meta("name")
	
	ensure_valid_item_name(item)
	if temp_name != item.get_text(0):
		item.set_meta("name", item.get_text(0))
	
	var new_path = get_item_path(item)
	portrait_path_changed.emit(new_path, prev_path)
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	if parent.get_child_count() > 0:
		if index >= parent.get_child_count():
			# If the item was the last child, move it to the end
			undo_redo.add_undo_method(item, "move_after",
				parent.get_child(parent.get_child_count() - 1))
		else: # Otherwise, move it back to its original position
			undo_redo.add_undo_method(item, "move_before",
					parent.get_child(index if index > 0 else 0))
	else: # If the parent has no children, just add the item back to the parent
		undo_redo.add_undo_method(item.get_parent(), "remove_child", item)
		undo_redo.add_undo_method(parent, "add_child", item)
	
	if temp_name != item.get_text(0):
		undo_redo.add_do_method(item, "set_text", 0, item.get_text(0))
		undo_redo.add_do_method(item, "set_meta", "name", item.get_text(0))
		undo_redo.add_undo_method(item, "set_text", 0, temp_name)
		undo_redo.add_undo_method(item, "set_meta", "name", temp_name)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)

	undo_redo.add_do_method(self, "emit_signal", "portrait_path_changed", new_path, prev_path)
	undo_redo.add_undo_method(self, "emit_signal", "portrait_path_changed", prev_path, new_path)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


#endregion

#region === Input Handling =====================================================

## Called when the user right-clicks on a portrait item
func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.set_item_disabled(1, get_selected().get_metadata(0).has("group"))
		_popup_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))


## Called when the user selects a portrait item
func _on_item_selected() -> void:
	portrait_item_selected.emit(get_selected())


## Called when the user double-clicks on a portrait item
func _on_item_activated() -> void:
	rename_portrait_item(get_selected())


## Called when the user edits (rename) a portrait item
func _on_item_edited() -> void:
	var item := get_selected()
	var prev_path = ""
	if item == renaming_item.item:
		prev_path = renaming_item.prev_path
	
	ensure_valid_item_name(item)

	if item.get_meta("name") == item.get_text(0):
		return # If the name didn't change, do nothing
	
	var temp_name := item.get_meta("name")
	item.set_meta("name", item.get_text(0))

	if not item.get_metadata(0).has("group"): # Update the portrait name
		item.get_meta("portrait_editor").set_portrait_name(item.get_text(0))
	
	var new_path = get_item_path(item)
	portrait_path_changed.emit(new_path, prev_path)

	if item.get_meta("new_item"):
		item.set_meta("new_item", false)
		return # If it's a new item, do not register the action

	modified.emit(true)

	# --- UndoRedo -----------------------------------------------------
	undo_redo.create_action("Rename Portrait")
	undo_redo.add_do_method(item, "set_text", 0, item.get_text(0))
	undo_redo.add_do_method(item, "set_meta", "name", item.get_text(0))
	undo_redo.add_undo_method(item, "set_text", 0, temp_name)
	undo_redo.add_undo_method(item, "set_meta", "name", temp_name)

	if not item.get_metadata(0).has("group"): # Update the portrait name
		undo_redo.add_do_method(item.get_meta("portrait_editor"), "set_portrait_name", item.get_text(0))
		undo_redo.add_undo_method(item.get_meta("portrait_editor"), "set_portrait_name", temp_name)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)

	undo_redo.add_do_method(self, "emit_signal", "portrait_path_changed", new_path, prev_path)
	undo_redo.add_undo_method(self, "emit_signal", "portrait_path_changed", prev_path, new_path)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Called when the user selects an item in the popup menu
func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # Rename
			rename_portrait_item(get_selected())
		1: # Duplicate
			duplicate_portrait_item(get_selected())
		2: # Remove
			remove_portrait_item(get_selected())


## Called when the user clicks on a portrait item button
func _on_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		if id == 0: # Remove item button clicked
			remove_portrait_item(item)
		if id == 1: # Remove group button clicked
			if item.get_children().size() > 0:
				# If the group has children, show a confirmation dialog
				_remove_group_dialog.confirmed.connect(remove_portrait_item.bind(item))
				_remove_group_dialog.popup_centered()
			else:
				remove_portrait_item(item)
#endregion
