@tool
extends Node

# -----------------------------------------------------------------------------
# Update Manager
# -----------------------------------------------------------------------------
## Manager to handle updates for the Sprouty Dialogs plugin.
# -----------------------------------------------------------------------------

## Emitted when the update check is completed
signal update_checked(result: UpdateCheckResult)
## Emitted when a new version is received
signal new_version_received(update_info: Dictionary)
## Emitted when the download update is completed
signal download_completed(result: DownloadUpdateResult)

## Results for update check
enum UpdateCheckResult {UP_TO_DATE, UPDATE_AVAILABLE, FAILURE}
## Results for download update
enum DownloadUpdateResult {SUCCESS, FAILURE}

## GitHub releases API URL
const RELEASES_URL := "https://api.github.com/repos/SproutyLabs/SproutyDialogs/releases"
## Plugin folder name
const PLUGIN_FOLDER := "sprouty_dialogs"
## Temporary zip file path
const TEMP_ZIP_PATH := "user://temp.zip"

## Check update HTTP request
@onready var _update_check_request: HTTPRequest = $UpdateCheckRequest
## Download update HTTP request
@onready var _download_request: HTTPRequest = $DownloadUpdateRequest

## Current version of the plugin
var _current_version: String = ""
## New version release zip file URL
var _release_zip_url: String = ""


func _ready():
	_update_check_request.request_completed.connect(_on_update_check_request_completed)
	_download_request.request_completed.connect(_on_download_request_completed)


## Get the current version of the plugin
func get_current_version() -> String:
	if _current_version != "":
		return _current_version
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/" + PLUGIN_FOLDER + "/plugin.cfg")
	return plugin_cfg.get_value("plugin", "version", "unknown")


## Request to check for updates
func request_update_check() -> void:
	if _update_check_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_update_check_request.request(RELEASES_URL)


## Request to download the update
func request_download_update() -> void:
	_download_request.request(_release_zip_url)


## Handle update check request completed
func _on_update_check_request_completed(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	# Check for request success
	if result != HTTPRequest.RESULT_SUCCESS:
		update_checked.emit(UpdateCheckResult.FAILURE)
		return

	# Parse JSON response to get the latest release version
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_ARRAY: return

	var current_version := get_current_version()
	var last_release = response[0]
	var last_version = last_release["tag_name"].strip_edges().trim_prefix('v')

	if last_version.split(".").size() < 3:
		last_version += ".0" # Ensure semantic versioning format

	# Notify if an update is available
	if _compare_versions(last_version, current_version):
		_current_version = last_version
		_release_zip_url = last_release.zipball_url
		update_checked.emit(UpdateCheckResult.UPDATE_AVAILABLE)
		new_version_received.emit({
			"version": last_version,
			"date": last_release.published_at.split("T")[0],
			"author": last_release.author.login,
			"body": last_release.body
		})
	else:
		update_checked.emit(UpdateCheckResult.UP_TO_DATE)


## Compare two semantic version strings
func _compare_versions(v1: String, v2: String) -> bool:
	var parts1 = v1.split(".")
	var parts2 = v2.split(".")
	
	for i in range(max(parts1.size(), parts2.size())):
		if parts1[i] > parts2[i]:
			return true
	return false


## Handle download request completed
func _on_download_request_completed(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	# Check for request success
	if result != HTTPRequest.RESULT_SUCCESS:
		_current_version = ""
		download_completed.emit(DownloadUpdateResult.FAILURE)
		return
	
	# Save the downloaded zip
	var zip_file: FileAccess = FileAccess.open(TEMP_ZIP_PATH, FileAccess.WRITE)
	zip_file.store_buffer(body)
	zip_file.close()

	# Remove the old plugin files
	OS.move_to_trash(ProjectSettings.globalize_path("res://addons/" + PLUGIN_FOLDER))

	# Extract the zip contents to the addons directory
	var zip_reader: ZIPReader = ZIPReader.new()
	zip_reader.open(TEMP_ZIP_PATH)
	var files: PackedStringArray = zip_reader.get_files()

	var base_path: String = files[0].path_join('addons/')
	for path in files:
		if not PLUGIN_FOLDER in path:
			continue

		var new_file_path: String = path.replace(base_path, "")
		if path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute("res://addons/".path_join(new_file_path))
		else:
			var file: FileAccess = FileAccess.open("res://addons/".path_join(new_file_path), FileAccess.WRITE)
			file.store_buffer(zip_reader.read_file(path))

	zip_reader.close()
	DirAccess.remove_absolute(TEMP_ZIP_PATH)
	download_completed.emit(DownloadUpdateResult.SUCCESS)