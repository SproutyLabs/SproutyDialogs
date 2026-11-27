@tool
class_name EditorSproutyDialogsProbabilityContainer
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Probability Container Component
# -----------------------------------------------------------------------------
## Component that handles the probability values for the randomizer node.
# -----------------------------------------------------------------------------

## Emitted when the text in any of the text boxes changes
signal modified(modified: bool)
## Emitted when the probability value changes
signal probability_changed(value: float)
## Triggered when the slot is removed
signal slot_removed(index)

## Probability label to display the slot position index
@onready var _probability_label: Label = $Header/ProbabilityLabel
## Remove button
@onready var _remove_button: Button = $Header/RemoveButton
## Lock toggle to enable or disable the probability value
@onready var _lock_toggle: Button = $Field/LockToggle
## SpinBox to set the probability value
@onready var _probability_value: SpinBox = $Field/ProbabilityValue

## Slot position index
var slot_index: int = 0

## Probability value for the slot (for UndoRedo)
var _prob_value: float = 0.0
## Flag to check if the probability value was modified (for UndoRedo)
var _value_modified: bool = false

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	_probability_value.value_changed.connect(_on_probability_value_changed)
	_lock_toggle.toggled.connect(_on_lock_toggle_toggled)
	_lock_toggle.icon = get_theme_icon("Lock", "EditorIcons")
	_lock_toggle.toggle_mode = true
	set_lock_toggle_enabled(false)

	_remove_button.pressed.connect(_on_remove_button_pressed)
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_show_remove_button()


## Get the probability value for the slot (in the range of 0.0 to 1.0)
func get_probability_value() -> float:
	return _probability_value.value / 100.0


## Set the probability value for the slot (in the range of 0.0 to 1.0)
func set_probability_value(value: float) -> void:
	_prob_value = value * 100.0
	_probability_value.set_value_no_signal(value)


## Get the lock toggle state (enabled or disabled)
func get_lock_toggle_state() -> bool:
	return _lock_toggle.button_pressed


## Set the lock toggle enabled or disabled
func set_lock_toggle_enabled(enabled: bool) -> void:
	_lock_toggle.button_pressed = enabled


## Handle when the probability value changes
func _on_probability_value_changed(value: float) -> void:
	if _prob_value != _probability_value.value:
		var temp = _prob_value
		_prob_value = _probability_value.value
		_value_modified = true
		probability_changed.emit(_prob_value / 100.0)
	
		# --- UndoRedo ---------------------------------------------------------
		undo_redo.create_action("Edit Probability #" + str(slot_index + 1), 1)
		undo_redo.add_do_property(self, "_prob_value", _prob_value)
		undo_redo.add_do_method(_probability_value, "set_value_no_signal", _prob_value)
		undo_redo.add_undo_property(self, "_prob_value", temp)
		undo_redo.add_undo_method(_probability_value, "set_value_no_signal", temp)

		undo_redo.add_do_method(self, "emit_signal", "probability_changed", _prob_value / 100.0)
		undo_redo.add_undo_method(self, "emit_signal", "probability_changed", temp / 100.0)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ----------------------------------------------------------------------


## Handle when the lock toggle is toggled
func _on_lock_toggle_toggled(enabled: bool) -> void:
	_probability_value.editable = enabled
	var icon_name = "Lock" if enabled else "Unlock"
	_lock_toggle.icon = get_theme_icon(icon_name, "EditorIcons")


## Handle when the default text box loses focus
func _on_value_focus_exited() -> void:
	if _value_modified:
		_value_modified = false
		modified.emit(true)


## Update the option position index
func update_option_index(index: int) -> void:
	_probability_label.text = tr("Probability") + " #" + str(index + 1)
	name = name.split('_')[0] + "_" + str(index)
	slot_index = index
	_show_remove_button()


## Remove option when the remove button is pressed
func _on_remove_button_pressed() -> void:
	slot_removed.emit(slot_index)


## Show remove button only when it is not the first option
func _show_remove_button() -> void:
	_remove_button.visible = slot_index