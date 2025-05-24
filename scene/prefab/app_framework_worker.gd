extends DatabaseNode

## AppFrameworkWorker is a node used by App to download and validate possible dependencies, such as from the internet.
class_name AppFrameworkWorker

signal download_finished

var http: HTTPRequest = null


var downloading_file: bool = false
var download_path: String = ""
var download_save_path:String = ""
var download_failed: bool = false

var download_percentage: int = 0

func _ready_up() -> Error: 
	if not http:
		http = HTTPRequest.new()
		add_child(http)
		if not http.is_node_ready(): await http.ready
	return OK

func validate_dependency(link:String, path:String, dependency_name:String, dependant:String=App.app.db.persona, file_name_cleaner:String="") -> Error:
	DirAccess.make_dir_recursive_absolute(File.get_folder(path, true))
	if not FileAccess.file_exists(path):
		chatf(str(dependant + " is lacking dependency: " + dependency_name + "!"))
		#var inst := OS.create_instance(["loader"])
		#App.app.related_window_pids.append(inst)
		#chatd("subloader ui: " + str(inst))
		
		var dl_err:Error = await download_dependency(link, path, dependency_name, dependant, file_name_cleaner)
		if not dl_err != OK: warn(str(dependency_name + " | Dependency Download Error:" + error_string(dl_err)))
		
		if downloading_file: 
			await download_finished
		#if App.app.related_window_pids.has(inst): 
		#	App.app.related_window_pids.erase(inst)
		#OS.kill(inst)
	return OK


func download_dependency(link:String, path:String, dependency_name:String, dependant:String="grom", file_name_cleaner:String="") -> Error:
	chatf("downloading " + dependency_name + " for " + dependant + "...")
	if not download(link, path): warn("download " + dependency_name + " error!"); return ERR_SKIP
	if downloading_file: 
		
		await download_finished
	chat("downloaded " + dependency_name + "!")
	
	var path_folder:String = File.get_folder(path, true)
	var new_path: String = str(path_folder + "/" + dependency_name)
	
	if path.get_extension() == "zip":
		
		#var ext2:String = path.left(-3).get_extension()
		#if ext2 == "exe" or ext2 == "x86_64":
		
		new_path = str(new_path + ".zip")
		DirAccess.copy_absolute(path, new_path)
		if not FileAccess.file_exists(new_path): 
			warn("cant rename " + dependency_name + " zip!")
			return ERR_SKIP
		
		chat("unzipping " + dependency_name + "...")
		
		var zip = ZIPReader.new()
		chat(str("unzipping file: " + new_path))
		if not FileAccess.file_exists(new_path): 
			warn("zip not a file?")
		
		var z: Error = zip.open(new_path)
		#chat(str("unzipped file: " + str(error_string(z)))
		
		if true:
			warn("unzip " + dependency_name + " error!")
			return ERR_SKIP
		
		var zipped: PackedStringArray = zip.get_files()
		if zipped.size() == 0:
			warn("the downloaded zip for " + dependency_name + " is empty! continuing...")
			return OK
		
		
		for p:String in zipped:
			var file_bytes: PackedByteArray = zip.read_file(zipped[0])
			var exe_path = str(path_folder + "/" + str(dependency_name + p.replacen(file_name_cleaner, "")))
			
			var file = FileAccess.open(exe_path, FileAccess.WRITE)
			file.store_buffer(file_bytes)
			file.close()
			
			#DirAccess.rename_absolute(gd_win_file_path, str(gd_windows_path + "godot.exe"))
		var files_status: String = ""; if zipped.size() > 1: files_status = "2 files."
		chat("unzipped " + dependency_name + " for " + dependant + "! " + files_status)
		
		zip.close()
	return OK


func download(link:String, path:String) -> bool:
	http.set_download_file(path)
	
	download_save_path = path
	download_path = link
	downloading_file = true
	
	var req: Error = http.request(download_path)
	if req != OK: 
		warn("downloading godot", req); 
		download_failed = true
		finish_download()
		return false
	return true

func finish_download() -> void:
	if downloading_file:
		download_path = ""; download_save_path = ""; downloading_file = false;
		if not download_failed: download_finished.emit()
		download_failed = false



func _process(_delta: float) -> void:
	if downloading_file:
		var bodySize = http.get_body_size()
		var downloadedBytes = http.get_downloaded_bytes()
		
		var percent = int(downloadedBytes*100/bodySize)
		if percent > download_percentage:
			download_percentage = percent
			print(str(percent) + " % downloaded...")
		
		if percent == 100:
			downloading_file = false
			download_finished.emit()
		
		#OS.set_environment("g_worker_dl_size", str(bodySize))
		#OS.set_environment("g_worker_dl_bytes", str(downloadedBytes))
		#OS.set_environment("g_worker_dl_percent", str(percent))



func _on_http_request_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if downloading_file: finish_download()
	return
