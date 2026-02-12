@tool
class_name EditorSproutyDialogsTranslationsContainer
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Translations Container Component
# -----------------------------------------------------------------------------
## Component to handle translations text boxes. It allows to set the dialog
## text boxes for each locale, load the dialog translations text and get
## the dialog translations text on a dict.
# -----------------------------------------------------------------------------

## Emitted when the text in any of the text boxes changes
signal modified(modified: bool)
## Emitted when pressing the expand button of a text box to open the text editor
signal open_text_editor(text_box: TextEdit)
## Emitted when change the focus to another text box while the text editor is open
signal update_text_editor(text_box: TextEdit)

## Flag to indicate if is using text boxes for translation
## True for use expandable text boxes for translation, false for use line edits
@export var _use_text_boxes: bool = true
## Extra node to show when expanding the text boxes
## This can be used to show extra information or UI elements.
@export var _extra_to_show: Node = null

## Text boxes container
@onready var _text_boxes: Container = %TextBoxes

## Translation text box and text line scene resources
var _translation_box = preload("res://addons/sprouty_dialogs/editor/components/translation_box.tscn")
var _translation_line = preload("res://addons/sprouty_dialogs/editor/components/translation_line.tscn")

## Collapse/Expand icon resources
var collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	# Collapse text boxes by default
	if _text_boxes.get_parent() != self:
		_text_boxes.get_parent().visible = false
	_text_boxes.visible = false


## Return the dialog translations text on a dictionary
func get_translations_text() -> Dictionary:
	var dialogs = {}
	for box in _text_boxes.get_children():
		if box is EditorSproutyDialogsTranslationBox:
			dialogs[box.get_locale()] = box.get_text()
	return dialogs


## Set input text boxes for each locale
func set_translation_boxes(locales: Array) -> void:
	for box in _text_boxes.get_children():
		if box is EditorSproutyDialogsTranslationBox:
			box.queue_free() # Clear boxes
	
	if locales.is_empty():
		self.visible = false
		return
	
	for locale in locales: # Add a box for each locale
		var box = null
		if _use_text_boxes:
			box = _translation_box.instantiate()
		else:
			box = _translation_line.instantiate()
		box.ready.connect(box.set_locale.bind(locale))
		_text_boxes.add_child(box)
		box.undo_redo = undo_redo
		box.open_text_editor.connect(open_text_editor.emit)
		box.update_text_editor.connect(update_text_editor.emit)
		box.modified.connect(modified.emit)
	self.visible = true


## Load dialog translations text
func load_translations_text(dialogs: Dictionary) -> void:
	for box in _text_boxes.get_children():
		if box is EditorSproutyDialogsTranslationBox and dialogs.has(box.get_locale()):
			box.set_text(dialogs[box.get_locale()])


## Show or collapse the text boxes
func _on_expand_button_toggled(toggled_on: bool) -> void:
	if _text_boxes.get_parent() != self:
		_text_boxes.get_parent().visible = toggled_on
	if _extra_to_show:
		_extra_to_show.visible = toggled_on
	
	_text_boxes.visible = toggled_on
	$Header/ExpandButton.icon = collapse_up_icon if toggled_on else collapse_down_icon
