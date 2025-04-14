@tool
extends VBoxContainer

@onready var _portrait_name: Label = $Title/PortraitName


## Get the portrait settings from the editor
func get_portrait_data() -> Dictionary:
	return {}


## Load the portrait settings into the editor
func load_portrait_data(data: Dictionary) -> void:
	# Load the portrait settings from the given data
	_portrait_name.text = data.name

	# TODO: Load other settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name
