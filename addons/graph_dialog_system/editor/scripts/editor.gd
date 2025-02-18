@tool
extends Control

@export var file_manager : SplitContainer
@export var tab_container : TabContainer

@onready var tab_icons: Array[Texture2D] = [
	preload("res://addons/graph_dialog_system/icons/Script.svg"),
	preload("res://addons/graph_dialog_system/icons/Character.svg"),
	preload("res://addons/graph_dialog_system/icons/Variable.svg"),
	preload("res://addons/graph_dialog_system/icons/Settings.svg")
]

func _ready():
	_show_first_settings()
	set_tabs_icons()

func set_tabs_icons() -> void:
	# Set the tab menu icons
	for index in tab_icons.size():
		tab_container.set_tab_icon(index, tab_icons[index])

func switch_active_tab(tab : int):
	# Change the selected active tab
	tab_container.current_tab = tab

func _on_tab_selected(tab: int):
	# Handle when a tab is selected
	match tab:
		0: # Graph dialog tab
			file_manager.show_csv_container()
		1: # Character tab
			file_manager.hide_csv_container()
		2: # Variable tab
			file_manager.hide_csv_container()

func _show_first_settings():
	# Show first settings screen
	if GDialogsTranslationManager.csv_files_path.is_empty():
		$FirstSettings.visible = true
		$MainContainer.visible = false
	else:
		$FirstSettings.visible = false
		$MainContainer.visible = true

func _on_select_csv_folder_pressed() -> void:
	# Open the dialog to select a folder to CSV files
	$FirstSettings/OpenFolderDialog.popup_centered()

func _on_csv_folder_selected(path: String) -> void:
	# Set a folder path for CSV files
	GDialogsTranslationManager.csv_files_path = path
	GDialogsTranslationManager.save_translation_settings()
	$FirstSettings.visible = false
	$MainContainer.visible = true
