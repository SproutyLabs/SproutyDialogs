@tool
extends VBoxContainer

## -----------------------------------------------------------------------------
## Translations text boxes container
##
## Component to handle the dialog translations text boxes. It allows to set the
## dialog text boxes for each locale, load the dialog translations text and get
## the dialog translations text on a dict.
## -----------------------------------------------------------------------------

## True if is using text boxes for translation, false if is using line edits
@export var useTextBoxes: bool = true

## Text boxes container
@onready var text_boxes: Container = $TextBoxes

## Translation box scene
var translation_box := preload(
	"res://addons/graph_dialog_system/editor/components/translation_box.tscn")

## Translation line scene
var translation_line := preload(
	"res://addons/graph_dialog_system/editor/components/translation_line.tscn")


func _ready():
	# Collapse text boxes by default
	text_boxes.visible = false


## Return the dialog translations text on a dict
func get_translations_text() -> Dictionary:
	var dialogs = {}
	for box in text_boxes.get_children():
		if box is GDialogsTranslationBox:
			dialogs[box.get_locale()] = box.get_text()
	return dialogs


## Set input text boxes for each locale
func set_translation_boxes(locales: Array) -> void:
	for box in text_boxes.get_children():
		if box is GDialogsTranslationBox:
			box.queue_free() # Clear boxes
	
	if locales.is_empty():
		self.visible = false
		return
	
	for locale in locales: # Add a box for each locale
		var box = null
		if useTextBoxes:
			box = translation_box.instantiate()
		else:
			box = translation_line.instantiate()
		text_boxes.add_child(box)
		box.set_locale(locale)
	self.visible = true


## Load dialog translations text
func load_translations_text(dialogs: Dictionary) -> void:
	for box in text_boxes.get_children():
		if box is GDialogsTranslationBox and dialogs.has(box.get_locale()):
			box.set_text(dialogs[box.get_locale()])


## Show or collapse the text boxes
func _on_expand_button_toggled(toggled_on: bool) -> void:
	text_boxes.visible = toggled_on
