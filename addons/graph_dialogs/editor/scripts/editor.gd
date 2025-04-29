@tool
extends Control

## -----------------------------------------------------------------------------
## Graph dialog system editor
##
## This script handles the editor UI.
## -----------------------------------------------------------------------------

## File manager container on side bar
@onready var file_manager: SplitContainer = %FileManager
## First settings panel
@onready var first_settings: Panel = $FirstSettings
## Main container with the tabs
@onready var main_container: HSplitContainer = $MainContainer
## Tab container with modules
@onready var tab_container: TabContainer = %TabContainer

## Tab icons
@onready var tab_icons: Array[Texture2D] = [
	get_theme_icon('Script', 'EditorIcons'),
	preload("res://addons/graph_dialogs/icons/character.svg"),
	preload("res://addons/graph_dialogs/icons/variable.svg"),
	preload("res://addons/graph_dialogs/icons/settings.svg")
]


func _ready():
	_show_first_settings()
	set_tabs_icons()


## Set the tab menu icons
func set_tabs_icons() -> void:
	for index in tab_icons.size():
		tab_container.set_tab_icon(index, tab_icons[index])


## Switch the active tab
func switch_active_tab(tab: int):
	tab_container.current_tab = tab


## Handle the tab selection
func _on_tab_selected(tab: int):
	match tab:
		0: # Graph dialog tab
			if file_manager:
				file_manager.show_csv_container()
				file_manager.switch_to_file_on_tab(tab)
		1: # Character tab
			if file_manager:
				file_manager.hide_csv_container()
				file_manager.switch_to_file_on_tab(tab)
		2: # Variable tab
			if file_manager:
				file_manager.hide_csv_container()


## Show the first settings screen
func _show_first_settings():
	if GraphDialogsTranslationManager.csv_files_path.is_empty():
		first_settings.visible = true
		main_container.visible = false
	else:
		first_settings.visible = false
		main_container.visible = true


## Open the dialog to select a folder to CSV files
func _on_select_csv_folder_pressed() -> void:
	first_settings.get_node("OpenFolderDialog").popup_centered()


## Set a folder path for CSV files
func _on_csv_folder_selected(path: String) -> void:
	GraphDialogsTranslationManager.csv_files_path = path
	
	# Set the path of the CSV file for character names
	GraphDialogsTranslationManager.char_names_csv_path = (
		path + "/" + GraphDialogsTranslationManager.DEFAULT_CHAR_NAMES_CSV
		)
	# Create the CSV file for character names
	if not FileAccess.file_exists(GraphDialogsTranslationManager.char_names_csv_path):
		GraphDialogsTranslationManager.new_csv_template_file(
			GraphDialogsTranslationManager.DEFAULT_CHAR_NAMES_CSV
			)
	first_settings.visible = false
	main_container.visible = true
