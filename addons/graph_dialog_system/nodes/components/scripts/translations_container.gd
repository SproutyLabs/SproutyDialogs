@tool
extends VBoxContainer

@onready var text_boxes = $TextBoxes

var translation_box := preload(
	"res://addons/graph_dialog_system/nodes/components/translation_box.tscn")

func _ready():
	text_boxes.visible = false

func set_translation_boxes(locales: Array) -> void:
	# Set input text boxes for each locale
	for box in text_boxes.get_children():
		box.queue_free() # Clear boxes
	
	for locale in locales: # Add a box for each locale
		var box = translation_box.instantiate()
		text_boxes.add_child(box)
		box.set_locale(locale)

func load_translations_text() -> void:
	pass

func _on_expand_button_toggled(toggled_on : bool) -> void:
	text_boxes.visible = toggled_on
