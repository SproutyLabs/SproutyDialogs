@tool
extends PopupPanel

# -----------------------------------------------------------------------------
# Update Panel
# -----------------------------------------------------------------------------
## Panel to show information of a new version of the Sprouty Dialogs plugin
## and allow the user to install the update.
# -----------------------------------------------------------------------------

## Emitted when the user requests to install the update
signal install_update_requested()

## Version label reference
@onready var _version_label: RichTextLabel = $Container/Header/Container/VersionLabel
## Published info label reference
@onready var _published_info_label: RichTextLabel = $Container/Header/Container/PublishedInfoLabel
## Release info label reference
@onready var _release_info_label: RichTextLabel = $Container/ReleaseInfoLabel

## Install button reference
@onready var _install_button: Button = $Container/InstallButton


func _ready() -> void:
	_install_button.pressed.connect(_on_install_button_pressed)
	hide()


## Set the update information for the update panel
func set_update_info(update_info: Dictionary) -> void:
	_version_label.text = "[color=orange][b][i][font s=36]New Version " + update_info.version + " Available!"
	_published_info_label.text = "[color=gray][i]Published on " + update_info.date + " by " + update_info.author
	_release_info_label.text = _markdown_to_bbcode(update_info.body)


## Convert markdown text to BBCode
func _markdown_to_bbcode(text: String) -> String:
	var title_regex := RegEx.create_from_string("(^|\n)((?<level>#+)(?<title>.*))\\n")
	var res := title_regex.search(text)
	while res:
		text = text.replace(res.get_string(2), "[b]" + res.get_string("title").strip_edges() + "[/b][hr]")
		res = title_regex.search(text)

	var link_regex := RegEx.create_from_string("(?<!\\!)\\[(?<text>[^\\]]*)]\\((?<link>[^)]*)\\)")
	res = link_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "[url=" + res.get_string("link")
				+"]" + res.get_string("text").strip_edges() + "[/url]")
		res = link_regex.search(text)

	var image_regex := RegEx.create_from_string("\\!\\[(?<text>[^\\]]*)]\\((?<link>[^)]*)\\)\n*")
	res = image_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "[url=" + res.get_string("link")
				+"]" + res.get_string("text").strip_edges() + "[/url]")
		res = image_regex.search(text)
	
	var bold_regex := RegEx.create_from_string("\\*\\*(?<text>[^\\*\\n]*)\\*\\*")
	res = bold_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "[b]" + res.get_string("text").strip_edges() + "[/b]")
		res = bold_regex.search(text)
	
	var italics_regex := RegEx.create_from_string("\\*(?<text>[^\\*\\n]*)\\*")
	res = italics_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "[i]" + res.get_string("text").strip_edges() + "[/i]")
		res = italics_regex.search(text)

	var bullets_regex := RegEx.create_from_string("(?<=\\n)(\\*|-)(?<text>[^\\*\\n]*)")
	res = bullets_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "\n[ul]" + res.get_string("text").strip_edges() + "[/ul]")
		res = bullets_regex.search(text)

	var small_code_regex := RegEx.create_from_string("(?<!`)`(?<text>[^`]+)`")
	res = small_code_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "[code][color=" +
				get_theme_color("accent_color", "Editor").to_html() + "]"
				+ res.get_string("text").strip_edges() + "[/color][/code]")
		res = small_code_regex.search(text)

	var big_code_regex := RegEx.create_from_string("(?<!`)```(?<text>[^`]+)```")
	res = big_code_regex.search(text)
	while res:
		text = text.replace(res.get_string(), "\n[center][code][bgcolor=" +
				get_theme_color("box_selection_fill_color", "Editor").to_html() + "]"
				+ res.get_string("text").strip_edges() + "[/bgcolor][/code]\n")
		res = big_code_regex.search(text)

	return text


## Handle Install button pressed
func _on_install_button_pressed() -> void:
	install_update_requested.emit()
	
	# TODO: Add waiting for installation feedback