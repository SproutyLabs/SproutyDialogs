@tool
extends TabContainer

# -----------------------------------------------------------------------------
# Settings Panel
# -----------------------------------------------------------------------------
## This script handles the settings panel in the Sprouty Dialogs editor.
## It contains the general settings, text settings and translation settings.
# -----------------------------------------------------------------------------

## General settings reference
@onready var general_settings: Control = %GeneralSettings
## Text settings reference
@onready var text_settings: Control = %TextSettings
## Translation settings reference
@onready var translation_settings: Control = %TranslationSettings

## Tab icons
@onready var tab_icons: Array[Texture2D] = [
	preload("res://addons/sprouty_dialogs/editor/icons/settings.svg"),
	preload("res://addons/sprouty_dialogs/editor/icons/text_editor/text.svg"),
	preload("res://addons/sprouty_dialogs/editor/icons/translation.svg")
]


func _ready():
	set_tabs_icons()


## Set the tab menu icons
func set_tabs_icons() -> void:
	for index in tab_icons.size():
		set_tab_icon(index, tab_icons[index])