@tool
extends MarginContainer

signal locale_removed(locale_code : String)

@onready var code_input : LineEdit = $Container/CodeInput
@onready var language_dropdown : OptionButton = $Container/LanguageDropdown
@onready var countries_dropdown : OptionButton = $Container/CountryDropdown
@onready var popup_selector : PopupMenu = $PopupSelector

var lang_code : String = ""
var country_code : String = ""

func _ready():
	_set_language_dropdown()
	_set_countries_dropdown()

func get_locale_code() -> String:
	# Return the code of the current locale setted
	var splited_code = code_input.text.split("_")
	var lang = splited_code[0]
	var country = splited_code[1] if splited_code.size() > 1 else ""
	
	if lang != "": # Check language code
		if not TranslationServer.get_all_languages().has(lang):
			printerr("[Translation Settings] Language code '" + lang + "' is not valid.")
			return ""
	else:
		printerr("[Translation Settings] Need to select a language, code '"+ 
				code_input.text + "'' not valid.")
		return ""
	
	if country != "": # Check country code
		if not TranslationServer.get_all_countries().has(country.to_upper()):
			printerr("[Translation Settings] Country code '" + country + "' is not valid.")
			return ""
	
	return code_input.text
	
func load_locale(locale_code : String) -> void:
	# Fill the field with a loaded locale
	var splited_code = locale_code.split("_")
	lang_code = splited_code[0]
	country_code = splited_code[1] if splited_code.size() > 1 else ""
	
	code_input.text = lang_code + ("_" + country_code if country_code != "" else "")
	language_dropdown.select(TranslationServer.get_all_languages().find(lang_code) + 1)
	countries_dropdown.select(TranslationServer.get_all_countries().find(country_code) + 1)

#region --- Dropdown handling ---
func _set_language_dropdown() -> void:
	# Set language dropdown
	language_dropdown.clear()
	language_dropdown.add_item("(no one)")
	for lang in TranslationServer.get_all_languages():
		language_dropdown.add_item(
				TranslationServer.get_language_name(lang) + " (" + lang + ")")

func _set_countries_dropdown() -> void:
	# Set countries dropdown
	countries_dropdown.clear()
	countries_dropdown.add_item("(no one)")
	for country in TranslationServer.get_all_countries():
		countries_dropdown.add_item(
				TranslationServer.get_country_name(country) + " (" + country + ")")

func _on_language_dropdown_item_selected(index : int) -> void:
	# Select language by dropdown
	if index == 0: lang_code = ""
	else: lang_code = TranslationServer.get_all_languages()[index - 1]
	code_input.text = lang_code + ("_" + country_code if country_code != "" else "")

func _on_country_dropdown_item_selected(index : int) -> void:
	# Select country by dropdown
	if index == 0: country_code = ""
	else: country_code = TranslationServer.get_all_countries()[index - 1]
	code_input.text = lang_code + ("_" + country_code if country_code != "" else "")
#endregion

#region --- Code input handling ---
func _on_code_input_text_changed(new_text : String) -> void:
	# Select the locale with manual input
	popup_selector.clear()
	
	if new_text.contains("_"): # Show countries suggestions
		var countries = TranslationServer.get_all_countries()
		for index in countries.size():
			if countries[index].to_lower().contains(new_text.split("_")[1].to_lower()):
				popup_selector.add_item(
						TranslationServer.get_country_name(countries[index])
							+ " (" + countries[index] + ")")
				popup_selector.set_item_metadata(popup_selector.item_count - 1, 
					{
						"item_type" : "country",
						"index" : index
					}
				)
	else: # Show languages suggestions
		var langs = TranslationServer.get_all_languages()
		for index in langs.size():
			if langs[index].contains(new_text):
				popup_selector.add_item(
						TranslationServer.get_language_name(langs[index])
							+ " (" + langs[index] + ")")
				popup_selector.set_item_metadata(popup_selector.item_count - 1,
					{
						"item_type" : "lang",
						"index" : index
					}
				)
	
	if popup_selector.item_count > 0: # Show popup
		var pos := Vector2(100, 0) + code_input.global_position + Vector2(get_window().position)
		popup_selector.popup(Rect2(pos, popup_selector.size))

func _on_code_input_text_submitted(new_text : String) -> void:
	# Set the language and country manually typed in the dropdowns
	var splited_code = new_text.split("_")
	var lang = splited_code[0]
	var country = splited_code[1] if splited_code.size() > 1 else ""
	
	if lang != "": # Set language on dropdown
		var all_langs = TranslationServer.get_all_languages()
		if all_langs.has(lang):
			language_dropdown.select(all_langs.find(lang) + 1)
			lang_code = lang
		else:
			language_dropdown.select(0)
			printerr("[Translation Settings] Language code '" + lang + "' is not valid.")
			return
	else:
		printerr("[Translation Settings] Need to select a language, code '"+ 
				new_text + "'' not valid.")
		language_dropdown.select(0)
	
	if country != "": # Set country on dropdown
		var all_countries = TranslationServer.get_all_countries()
		if all_countries.has(country.to_upper()):
			countries_dropdown.select(all_countries.find(country.to_upper()) + 1)
			code_input.text = lang_code + "_" + country.to_upper()
			country_code = country.to_upper()
		else:
			countries_dropdown.select(0)
			printerr("[Translation Settings] Country code '" + country + "' is not valid.")
	else:
		countries_dropdown.select(0)

func _on_popup_selector_id_pressed(id : int) -> void:
	# Select a language or country code
	if popup_selector.get_item_metadata(id).item_type == "country":
		country_code = popup_selector.get_item_text(id).split("(")[1].replace(")", "")
		lang_code = code_input.text.split("_")[0]
	elif popup_selector.get_item_metadata(id).item_type == "lang":
		lang_code = popup_selector.get_item_text(id).split("(")[1].replace(")", "")
	
	code_input.text = lang_code + ("_" + country_code if country_code != "" else "")
	_on_code_input_text_submitted(code_input.text)
#endregion

func _on_remove_button_pressed():
	# Remove locale field
	locale_removed.emit(code_input.text)
	queue_free()
