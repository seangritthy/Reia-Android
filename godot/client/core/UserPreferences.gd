extends Node
## AUTOLOAD: UserPreferences
## Handles saving and loading local client settings (Username, Audio Levels, Keybinds).

const PREFS_PATH = "user://client_prefs.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	var err := _config.load(PREFS_PATH)
	if err != OK:
		print("Failed to load user preferences: ", err)
	TranslationServer.set_locale(get_language())

func get_language() -> String:
	return _config.get_value("Language", "locale", "km")

func set_language(locale_code: String) -> void:
	_config.set_value("Language", "locale", locale_code)
	TranslationServer.set_locale(locale_code)
	var err := _config.save(PREFS_PATH)
	if err != OK:
		print("Failed to save language preference: ", err)

func save_username(username: String) -> void:
	_config.set_value("Auth", "username", username)
	var err := _config.save(PREFS_PATH)
	if err != OK:
		print("Failed to save user preferences: ", err)

func get_username() -> String:
	return _config.get_value("Auth", "username", "Adventurer")
