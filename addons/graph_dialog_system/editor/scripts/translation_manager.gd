@tool
extends HSplitContainer

@onready var default_locale_dropdown : OptionButton = $"%DefaultLocale"/OptionButton
@onready var testing_locale_dropdown : OptionButton = $"%TestingLocale"/OptionButton
@onready var locales_container : VBoxContainer = %LocalesContainer

var locale_field := preload("res://addons/graph_dialog_system/editor/components/locale_field.tscn")

func _ready():
	set_locales_on_dropdown(default_locale_dropdown)
	set_locales_on_dropdown(testing_locale_dropdown)
	set_locale_list()
	
func set_locales_on_dropdown(dropdown : OptionButton) -> void:
	# Load the saved locales on a dropdown
	if TranslationServer.get_loaded_locales().is_empty(): return
	
	dropdown.clear()
	for locale in TranslationServer.get_loaded_locales():
		dropdown.add_item(locale)

func set_locale_list() -> void:
	# Set locale list loading the saved locales
	if locales_container.get_child(0) is MarginContainer:
		locales_container.get_child(0).queue_free() # Remove placeholder
	
	for locale in TranslationServer.get_loaded_locales():
		# Load saved locales in the list
		var new_locale = locale_field.instantiate()
		new_locale.connect("locale_removed", _on_locale_removed)
		locales_container.add_child(new_locale)
		new_locale.load_locale(locale)

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

func _on_save_locales_button_pressed():
	# Save localization settings
	
	# TODO: set new locales
	
	# Update dropdown options
	set_locales_on_dropdown(default_locale_dropdown)
	set_locales_on_dropdown(testing_locale_dropdown)
