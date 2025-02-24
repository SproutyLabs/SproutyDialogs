@tool
extends VBoxContainer

signal locales_changed

@onready var locales_container : VBoxContainer = %LocalesContainer
@onready var confirm_panel : AcceptDialog = $ConfirmSaveLocales

var locale_field := preload("res://addons/graph_dialog_system/editor/components/locale_field.tscn")
var current_locales : Array = []

func _ready() -> void:
	confirm_panel.get_ok_button().hide()
	confirm_panel.add_button('Save Changes', true, 'save_changes')
	confirm_panel.add_button('Discard Changes', true, 'discard_changes')
	confirm_panel.add_cancel_button('Cancel')
	_set_locale_list()

func _set_locale_list() -> void:
	# Set locale list loading the saved locales
	for child in locales_container.get_children():
		if child is MarginContainer:
			child.queue_free()
	
	if GDialogsTranslationManager.locales.is_empty():
		$"%LocalesContainer"/Label.visible = true
		return
	
	$"%LocalesContainer"/Label.visible = false
	for locale in GDialogsTranslationManager.locales:
		# Load saved locales in the list
		var new_locale = locale_field.instantiate()
		new_locale.connect("locale_removed", _on_locale_removed)
		locales_container.add_child(new_locale)
		new_locale.load_locale(locale)

func _on_add_locale_pressed() -> void:
	# Add new locale to the list
	var new_locale = locale_field.instantiate()
	new_locale.connect("locale_removed", _on_locale_removed)
	new_locale.connect("locale_modified", _on_locales_modified)
	locales_container.add_child(new_locale)
	$"%LocalesContainer"/Label.visible = false
	_on_locales_modified()

func _on_locale_removed(locale_code : String) -> void:
	# When a locale is removed check this
	if locales_container.get_child_count() == 0:
		$"%LocalesContainer"/Label.visible = true
	_on_locales_modified()

func _save_locales() -> void:
	# Save locales in translation settings
	GDialogsTranslationManager.locales = current_locales
	GDialogsTranslationManager.save_translation_settings()
	GDialogsTranslationManager.collect_translations()
	locales_changed.emit()
	current_locales = []
	$SaveButton.text = "Save Locales"
	print("[Graph Dialogs] Locales saved.")

func _on_save_locales_pressed() -> void:
	# Collect locales selected and save changes
	for field in locales_container.get_children():
		if not field is MarginContainer: continue
		var locale = field.get_locale_code()
		if locale == "":
			printerr("[Graph Dialogs] Cannot save locales, please fix the issues.")
			return
		current_locales.append(locale)
	
	# If a locale has been removed, show confirmation alert
	for locale in GDialogsTranslationManager.locales:
		if not current_locales.has(locale):
			confirm_panel.popup_centered()
			return
	
	_save_locales()

func _on_confirm_save_action(action) -> void:
	# Set the confirm save dialog actions
	confirm_panel.hide()
	
	match action:
		"save_changes":
			_save_locales()
		"discard_changes":
			$SaveButton.text = "Save Locales"
			current_locales = []
			_set_locale_list()

func _on_confirm_save_canceled() -> void:
	current_locales = []

func _on_locales_modified() -> void:
	$SaveButton.text = "Save Locales (*)"
