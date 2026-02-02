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
@onready var _version_label: RichTextLabel = $NewVersionContainer/Header/Container/VersionLabel
## Published info label reference
@onready var _published_info_label: RichTextLabel = $NewVersionContainer/Header/Container/PublishedInfoLabel
## Release info label reference
@onready var _release_info_label: RichTextLabel = $NewVersionContainer/ReleaseInfoLabel

## Install button reference
@onready var _install_button: Button = $NewVersionContainer/InstallButton
## Restart button reference
@onready var _restart_button: Button = $InstallCompletePanel/Container/RestartButton
## Back button reference
@onready var _back_button: Button = $InstallCompletePanel/Container/BackButton


func _ready() -> void:
	_release_info_label.meta_clicked.connect(_on_url_meta_clicked)
	_install_button.pressed.connect(_on_install_button_pressed)
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_back_button.pressed.connect(func() -> void:
		$InstallCompletePanel.hide()
		$NewVersionContainer.show()
	)
	_restart_button.icon = get_theme_icon("Reload", "EditorIcons")
	$NewVersionContainer.show()
	$InstallCompletePanel.hide()
	$LoadingPanel.hide()
	hide()


## Set the release information for the update panel
func set_release_info(update_info: Dictionary) -> void:
	_version_label.text = "[color=orange][b][i][font s=36]New Version " + update_info.version + " Available!"
	_published_info_label.text = "[color=gray][i]Published on " + update_info.date + " by " + update_info.author
	_release_info_label.text = _markdown_to_bbcode(update_info.body)


## Handle download completed
func download_completed(result: int) -> void:
	$InstallCompletePanel.show()
	$LoadingPanel.hide()
	match result:
		0: # Success
			$InstallCompletePanel/Container/RichTextLabel.text = "[center][color=greenyellow]Update installed succesfully![/color]" \
					+"\n\nPlease restart the editor\nto apply the update."
			_restart_button.show()
			_back_button.hide()
		1: # Failure
			$InstallCompletePanel/Container/RichTextLabel.text = "[center][color=tomato]The update could not be installed.[/color]" \
					+"\n\nPlease try again later."
			_restart_button.hide()
			_back_button.show()


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
	$LoadingPanel.show()
	$NewVersionContainer.hide()
	install_update_requested.emit()
	$LoadingPanel/Container/LoadingIcon/Animation.play()


## Handle Restart button pressed
func _on_restart_button_pressed() -> void:
	Engine.get_singleton("EditorInterface").restart_editor(true)


## Handle URLs clicked in release info
func _on_url_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))