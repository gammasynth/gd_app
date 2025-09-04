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

#region Set Image to OS Clipboard

## Special thanks to https://github.com/MewPurPur/GodSVG
static func copy_image_to_os(img:Image) -> void:
	match OS.get_name():
		"Web":
			copy_image_to_web(img)
		"Windows":
			copy_image_to_windows(img)
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			copy_image_to_linux(img)
		"Android":
			instance.warn("Copy image not implemented on Android!")
			# TODO

static func copy_image_to_web(img:Image) -> void:
	AlertSystem.create_alert("Copying Image...", "Attempting to copy an Image to the clipboard...")
	JavaScriptBridge.eval("""
		window.copyImageToClipboard = (data, mimeType) => {
			const blob = new Blob([data], { "type": mimeType });
			console.log(mimeType);
			navigator.clipboard.write([new ClipboardItem({ [mimeType]: blob })]);
		}
	""")
	var mime_type:String = "image/png"
	var image_buf := img.save_png_to_buffer()
	var buf = JavaScriptBridge.create_object("ArrayBuffer", image_buf.size())
	var data = JavaScriptBridge.create_object("Uint8Array", buf)
	for i in len(image_buf):
		data[i] = image_buf[i]
	JavaScriptBridge.get_interface("window").window.copyImageToClipboard(data, mime_type)
	AlertSystem.create_alert("Copied Image!", "An image was copied to the OS clipboard.", 3.5, 2.0)

static func copy_image_to_windows(img:Image) -> void:
	var cmd_output:Array = []
	DirAccess.make_dir_recursive_absolute("user://temp/")
	var temp_path: String = "user://temp/buffer_image.png"
	img.save_png(temp_path)
	var file:FileAccess = FileAccess.open(temp_path, FileAccess.READ)
	temp_path = file.get_path_absolute()
	
	
	AlertSystem.create_alert("Copying Image...", "Attempting to copy an Image to the clipboard...")
	if ui: await RenderingServer.frame_post_draw
	var ps_script: String = """
			Add-Type -AssemblyName System.Windows.Forms;
			$bmp = New-Object Drawing.Bitmap('%s');
			[Windows.Forms.Clipboard]::SetImage($bmp)
		""" % temp_path.replace('\\', '/')
	var e := OS.execute("powershell.exe", ["-Command", ps_script], cmd_output, true)
	if e < 0: instance.warn(str("Failed powershell image copy command! | " + str(cmd_output)))
	else: AlertSystem.create_alert("Copied Image!", "An image was copied to the OS clipboard.", 3.5, 2.0)
	print(cmd_output)

static func copy_image_to_linux(img:Image) -> void:
	var cmd_output:Array = []
	var mime_type:String = "image/png"
	var display_manager_arr := []
	AlertSystem.create_alert("Copying Image...", "Attempting to copy an Image to the clipboard...")
	OS.execute("echo", ["$XDG_SESSION_TYPE"], display_manager_arr)
	var using_x11 := "x11" in "".join(display_manager_arr)
	
	# System clipboard utils.
	const x11_utils := ["xclip"]
	const wayland_utils := ["xclip", "wl-copy"]
	var usable_utils := (x11_utils if using_x11 else wayland_utils)
	
	# Trying every available clipboard util
	var cmd := []
	var exit_code := -99
	var temp_path: String = "user://temp/buffer_image.png"
	for util in usable_utils:
		if OS.execute("which", [util]) == 0:
			match util:
				"xclip":
					cmd = ["xclip", "-selection", "clipboard", "-l", "1", "-quiet", "-t", mime_type, "-i", temp_path]
					exit_code = OS.execute(cmd[0], cmd.slice(1, len(cmd)-1), cmd_output, true)
				"wl-copy":
					cmd = ["wl-copy -f -t %s < '%s'" % [mime_type, temp_path]]
					var dict := OS.execute_with_pipe("bash", ["-c", "".join(cmd)], false)
					if dict.is_empty():
						return instance.warn(str("Failed wl-copy image copy command! | " + str(cmd_output)))
					var stdio: FileAccess = dict.stdio
					cmd_output.append(stdio.get_pascal_string())
					stdio.close()
					var secs_waited := 0
					while OS.is_process_running(dict.pid):
						OS.delay_msec(1000)
						secs_waited += 1
						if secs_waited > 2:
							OS.kill(dict.pid)
							instance.warn("Timed out waiting for wl-copy")
					exit_code = OS.get_process_exit_code(dict.pid)
			if exit_code == 0:
				AlertSystem.create_alert("Copied Image!", "An image was copied to the OS clipboard.", 3.5, 2.0)
#endregion
