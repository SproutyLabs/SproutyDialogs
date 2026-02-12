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

## Emitted when the translation settings changes
signal translation_enabled_changed(enabled: bool)
## Emitted when the locales change
signal locales_changed

## Start panel reference
@onready var _start_panel: Control = $StartPanel
## Character editor container reference
@onready var _editor_panel: Control = $EditorPanel

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


## Returns the current character editor panel
func get_current_character_editor() -> EditorSproutyDialogsCharacterEditor:
	if _editor_panel.get_child_count() > 0:
		return _editor_panel.get_child(0)
	return null


## Switch the current character editor panel
func switch_current_character_editor(new_editor: EditorSproutyDialogsCharacterEditor) -> void:
	# Remove old panel and switch to the new one
	if _editor_panel.get_child_count() > 0:
		_editor_panel.remove_child(_editor_panel.get_child(0))
	
	# Connect signals to the new editor
	if not is_connected("translation_enabled_changed", new_editor.on_translation_enabled_changed):
		translation_enabled_changed.connect(new_editor.on_translation_enabled_changed)
		locales_changed.connect(new_editor.on_locales_changed)
	
	new_editor.undo_redo = undo_redo
	_editor_panel.add_child(new_editor)
	show_character_editor()


## Show the start panel instead of character panel
func show_start_panel() -> void:
	_editor_panel.visible = false
	_start_panel.visible = true


## Show the character panel
func show_character_editor() -> void:
	_editor_panel.visible = true
	_start_panel.visible = false