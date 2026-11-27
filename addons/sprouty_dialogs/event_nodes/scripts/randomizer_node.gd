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

## Flag to check if the error alert is displaying
var _displaying_error: bool = false
## Error alert to show when the locked probabilities exceed 100%
var _probability_error_alert: EditorSproutyDialogsAlert


func _ready():
	super()
	$AddSlotButton.pressed.connect(_on_add_slot_button_pressed)
	$AddSlotButton.icon = get_theme_icon("Add", "EditorIcons")
	if not get_child(0) is EditorSproutyDialogsProbabilityContainer:
		_first_slot = _add_new_slot() # Add the first slot
	else:
		_first_slot = get_child(0) as EditorSproutyDialogsProbabilityContainer
		_setup_slot(_first_slot)
		_update_probabilities()
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	tree_exiting.connect(_on_tree_exiting)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name) if get_parent() and get_parent().has_method("get_node_connections") else []

	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"probabilities": [],
		"lock_states": [],
		"to_node": get_output_connections(),
		"to_dialog": to_dialog,
		"offset": position_offset.round(),
		"size": size.round()
	}
	var data = dict[name.to_snake_case()]
	
	for child in get_children():
		if child is EditorSproutyDialogsProbabilityContainer:
			data["probabilities"].insert(child.slot_index, child.get_probability_value())
			data["lock_states"].insert(child.slot_index, child.get_lock_state())
	
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	to_dialog = dict.get("to_dialog", "")
	position_offset = dict["offset"]
	size = dict["size"]

	load_probability_slots(dict["probabilities"], dict["lock_states"])

#endregion


## Load probability slots from data
func load_probability_slots(probabilities: Array, lock_states: Array) -> void:
	for slot in probabilities.size():
		var prob_container: EditorSproutyDialogsProbabilityContainer
		if slot == 0: # Load the first option
			prob_container = _first_slot
		else:
			prob_container = _add_new_slot(false)

		prob_container.set_probability_value(probabilities[slot])
		prob_container.set_lock_state(lock_states[slot])


## Create a new probability slot for the randomizer node
func _new_slot() -> EditorSproutyDialogsProbabilityContainer:
	var new_slot = _probability_scene.instantiate()
	_setup_slot(new_slot)
	return new_slot


## Set up a probability slot signals and undo redo manager
func _setup_slot(slot: EditorSproutyDialogsProbabilityContainer) -> void:
	slot.undo_redo = undo_redo
	slot.probability_changed.connect(_on_probability_value_changed)
	slot.lock_toggled.connect(_on_lock_toggled)
	slot.slot_removed.connect(_on_option_removed)
	slot.modified.connect(modified.emit)
	slot.resized.connect(_on_slot_resized)


## Keep the node size adjusted when a slot is resized
func _on_slot_resized() -> void:
	position_offset.y += 0.01
	_on_resized()


## Add a new slot to the randomizer node
func _add_new_slot(update_probabilities: bool = true) -> EditorSproutyDialogsProbabilityContainer:
	var new_slot = _new_slot()
	var slot_index = get_child_count() - 1
	
	add_child(new_slot, true)
	move_child(new_slot, slot_index)
	new_slot.update_option_index(slot_index)
	
	# Add slot to connect the option
	set_slot(slot_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	if update_probabilities:
		_update_probabilities()
	return new_slot


## Add an option at a given index
func _add_slot_at_index(index: int, new_slot: EditorSproutyDialogsProbabilityContainer,
		update_probabilities: bool = true) -> void:
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
	if update_probabilities:
		_update_probabilities()


## Remove an option at a given index
func _remove_slot(index: int, update_probabilities: bool = true) -> void:
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
	if update_probabilities:
		_update_probabilities()


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
	undo_redo.add_undo_method(self, "_add_slot_at_index", index, temp_node)
	if temp_connections.size() > 0 and parent != null: # Restore connections if there were any
		undo_redo.add_undo_method(parent, "connect_node", name, index,
				temp_connections[0]["to_node"], temp_connections[0]["to_port"])
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle when a probability value changes
func _on_probability_value_changed(_value: float) -> void:
	_update_probabilities()


## Handle when a slot lock toggle changes
func _on_lock_toggled(_locked: bool) -> void:
	_update_probabilities()
	modified.emit(true)


## Calculate and update the probabilities of the unlocked slots
func _update_probabilities() -> void:
	var slots: Array[EditorSproutyDialogsProbabilityContainer] = []
	var unlocked_slots: Array[EditorSproutyDialogsProbabilityContainer] = []
	var locked_sum := 0.0

	for child in get_children():
		if child is EditorSproutyDialogsProbabilityContainer:
			var slot: EditorSproutyDialogsProbabilityContainer = child
			slots.append(slot)
			if slot.get_lock_state():
				locked_sum += slot.get_probability_value() * 100.0
			else:
				unlocked_slots.append(slot)

	# Locked slots cannot exceed the total probability
	if locked_sum > 100.0 + 0.001:
		_show_probability_error(slots)
		return

	_clear_probability_error(slots)

	# All slots are locked, so there is nothing to recalculate
	if unlocked_slots.is_empty():
		return

	# Distribute the remaining probability equally between the unlocked slots
	var remaining := 100.0 - locked_sum
	var per_slot := remaining / unlocked_slots.size()
	var assigned := 0.0

	for index in unlocked_slots.size():
		var value := per_slot
		if index == unlocked_slots.size() - 1:
			value = remaining - assigned # Keep the total probability at 100%
		value = snappedf(maxf(value, 0.0), 0.01)
		assigned += value
		unlocked_slots[index].set_probability_value(value / 100.0)


## Show the error alert and mark the locked slots with the error style
func _show_probability_error(slots: Array[EditorSproutyDialogsProbabilityContainer]) -> void:
	for slot in slots:
		slot.set_error_style(slot.get_lock_state())

	var parent = get_parent()
	if parent != null and "alerts" in parent and parent.alerts != null:
		var message := "Randomizer Node #" + str(node_index) \
				+" locked probabilities sum more than 100%"
		if _probability_error_alert == null:
			_probability_error_alert = parent.alerts.show_alert(message, 0)
		else:
			parent.alerts.focus_alert(_probability_error_alert)
	_displaying_error = true


## Hide the error alert and remove the error style from the slots
func _clear_probability_error(slots: Array[EditorSproutyDialogsProbabilityContainer]) -> void:
	for slot in slots:
		slot.set_error_style(false)

	if _displaying_error:
		var parent = get_parent()
		if parent != null and "alerts" in parent and parent.alerts != null \
				and _probability_error_alert:
			parent.alerts.hide_alert(_probability_error_alert)
		_probability_error_alert = null
		_displaying_error = false


## Hide active error alert on node destroy
func _on_tree_exiting() -> void:
	var parent = get_parent()
	if parent != null and "alerts" in parent and parent.alerts != null \
			and _probability_error_alert:
		parent.alerts.hide_alert(_probability_error_alert)
	_probability_error_alert = null