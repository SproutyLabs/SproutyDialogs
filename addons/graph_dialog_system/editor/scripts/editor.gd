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
