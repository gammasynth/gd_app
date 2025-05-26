extends AppExtendable
## App is a base Node class that can be extended from for a app's root Node, or used as a Singleton (AutoLoad).
## App should allow easy interaction between APIs in an application, and streamline SceneTree workflow.
class_name App

#signal core_system_event(event_name:String, event_text:String, event_importance:int)


static var app : App
static var debug_all:bool = false
static var deep_debug_all:bool = false

@export var debug_database : bool = false
@export var registry_system: bool = false

func _set_debug(b:bool) -> void: 
	db.debug = b
	db.debug_all = b
func _set_deep_debug(b:bool) -> void: 
	db.deep_debug = b
	db.deep_debug_all = b


func _initialized() -> void:
	if app or instance: push_error("No, only use one App.gd based node.")
	app = self
	instance = self
	
	session_seed = randi()
	game_seed = randi()
	seed(0)
	
	
	
	_app_initialized()

func _app_initialized() -> void:
	return


func _ready_up() -> Error:
	#get_window().ready.connect(start)
	#ready.connect(start)
	
	if not get_window().is_node_ready():
		await get_window().ready
	
	await start()
	
	return OK#await start()


func _pre_app_start() -> Error: 
	return OK




func _welcome_new_user() -> void: return



func _pre_start() -> Error:
	
	db.debug_toggled.connect(func(b:bool): debug_all = b)
	debug = debug
	
	db.deep_debug_toggled.connect(func(b:bool): deep_debug_all = b)
	deep_debug = deep_debug
	
	
	if not ui_scene_path.is_empty(): 
		ui = load(ui_scene_path).instantiate()
		await Make.child(ui, get_window())
	
	db.persona = title
	chatf(str("^&" + title), Text.COLORS.cyan)
	
	chatf("^&[gammasynth]", Text.COLORS.green)
	chatf(" ")
	
	track_device_app()
	
	
	var args_err: Error = await parse_boot_args()
	if args_err == OK: pass
	else:
		if args_err == ERR_SKIP:
			close()
			return OK
	
	if show_boot_info:
		deep_boot_info()
		chatf(" ")
	
	var framework_err:Error = await setup_app_framework()
	if framework_err != OK: return framework_err
	
	await setup_actions_handler()
	
	# begin app
	
	state = APP_STATES.BOOT
	
	chatf(str("^&Starting " + title + "..."))
	
	chat("debug mode", Text.COLORS.green)
	if debug_database: 
		chatf("debug database mode", Text.COLORS.green)
		
	chatf(" ")
	
	if first_run: await _welcome_new_user()
	# setup ui, if using
	
	await _pre_app_start()
	app_starting.emit()
	
	if ui:
		if ui_subduing:
			await ui_mercy
	
	
	
	# setup registry, if using
	
	if registry_system:
		await setup_registry_system()
		
		if debug_database: 
			var debug_db: Window
			debug_db = Registry.pull("debug", "debug_database_window.tscn")
			
			if not debug_db: debug_db = load("res://core/scene/prefab/debug/debug_database_window.tscn").instantiate()
			await Make.child(debug_db, self)
		
		chatf(str(product_type + " files inititalized!"))
	
	
	chatf(str("^&" + title + " started."), Text.COLORS.cyan)
	chatf(" ")
	
	
	var app_sesh_err:Error = await start_app_session()
	check("start_app_session", app_sesh_err)
	
	state = APP_STATES.RUNNING
	started = true
	
	return OK



#func _post_start() -> Error: 
	#return OK
#
#func _finish_tick() -> Error:
	#return OK



#static func system_event(event_name:String, event_text:String, event_importance:int=0) -> void:
	#var print_event:bool = false
	#if debug_all or instance and instance.debug: print_event = true
	#if event_importance > 0: print_event = true
	#if print_event:
		#print(str(event_importance) + " | " + event_name + " | " + event_text)
	#if instance: 
		#instance.core_system_event.emit(event_name, event_text, event_importance);
