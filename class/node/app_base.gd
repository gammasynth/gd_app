extends DatabaseNode

class_name AppBase

enum APP_STATES {
	INIT, 
	DEVICE_START_SESSION,
	PARSE_BOOT_ARGS, 
	BOOT, 
	REGISTRY_BOOT, 
	LOADING, 
	APP_START_SESSION,
	RUNNING, 
	QUERY, 
	CLOSING
	}

static var state : APP_STATES = APP_STATES.INIT


static var debug_all:bool = false
static var deep_debug_all:bool = false

static var title: String = ProjectSettings.get_setting("application/config/name")


## If the program is a game, and not general software.
@export var is_game : bool = false
@export var show_title_instead_of_product_type:bool = false
var product_type:String = "app":
	get:
		if is_game: product_type = "game"
		else: product_type = "app"
		if show_title_instead_of_product_type: product_type = title
		return product_type

@export var show_boot_info: bool = false


@export var focusless_input : bool = false# TODO
var is_input_allowed: bool = true:
	get:
		if focusless_input: return true
		if get_window().has_focus():
			is_input_allowed = true
		else:
			is_input_allowed = false
		return is_input_allowed

static var version: String = "0.0.0.1"
var first_run: bool = true
@export var mandatory_device_tracking: bool = true
@export var clear_all_user_files_on_version_update: bool = true

func get_res_version() -> void:
	var res: Dictionary = File.load_dict_file("res://version.json")
	version = res.get("version")


func _get_general_encryption_key() -> String: return str(floor(hash(title)*PI*hash(title)))

func _get_device_track_encryption_key() -> String: return _get_general_encryption_key()


func track_device_app() -> void:
	state = APP_STATES.DEVICE_START_SESSION
	
	get_res_version()
	
	DirAccess.make_dir_recursive_absolute("user://")
	if not FileAccess.file_exists("user://version.json"):
		var res_version: Dictionary = File.load_dict_file("res://version.json")
		File.save_dict_file(res_version, "user://version.json", _get_device_track_encryption_key())
		return
	else: first_run = false
	
	if not FileAccess.file_exists("user://version.json"):
		if mandatory_device_tracking: 
			print_rich("APP LACKS FILE ACCESS PERMISSIONS IN OPERATING SYSTEM, OR APP FILES WERE TAMPERED WITH. APP USAGE DENIED.")
			get_tree().quit()
			return
		else:
			warn("device tracking broken?")
			return
	
	var user_version: Dictionary = File.load_dict_file("user://version.json", _get_device_track_encryption_key())
	if user_version.get("version") != version:
		chat("App version is different than local user files versioning.", Text.COLORS.yellow)
		
		if clear_all_user_files_on_version_update:
			chat("Clearing previous app user data.", Text.COLORS.orange)
			DirAccess.remove_absolute("user://")
			DirAccess.make_dir_recursive_absolute("user://")
		
		var res_version: Dictionary = File.load_dict_file("res://version.json")
		File.save_dict_file(res_version, "user://version.json", _get_device_track_encryption_key())


func deep_boot_info() -> void:
	# ---
	
	chat(str("engine args: " + str(OS.get_cmdline_args())))
	chat(str("user args: " + str(OS.get_cmdline_user_args())))
	if debug: print(" ")
	
	#chat(str("omni is running on: " + str(OS.get_distribution_name()) + "; " + str(OS.get_model_name())))
	print_rich(Text.color(str(product_type + " is running on: " + str(OS.get_distribution_name())), Text.COLORS.white))
	print(" ")
	
	# ---
	
	chat(str("model: " + str(OS.get_model_name())))
	chat(str("cpu: " + str(OS.get_processor_name())))
	chat(str("cores: " + str(OS.get_processor_count())))
	if debug: print(" ")
	
	
	chat(str("memory: " + str(OS.get_memory_info())))
	if debug: print(" ")
	
	chat(str("locale: " + str(OS.get_locale())))
	if debug: print(" ")
	
	# ---
	
	chat(str("data dir: " + OS.get_data_dir()))
	chat(str("user data dir: " + OS.get_user_data_dir()))
	chat(str("config dir: " + str(OS.get_config_dir())))
	chat(str("cache dir: " + str(OS.get_cache_dir())))
	if debug: print(" ")
	
	# ---
