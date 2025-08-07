extends AppProgram

class_name AppExtendable

signal action_recorded
signal action_undone
signal action_redone

var registry: Registry
@export var registry_system: bool = false
@export var debug_database : bool = false

var framework_worker: AppFrameworkWorker = null
var actions_handler: AppActionsHandler = null
var alert_system: AlertSystem = null
var chat_system: ChatSystem = null

static var user_profile: UserProfileData = null

#region App Framework Boot Setup

func setup_app_framework() -> Error:
	
	await setup_framework_worker()
	await try_update_framework()
	
	await setup_alert_system()
	await setup_chat_system()
	
	await setup_actions_handler()
	
	await setup_registry_system()
	
	return OK



func setup_framework_worker() -> Error:
	if not framework_worker:
		framework_worker = await AppFrameworkWorker.new()
		framework_worker.name = "app_framework_worker"
		await Make.child(framework_worker, self)
	return OK

func setup_alert_system() -> Error:
	if not alert_system:
		alert_system = await  AlertSystem.new()
		alert_system.name = "app_alert_system"
		await Make.child(alert_system, self)
	return OK

func setup_chat_system() -> Error:
	if not chat_system:
		chat_system = await  ChatSystem.new()
		chat_system.name = "app_chat_system"
		await Make.child(chat_system, self)
	return OK

func setup_actions_handler() -> Error:
	if not actions_handler:
		actions_handler = await AppActionsHandler.new()
		actions_handler.name = "app_actions_handler"
		await Make.child(actions_handler, self)
	return OK


func setup_registry_system() -> Error:
	state = APP_STATES.REGISTRY_BOOT
	await get_tree().create_timer(0.01).timeout
	chatf((str("Preparing " + product_type + " files...")))
	
	
	if not registry:
		registry = Registry.new("Registry")
		await Make.child(registry, self)
		registry.load_tracker = LoadTracker.new()
		registry.load_tracker.finished.connect(func(): 
			if ui and ui.current_loading_screen: 
				ui.current_loading_screen.queue_free()
			registry.load_tracker = null)
	
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
		debug_db = Registry.pull("debug", "debug_database_window.tscn")
		
		if not debug_db: debug_db = load("res://core/scene/prefab/debug/debug_database_window.tscn").instantiate()
		await Make.child(debug_db, self)
		
	
	chatf(str(product_type + " files inititalized!"))
	
	return OK
#endregion



#region Online Dependency Handling
## Override this function to download dependencies.
func _update_dependencies() -> Error: return OK

func try_update_framework() -> Error:
	var dep:Error = await _update_dependencies()
	if dep == OK: pass
	else:
		if dep == ERR_SKIP:
			force_close()
			return ERR_SKIP
	return OK
#endregion



#region Expose AppActions Static
func _app_extendable_unhandled_input(event: InputEvent) -> void:
	if event.is_action("ui_redo") and event.is_pressed():
		redo()
	if event.is_action("ui_undo") and event.is_pressed():
		undo()


static func undo(by_amount:int=1):
	var a:AppExtendable = instance as AppExtendable
	a.actions_handler.undo(by_amount)
	a.action_undone.emit()

static func redo(by_amount:int=1):
	var a:AppExtendable = instance as AppExtendable
	a.actions_handler.redo(by_amount)
	a.action_redone.emit()

static func record_action(action:AppAction):
	var a:AppExtendable = instance as AppExtendable
	a.actions_handler.record_action(action)
	a.action_recorded.emit()
#endregion
