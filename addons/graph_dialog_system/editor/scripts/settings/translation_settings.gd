@tool
extends HSplitContainer

signal locales_changed
signal default_locale_changed
signal testing_locale_changed

@onready var default_locale_dropdown : OptionButton = $"%DefaultLocale"/OptionButton
@onready var testing_locale_dropdown : OptionButton = $"%TestingLocale"/OptionButton
@onready var locales_selector : VBoxContainer = %LocalesSelector
@onready var csv_folder_field : MarginContainer = %CSVFolderField

func _init() -> void:
	GDialogsTranslationManager.load_translation_settings()
	GDialogsTranslationManager.translation_settings = self

func _ready() -> void:
	locales_selector.connect("locales_changed", _on_locales_changed)
	csv_folder_field.connect("folder_path_changed", _set_csv_files_path)
	
	if not GDialogsTranslationManager.csv_files_path.is_empty():
		csv_folder_field.set_value(GDialogsTranslationManager.csv_files_path)
	
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)

func _set_locales_on_dropdown(dropdown : OptionButton, default : bool) -> void:
	# Load the saved locales on a dropdown
	dropdown.clear()
	var locales = GDialogsTranslationManager.locales
	
	if locales.is_empty():
		dropdown.add_item("(no one)")
	
	for index in locales.size():
		dropdown.add_item(locales[index])
		if default and locales[index] == GDialogsTranslationManager.default_locale\
				or not default and locales[index] == GDialogsTranslationManager.testing_locale:
			dropdown.select(index)

func _on_default_locale_selected(index: int) -> void:
	# Select default locale from dropdown
	GDialogsTranslationManager.default_locale = default_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()
	default_locale_changed.emit()

func _on_testing_locale_selected(index: int) -> void:
	# Select testing locale from dropdown
	GDialogsTranslationManager.testing_locale = testing_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()
	testing_locale_changed.emit()

func _on_locales_changed() -> void:
	# When the selected locales change, update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = GDialogsTranslationManager.locales
	if not new_locales.has(GDialogsTranslationManager.default_locale):
		_on_default_locale_selected(0)
	if not new_locales.has(GDialogsTranslationManager.testing_locale):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()

func _set_csv_files_path(path : String) -> void:
	# Change the path to CSV translation files
	GDialogsTranslationManager.csv_files_path = path
	GDialogsTranslationManager.save_translation_settings()

func _on_collect_translations_pressed() -> void:
	# Collect the translation files from the CSV files folder
	GDialogsTranslationManager.collect_translations()
