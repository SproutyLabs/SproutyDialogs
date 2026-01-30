@tool
extends Control

# -----------------------------------------------------------------------------
# Main editor controller
# -----------------------------------------------------------------------------
## This script handles the editor view and the interaction between the
## different modules of the plugin.
# -----------------------------------------------------------------------------

## Test scene path used to play dialogs in the editor.
const TEST_SCENE_PATH = "res://addons/sprouty_dialogs/utils/test_scene/dialog_test_scene.tscn"

## Side bar reference
@onready var side_bar: Control = %SideBar
## File manager reference
@onready var file_manager: Control = side_bar.file_manager

## Dialogue panel reference
@onready var dialogue_panel: Control = %DialoguePanel
## Character panel reference
@onready var character_panel: Control = %CharacterPanel
## Variable panel reference
@onready var variable_panel: Control = %VariablePanel
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

## About panel reference
@onready var _about_panel: PopupPanel = $AboutPanel
## Update panel reference
@onready var _update_panel: PopupPanel = $AboutPanel/UpdatePanel
## Update manager reference
@onready var _update_manager: Node = $UpdateManager

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	set_tabs_icons()
	# Set undo redo manager
	dialogue_panel.undo_redo = undo_redo
	character_panel.undo_redo = undo_redo
	variable_panel.undo_redo = undo_redo
	settings_panel.undo_redo = undo_redo
	file_manager.undo_redo = undo_redo

	# File manager signals
	file_manager.all_dialog_files_closed.connect(dialogue_panel.show_start_panel)
	file_manager.all_character_files_closed.connect(character_panel.show_start_panel)
	file_manager.request_to_switch_tab.connect(switch_active_tab)
	file_manager.request_to_switch_graph.connect(dialogue_panel.switch_current_graph)
	file_manager.request_to_switch_character.connect(
			character_panel.switch_current_character_editor)
	
	# Dialogue panel signals
	dialogue_panel.graph_editor_visible.connect(side_bar.csv_path_field_visible)
	dialogue_panel.new_dialog_file_pressed.connect(file_manager.on_new_dialog_pressed)
	dialogue_panel.open_dialog_file_pressed.connect(file_manager.on_open_file_pressed)
	dialogue_panel.open_character_file_request.connect(file_manager.load_file.unbind(1))
	dialogue_panel.play_dialog_request.connect(play_dialog_scene)

	# Character panel signals
	character_panel.new_character_file_pressed.connect(
			file_manager.on_new_character_pressed)
	character_panel.open_character_file_pressed.connect(
			file_manager.on_open_file_pressed)
	
	# Settings and update manager setup
	_connect_settings_panel_signals()
	_setup_update_manager()

	# Check for updates on startup
	_update_manager.request_update_check()
	

## Connect signals from settings panel to other modules
func _connect_settings_panel_signals() -> void:
	# Graph editor signals
	settings_panel.translation_settings.translation_enabled_changed.connect(
			dialogue_panel.on_translation_enabled_changed)
	settings_panel.translation_settings.locales_changed.connect(
			dialogue_panel.on_locales_changed)
	settings_panel.translation_settings.default_locale_changed.connect(
			dialogue_panel.on_locales_changed)
	
	# Character panel signals
	settings_panel.translation_settings.translate_character_names_changed.connect(
			character_panel.on_translation_enabled_changed)
	settings_panel.translation_settings.locales_changed.connect(
			character_panel.on_locales_changed)
	settings_panel.translation_settings.default_locale_changed.connect(
			character_panel.on_locales_changed)


## Connect update manager signals and setup version
func _setup_update_manager() -> void:
	side_bar.version_button.pressed.connect(_about_panel.popup)
	_about_panel.check_updates_requested.connect(_update_manager.request_update_check)
	_update_panel.install_update_requested.connect(_update_manager.request_download_update)
	_update_manager.new_version_received.connect(_update_panel.set_release_info)

	# Update UI when update check is completed
	_update_manager.update_checked.connect(func(result: int) -> void:
		_about_panel.set_version_status(result)
		side_bar.set_version_status(result)
	)
	# Update UI when download is completed
	_update_manager.download_completed.connect(func(result):
		_update_panel.download_completed(result)
		_about_panel.set_version_status(result)
		side_bar.set_version_status(result)
		if result == 0: # Success
			side_bar.set_plugin_version(_update_manager.get_current_version())
			_about_panel.set_plugin_version(_update_manager.get_current_version())
		)
	# Set plugin version in about panel and side bar
	var version = _update_manager.get_current_version()
	side_bar.set_plugin_version(version)
	_about_panel.set_plugin_version(version)


## Play a dialog from the current graph starting from the given ID
func play_dialog_scene(start_id: String, dialog_path: String = "") -> void:
	file_manager.save_file()
	if dialog_path.is_empty(): # Use the current open dialog
		dialog_path = file_manager.get_current_file_path()
		if dialog_path.is_empty():
			printerr("[Sprouty Dialogs] Cannot play dialog: No dialog file is open.")
			return
	SproutyDialogsSettingsManager.set_setting("play_dialog_path", dialog_path)
	SproutyDialogsSettingsManager.set_setting("play_start_id", start_id)
	Engine.get_singleton("EditorInterface").play_custom_scene(TEST_SCENE_PATH)


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
		0: # Dialogues tab
			if side_bar:
				if dialogue_panel.get_current_graph() != null:
					side_bar.csv_path_field_visible(true)
				file_manager.switch_to_file_on_tab(
						tab, dialogue_panel.get_current_graph())
		1: # Character tab
			if file_manager:
				side_bar.csv_path_field_visible(false)
				file_manager.switch_to_file_on_tab(
						tab, character_panel.get_current_character_editor())
		_: # Other tabs
			if file_manager:
				side_bar.csv_path_field_visible(false)
				pass
