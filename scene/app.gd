extends AppBase
## App is a base Node class that can be extended from for a app's root Node, or used as a Singleton (AutoLoad).
## App should allow easy interaction between APIs in an application, and streamline SceneTree workflow.
class_name App

#signal core_system_event(event_name:String, event_text:String, event_importance:int)


static var app : App = null


@export var debug_database : bool = false
@export var registry_system: bool = false
var registry: Registry

static var session_seed : int = 0
static var game_seed : int = 0
static var unique_id_count : int = 0

var started: bool = false



var framework_worker: AppFrameworkWorker = null

func _initialized() -> void:
	if app: push_error("No, only use one App.gd based node.")
	app = self
	session_seed = randi()
	game_seed = randi()
	seed(0)
	
	db.persona = title
	print_rich(Text.color(title, Text.COLORS.cyan))
	
	track_device_app()
	
	_app_initialized()

func _app_initialized() -> void:
	return


func _ready_up() -> Error:
	get_window().ready.connect(start)
	return OK#await start()

func _pre_app_start() -> Error: 
	return OK



func _welcome_new_user() -> void: return

func _update_dependencies() -> Error: return OK

func _pre_start() -> Error:
	
	db.debug_toggled.connect(func(b:bool): debug_all = b)
	debug = debug
	
	db.deep_debug_toggled.connect(func(b:bool): deep_debug_all = b)
	deep_debug = deep_debug
	
	print_rich(Text.color("[gammasynth]", Text.COLORS.green))
	print(" ")
	
	
	if not ui_scene_path.is_empty(): 
		chatd("loading AppUI from path...")
		ui = load(ui_scene_path).instantiate()
		await Make.child(ui, get_window())
	
	
	var args_err: Error = await parse_boot_args()
	if args_err == OK: pass
	else:
		if args_err == ERR_SKIP:
			close()
			return OK
	
	if show_boot_info:
		deep_boot_info()
		print(" ")
	
	if not framework_worker:
		framework_worker = await AppFrameworkWorker.new()
		add_child(framework_worker)
		if not framework_worker.is_node_ready(): await framework_worker.ready
	
	var dep:Error = await _update_dependencies()
	if dep != OK: return dep
	
	# begin app
	
	state = APP_STATES.BOOT
	
	print_rich((str("Starting " + title + "...")))
	
	chat("debug mode", Text.COLORS.green)
	if debug_database: 
		chat("debug database mode", Text.COLORS.green, true)
		
	print(" ")
	
	if first_run: await _welcome_new_user()
	# setup ui, if using
	
	await _pre_app_start()
	#app_starting.emit()
	
	if ui:
		if ui_subduing:
			await ui_mercy
	
	
	
	# setup registry, if using
	
	if registry_system:
		state = APP_STATES.REGISTRY_BOOT
		await get_tree().create_timer(0.01).timeout
		print_rich((str("Preparing " + product_type + " files...")))
		
		
		if not registry:
			registry = Registry.new("Registry")
			await Make.child(registry, self)
			registry.load_tracker = LoadTracker.new()
			registry.load_tracker.finished.connect(func(): registry.load_tracker = null)
		
		load_tracker = registry.load_tracker
		load_tracker.finished.connect(func(): load_tracker = null)
		
		pre_load.emit()
		if ui:
			if ui_subduing:
				await ui_mercy
		
		registry.boot_load = true
		
		await registry.start()
		
		if debug_database: 
			var debug_db: Window
			if registry_system: debug_db = Registry.pull("debug", "debug_database_window.tscn")
			
			if not debug_db: debug_db = load("res://core/scene/prefab/debug/debug_database_window.tscn").instantiate()
			await Make.child(debug_db, self)
		
		print_rich((str(product_type + " files inititalized!")))
		#print(" ")
	
	
	print_rich(Text.color(str(title + " started."), Text.COLORS.cyan))
	print(" ")
	
	
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

func start_app_session() -> Error:
	state = APP_STATES.DEVICE_START_SESSION
	return await _start_app_session()

func _start_app_session() -> Error:
	return OK


#static func system_event(event_name:String, event_text:String, event_importance:int=0) -> void:
	#var print_event:bool = false
	#if debug_all or instance and instance.debug: print_event = true
	#if event_importance > 0: print_event = true
	#if print_event:
		#print(str(event_importance) + " | " + event_name + " | " + event_text)
	#if instance: 
		#instance.core_system_event.emit(event_name, event_text, event_importance);



static func get_unique_id() -> int:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	unique_id_count += 1
	rng.seed = game_seed + unique_id_count
	
	return rng.randi()




static func close() -> void:
	
	state = APP_STATES.QUERY
	# query_type = type_quit ~?
	# add close query confirm here before close code below
	
	state = APP_STATES.CLOSING
	
	
	if ui:
		ui.queue_free()
	
	await app.get_tree().process_frame
	
	if app.registry:
		app.registry.queue_free()
	
	await app.get_tree().process_frame
	
	app.get_tree().quit()
