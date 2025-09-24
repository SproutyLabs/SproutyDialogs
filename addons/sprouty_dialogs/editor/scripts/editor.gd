@tool
extends Control

# -----------------------------------------------------------------------------
# Main editor controller
# -----------------------------------------------------------------------------
## This script handles the editor view and the interaction between the
## different modules of the plugin.
# -----------------------------------------------------------------------------

## Side bar reference
@onready var side_bar: Control = %SideBar
## File manager reference
@onready var file_manager: Control = side_bar.file_manager

## Workspace reference
@onready var workspace: Control = %Workspace
## Character panel reference
@onready var character_panel: Control = %CharacterPanel
## Variable panel reference
@onready var variables_panel: Control = %VariablesPanel
## Settings panel reference
@onready var settings_panel: Control = %SettingsPanel

## Main container with the tabs
@onready var main_container: HSplitContainer = $MainContainer
## Tab container with modules
@onready var tab_container: TabContainer = %TabContainer

## Tab icons
@onready var tab_icons: Array[Texture2D] = [
	get_theme_icon('Script', 'EditorIcons'),
	preload("res://addons/sprouty_dialogs/editor/icons/character.svg"),
	preload("res://addons/sprouty_dialogs/editor/icons/variable.svg"),
	preload("res://addons/sprouty_dialogs/editor/icons/settings.svg")
]


func _ready():
	set_tabs_icons()

	# File manager signals
	file_manager.all_dialog_files_closed.connect(workspace.show_start_panel)
	file_manager.all_character_files_closed.connect(character_panel.show_start_panel)
	file_manager.request_to_switch_tab.connect(switch_active_tab)
	file_manager.request_to_switch_graph.connect(workspace.switch_current_graph)
	file_manager.request_to_switch_character.connect(
			character_panel.switch_current_character_editor)
	
	# Workspace signals
	workspace.graph_editor_visible.connect(side_bar.csv_path_field_visible)
	workspace.new_dialog_file_pressed.connect(file_manager.on_new_dialog_pressed)
	workspace.open_dialog_file_pressed.connect(file_manager.on_open_file_pressed)
	workspace.open_character_file_request.connect(file_manager.load_file.unbind(1))
	workspace.play_dialog_request.connect(play_dialog_scene)

	# Character panel signals
	character_panel.new_character_file_pressed.connect(
			file_manager.on_new_character_pressed)
	character_panel.open_character_file_pressed.connect(
			file_manager.on_open_file_pressed)
	
	# Settings panel signals
	_connect_settings_panel_signals()


## Connect signals from settings panel to other modules
func _connect_settings_panel_signals() -> void:
	# Graph editor signals
	settings_panel.translation_settings.translation_enabled_changed.connect(
			workspace.on_translation_enabled_changed)
	settings_panel.translation_settings.locales_changed.connect(
			workspace.on_locales_changed)
	settings_panel.translation_settings.default_locale_changed.connect(
			workspace.on_locales_changed)
	
	# Character panel signals
	settings_panel.translation_settings.translate_character_names_changed.connect(
			character_panel.on_translation_enabled_changed)
	settings_panel.translation_settings.locales_changed.connect(
			character_panel.on_locales_changed)
	settings_panel.translation_settings.default_locale_changed.connect(
			character_panel.on_locales_changed)


## Play a dialog from the current graph starting from the given ID
func play_dialog_scene(start_id: String, dialog_path: String = "") -> void:
	file_manager.save_file()
	if dialog_path.is_empty(): # Use the current open dialog
		dialog_path = file_manager.get_current_file_path()
		if dialog_path.is_empty():
			printerr("[Sprouty Dialogs] Cannot play dialog: No dialog file is open.")
			return
	EditorSproutyDialogsSettingsManager.set_setting("play_dialog_path", dialog_path)
	EditorSproutyDialogsSettingsManager.set_setting("play_start_id", start_id)
	EditorInterface.play_custom_scene("res://addons/sprouty_dialogs/objects/test_scene/dialog_test_scene.tscn")


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
			if side_bar:
				if workspace.get_current_graph() != null:
					side_bar.csv_path_field_visible(true)
				file_manager.switch_to_file_on_tab(
						tab, workspace.get_current_graph())
		1: # Character tab
			if file_manager:
				side_bar.csv_path_field_visible(false)
				file_manager.switch_to_file_on_tab(
						tab, character_panel.get_current_character_editor())
		_: # Other tabs
			if file_manager:
				side_bar.csv_path_field_visible(false)
				pass