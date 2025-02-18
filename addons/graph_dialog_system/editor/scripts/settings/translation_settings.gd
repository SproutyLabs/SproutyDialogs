@tool
extends HSplitContainer

signal locales_changed

@onready var default_locale_dropdown : OptionButton = $"%DefaultLocale"/OptionButton
@onready var testing_locale_dropdown : OptionButton = $"%TestingLocale"/OptionButton
@onready var locales_container : VBoxContainer = %LocalesContainer

var locale_field := preload("res://addons/graph_dialog_system/editor/components/locale_field.tscn")

func _ready():
	GDialogsTranslationManager.load_translation_settings()
	_set_locales_on_dropdown(default_locale_dropdown)
	_set_locales_on_dropdown(testing_locale_dropdown)
	_set_locale_list()
	
func _set_locales_on_dropdown(dropdown : OptionButton) -> void:
	# Load the saved locales on a dropdown
	if GDialogsTranslationManager.locales.is_empty(): return
	
	dropdown.clear()
	for locale in GDialogsTranslationManager.locales:
		dropdown.add_item(locale)

func _set_locale_list() -> void:
	# Set locale list loading the saved locales
	if locales_container.get_child(0) is MarginContainer:
		locales_container.get_child(0).queue_free() # Remove placeholder
	
	for locale in GDialogsTranslationManager.locales:
		# Load saved locales in the list
		var new_locale = locale_field.instantiate()
		new_locale.connect("locale_removed", _on_locale_removed)
		locales_container.add_child(new_locale)
		new_locale.load_locale(locale)

func get_default_locale() -> String:
	# Return the default locale
	return default_locale_dropdown.get_item_text(
			default_locale_dropdown.get_selected_id())

func get_test_locale() -> String:
	# Return the test locale
	return testing_locale_dropdown.get_item_text(
			testing_locale_dropdown.get_selected_id())

func _on_add_locale_button_pressed():
	# Add new locale to the list
	var new_locale = locale_field.instantiate()
	new_locale.connect("locale_removed", _on_locale_removed)
	locales_container.add_child(new_locale)
	$"%LocalesContainer"/Label.visible = false

func _on_locale_removed(locale_code : String) -> void:
	if locales_container.get_child_count() == 0:
		$"%LocalesContainer"/Label.visible = true
	print("locale '"+ locale_code +"' removed")

func _on_save_locales_button_pressed() -> void:
	# Save locales in a csv file template
	var current_locales = []
	
	for field in locales_container.get_children():
		if not field is MarginContainer: continue
		var locale = field.get_locale_code()
		if locale == "":
			printerr("[Translation Settings] Cannot save locales, please fix the issues.")
			return
		current_locales.append(locale)
	
	# Save csv template and set the translations
	GDialogsTranslationManager.locales = current_locales
	GDialogsTranslationManager.save_translation_settings()
	GDialogsTranslationManager.collect_translations()
	_set_locales_on_dropdown(default_locale_dropdown)
	_set_locales_on_dropdown(testing_locale_dropdown)
	locales_changed.emit()
	print("[Translation Settings] Locales saved.")

func _on_collect_translations_pressed() -> void:
	GDialogsTranslationManager.collect_translations()
