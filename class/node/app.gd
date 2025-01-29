extends AppBase
## App is a base Node class that can be extended from for a app's root Node, or used as a Singleton (AutoLoad).
## App should allow easy interaction between APIs in an application, and streamline SceneTree workflow.
class_name App

#signal core_system_event(event_name:String, event_text:String, event_importance:int)

signal app_starting

signal pre_load

signal ui_mercy

static var app : App = null

## If the program is a game, and not general software.
@export var is_game : bool = false
@export var show_title_instead_of_product_type:bool = false

static var ui:Control = null# This needs to be an AppUI node, if using GUI for this App.
var ui_subduing:bool = false

@export var debug_database : bool = false
@export var registry_system: bool = false
var registry: Registry

static var session_seed : int = 0
static var game_seed : int = 0
static var unique_id_count : int = 0

var started: bool = false




func _initialized() -> void:
	if app: push_error("No, only use one App.gd based node.")
	app = self
	session_seed = randi()
	game_seed = randi()
	seed(0)

func _ready_up() -> Error:
	return await start()

func _pre_app_start() -> Error: 
	return OK


func _pre_start() -> Error:
	db.debug_toggled.connect(func(b:bool): debug_all = b)
	debug = debug
	
	db.deep_debug_toggled.connect(func(b:bool): deep_debug_all = b)
	deep_debug = deep_debug
	
	state = APP_STATES.BOOT
	
	print_rich(Text.color("[gammasynth]", Text.COLORS.green))
	print(" ")
	print_rich((str("Starting " + title + "...")))
	
	chat("debug mode", Text.COLORS.green)
	if debug_database: 
		chat("debug database mode", Text.COLORS.green, true)
		
	print(" ")
	
	
	await _pre_app_start()
	app_starting.emit()
	
	if ui:
		if ui_subduing:
			await ui_mercy
	
	
	
	var product_type:String = "app"; if is_game: product_type = "game"
	if show_title_instead_of_product_type: product_type = title
	
	if registry_system:
		state = APP_STATES.REGISTRY_BOOT
		await get_tree().create_timer(0.01).timeout
		print_rich((str("Preparing " + product_type + " files...")))
		
		if not registry:
			registry = Registry.new("Registry")
			await Make.child(registry, self)
		
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
	
	print_rich((str(title + " started.")))
	print(" ")
	
	started = true
	
	return OK


func _finish_tick() -> Error:
	print_rich(Text.color(str(title + " started."), Text.COLORS.cyan))
	print(" ")
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
