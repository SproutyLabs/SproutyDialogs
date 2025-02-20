@tool
extends VBoxContainer

signal locales_changed

@onready var locales_container : VBoxContainer = %LocalesContainer

var locale_field := preload("res://addons/graph_dialog_system/editor/components/locale_field.tscn")

func _ready() -> void:
	_set_locale_list()

func _set_locale_list() -> void:
	# Set locale list loading the saved locales
	if locales_container.get_child(0) is MarginContainer:
		locales_container.get_child(0).queue_free() # Remove placeholder
	
	if GDialogsTranslationManager.locales.is_empty(): return
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
	locales_container.add_child(new_locale)
	$"%LocalesContainer"/Label.visible = false

func _on_locale_removed(locale_code : String) -> void:
	# When a locale is removed check this
	if locales_container.get_child_count() == 0:
		$"%LocalesContainer"/Label.visible = true
	print("locale '"+ locale_code +"' removed")

func _on_save_locales_pressed() -> void:
	# Save locales in a csv file template
	var current_locales = []
	
	for field in locales_container.get_children():
		if not field is MarginContainer: continue
		var locale = field.get_locale_code()
		if locale == "":
			printerr("[Graph Dialogs] Cannot save locales, please fix the issues.")
			return
		current_locales.append(locale)
	
	# Save csv template and set the translations
	GDialogsTranslationManager.locales = current_locales
	GDialogsTranslationManager.save_translation_settings()
	GDialogsTranslationManager.collect_translations()
	locales_changed.emit()
	print("[Graph Dialogs] Locales saved.")
