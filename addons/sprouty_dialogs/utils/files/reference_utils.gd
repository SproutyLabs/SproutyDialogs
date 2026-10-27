@tool
class_name SproutyDialogsReferenceUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs Reference Utils
# -----------------------------------------------------------------------------
## This module is responsible for the resource references used in the plugin.
## A resource reference is a dictionary that stores the resource UID and its
## file path, so the resource can still be loaded by its path when the UID is
## no longer valid. It provides methods to create, check, resolve and load
## resource references.
# -----------------------------------------------------------------------------


## Creates a resource reference dictionary with the given resource UID and file
## path. This is the format used to store the resource references in the plugin
## data (e.g. the character references of the dialogue data).
static func create_reference_dict(uid: int = -1, path: String = "") -> Dictionary:
	if uid == -1 and path != "":
		return create_reference_from_path(path)
	if path == "" and uid != -1:
		return create_reference_from_uid(uid)
	return {"uid": uid, "path": path}


## Creates a resource reference dictionary for the resource by the given path.
## If the path is not valid, the path is still kept (with no UID) to not lose
## the reference data, so it can be recovered or resolved later.
static func create_reference_from_path(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {"uid": -1, "path": path}
	return {"uid": ResourceSaver.get_resource_id_for_path(path, true), "path": path}


## Creates a resource reference dictionary for the resource by the given UID.
## If the UID is not valid, the UID is still kept (with no path) to not lose
## the reference data, so it can be recovered or resolved later.
static func create_reference_from_uid(uid: int) -> Dictionary:
	if not SproutyDialogsFileUtils.check_valid_uid_path(uid):
		return {"uid": uid, "path": ""}
	return {"uid": uid, "path": ResourceUID.get_id_path(uid)}


## Normalizes a resource reference to a reference dictionary with "uid" and
## "path" keys. Accepts legacy references storing only the resource UID as an
## int, returning a reference dictionary with the UID and an empty path.
## Also, accept a String to create the reference dictionary from a path.
## Any other value is normalized to an empty reference dictionary.
static func normalize_reference_dict(reference: Variant) -> Dictionary:
	if reference is Dictionary:
		return {
			"uid": reference.get("uid", -1),
			"path": str(reference.get("path", "")),
		}
	if reference is int:
		return create_reference_from_uid(reference)
	if reference is String:
		return create_reference_from_path(reference)
	return create_reference_dict()


## Check if a resource reference is empty, meaning that it stores no usable
## resource UID nor file path.
static func is_reference_dict_empty(reference: Variant) -> bool:
	if not reference is Dictionary:
		return true
	var reference_normalized = normalize_reference_dict(reference)
	return reference_normalized["uid"] == -1 and reference_normalized["path"].is_empty()


## Returns the file path of a resource UID, using the given path as fallback
## when the UID is no longer valid (e.g. the resource was renamed or moved
## outside of the editor). Returns an empty string when none of them is valid.
static func get_reference_path_from_uid(uid: int, path_fallback: String = "") -> String:
	if SproutyDialogsFileUtils.check_valid_uid_path(uid):
		return ResourceUID.get_id_path(uid)
	if not path_fallback.is_empty() and ResourceLoader.exists(path_fallback):
		return path_fallback
	return ""


## Returns the resolved file path of a resource reference. The stored UID is
## resolved first, using the stored path as fallback when the UID is no longer
## valid. Returns an empty string when the path cannot be resolved.
static func get_reference_path(reference: Dictionary) -> String:
	return get_reference_path_from_uid(reference.get("uid", -1), str(reference.get("path", "")))


## Load a resource by its UID, using the given path as fallback.
## The resource is loaded from its UID path first; when the UID is no longer
## valid, the resource is loaded from the fallback path instead, if the file
## exists there. Returns null when the resource cannot be loaded.
static func load_resource(uid: int, path_fallback: String = "") -> Resource:
	var path: String = get_reference_path_from_uid(uid, path_fallback)
	if path.is_empty():
		return null
	return load(path)


## Load a resource from a resource reference.
## The resource is loaded from its stored UID first, using the stored path
## as fallback when the UID is no longer valid.
## Returns null when the resource cannot be loaded.
static func load_resource_from_reference(reference: Dictionary) -> Resource:
	if not reference.has("uid") or not reference.has("path"):
		printerr("[Sprouty Dialogs] Cannot load resource reference: " + str(reference))
		return null
	return load_resource(reference.get("uid", -1), str(reference.get("path", "")))
