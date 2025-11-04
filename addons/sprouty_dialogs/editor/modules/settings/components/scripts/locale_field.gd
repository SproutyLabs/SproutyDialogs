@tool
class_name EditorSproutyDialogsLocaleField
extends MarginContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Locale Field Component
# -----------------------------------------------------------------------------
## Component that allows the user to select a locale from the translation server
## selecting the language and country using dropdowns or manual input.
# -----------------------------------------------------------------------------

## Triggered when the locale is removed.
signal locale_removed(locale_code: String)
## Triggered when the locale is modified.
signal locale_modified

## Locale code input to set the locale.
@onready var _code_input: LineEdit = $Container/CodeInput
## Dropdown to select the language.
@onready var _language_dropdown: OptionButton = $Container/LanguageDropdown
## Dropdown to select the country.
@onready var _countries_dropdown: OptionButton = $Container/CountryDropdown
## Button to remove the locale field.
@onready var _remove_button: Button = $Container/RemoveButton
## Popup to show suggestions from code input.
@onready var _popup_selector: PopupMenu = $PopupSelector

## Current language code.
var _lang_code: String = ""
## Current country code.
var _country_code: String = ""
## Current locale code.
var _current_locale: String = ""


func _ready():
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_set_language_dropdown()
	_set_countries_dropdown()


## Returns the locale code from the current input.
func get_locale_code() -> String:
	var splited_code = _code_input.text.split("_")
	var lang = splited_code[0]
	var country = splited_code[1] if splited_code.size() > 1 else ""
	
	if lang != "": # Check language code
		if not TranslationServer.get_all_languages().has(lang):
			printerr("[Sprouty Dialogs] Language code '" + lang + "' is not valid.")
			return ""
	else:
		printerr("[Sprouty Dialogs] Need to select a language, code '" +
				_code_input.text + "'' not valid.")
		return ""
	
	if country != "": # Check country code
		if not TranslationServer.get_all_countries().has(country.to_upper()):
			printerr("[Sprouty Dialogs] Country code '" + country + "' is not valid.")
			return ""
	
	return _code_input.text


## Load a locale from a locale code.
func load_locale(locale_code: String) -> void:
	var splited_code = locale_code.split("_")
	_lang_code = splited_code[0]
	_country_code = splited_code[1] if splited_code.size() > 1 else ""
	
	_code_input.text = _lang_code + ("_" + _country_code if _country_code != "" else "")
	_language_dropdown.select(TranslationServer.get_all_languages().find(_lang_code) + 1)
	_countries_dropdown.select(TranslationServer.get_all_countries().find(_country_code) + 1)
	_current_locale = locale_code


## Remove this locale field.
func _on_remove_button_pressed():
	locale_removed.emit(_code_input.text)
	queue_free()


#region === Dropdown handling ==================================================

## Set language dropdown.
func _set_language_dropdown() -> void:
	_language_dropdown.clear()
	_language_dropdown.add_item("(no one)")
	for lang in TranslationServer.get_all_languages():
		_language_dropdown.add_item(
				TranslationServer.get_language_name(lang) + " (" + lang + ")")


## Set countries dropdown.
func _set_countries_dropdown() -> void:
	_countries_dropdown.clear()
	_countries_dropdown.add_item("(no one)")
	for country in TranslationServer.get_all_countries():
		_countries_dropdown.add_item(
				TranslationServer.get_country_name(country) + " (" + country + ")")


## Select a language by dropdown.
func _on_language_dropdown_item_selected(index: int) -> void:
	if index == 0: _lang_code = ""
	else: _lang_code = TranslationServer.get_all_languages()[index - 1]
	_code_input.text = _lang_code + ("_" + _country_code if _country_code != "" else "")


## Select a country by dropdown.
func _on_country_dropdown_item_selected(index: int) -> void:
	if index == 0: _country_code = ""
	else: _country_code = TranslationServer.get_all_countries()[index - 1]
	_code_input.text = _lang_code + ("_" + _country_code if _country_code != "" else "")
#endregion

#region === Code input handling ================================================

## Add an country or language item to popup.
func _add_item_to_popup(item: String, type: String, index: int) -> void:
	var item_name = ""
	if type == "country": item_name = TranslationServer.get_country_name(item)
	elif type == "lang": item_name = TranslationServer.get_language_name(item)
	
	_popup_selector.add_item(item_name + " (" + item + ")")
	_popup_selector.set_item_metadata(_popup_selector.item_count - 1,
		{
			"item_type": type,
			"index": index
		}
	)


## Show popup suggestions from manual code input.
func _on_code_input_text_changed(new_text: String) -> void:
	_popup_selector.clear()
	if new_text != _current_locale:
		locale_modified.emit()
	
	if new_text.contains("_"):
		# Show countries suggestions
		var countries = TranslationServer.get_all_countries()
		for index in countries.size():
			if countries[index].to_lower().contains(new_text.split("_")[1].to_lower()):
				_add_item_to_popup(countries[index], "country", index)
	else:
		# Show languages suggestions
		var langs = TranslationServer.get_all_languages()
		for index in langs.size():
			if langs[index].contains(new_text):
				_add_item_to_popup(langs[index], "lang", index)
	
	if _popup_selector.item_count > 0: # Show popup
		var pos := Vector2(100, 0) + _code_input.global_position + Vector2(get_window().position)
		_popup_selector.popup(Rect2(pos, _popup_selector.get_contents_minimum_size()))


## Set the language and country from input in the dropdowns.
func _on_code_input_text_submitted(new_text: String) -> void:
	var splited_code = new_text.split("_")
	var lang = splited_code[0]
	var country = splited_code[1] if splited_code.size() > 1 else ""
	
	# Set language on dropdown
	if lang != "":
		var all_langs = TranslationServer.get_all_languages()
		if all_langs.has(lang):
			_language_dropdown.select(all_langs.find(lang) + 1)
			_lang_code = lang
		else:
			_language_dropdown.select(0)
			printerr("[Sprouty Dialogs] Language code '" + lang + "' is not valid.")
			return
	else:
		printerr("[Sprouty Dialogs] Need to select a language, code '" +
				new_text + "'' not valid.")
		_language_dropdown.select(0)
	
	# Set country on dropdown
	if country != "":
		var all_countries = TranslationServer.get_all_countries()
		if all_countries.has(country.to_upper()):
			_countries_dropdown.select(all_countries.find(country.to_upper()) + 1)
			_code_input.text = _lang_code + "_" + country.to_upper()
			_country_code = country.to_upper()
		else:
			_countries_dropdown.select(0)
			printerr("[Sprouty Dialogs] Country code '" + country + "' is not valid.")
	else:
		_countries_dropdown.select(0)


## Select a language or country code from popup suggestions.
func _on_popup_selector_id_pressed(id: int) -> void:
	if _popup_selector.get_item_metadata(id).item_type == "country":
		_country_code = _popup_selector.get_item_text(id).split("(")[1].replace(")", "")
		_lang_code = _code_input.text.split("_")[0]
	elif _popup_selector.get_item_metadata(id).item_type == "lang":
		_lang_code = _popup_selector.get_item_text(id).split("(")[1].replace(")", "")
	
	_code_input.text = _lang_code + ("_" + _country_code if _country_code != "" else "")
	_on_code_input_text_submitted(_code_input.text)
#endregion
