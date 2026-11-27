@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Randomizer Node
# -----------------------------------------------------------------------------
## Node to select a random output node in the dialog tree.
# -----------------------------------------------------------------------------

## Probability container template
@onready var _probability_scene := preload("res://addons/sprouty_dialogs/editor/components/probability_container.tscn")

## First slot container
var _first_slot: EditorSproutyDialogsProbabilityContainer


func _ready():
	super()
	$AddSlotButton.pressed.connect(_on_add_slot_button_pressed)
	$AddSlotButton.icon = get_theme_icon("Add", "EditorIcons")
	if not get_child(0) is EditorSproutyDialogsProbabilityContainer:
		_first_slot = _add_new_slot() # Add the first slot
	else:
		_first_slot = get_child(0)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name) if get_parent() and get_parent().has_method("get_node_connections") else []

	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"probabilities": [],
		"to_node": get_output_connections(),
		"to_dialog": to_dialog,
		"offset": position_offset.round(),
		"size": size.round()
	}
	var data = dict[name.to_snake_case()]
	
	for child in get_children():
		if child is EditorSproutyDialogsProbabilityContainer:
			data["probabilities"].insert(child.slot_index, child.get_probability_value())
	
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	to_dialog = dict.get("to_dialog", "")
	position_offset = dict["offset"]
	size = dict["size"]

	load_probability_slots(dict["probabilities"])

#endregion


## Load probability slots from data
func load_probability_slots(probabilities: Array) -> void:
	for slot in probabilities.size():
		var prob_container: EditorSproutyDialogsProbabilityContainer
		if slot == 0: # Load the first option
			prob_container = _first_slot
		else:
			prob_container = _add_new_slot()

		prob_container.set_probability_value(probabilities[slot])


## Create a new probability slot for the randomizer node
func _new_slot() -> EditorSproutyDialogsProbabilityContainer:
	var new_slot = _probability_scene.instantiate()
	new_slot.undo_redo = undo_redo
	new_slot.probability_changed.connect(_on_probability_value_changed)
	new_slot.slot_removed.connect(_on_option_removed)
	new_slot.modified.connect(modified.emit)
	new_slot.resized.connect(func():
		position_offset.y += 0.01
		_on_resized()
		)
	return new_slot


## Add a new slot to the randomizer node
func _add_new_slot() -> EditorSproutyDialogsProbabilityContainer:
	var new_slot = _new_slot()
	var slot_index = get_child_count() - 1
	
	add_child(new_slot, true)
	move_child(new_slot, slot_index)
	new_slot.update_option_index(slot_index)
	
	# Add slot to connect the option
	set_slot(slot_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	return new_slot


## Add an option at a given index
func _add_slot_at_index(index: int, new_slot: EditorSproutyDialogsProbabilityContainer) -> void:
	add_child(new_slot, true)
	move_child(new_slot, index)
	new_slot.update_option_index(index)

	# Add a new slot
	set_slot(get_child_count() - 2, false, 0, Color.WHITE, true, 0, Color.WHITE)

	# Update the following options to the new one, by moving them downwards
	var options = get_children().filter(func(c): return c is EditorSproutyDialogsProbabilityContainer)
	options.reverse()
	var parent = get_parent()
	for option in options:
		if option.get_index() > index:
			option.update_option_index(option.get_index())
			if parent and parent.has_method("get_node_output_connections"):
				# Get the connections on previous port and move them to current port
				var prev_connections = parent.get_node_output_connections(name, option.get_index() - 1)
				parent.disconnect_node_on_port(name, option.get_index() - 1) # Remove old connections
				for connection in prev_connections: # Update to new connections
					parent.connect_node(name, option.get_index(),
						connection["to_node"], connection["to_port"])

	_on_resized() # Resize container vertically


## Remove an option at a given index
func _remove_slot(index: int) -> void:
	var parent = get_parent()
	for child in get_children():
		# Update the following slots to the removed one, by moving them upwards
		if child is EditorSproutyDialogsProbabilityContainer and child.get_index() >= index:
			child.update_option_index(child.get_index() - 1)
			if parent and parent.has_method("get_node_output_connections"):
				# Get the connections on next port and move them to current port
				var next_connections = parent.get_node_output_connections(name, child.get_index() + 1)
				parent.disconnect_node_on_port(name, child.get_index()) # Remove old connections
				for connection in next_connections: # Update to new connections
					parent.connect_node(name, child.get_index(),
						connection["to_node"], connection["to_port"])
	
	remove_child(get_child(index))

	# Remove the last remaining port
	set_slot(get_child_count() - 1, false, 0, Color.WHITE, false, 0, Color.WHITE)
	_on_resized() # Resize container vertically


## Handle when the add option button is pressed
func _on_add_slot_button_pressed() -> void:
	_add_new_slot()
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Add Probability Slot")
	undo_redo.add_do_method(self, "_add_new_slot")
	undo_redo.add_undo_method(self, "_remove_slot", get_child_count() - 2)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle when an option is removed
func _on_option_removed(index: int) -> void:
	var parent = get_parent()
	var temp_connections = parent.get_node_output_connections(name, index) if parent and parent.has_method("get_node_output_connections") else []
	var temp_node = get_child(index)
	_remove_slot(index)
	modified.emit(true)
	
	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Remove Probability Slot")
	undo_redo.add_do_method(self, "_remove_slot", index)
	undo_redo.add_undo_method(self, "_add_slot", index, temp_node)
	if temp_connections.size() > 0 and parent != null: # Restore connections if there were any
		undo_redo.add_undo_method(parent, "connect_node", name, index,
				temp_connections[0]["to_node"], temp_connections[0]["to_port"])
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle when a probability value changes
func _on_probability_value_changed(value: float) -> void:
	# TODO: Ensure that the sum of all probabilities is 1.0, and if not, normalize them.
	# To normalize, divide each probability by the sum of all probabilities and multiply by 100.0 to get the percentage.
	# Then update the probability values of each lock slot accordingly.
	# The unlocked slots should be updated by the user, if there is an inconsistency, a error message should indicate it.
	pass