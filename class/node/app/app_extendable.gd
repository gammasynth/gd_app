extends AppProgram

class_name AppExtendable

signal action_recorded
signal action_undone
signal action_redone

var registry: Registry

var framework_worker: AppFrameworkWorker = null
var actions_handler: AppActionsHandler = null

func _update_dependencies() -> Error: return OK

func setup_app_framework() -> Error:
	if not framework_worker:
		framework_worker = await AppFrameworkWorker.new()
		framework_worker.name = "app_framework_worker"
		await Make.child(framework_worker, self)
	
	var dep:Error = await _update_dependencies()
	if dep == OK: pass
	else:
		if dep == ERR_SKIP:
			force_close()
			return ERR_SKIP
	return OK


func setup_registry_system() -> Error:
	state = APP_STATES.REGISTRY_BOOT
	await get_tree().create_timer(0.01).timeout
	chatf((str("Preparing " + product_type + " files...")))
	
	
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
	return OK


func setup_actions_handler() -> Error:
	if not actions_handler:
		actions_handler = await AppActionsHandler.new()
		actions_handler.name = "app_actions_handler"
		await Make.child(actions_handler, self)
	return OK


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
