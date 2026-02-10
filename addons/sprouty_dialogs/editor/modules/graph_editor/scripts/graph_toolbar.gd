@tool
extends PanelContainer

# -----------------------------------------------------------------------------
# Graph Toolbar
# -----------------------------------------------------------------------------
## Handles the toolbar of the graph editor.
# -----------------------------------------------------------------------------

## Emitted when is requesting to play a dialog from a start node
signal play_dialog_request(start_id: String)
## Emitted to request for the start ids in the graph
signal request_start_ids

## Emitted when the toolbar is collapsed
signal toolbar_collapsed

## Add node pop-up menu
@onready var _add_node_menu: PopupMenu


func _ready() -> void:
	%CollapseButton.pressed.connect(_on_collapse_button_pressed)
	%AddNodeButton.pressed.connect(_show_add_node_menu)
	%RunButton.about_to_popup.connect(request_start_ids.emit)
	%RunButton.get_popup().index_pressed.connect(_play_selected_dialog)

	# Set buttons icons
	%AddNodeButton.icon = get_theme_icon("Add", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%CopyButton.icon = get_theme_icon("ActionCopy", "EditorIcons")
	%CutButton.icon = get_theme_icon("ActionCut", "EditorIcons")
	%PasteButton.icon = get_theme_icon("ActionPaste", "EditorIcons")
	%RunButton.icon = get_theme_icon("PlayScene", "EditorIcons")


## Set nodes list on add node menu
func set_add_node_menu(menu: PopupMenu) -> void:
	_add_node_menu = menu


## Set the run menu with the start ids from the graph
func set_start_ids_menu(start_ids: Array) -> void:
	var popup = %RunButton.get_popup()
	popup.clear()

	# If there is no dialog trees, return
	if start_ids.size() == 0:
		print("[Sprouty Dialogs] No dialog IDs to play.")
		return

	# If there is only one dialog, play it
	if start_ids.size() == 1:
		play_dialog_request.emit(start_ids[0])
		return

	for id in start_ids: # Populate the start ids list
		popup.add_icon_item(get_theme_icon("Play", "EditorIcons"), id)


## Switch between show the nodes options on buttons or menu
func switch_node_options_view(buttons_visible: bool) -> void:
	%NodeOptions.visible = buttons_visible
	%NodeOptionsMenu.visible = not buttons_visible
	%CollapseSeparator.visible = buttons_visible
	%CollapseButton.visible = buttons_visible


## Update node options availability
func update_node_options(has_selection: bool) -> void:
	%RemoveButton.disabled = not has_selection
	%DuplicateButton.disabled = not has_selection
	%CopyButton.disabled = not has_selection
	%CutButton.disabled = not has_selection


## Show a pop-up menu at a given position
func _show_add_node_menu() -> void:
	var pop_pos = %AddNodeButton.global_position
	_add_node_menu.popup(Rect2(
			pop_pos.x, pop_pos.y + %AddNodeButton.size.y * 2,
			_add_node_menu.size.x, _add_node_menu.size.y
		)
	)
	_add_node_menu.reset_size()


## Play the dialog with the selected the start id
func _play_selected_dialog(index: int) -> void:
	var start_id = %RunButton.get_popup().get_item_text(index)
	play_dialog_request.emit(start_id)


## Collapse the toolbar on button pressed
func _on_collapse_button_pressed() -> void:
	toolbar_collapsed.emit()
	hide()