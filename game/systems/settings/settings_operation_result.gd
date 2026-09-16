class_name SettingsOperationResult
extends RefCounted

var success: bool = false
var reason_key: StringName = &""
var settings: SettingsProfile
var source_path: String = ""
var recovered_from_backup: bool = false


static func succeeded(
	profile: SettingsProfile,
	path: String = ""
) -> SettingsOperationResult:
	var result := SettingsOperationResult.new()
	result.success = true
	result.settings = profile
	result.source_path = path
	return result


static func failed(reason: StringName) -> SettingsOperationResult:
	var result := SettingsOperationResult.new()
	result.reason_key = reason
	return result
