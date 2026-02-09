@tool
extends PanelContainer

# -----------------------------------------------------------------------------
# Graph Toolbar
# -----------------------------------------------------------------------------
## Handles the toolbar of the graph editor.
# -----------------------------------------------------------------------------

## Emitted when is requesting to play a dialog from a start node
signal play_dialog_request(start_id: String)

## Add node pop-up menu
@onready var _add_node_menu: PopupMenu


func _ready() -> void:
	%AddNodeButton.pressed.connect(_show_popup_menu)

	# Set buttons icons
	%AddNodeButton.icon = get_theme_icon("Add", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%CopyButton.icon = get_theme_icon("ActionCopy", "EditorIcons")
	%CutButton.icon = get_theme_icon("ActionCut", "EditorIcons")
	%PasteButton.icon = get_theme_icon("ActionPaste", "EditorIcons")


## Set nodes list on add node menu
func set_add_node_menu(menu: PopupMenu) -> void:
	_add_node_menu = menu


## Switch between show the nodes options on buttons or menu
func switch_node_options_view(buttons_visible: bool) -> void:
	%NodeOptions.visible = buttons_visible
	%NodeOptionsMenu.visible = not buttons_visible


## Show a pop-up menu at a given position
func _show_popup_menu() -> void:
	var pop_pos = %AddNodeButton.global_position
	_add_node_menu.popup(Rect2(
			pop_pos.x, pop_pos.y + %AddNodeButton.size.y * 2,
			_add_node_menu.size.x, _add_node_menu.size.y
		)
	)
	_add_node_menu.reset_size()