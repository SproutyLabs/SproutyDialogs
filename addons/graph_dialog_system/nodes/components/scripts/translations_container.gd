@tool
extends VBoxContainer

@onready var text_boxes = $TextBoxes

var translation_box := preload(
	"res://addons/graph_dialog_system/nodes/components/translation_box.tscn")

func _ready():
	text_boxes.visible = false

func get_translations_text() -> Dictionary:
	# Return the dialog translations text on a dict
	var dialogs = {}
	for box in text_boxes.get_children():
		dialogs[box.get_locale()] = box.get_text()
	return dialogs

func set_translation_boxes(locales: Array) -> void:
	# Set input text boxes for each locale
	for box in text_boxes.get_children():
		box.queue_free() # Clear boxes
	
	if locales.is_empty(): 
		self.visible = false
		return
	
	for locale in locales: # Add a box for each locale
		var box = translation_box.instantiate()
		text_boxes.add_child(box)
		box.set_locale(locale)
	self.visible = true

func load_translations_text(dialogs : Dictionary) -> void:
	# Load dialog translations
	for box in text_boxes.get_children():
		if dialogs.has(box.get_locale()):
			box.set_text(dialogs[box.get_locale()])

func _on_expand_button_toggled(toggled_on : bool) -> void:
	text_boxes.visible = toggled_on
