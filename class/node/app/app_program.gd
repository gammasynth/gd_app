#|*******************************************************************
# app_program.gd
#*******************************************************************
# This file is part of gd_app.
# 
# gd_app is an open-source software library.
# gd_app is licensed under the MIT license.
# https://github.com/gammasynth/gd_app
#*******************************************************************
# Copyright (c) 2025 AD - present; 1447 AH - present, Gammasynth.  
# 
# Gammasynth
# 
# Gammasynth (Gammasynth Software), Texas, U.S.A.
# https://gammasynth.com
# https://github.com/gammasynth
# 
# This software is licensed under the MIT license.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
#|*******************************************************************
extends AppBase

class_name AppProgram

var tested_internet_with_response:bool = false
var tested_internet_data:Dictionary = {}

func get_res_version() -> Dictionary:
	var res: Dictionary = File.load_dict_file("res://version.json")
	version = res.get("version")
	return res



static func get_unique_id() -> int:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	unique_id_count += 1
	rng.seed = game_seed + unique_id_count
	
	return rng.randi()



func _get_general_encryption_key() -> String: return str(floor(hash(title)*PI*hash(title)))

func _get_device_track_encryption_key() -> String: return _get_general_encryption_key()

func test_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	tested_internet_with_response = true
	tested_internet_data.set("result", result)
	tested_internet_data.set("response_code", response_code)
	tested_internet_data.set("headers", headers)
	tested_internet_data.set("body", body)

#request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray)
## Returns bool if an HTTP request made to [member AppBase.internet_connection_test_URL] return a successful 200 code. Use await when calling.
func is_connected_to_internet() -> bool:
	var http:HTTPRequest = HTTPRequest.new()
	await Make.child(http, self)
	
	http.request_completed.connect(test_http_completed)
	tested_internet_with_response = false
	tested_internet_data = {}
	
	var err:Error = http.request(internet_connection_test_URL)
	warn("Test Internet Connection", err)
	if err != OK: return false
	
	if not tested_internet_with_response: await http.request_completed
	
	if not tested_internet_data.is_empty() and tested_internet_data.has("result") and tested_internet_data.get("result") == 0: return true
	return false

func track_device_app() -> void:
	if not device_tracking: return
	if mandatory_device_tracking:
		if not await is_connected_to_internet():
			warn(str("Internet connection is required in order to use this " + product_type))
			if AlertSystem.instance: AlertSystem.do_alert(Alert.ALERT_TYPES.WARNING, "No Internet Connection!", str("This " + product_type + " requires an internet connection in order to operate! Closing..."), 3.0, 1.0)
			await get_tree().create_timer(2.0).timeout
			return force_close()
	
	if OS.get_name() == "Web":
		chatf("App is running in browser, skipping device track!")
		return
	
	state = APP_STATES.DEVICE_START_SESSION
	
	var res_version: Dictionary = get_res_version()
	
	DirAccess.make_dir_recursive_absolute("user://")
	if not FileAccess.file_exists("user://version.json"):
		File.save_dict_file(res_version, "user://version.json", _get_device_track_encryption_key())
		return
	else: 
		first_run = false
	
	if not FileAccess.file_exists("user://version.json"):
		warn("APP LACKS FILE ACCESS PERMISSIONS IN OPERATING SYSTEM, OR APP FILES WERE TAMPERED WITH.")
		warn("Missing version.json in user directory, possibly fatal, continuing...")
		warn("FILE PERMISSIONS ERROR!")
	
	var user_version: Dictionary = File.load_dict_file("user://version.json", _get_device_track_encryption_key())
	if not user_version.is_empty() and user_version.get("version") != version:
		chatf("App version is different than local user files versioning.", Text.COLORS.yellow)
		
		if clear_all_user_files_on_version_update:
			chatf("Clearing previous app user data.", Text.COLORS.orange)
			DirAccess.remove_absolute("user://")
			DirAccess.make_dir_recursive_absolute("user://")
		
		File.save_dict_file(res_version, "user://version.json", _get_device_track_encryption_key())
	
	_track_device_app()

func _track_device_app() -> void: pass

func deep_boot_info() -> void:
	if OS.get_name() == "Web":
		chatf("App is running in browser, skipping deep boot info!")
		return
	# ---
	
	#chat(str("engine args: " + str(OS.get_cmdline_args())))
	#chat(str("user args: " + str(OS.get_cmdline_user_args())))
	chatf(" ")
	
	#chat(str("omni is running on: " + str(OS.get_distribution_name()) + "; " + str(OS.get_model_name())))
	chatf(Text.color(str(product_type + " is running on: " + str(OS.get_distribution_name())), Text.COLORS.white))
	chatf(" ")
	
	# ---
	
	chatf(str("model: " + str(OS.get_model_name())))
	chatf(str("cpu: " + str(OS.get_processor_name())))
	chatf(str("cores: " + str(OS.get_processor_count())))
	chatf(" ")
	
	
	chatf(str("memory: " + str(OS.get_memory_info())))
	chatf(" ")
	
	chatf(str("locale: " + str(OS.get_locale())))
	chatf(" ")
	
	# ---
	
	chatf(str("data dir: " + OS.get_data_dir()))
	chatf(str("user data dir: " + OS.get_user_data_dir()))
	chatf(str("config dir: " + str(OS.get_config_dir())))
	chatf(str("cache dir: " + str(OS.get_cache_dir())))
	chatf(" ")
	
	# ---


func parse_boot_args() -> Error:
	if OS.get_name() == "Web":
		chatf("App is running in browser, skipping parse boot args!")
		return OK
	state = APP_STATES.PARSE_BOOT_ARGS
	
	var engine_args:PackedStringArray = OS.get_cmdline_args()
	var user_args:PackedStringArray = OS.get_cmdline_user_args()
	
	#var window: Window = Window.new()
	#window.force_native = true
	#
	#await Make.child(window, get_window())
	#return OK
	
	var os: String = OS.get_name()
	if os != "Windows" and os != "Linux": warn("not supported on this operating system!"); return ERR_SKIP
	
	
	
	var args: PackedStringArray = engine_args
	for arg in user_args:
		if not args.has(arg): args.append(arg)
	
	
	
	if args.has("dd"): deep_debug = true
	
	chatd(os)
	chatd(str("engine args: "))
	for arg in engine_args:
		if arg is String:
			if arg.begins_with("uid://"):
				var uid:int = ResourceUID.text_to_id(arg)
				
				if ResourceUID.has_id(uid):
					var uid_path:String = ResourceUID.get_id_path(uid)
					chatd(arg)
					arg = str("[from UID:] " + uid_path)
		chatd(arg)
	
	chatd(" - ")
	chatd(str("user args: "))
	for arg in user_args:
		chatd(arg)
	
	chatd(" - ")
	#
	if args.has("quit"): return ERR_SKIP
	#var is_main_instance:bool = true
	#
	#if args.has("is_sub"): is_main_instance = false
	
	#if args.has("loader"):
		#is_loader_instance = true
		#load_tracker = LoadTracker.new()
		#load_tracker.worker_started(1)
		#pre_load.emit()
		#if ui:
			#if ui_subduing:
				#await ui_mercy
		#return OK
	
	return await _parse_boot_args(engine_args, user_args)




func _parse_boot_args(_engine_args:PackedStringArray, _user_args:PackedStringArray) -> Error: return OK




func start_app_session() -> Error:
	state = APP_STATES.DEVICE_START_SESSION
	return await _start_app_session()

func _start_app_session() -> Error:
	return OK


func window_mouse_entered() -> void:
	_window_mouse_entered()

func _window_mouse_entered() -> void: pass

func window_mouse_exited() -> void:
	_window_mouse_exited()

func _window_mouse_exited() -> void: pass

# - - -

# App Operation

# - - -
## Returns bool true if AppProgram can be closed at this moment. [br][br]
## Override [method _query_close] instead to insert functionality.
func query_close() -> bool: return await _query_close()

## Return bool false if you need to prevent the AppProgram from closing.
func _query_close() -> bool:
	state = APP_STATES.QUERY
	# query_type = type_quit ~?
	# add close query confirm here before close code below
	# TODO
	return true

func closing() -> Error: return await _closing()

## Override this method to insert functionality to execute just prior to AppProgram closing.
func _closing() -> Error: return OK

static func force_close() -> void: close(true)

static func reboot(forced:bool=false) -> void: close(forced, true)

static func close(forced:bool=false, do_reboot:bool=false) -> void:
	if OS.get_name() == "Web":
		instance.chatf("App is running in browser, can't close!")
		return
	
	if forced:
		state = APP_STATES.CLOSING
		var close_err:Error = await instance.closing()
		instance.warn("_closing method", close_err)
		
		for pid in instance.related_window_pids:
			OS.kill(pid)
		instance.related_window_pids.clear()
		
		if do_reboot:
			instance.get_tree().reload_current_scene()
		else:
			instance.get_tree().quit()
		
	else:
		if not await instance.query_close(): return
		
		state = APP_STATES.CLOSING
		var close_err:Error = await instance.closing()
		instance.warn("_closing method", close_err)
		
		if ui:
			ui.queue_free()
		
		await instance.get_tree().process_frame
		
		if instance.registry:
			instance.registry.queue_free()
		
		for pid in instance.related_window_pids:
			OS.kill(pid)
		instance.related_window_pids.clear()
		
		await instance.get_tree().process_frame
		
		if do_reboot:
			instance.get_tree().reload_current_scene()
		else:
			instance.get_tree().quit()
