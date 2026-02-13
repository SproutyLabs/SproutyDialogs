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

## Emitted when the translation settings changes
signal translation_enabled_changed(enabled: bool)
## Emitted when the locales change
signal locales_changed

## Start panel reference
@onready var _start_panel: Panel = $StartPanel
## Graph editor container reference
@onready var _graph_panel: Control = $GraphEditor
## Graph editor toolbar reference
@onready var _graph_toolbar: Control = $GraphEditor/Toolbar
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

	_graph_toolbar.request_start_ids.connect(_on_request_start_ids)
	_graph_toolbar.play_dialog_request.connect(play_dialog_request.emit)
	_graph_toolbar.toolbar_collapsed.connect(_on_toolbar_collapsed)
	_text_editor.text_editor_closed.connect(_on_text_editor_closed)

	_new_dialog_button.icon = get_theme_icon("Add", "EditorIcons")
	_open_dialog_button.icon = get_theme_icon("Folder", "EditorIcons")

	if _graph_panel.get_child_count() > 1: # Destroy the placeholder graph
		_graph_panel.get_child(1).queue_free()
	show_start_panel()


## Returns the current graph on editor
func get_current_graph() -> EditorSproutyDialogsGraphEditor:
	if _graph_panel.get_child_count() > 1:
		return _graph_panel.get_child(1)
	else: return null


## Switch the current graph on editor
func switch_current_graph(new_graph: EditorSproutyDialogsGraphEditor) -> void:
	# Remove old graph and switch to the new one
	if _graph_panel.get_child_count() > 1:
		_graph_panel.remove_child(_graph_panel.get_child(1))
	
	# Connect signals to the new graph
	if not new_graph.is_connected("open_text_editor", _show_text_editor):
		new_graph.open_text_editor.connect(_show_text_editor)
		new_graph.update_text_editor.connect(_text_editor.update_text_editor)
		new_graph.open_character_file_request.connect(open_character_file_request.emit)
		new_graph.play_dialog_request.connect(play_dialog_request.emit)
		new_graph.toolbar_expanded.connect(_on_toolbar_expanded)
		new_graph.nodes_selection_changed.connect(_graph_toolbar.update_node_options)
		new_graph.paste_selection_changed.connect(_graph_toolbar.update_paste_button)

		_graph_toolbar.node_option_pressed.connect(new_graph.on_node_option_selected)
		translation_enabled_changed.connect(new_graph.on_translation_enabled_changed)
		locales_changed.connect(new_graph.on_locales_changed)
	
	new_graph.undo_redo = undo_redo
	_graph_panel.add_child(new_graph)
	show_graph_editor()
	
	_graph_toolbar.set_add_node_menu(new_graph.get_node("AddNodeMenu"))


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


## Show the text editor
func _show_text_editor(text_editor: Variant) -> void:
	if not _graph_toolbar.visible:
		get_current_graph().show_expand_toolbar_button(false)
	_text_editor.show_text_editor(text_editor)


## Handle when the text editor is closed
func _on_text_editor_closed() -> void:
	if not _graph_toolbar.visible:
		get_current_graph().show_expand_toolbar_button(true)


## Handle the request for the start ids from the toolbar
func _on_request_start_ids() -> void:
	var start_ids = get_current_graph().get_start_ids()
	_graph_toolbar.set_start_ids_menu(start_ids)


## Handle when the toolbar is collapsed
func _on_toolbar_collapsed() -> void:
	get_current_graph().show_expand_toolbar_button(true)


## Handle when the toolbar is expanded
func _on_toolbar_expanded() -> void:
	get_current_graph().show_expand_toolbar_button(false)
	_graph_toolbar.show()
