@tool
extends PanelContainer

# -----------------------------------------------------------------------------
# Character Panel
# -----------------------------------------------------------------------------
## Handles the tab panel for the character editor.
# -----------------------------------------------------------------------------

## Emitted when the new character file button is pressed
signal new_character_file_pressed
## Emitted when the open character file button is pressed
signal open_character_file_pressed

## Start panel reference
@onready var _start_panel: Control = $StartPanel
## Character editor container reference
@onready var _character_editor: Control = $CharacterEditor

## New character button reference (from start panel)
@onready var _new_character_button: Button = %NewCharacterButton
## Open character button reference (from start panel)
@onready var _open_character_button: Button = %OpenCharacterButton

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	_new_character_button.pressed.connect(new_character_file_pressed.emit)
	_open_character_button.pressed.connect(open_character_file_pressed.emit)

	_new_character_button.icon = get_theme_icon("Add", "EditorIcons")
	_open_character_button.icon = get_theme_icon("Folder", "EditorIcons")
	show_start_panel()


## Get the current character editor panel
func get_current_character_editor() -> Container:
	if get_child_count() > 1:
		return get_child(1)
	return null


## Switch the current character editor panel
func switch_current_character_editor(new_editor: Container) -> void:
	# Remove old panel and switch to the new one
	if get_child_count() > 1:
		remove_child(get_child(1))
	
	new_editor.undo_redo = undo_redo
	add_child(new_editor)
	show_character_editor()


## Show the start panel instead of character panel
func show_start_panel() -> void:
	_character_editor.visible = false
	_start_panel.visible = true


## Show the character panel
func show_character_editor() -> void:
	_character_editor.visible = true
	_start_panel.visible = false


## Update the character editor to reflect the new locales
func on_locales_changed() -> void:
	var current_editor = get_current_character_editor()
	if current_editor: current_editor.on_locales_changed()


## Update the character names translation setting
func on_translation_enabled_changed(enabled: bool) -> void:
	var current_editor = get_current_character_editor()
	if current_editor:
		current_editor.on_translation_enabled_changed(enabled)