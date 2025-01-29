extends DatabaseNode

class_name AppBase

enum APP_STATES {INIT, BOOT, REGISTRY_BOOT, LOADING, }
static var state : APP_STATES = APP_STATES.INIT


static var debug_all:bool = false
static var deep_debug_all:bool = false

static var title: String = ProjectSettings.get_setting("application/config/name")


@export var focusless_input : bool = false# TODO
var is_input_allowed: bool = true:
	get:
		if focusless_input: return true
		if get_window().has_focus():
			is_input_allowed = true
		else:
			is_input_allowed = false
		return is_input_allowed
