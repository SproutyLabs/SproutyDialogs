@tool
extends HSplitContainer

@export var csv_files_path : String = ""

@onready var default_locale_dropdown : OptionButton = $"%DefaultLocale"/OptionButton
@onready var testing_locale_dropdown : OptionButton = $"%TestingLocale"/OptionButton
@onready var locales_container : VBoxContainer = %LocalesContainer

var csv_template_file : String = "locales_template.csv"
var localization_data_path := "res://addons/graph_dialog_system/editor/data/localization/"
var locale_field := preload("res://addons/graph_dialog_system/editor/components/locale_field.tscn")

func _ready():
	_set_locales_on_dropdown(default_locale_dropdown)
	_set_locales_on_dropdown(testing_locale_dropdown)
	_set_locale_list()
	
func _set_locales_on_dropdown(dropdown : OptionButton) -> void:
	# Load the saved locales on a dropdown
	if TranslationServer.get_loaded_locales().is_empty(): return
	
	dropdown.clear()
	for locale in TranslationServer.get_loaded_locales():
		print(locale)
		dropdown.add_item(locale)

func _set_locale_list() -> void:
	# Set locale list loading the saved locales
	if locales_container.get_child(0) is MarginContainer:
		locales_container.get_child(0).queue_free() # Remove placeholder
	
	for locale in TranslationServer.get_loaded_locales():
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
	var locales_header = ["keys"]
	locales_header.append(get_default_locale()) # Put default lang first
	
	for field in locales_container.get_children():
		if not field is MarginContainer: continue
		var locale = field.get_locale_code()
		if locale == get_default_locale(): continue
		if locale == "":
			printerr("[Translation Settings] Cannot save locales, please fix the issues.")
			return
		locales_header.append(locale)
	
	# Save csv template and set the translations
	CSVFileManager.save_file(locales_header, [], localization_data_path + csv_template_file)
	print("[Translation Settings] Locales saved.")

func collect_translations(path : String) -> void:
	# Collect translation files and add to the project settings
	var translation_files := []
	var all_translation_files: Array = ProjectSettings.get_setting(
			'internationalization/locale/translations', [])
	
	# Collect translation files from csv folder
	for file in DirAccess.get_files_at(path):
		if file.ends_with('.translation'):
			if not file in translation_files:
				translation_files.append(file)
	
	for file in translation_files:
		if not file in all_translation_files:
			all_translation_files.append(file)
	
	var valid_translation_files := PackedStringArray(all_translation_files)
	ProjectSettings.set_setting('internationalization/locale/translations', valid_translation_files)
	ProjectSettings.save()

func _on_collect_translations_pressed() -> void:
	collect_translations(localization_data_path)
