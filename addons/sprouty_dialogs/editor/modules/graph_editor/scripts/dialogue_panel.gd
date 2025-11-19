@tool
extends Control

# -----------------------------------------------------------------------------
# Dialogue Panel
# -----------------------------------------------------------------------------
## Handles the tab panel for dialogues with the graph editor and text editor.
# -----------------------------------------------------------------------------

## Emitted when the graph editor is visible
signal graph_editor_visible(visible: bool)

## Emitted when the new dialog file button is pressed
signal new_dialog_file_pressed
## Emitted when the open dialog file button is pressed
signal open_dialog_file_pressed

## Emitted when is requesting to open a character file
signal open_character_file_request(path: String)
## Emitted when is requesting to play a dialog from a start node
signal play_dialog_request(start_id: String)

## Start panel reference
@onready var _start_panel: Panel = $StartPanel
## Graph editor container reference
@onready var _graph_panel: Panel = $GraphEditor
## Text editor reference
@onready var _text_editor: EditorSproutyDialogsTextEditor = $TextEditor

## New dialog button reference (from start panel)
@onready var _new_dialog_button: Button = %NewDialogButton
## Open dialog button reference (from start panel)
@onready var _open_dialog_button: Button = %OpenDialogButton

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	_new_dialog_button.pressed.connect(new_dialog_file_pressed.emit)
	_open_dialog_button.pressed.connect(open_dialog_file_pressed.emit)
	
	_new_dialog_button.icon = get_theme_icon("Add", "EditorIcons")
	_open_dialog_button.icon = get_theme_icon("Folder", "EditorIcons")
	if _graph_panel.get_child_count() > 0: # Destroy the placeholder graph
		_graph_panel.get_child(0).queue_free()
	show_start_panel()


## Returns the current graph on editor
func get_current_graph() -> EditorSproutyDialogsGraphEditor:
	if _graph_panel.get_child_count() > 0:
		return _graph_panel.get_child(0)
	else: return null


## Switch the current graph on editor
func switch_current_graph(new_graph: EditorSproutyDialogsGraphEditor) -> void:
	# Remove old graph and switch to the new one
	if _graph_panel.get_child_count() > 0:
		_graph_panel.remove_child(_graph_panel.get_child(0))
	
	# Connect signals to the new graph
	if not new_graph.is_connected("open_text_editor", _text_editor.show_text_editor):
		new_graph.open_text_editor.connect(_text_editor.show_text_editor)
		new_graph.update_text_editor.connect(_text_editor.update_text_editor)
		new_graph.open_character_file_request.connect(open_character_file_request.emit)
		new_graph.play_dialog_request.connect(play_dialog_request.emit)
	
	new_graph.undo_redo = undo_redo
	_graph_panel.add_child(new_graph)
	show_graph_editor()


## Show the start panel instead of graph editor
func show_start_panel() -> void:
	_graph_panel.visible = false
	_text_editor.visible = false
	_start_panel.visible = true
	graph_editor_visible.emit(false)


## Show the graph editor
func show_graph_editor() -> void:
	_graph_panel.visible = true
	_start_panel.visible = false
	graph_editor_visible.emit(true)


## Update the character editor to reflect the new locales
func on_locales_changed() -> void:
	var current_editor = get_current_graph()
	if current_editor: current_editor.on_locales_changed()


## Update the character names translation setting
func on_translation_enabled_changed(enabled: bool) -> void:
	var current_editor = get_current_graph()
	if current_editor:
		current_editor.on_translation_enabled_changed(enabled)