extends DatabaseNode

class_name AppBase

enum APP_STATES {INIT, PARSE_BOOT_ARGS, BOOT, REGISTRY_BOOT, LOADING, RUNNING, QUERY, CLOSING}
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
